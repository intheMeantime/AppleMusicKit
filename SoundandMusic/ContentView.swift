//
//  ContentView.swift
//  SoundandMusic
//
//  Created by nooy on 6/2/26.
//

import SwiftUI
import MusicKit
import AppKit   // NSEvent 모니터링

// MARK: - ContentView (TabView 루트)

struct ContentView: View {
    @StateObject private var musicManager = MusicManager()
    
    var body: some View {
        VStack(spacing: 0) {
            AuthStatusBar(musicManager: musicManager)
            
            TabView {
                Tab1SearchPlayView(musicManager: musicManager)
                    .tabItem { Label("재생", systemImage: "play.circle") }
                
                Tab2ArtworkView(musicManager: musicManager)
                    .tabItem { Label("아트워크", systemImage: "photo") }
                
                Tab3RecommendationsView(musicManager: musicManager)
                    .tabItem { Label("추천", systemImage: "star.circle") }
                
                Tab4ReplayView(musicManager: musicManager)
                    .tabItem { Label("Replay", systemImage: "calendar.badge.clock") }
            }
        }
        .frame(minWidth: 480, minHeight: 640)
        .onAppear {
            Task { await musicManager.requestAuthorization() }
        }
    }
}

// MARK: - 상단 권한 상태 바

struct AuthStatusBar: View {
    @ObservedObject var musicManager: MusicManager
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(musicManager.isAuthorized ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(musicManager.isAuthorized ? "Apple Music 연결됨" : "연결 필요")
                .font(.subheadline)
                .foregroundColor(.secondary)
            if !musicManager.isAuthorized {
                Button("권한 요청") {
                    Task { await musicManager.requestAuthorization() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}


// ═══════════════════════════════════════════════════
// MARK: - 탭 1: 검색 + 키보드 재생
// ═══════════════════════════════════════════════════

struct Tab1SearchPlayView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var keyword = ""
    
    // NSEvent 모니터 핸들
    @State private var localKeyMonitor: Any? = nil   // 앱 포커스 시
    @State private var globalKeyMonitor: Any? = nil  // 앱 밖에서도 감지 (Accessibility 권한 필요)
    @State private var hasAccessibilityPermission: Bool = AXIsProcessTrusted()
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── 검색 바 ──────────────────────────────
            HStack {
                TextField("곡 제목 또는 아티스트 검색", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { search() }
                // 키보드 모드 ON이면 TextField 비활성화
//                    .disabled(musicManager.isKeyboardModeEnabled)
                
                Button("검색") { search() }
                    .disabled(!musicManager.isAuthorized
                              || keyword.trimmingCharacters(in: .whitespaces).isEmpty
                              || musicManager.isKeyboardModeEnabled)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // ── 키보드 모드 컨트롤 패널 ───────────────
            KeyboardModePanel(musicManager: musicManager,
                              hasAccessibilityPermission: $hasAccessibilityPermission)
            
            Divider()
            
            // ── 검색 결과 리스트 ─────────────────────
            if musicManager.searchResults.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("검색어를 입력하세요")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List(musicManager.searchResults) { song in
                    SongRowView(
                        song: song,
                        isPlaying: musicManager.nowPlayingSong?.id == song.id
                        && musicManager.isPlaying,
                        isSelected: musicManager.selectedSong?.id == song.id,
                        isKeyboardMode: musicManager.isKeyboardModeEnabled
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        musicManager.handleSongTap(song)
                    }
                }
                .listStyle(.plain)
            }
        }
        // ── NSEvent 키보드 모니터 ────────────────────
        .onAppear {
            hasAccessibilityPermission = AXIsProcessTrusted()
            startKeyMonitor()
        }
        .onDisappear { stopKeyMonitor() }
        .onChange(of: musicManager.isKeyboardModeEnabled) { _ in
            stopKeyMonitor()
            startKeyMonitor()
        }
        // 권한이 새로 생기면 글로벌 모니터 재등록
        .onChange(of: hasAccessibilityPermission) { granted in
            if granted { stopKeyMonitor(); startKeyMonitor() }
        }
    }
    
    // MARK: - 검색
    
    private func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await musicManager.searchSong(keyword: trimmed) }
    }
    
    // MARK: - 키보드 모니터 등록 / 해제
    
    private func startKeyMonitor() {
        guard localKeyMonitor == nil else { return }
        
        // ── 로컬 모니터: 앱이 Key Window일 때 ──────
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.shouldHandleKey(event) else { return event }
            self.musicManager.handleKeyPress(key: event.charactersIgnoringModifiers ?? "")
            return nil  // 이벤트 소비 (TextField 등으로 전달 안 함)
        }
        
        // ── 글로벌 모니터: 다른 앱이 앞에 있어도 감지 ─
        // Accessibility 권한이 없으면 addGlobalMonitor는 nil 반환
        if AXIsProcessTrusted() {
            globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                guard self.shouldHandleKey(event) else { return }
                // 글로벌 모니터는 MainActor 보장이 없으므로 명시적으로 전환
                Task { @MainActor in
                    self.musicManager.handleKeyPress(
                        key: event.charactersIgnoringModifiers ?? ""
                    )
                }
            }
        }
    }
    
    private func stopKeyMonitor() {
        if let m = localKeyMonitor  { NSEvent.removeMonitor(m); localKeyMonitor  = nil }
        if let m = globalKeyMonitor { NSEvent.removeMonitor(m); globalKeyMonitor = nil }
    }
    
    /// 키 이벤트를 MusicManager로 넘길지 판단
    private func shouldHandleKey(_ event: NSEvent) -> Bool {
        guard musicManager.isKeyboardModeEnabled,
              musicManager.selectedSong != nil else { return false }
        let key = event.charactersIgnoringModifiers ?? ""
        guard !key.isEmpty else { return false }
        // Command / Control / Option 조합키는 무시
        return event.modifierFlags.intersection([.command, .control, .option]).isEmpty
    }
}

// MARK: - 키보드 모드 컨트롤 패널

struct KeyboardModePanel: View {
    @ObservedObject var musicManager: MusicManager
    @Binding var hasAccessibilityPermission: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── 상단: 토글 + 선택된 곡 정보 ──────────
            HStack(spacing: 12) {
                
                // 키보드 모드 토글
                Toggle(isOn: Binding(
                    get: { musicManager.isKeyboardModeEnabled },
                    set: { _ in musicManager.toggleKeyboardMode() }
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "keyboard")
                            .foregroundColor(musicManager.isKeyboardModeEnabled
                                             ? .accentColor : .secondary)
                        Text("키보드 모드")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .toggleStyle(.switch)
//                .disabled(musicManager.searchResults.isEmpty)
                
                Spacer()
                
                // ── 여기 추가 ────── 재생 중지 간격 커스텀 설정 ────────────────────
                if musicManager.isKeyboardModeEnabled {
                    HStack(spacing: 6) {
                        Text("매")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Stepper(
                            value: $musicManager.pauseInterval,
                            in: 2...20
                        ) {
                            Text("\(musicManager.pauseInterval)번")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.primary)
                                .frame(minWidth: 28)
                        }
                        .fixedSize()
                        
                        Text("마다 ⏸")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                // ────────────────────────────────────────
                
                // 선택된 곡 표시
                if let song = musicManager.selectedSong {
                    HStack(spacing: 6) {
                        if let artwork = song.artwork {
                            ArtworkImage(artwork, width: 24, height: 24)
                                .cornerRadius(3)
                        }
                        Text(song.title)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        Text("선택됨")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                } else if musicManager.isKeyboardModeEnabled {
                    Label("곡을 클릭해서 선택하세요", systemImage: "cursorarrow.click")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // ── 키보드 모드 ON일 때: 안내 + 키 로그 ──
            if musicManager.isKeyboardModeEnabled {
                VStack(spacing: 8) {
                    
                    // 상태 안내
                    HStack(spacing: 8) {
                        Image(systemName: musicManager.selectedSong == nil
                              ? "exclamationmark.circle" : "checkmark.circle.fill")
                        .foregroundColor(musicManager.selectedSong == nil
                                         ? .orange : .green)
                        Text(musicManager.selectedSong == nil
                             ? "리스트에서 곡을 선택하면 키 입력으로 재생/정지됩니다"
                             : "키를 눌러보세요 — ▶ 재생 / ⏸ 정지")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        Spacer()
                        if musicManager.keyPressCount > 0 {
                            Text("총 \(musicManager.keyPressCount)회")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // Accessibility 권한 경고
                    if !hasAccessibilityPermission {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("앱 밖에서도 키 입력을 받으려면 손쉬운 사용 권한이 필요합니다")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("권한 설정") {
                                // 시스템 손쉬운 사용 설정 열기
                                NSWorkspace.shared.open(
                                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                                )
                            }
                            .font(.caption2)
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .onReceive(
                                NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
                            ) { _ in
                                // 설정에서 돌아올 때 권한 상태 재확인
                                hasAccessibilityPermission = AXIsProcessTrusted()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.06))
                        .cornerRadius(6)
                        .padding(.horizontal)
                    }
                    
                    // 키 로그 스크롤 뷰
                    if !musicManager.keyLog.isEmpty {
                        KeyLogScrollView(log: musicManager.keyLog)
                    }
                }
                .padding(.bottom, 10)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .background(
            musicManager.isKeyboardModeEnabled
            ? Color.accentColor.opacity(0.04)
            : Color.clear
        )
        .animation(.easeInOut(duration: 0.2), value: musicManager.isKeyboardModeEnabled)
    }
}

// MARK: - 키 로그 가로 스크롤 뷰

struct KeyLogScrollView: View {
    let log: [KeyLogEntry]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(log) { entry in
                    KeyLogCell(entry: entry)
                    // 최신 항목(맨 앞)이 살짝 크게
                        .scaleEffect(entry.id == log.first?.id ? 1.05 : 1.0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(height: 52)
    }
}

// MARK: - 키 로그 셀

struct KeyLogCell: View {
    let entry: KeyLogEntry
    
    var body: some View {
        VStack(spacing: 2) {
            Text(entry.key)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(entry.action.isPlay ? .primary : .secondary)
            
            Text(entry.action.label)
                .font(.system(size: 10))
                .foregroundColor(entry.action.isPlay ? .accentColor : .orange)
        }
        .frame(width: 36, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(entry.action.isPlay
                      ? Color.accentColor.opacity(0.12)
                      : Color.orange.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            entry.action.isPlay
                            ? Color.accentColor.opacity(0.3)
                            : Color.orange.opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.7).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

// MARK: - NowPlaying 바

struct NowPlayingBar: View {
    let song: Song
    let isPlaying: Bool
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .foregroundColor(.accentColor)
            
            if let artwork = song.artwork {
                ArtworkImage(artwork, width: 34, height: 34)
                    .cornerRadius(4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline).bold()
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 재생 중 파형 인디케이터
            if isPlaying {
                WaveformIndicator()
            } else {
                Image(systemName: "pause.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
            
            Button {
                onStop()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.accentColor.opacity(0.08))
    }
}

// MARK: - 파형 인디케이터

struct WaveformIndicator: View {
    @State private var phase = false
    
    let heights: [CGFloat] = [6, 14, 10, 18, 8]
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(heights.indices, id: \.self) { i in
                let barHeight: CGFloat = phase ? heights[i] : heights[(i + 2) % heights.count]
                let duration: Double = 0.4 + Double(i) * 0.1
                let delay: Double = Double(i) * 0.08
                let anim: Animation = .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: barHeight)
                    .animation(anim, value: phase)
            }
        }
        .frame(height: 20)
        .onAppear { phase = true }
    }
}

// MARK: - 곡 행 뷰 (선택 상태 추가)

struct SongRowView: View {
    let song: Song
    let isPlaying: Bool
    let isSelected: Bool
    let isKeyboardMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            
            // 아트워크 + 상태 오버레이
            ZStack {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 120, height: 120)
                        .cornerRadius(6)
                }
                if isPlaying {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 46, height: 46)
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                } else if isSelected && isKeyboardMode {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                        .frame(width: 46, height: 46)
                }
            }
            .frame(width: 150, height: 150)
            
            // 텍스트 정보
            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.body)
                    .foregroundColor(isPlaying ? .accentColor
                                     : isSelected ? .accentColor
                                     : .primary)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let album = song.albumTitle {
                    Text(album)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                        .lineLimit(1)
                }
                // 1. 식별자 및 기본 정보
                Text("ID(id): \(song.id.rawValue)")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("장르(genreNames): \(song.genreNames.isEmpty ? "-" : song.genreNames.joined(separator: ", "))")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("재생 시간(duration): \(song.duration != nil ? "\(Int(song.duration!))초" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("트랙 번호(trackNumber): \(song.trackNumber != nil ? "\(song.trackNumber!)" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("디스크 번호(discNumber): \(song.discNumber != nil ? "\(song.discNumber!)" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("발매일(releaseDate): \(song.releaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("ISRC 코드(isrc): \(song.isrc ?? "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                // 2. 클래식 음악 관련 프로퍼티
                Text("작품명(workName): \(song.workName ?? "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("악장명(movementName): \(song.movementName ?? "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("악장 번호(movementNumber): \(song.movementNumber != nil ? "\(song.movementNumber!)" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("총 악장 수(movementCount): \(song.movementCount != nil ? "\(song.movementCount!)" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("클래식 기여(attribution): \(song.attribution ?? "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("작곡가(composerName): \(song.composerName ?? "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                // 3. 특성 및 상태 정보
                Text("가사 보유 여부(hasLyrics): \(song.hasLyrics ? "있음" : "없음")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("Apple Digital Master 여부(isAppleDigitalMaster): \(song.isAppleDigitalMaster != nil ? (song.isAppleDigitalMaster! ? "예" : "아니오") : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("콘텐츠 등급(contentRating): \(song.contentRating != nil ? String(describing: song.contentRating!) : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("내 재생 횟수(playCount): \(song.playCount != nil ? "\(song.playCount!)회" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                // 4. URL 및 미디어 자산 정보
                Text("애플 뮤직 링크(url): \(song.url?.absoluteString ?? "-")")
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
                
                Text("아티스트 링크(artistURL): \(song.artistURL?.absoluteString ?? "-")")
                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
                
                Text("오디오 음질 버전(audioVariants): \(song.audioVariants != nil ? song.audioVariants!.map { "\($0)" }.joined(separator: ", ") : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                // 5. 연관된 MusicItem 관계성 데이터 (위 주석 참고)
                Text("연관 아티스트 수(artists): \(song.artists != nil ? "\(song.artists!.count)개" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("연관 앨범 수(albums): \(song.albums != nil ? "\(song.albums!.count)개" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("연관 작곡가 수(composers): \(song.composers != nil ? "\(song.composers!.count)개" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("연관 장르 객체 수(genres): \(song.genres != nil ? "\(song.genres!.count)개" : "-")")
                    .font(.caption).foregroundColor(.secondary)
                
                Text("연관 뮤직비디오 수(musicVideos): \(song.musicVideos != nil ? "\(song.musicVideos!.count)개" : "-")")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 우측 아이콘
            Group {
                if isPlaying {
                    Image(systemName: "waveform")
                        .foregroundColor(.accentColor)
                        .symbolEffect(.variableColor)
                } else if isSelected && isKeyboardMode {
                    // 키보드 모드에서 선택된 곡
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Text("선택")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(5)
                } else if isKeyboardMode {
                    Image(systemName: "cursorarrow.click")
                        .foregroundColor(.secondary.opacity(0.35))
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "play.circle")
                        .foregroundColor(.secondary.opacity(0.4))
                        .font(.system(size: 18))
                }
            }
        }
        .padding(.vertical, 4)
        // 선택된 곡은 배경 강조
        .background(
            isSelected && isKeyboardMode
            ? Color.accentColor.opacity(0.05)
            : Color.clear
        )
        .cornerRadius(6)
    }
}


// ═══════════════════════════════════════════════════
// MARK: - 탭 2: 아트워크 전용 검색
// ═══════════════════════════════════════════════════

struct Tab2ArtworkView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var keyword = ""
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("앨범 커버를 볼 곡/아티스트 검색", text: $keyword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { search() }
                Button("검색") { search() }
                    .disabled(!musicManager.isAuthorized
                              || keyword.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            
            Divider()
            
            if musicManager.artworkSearchResults.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("검색 결과의 앨범 커버가 표시됩니다")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(musicManager.artworkSearchResults) { song in
                            ArtworkCellView(song: song)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
    
    private func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await musicManager.searchArtwork(keyword: trimmed) }
    }
}

struct ArtworkCellView: View {
    let song: Song
    @State private var isHovered = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 아트워크 있으면 띄우기
            if let artwork = song.artwork {
                VStack(spacing: 8) {
                    ArtworkImage(artwork, width: .infinity, height: 300)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                    
                    // ================= [아트워크 프로퍼티 출력 부분] =================
                    VStack(alignment: .leading, spacing: 4) {
                        Text("--- Artwork Properties ---")
                            .font(.caption).bold()
                            .foregroundColor(.secondary)
                        
                        Text("가로 크기(width): \(artwork.maximumWidth)px")
                        Text("세로 크기(height): \(artwork.maximumHeight)px")
                        
                        // 대체 텍스트
                        Text("대체텍스트(alternateText): \(artwork.alternateText != nil ? "\(artwork.alternateText!)" : "-")")
                        
                        
                        // 배경색 (CGColor 또는 정형화된 형태, 옵셔널 처리)
                        // The average background color of the image.
                        Text("배경색(backgroundColor): \(artwork.backgroundColor != nil ? "\(artwork.backgroundColor!)" : "-")")
                            .background(
                                artwork.backgroundColor.map { Color(cgColor: $0) } ?? .clear
                            )
                        
                        // 텍스트 색상들 (옵셔널 처리)
                        Text("기본 텍스트 색상(primaryTextColor): \(artwork.primaryTextColor != nil ? "\(artwork.primaryTextColor!)" : "-")")
                            .background(
                                artwork.primaryTextColor.map { Color(cgColor: $0) } ?? .clear
                            )
                        Text("배경 보조 텍스트 색상(quaternaryTextColor): \(artwork.quaternaryTextColor != nil ? "\(artwork.quaternaryTextColor!)" : "-")")
                            .background(
                                artwork.quaternaryTextColor.map { Color(cgColor: $0) } ?? .clear
                            )
                        Text("삼차 텍스트 색상(secondaryTextColor): \(artwork.secondaryTextColor != nil ? "\(artwork.secondaryTextColor!)" : "-")")
                            .background(
                                artwork.secondaryTextColor.map { Color(cgColor: $0) } ?? .clear
                            )
                        Text("사차 텍스트 색상(tertiaryTextColor): \(artwork.tertiaryTextColor != nil ? "\(artwork.tertiaryTextColor!)" : "-")")
                            .background(
                                artwork.tertiaryTextColor.map { Color(cgColor: $0) } ?? .clear
                            )
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
            } else {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.15))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                        )
                    
                    Text("아트워크 정보가 없습니다.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 호버 시 곡 정보 오버레이
            if isHovered {
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.caption).bold()
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(song.artistName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(1.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                // ⚠️ .cornerRadius(8, corners: [...]) 커스텀 Extension을 사용하는 형태에 맞게 유지
                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
            }
        }
        .cornerRadius(8)
        .onHover { isHovered = $0 }
    }
}


// ═══════════════════════════════════════════════════
// MARK: - 탭 3: 개인 추천
// ═══════════════════════════════════════════════════

struct Tab3RecommendationsView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("나를 위한 추천")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        isLoading = true
                        await musicManager.fetchRecommendations()
                        isLoading = false
                    }
                } label: {
                    if isLoading { ProgressView().scaleEffect(0.7) }
                    else { Label("불러오기", systemImage: "arrow.clockwise") }
                }
                .disabled(!musicManager.isAuthorized || isLoading)
            }
            .padding()
            
            Divider()
            
            if musicManager.recommendations.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("'불러오기' 버튼을 눌러\n취향 기반 추천을 확인하세요")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(Array(musicManager.recommendations.enumerated()), id: \.offset) { _, rec in
                        RecommendationSectionView(recommendation: rec)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            if musicManager.isAuthorized && musicManager.recommendations.isEmpty {
                Task { isLoading = true; await musicManager.fetchRecommendations(); isLoading = false }
            }
        }
    }
}

struct RecommendationSectionView: View {
    let recommendation: MusicPersonalRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recommendation.title ?? "추천")
                .font(.headline)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(recommendation.items.enumerated()), id: \.offset) { _, item in
                        RecommendationItemView(item: item)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

struct RecommendationItemView: View {
    let item: MusicPersonalRecommendation.Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            artworkView.frame(width: 110, height: 110).cornerRadius(8)
            Text(title).font(.caption).bold().lineLimit(1).frame(width: 110, alignment: .leading)
            Text(subtitle).font(.caption2).foregroundColor(.secondary).lineLimit(1).frame(width: 110, alignment: .leading)
        }
    }
    
    @ViewBuilder private var artworkView: some View {
        switch item {
        case .album(let a):
            if let art = a.artwork { ArtworkImage(art, width: 110, height: 110) }
            else { placeholder("opticaldisc") }
        case .playlist(let p):
            if let art = p.artwork { ArtworkImage(art, width: 110, height: 110) }
            else { placeholder("music.note.list") }
        case .station(let s):
            if let art = s.artwork { ArtworkImage(art, width: 110, height: 110) }
            else { placeholder("radio") }
        @unknown default: placeholder("music.note")
        }
    }
    
    private var title: String {
        switch item {
        case .album(let a): return a.title
        case .playlist(let p): return p.name
        case .station(let s): return s.name
        @unknown default: return "알 수 없음"
        }
    }
    
    private var subtitle: String {
        switch item {
        case .album(let a): return a.artistName
        case .playlist: return "플레이리스트"
        case .station: return "스테이션"
        @unknown default: return ""
        }
    }
    
    @ViewBuilder
    private func placeholder(_ icon: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.15))
            .overlay(Image(systemName: icon).foregroundColor(.secondary))
    }
}


// ═══════════════════════════════════════════════════
// MARK: - 탭 4: 연간 Replay
// ═══════════════════════════════════════════════════

struct Tab4ReplayView: View {
    @ObservedObject var musicManager: MusicManager
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("연간 Replay").font(.headline)
                    Text("Apple Music 보관함의 Replay 플레이리스트")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    Task { isLoading = true; await musicManager.fetchReplayPlaylists(); isLoading = false }
                } label: {
                    if isLoading { ProgressView().scaleEffect(0.7) }
                    else { Label("불러오기", systemImage: "arrow.clockwise") }
                }
                .disabled(!musicManager.isAuthorized || isLoading)
            }
            .padding()
            
            Divider()
            
            if musicManager.replayPlaylists.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("'불러오기' 버튼을 눌러\n연간 Replay 플레이리스트를 확인하세요")
                        .multilineTextAlignment(.center).foregroundColor(.secondary)
                    Text("Apple Music에 Replay 플레이리스트가\n보관함에 저장된 경우 표시됩니다")
                        .font(.caption).foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                List(Array(musicManager.replayPlaylists.enumerated()), id: \.offset) { _, playlist in
                    ReplayPlaylistRowView(playlist: playlist)
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            if musicManager.isAuthorized && musicManager.replayPlaylists.isEmpty {
                Task { isLoading = true; await musicManager.fetchReplayPlaylists(); isLoading = false }
            }
        }
    }
}

struct ReplayPlaylistRowView: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 14) {
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 60, height: 60).cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.pink, .purple],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "calendar").foregroundColor(.white).font(.system(size: 22)))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name).font(.body).bold()
                if let desc = playlist.standardDescription {
                    Text(desc).font(.caption).foregroundColor(.secondary).lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary.opacity(0.5)).font(.caption)
        }
        .padding(.vertical, 6)
    }
}


// ═══════════════════════════════════════════════════
// MARK: - Helpers
// ═══════════════════════════════════════════════════

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft     = RectCorner(rawValue: 1 << 0)
    static let topRight    = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft  = RectCorner(rawValue: 1 << 3)
    static let all: RectCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft]
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: RectCorner
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = corners.contains(.topLeft)     ? radius : 0
        let tr = corners.contains(.topRight)    ? radius : 0
        let bl = corners.contains(.bottomLeft)  ? radius : 0
        let br = corners.contains(.bottomRight) ? radius : 0
        
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

