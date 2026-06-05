////
////  ContentView.swift
////  SoundandMusic
////
////  Created by nooy on 6/2/26.
////
//
//import SwiftUI
//import MusicKit
//
//// MARK: - ContentView (TabView 루트)
//
//struct ContentView: View {
//    @StateObject private var musicManager = MusicManager()
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // 상단 권한 상태 바
//            AuthStatusBar(musicManager: musicManager)
//            
//            TabView {
//                // 탭 1: 검색 + 재생
//                Tab1SearchPlayView(musicManager: musicManager)
//                    .tabItem {
//                        Label("재생", systemImage: "play.circle")
//                    }
//                
//                // 탭 2: 아트워크 검색
//                Tab2ArtworkView(musicManager: musicManager)
//                    .tabItem {
//                        Label("아트워크", systemImage: "photo")
//                    }
//                
//                // 탭 3: 개인 추천
//                Tab3RecommendationsView(musicManager: musicManager)
//                    .tabItem {
//                        Label("추천", systemImage: "star.circle")
//                    }
//                
//                // 탭 4: 연간 Replay
//                Tab4ReplayView(musicManager: musicManager)
//                    .tabItem {
//                        Label("Replay", systemImage: "calendar.badge.clock")
//                    }
//            }
//        }
//        .frame(minWidth: 420, minHeight: 600)
//        .onAppear {
//            Task { await musicManager.requestAuthorization() }
//        }
//    }
//}
//
//// MARK: - 상단 권한 상태 바
//
//struct AuthStatusBar: View {
//    @ObservedObject var musicManager: MusicManager
//    
//    var body: some View {
//        HStack(spacing: 8) {
//            Circle()
//                .fill(musicManager.isAuthorized ? Color.green : Color.red)
//                .frame(width: 10, height: 10)
//            Text(musicManager.isAuthorized ? "Apple Music 연결됨" : "연결 필요")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            if !musicManager.isAuthorized {
//                Button("권한 요청") {
//                    Task { await musicManager.requestAuthorization() }
//                }
//                .buttonStyle(.bordered)
//                .controlSize(.small)
//            }
//            
//            Spacer()
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 8)
//        .background(Color(nsColor: .windowBackgroundColor))
//    }
//}
//
//// MARK: - 탭 1: 검색 + 재생
//
//struct Tab1SearchPlayView: View {
//    @ObservedObject var musicManager: MusicManager
//    @State private var keyword = ""
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // 검색 바
//            HStack {
//                TextField("곡 제목 또는 아티스트 검색", text: $keyword)
//                    .textFieldStyle(.roundedBorder)
//                    .onSubmit { search() }
//                
//                Button("검색") { search() }
//                    .disabled(!musicManager.isAuthorized || keyword.trimmingCharacters(in: .whitespaces).isEmpty)
//            }
//            .padding()
//            
//            // 현재 재생 중 표시
//            if let song = musicManager.nowPlayingSong {
//                NowPlayingBar(song: song, isPlaying: musicManager.isPlaying) {
//                    musicManager.stopPlayback()
//                }
//            }
//            
//            Divider()
//            
//            // 결과 리스트
//            if musicManager.searchResults.isEmpty {
//                Spacer()
//                Text("검색어를 입력하세요")
//                    .foregroundColor(.secondary)
//                Spacer()
//            } else {
//                List(musicManager.searchResults) { song in
//                    SongRowView(
//                        song: song,
//                        isPlaying: musicManager.nowPlayingSong?.id == song.id && musicManager.isPlaying
//                    )
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        musicManager.playSong(song)
//                    }
//                }
//                .listStyle(.plain)
//            }
//        }
//    }
//    
//    private func search() {
//        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
//        guard !trimmed.isEmpty else { return }
//        Task { await musicManager.searchSong(keyword: trimmed) }
//    }
//}
//
//// MARK: - 현재 재생 중 바
//
//struct NowPlayingBar: View {
//    let song: Song
//    let isPlaying: Bool
//    let onStop: () -> Void
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: "music.note")
//                .foregroundColor(.accentColor)
//                .font(.system(size: 16))
//            
//            if let artwork = song.artwork {
//                ArtworkImage(artwork, width: 36, height: 36)
//                    .cornerRadius(4)
//            }
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(song.title)
//                    .font(.subheadline).bold()
//                    .lineLimit(1)
//                Text(song.artistName)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//            }
//            
//            Spacer()
//            
//            // 재생 중 애니메이션 인디케이터
//            if isPlaying {
//                HStack(spacing: 2) {
//                    ForEach(0..<3) { i in
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color.accentColor)
//                            .frame(width: 3, height: CGFloat.random(in: 8...18))
//                            .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: isPlaying)
//                    }
//                }
//                .frame(width: 16, height: 20)
//            }
//            
//            Button {
//                onStop()
//            } label: {
//                Image(systemName: "stop.circle.fill")
//                    .font(.system(size: 22))
//                    .foregroundColor(.secondary)
//            }
//            .buttonStyle(.plain)
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 10)
//        .background(Color.accentColor.opacity(0.08))
//    }
//}
//
//// MARK: - 곡 행 뷰
//
//struct SongRowView: View {
//    let song: Song
//    let isPlaying: Bool
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            ZStack {
//                if let artwork = song.artwork {
//                    ArtworkImage(artwork, width: 120, height: 120)
//                        .cornerRadius(6)
//                }
//                if isPlaying {
//                    RoundedRectangle(cornerRadius: 6)
//                        .fill(Color.black.opacity(0.45))
//                        .frame(width: 48, height: 48)
//                    Image(systemName: "speaker.wave.2.fill")
//                        .foregroundColor(.white)
//                        .font(.system(size: 30))
//                }
//            }
//            .frame(width: 150, height: 150)
//            
//            VStack(alignment: .leading, spacing: 3) {
//                // 제목
//                Text(song.title)
//                    .font(.body)
//                    .foregroundColor(isPlaying ? .accentColor : .primary)
//                    .lineLimit(1)
//                // 가수 이름
//                Text(song.artistName)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//                // 앨범 제목
//                if let album = song.albumTitle {
//                    Text("앨범제목(albumTitle): \(album)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//                // 1. 식별자 및 기본 정보
//                Text("ID(id): \(song.id.rawValue)")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("장르(genreNames): \(song.genreNames.isEmpty ? "-" : song.genreNames.joined(separator: ", "))")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("재생 시간(duration): \(song.duration != nil ? "\(Int(song.duration!))초" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("트랙 번호(trackNumber): \(song.trackNumber != nil ? "\(song.trackNumber!)" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("디스크 번호(discNumber): \(song.discNumber != nil ? "\(song.discNumber!)" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("발매일(releaseDate): \(song.releaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("ISRC 코드(isrc): \(song.isrc ?? "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                // 2. 클래식 음악 관련 프로퍼티
//                Text("작품명(workName): \(song.workName ?? "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("악장명(movementName): \(song.movementName ?? "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("악장 번호(movementNumber): \(song.movementNumber != nil ? "\(song.movementNumber!)" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("총 악장 수(movementCount): \(song.movementCount != nil ? "\(song.movementCount!)" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("클래식 기여(attribution): \(song.attribution ?? "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("작곡가(composerName): \(song.composerName ?? "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                // 3. 특성 및 상태 정보
//                Text("가사 보유 여부(hasLyrics): \(song.hasLyrics ? "있음" : "없음")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("Apple Digital Master 여부(isAppleDigitalMaster): \(song.isAppleDigitalMaster != nil ? (song.isAppleDigitalMaster! ? "예" : "아니오") : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("콘텐츠 등급(contentRating): \(song.contentRating != nil ? String(describing: song.contentRating!) : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("내 재생 횟수(playCount): \(song.playCount != nil ? "\(song.playCount!)회" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                // 4. URL 및 미디어 자산 정보
//                Text("애플 뮤직 링크(url): \(song.url?.absoluteString ?? "-")")
//                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
//                
//                Text("아티스트 링크(artistURL): \(song.artistURL?.absoluteString ?? "-")")
//                    .font(.caption).foregroundColor(.secondary).lineLimit(1)
//                
//                Text("오디오 음질 버전(audioVariants): \(song.audioVariants != nil ? song.audioVariants!.map { "\($0)" }.joined(separator: ", ") : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                // 5. 연관된 MusicItem 관계성 데이터 (위 주석 참고)
//                Text("연관 아티스트 수(artists): \(song.artists != nil ? "\(song.artists!.count)개" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("연관 앨범 수(albums): \(song.albums != nil ? "\(song.albums!.count)개" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("연관 작곡가 수(composers): \(song.composers != nil ? "\(song.composers!.count)개" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("연관 장르 객체 수(genres): \(song.genres != nil ? "\(song.genres!.count)개" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                Text("연관 뮤직비디오 수(musicVideos): \(song.musicVideos != nil ? "\(song.musicVideos!.count)개" : "-")")
//                    .font(.caption).foregroundColor(.secondary)
//                
//                
//                
//            }
//            
//            Spacer()
//            
//            if isPlaying {
//                Image(systemName: "waveform")
//                    .foregroundColor(.accentColor)
//                    .symbolEffect(.variableColor)
//            } else {
//                Image(systemName: "play.circle")
//                    .foregroundColor(.secondary.opacity(0.5))
//                    .font(.system(size: 20))
//            }
//        }
//        .padding(.vertical, 4)
//        .contentShape(Rectangle())
//    }
//}
//
//// MARK: - 탭 2: 아트워크 전용 검색
//
//struct Tab2ArtworkView: View {
//    @ObservedObject var musicManager: MusicManager
//    @State private var keyword = ""
//    
//    // 3열 그리드
//    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                TextField("앨범 커버를 볼 곡/아티스트 검색", text: $keyword)
//                    .textFieldStyle(.roundedBorder)
//                    .onSubmit { search() }
//                
//                Button("검색") { search() }
//                    .disabled(!musicManager.isAuthorized || keyword.trimmingCharacters(in: .whitespaces).isEmpty)
//            }
//            .padding()
//            
//            Divider()
//            
//            if musicManager.artworkSearchResults.isEmpty {
//                Spacer()
//                VStack(spacing: 8) {
//                    Image(systemName: "photo.on.rectangle.angled")
//                        .font(.system(size: 40))
//                        .foregroundColor(.secondary.opacity(0.4))
//                    Text("검색 결과의 앨범 커버가 표시됩니다")
//                        .foregroundColor(.secondary)
//                }
//                Spacer()
//            } else {
//                ScrollView {
//                    LazyVGrid(columns: columns, spacing: 8) {
//                        ForEach(musicManager.artworkSearchResults) { song in
//                            ArtworkCellView(song: song)
//                        }
//                    }
//                    .padding(12)
//                }
//            }
//        }
//    }
//    
//    private func search() {
//        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
//        guard !trimmed.isEmpty else { return }
//        Task { await musicManager.searchArtwork(keyword: trimmed) }
//    }
//}
//
//// MARK: - 아트워크 셀
//
//struct ArtworkCellView: View {
//    let song: Song
//    @State private var isHovered = false
//    
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            // 아트워크 있으면 띄우기
//            if let artwork = song.artwork {
//                VStack(spacing: 8) {
//                    ArtworkImage(artwork, width: .infinity, height: 300)
//                        .aspectRatio(1, contentMode: .fill)
//                        .clipped()
//                        .cornerRadius(8)
//                    
//                    // ================= [아트워크 프로퍼티 출력 부분] =================
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("--- Artwork Properties ---")
//                            .font(.caption).bold()
//                            .foregroundColor(.secondary)
//                        
//                        Text("가로 크기(width): \(artwork.maximumWidth)px")
//                        Text("세로 크기(height): \(artwork.maximumHeight)px")
//                        
//                    
//                        // 배경색 (CGColor 또는 정형화된 형태, 옵셔널 처리)
//                        // The average background color of the image.
//                        Text("배경색(backgroundColor): \(artwork.backgroundColor != nil ? "\(artwork.backgroundColor!)" : "-")")
//                            .background(
//                                artwork.backgroundColor.map { Color(cgColor: $0) } ?? .clear
//                            )
//                        
//                        // 텍스트 색상들 (옵셔널 처리)
//                        Text("기본 텍스트 색상(primaryTextColor): \(artwork.primaryTextColor != nil ? "\(artwork.primaryTextColor!)" : "-")")
//                            .background(
//                                artwork.primaryTextColor.map { Color(cgColor: $0) } ?? .clear
//                            )
//                        Text("배경 보조 텍스트 색상(quaternaryTextColor): \(artwork.quaternaryTextColor != nil ? "\(artwork.quaternaryTextColor!)" : "-")")
//                            .background(
//                                artwork.quaternaryTextColor.map { Color(cgColor: $0) } ?? .clear
//                            )
//                        Text("삼차 텍스트 색상(secondaryTextColor): \(artwork.secondaryTextColor != nil ? "\(artwork.secondaryTextColor!)" : "-")")
//                            .background(
//                                artwork.secondaryTextColor.map { Color(cgColor: $0) } ?? .clear
//                            )
//                        Text("사차 텍스트 색상(tertiaryTextColor): \(artwork.tertiaryTextColor != nil ? "\(artwork.tertiaryTextColor!)" : "-")")
//                            .background(
//                                artwork.tertiaryTextColor.map { Color(cgColor: $0) } ?? .clear
//                            )
//                    }
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .padding(.horizontal, 4)
//                }
//            } else {
//                VStack(spacing: 8) {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(Color.secondary.opacity(0.15))
//                        .aspectRatio(1, contentMode: .fit)
//                        .overlay(
//                            Image(systemName: "music.note")
//                                .foregroundColor(.secondary)
//                        )
//                    
//                    Text("아트워크 정보가 없습니다.")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            // 호버 시 곡 정보 오버레이
//            if isHovered {
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(song.title)
//                        .font(.caption).bold()
//                        .foregroundColor(.white)
//                        .lineLimit(1)
//                    Text(song.artistName)
//                        .font(.caption2)
//                        .foregroundColor(.white.opacity(0.8))
//                        .lineLimit(1)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(6)
//                .background(
//                    LinearGradient(
//                        colors: [.clear, .black.opacity(1.0)],
//                        startPoint: .top, endPoint: .bottom
//                    )
//                )
//                // ⚠️ .cornerRadius(8, corners: [...]) 커스텀 Extension을 사용하는 형태에 맞게 유지
//                .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
//            }
//        }
//        .cornerRadius(8)
//        .onHover { isHovered = $0 }
//    }
//}
//
//// MARK: - 탭 3: 개인 추천
//
//struct Tab3RecommendationsView: View {
//    @ObservedObject var musicManager: MusicManager
//    @State private var isLoading = false
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Text("나를 위한 추천")
//                    .font(.headline)
//                Spacer()
//                Button {
//                    Task {
//                        isLoading = true
//                        await musicManager.fetchRecommendations()
//                        isLoading = false
//                    }
//                } label: {
//                    if isLoading {
//                        ProgressView().scaleEffect(0.7)
//                    } else {
//                        Label("불러오기", systemImage: "arrow.clockwise")
//                    }
//                }
//                .disabled(!musicManager.isAuthorized || isLoading)
//            }
//            .padding()
//            
//            Divider()
//            
//            if musicManager.recommendations.isEmpty {
//                Spacer()
//                VStack(spacing: 12) {
//                    Image(systemName: "star.circle")
//                        .font(.system(size: 44))
//                        .foregroundColor(.secondary.opacity(0.35))
//                    Text("'불러오기' 버튼을 눌러\n취향 기반 추천을 확인하세요")
//                        .multilineTextAlignment(.center)
//                        .foregroundColor(.secondary)
//                }
//                Spacer()
//            } else {
//                List {
//                    ForEach(Array(musicManager.recommendations.enumerated()), id: \.offset) { _, rec in
//                        RecommendationSectionView(recommendation: rec)
//                    }
//                }
//                .listStyle(.plain)
//            }
//        }
//        .onAppear {
//            if musicManager.isAuthorized && musicManager.recommendations.isEmpty {
//                Task {
//                    isLoading = true
//                    await musicManager.fetchRecommendations()
//                    isLoading = false
//                }
//            }
//        }
//    }
//}
//
//// MARK: - 추천 섹션
//
//struct RecommendationSectionView: View {
//    let recommendation: MusicPersonalRecommendation
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // 섹션 제목
//            Text(recommendation.title ?? "추천")
//                .font(.headline)
//                .padding(.top, 8)
//            
//            // 가로 스크롤 아이템
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 12) {
//                    ForEach(Array(recommendation.items.enumerated()), id: \.offset) { _, item in
//                        RecommendationItemView(item: item)
//                    }
//                }
//                .padding(.bottom, 8)
//            }
//        }
//    }
//}
//
//// MARK: - 추천 아이템 (앨범 / 플레이리스트)
//
//struct RecommendationItemView: View {
//    let item: MusicPersonalRecommendation.Item
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 5) {
//            artworkView
//                .frame(width: 110, height: 110)
//                .cornerRadius(8)
//            
//            Text(title)
//                .font(.caption).bold()
//                .lineLimit(1)
//                .frame(width: 110, alignment: .leading)
//            
//            Text(subtitle)
//                .font(.caption2)
//                .foregroundColor(.secondary)
//                .lineLimit(1)
//                .frame(width: 110, alignment: .leading)
//        }
//    }
//    
//    @ViewBuilder
//    private var artworkView: some View {
//        switch item {
//        case .album(let album):
//            if let artwork = album.artwork {
//                ArtworkImage(artwork, width: 110, height: 110)
//            } else {
//                placeholderArtwork(systemName: "opticaldisc")
//            }
//        case .playlist(let playlist):
//            if let artwork = playlist.artwork {
//                ArtworkImage(artwork, width: 110, height: 110)
//            } else {
//                placeholderArtwork(systemName: "music.note.list")
//            }
//        case .station(let station):
//            if let artwork = station.artwork {
//                ArtworkImage(artwork, width: 110, height: 110)
//            } else {
//                placeholderArtwork(systemName: "radio")
//            }
//        @unknown default:
//            placeholderArtwork(systemName: "music.note")
//        }
//    }
//    
//    private var title: String {
//        switch item {
//        case .album(let album): return album.title
//        case .playlist(let playlist): return playlist.name
//        case .station(let station): return station.name
//        @unknown default: return "알 수 없음"
//        }
//    }
//    
//    private var subtitle: String {
//        switch item {
//        case .album(let album): return album.artistName
//        case .playlist: return "플레이리스트"
//        case .station: return "스테이션"
//        @unknown default: return ""
//        }
//    }
//    
//    @ViewBuilder
//    private func placeholderArtwork(systemName: String) -> some View {
//        RoundedRectangle(cornerRadius: 8)
//            .fill(Color.secondary.opacity(0.15))
//            .overlay(Image(systemName: systemName).foregroundColor(.secondary))
//    }
//}
//
//// MARK: - 탭 4: 연간 Replay
//
//struct Tab4ReplayView: View {
//    @ObservedObject var musicManager: MusicManager
//    @State private var isLoading = false
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                VStack(alignment: .leading, spacing: 2) {
//                    Text("연간 Replay")
//                        .font(.headline)
//                    Text("Apple Music 보관함의 Replay 플레이리스트")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                Spacer()
//                Button {
//                    Task {
//                        isLoading = true
//                        await musicManager.fetchReplayPlaylists()
//                        isLoading = false
//                    }
//                } label: {
//                    if isLoading {
//                        ProgressView().scaleEffect(0.7)
//                    } else {
//                        Label("불러오기", systemImage: "arrow.clockwise")
//                    }
//                }
//                .disabled(!musicManager.isAuthorized || isLoading)
//            }
//            .padding()
//            
//            Divider()
//            
//            if musicManager.replayPlaylists.isEmpty {
//                Spacer()
//                VStack(spacing: 12) {
//                    Image(systemName: "calendar.badge.clock")
//                        .font(.system(size: 44))
//                        .foregroundColor(.secondary.opacity(0.35))
//                    Text("'불러오기' 버튼을 눌러\n연간 Replay 플레이리스트를 확인하세요")
//                        .multilineTextAlignment(.center)
//                        .foregroundColor(.secondary)
//                    Text("Apple Music에 Replay 플레이리스트가\n보관함에 저장된 경우 표시됩니다")
//                        .font(.caption)
//                        .foregroundColor(.secondary.opacity(0.7))
//                        .multilineTextAlignment(.center)
//                }
//                Spacer()
//            } else {
//                List(Array(musicManager.replayPlaylists.enumerated()), id: \.offset) { _, playlist in
//                    ReplayPlaylistRowView(playlist: playlist)
//                }
//                .listStyle(.plain)
//            }
//        }
//        .onAppear {
//            if musicManager.isAuthorized && musicManager.replayPlaylists.isEmpty {
//                Task {
//                    isLoading = true
//                    await musicManager.fetchReplayPlaylists()
//                    isLoading = false
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Replay 플레이리스트 행
//
//struct ReplayPlaylistRowView: View {
//    let playlist: Playlist
//    
//    var body: some View {
//        HStack(spacing: 14) {
//            if let artwork = playlist.artwork {
//                ArtworkImage(artwork, width: 60, height: 60)
//                    .cornerRadius(8)
//            } else {
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(
//                        LinearGradient(
//                            colors: [.pink, .purple],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 60, height: 60)
//                    .overlay(
//                        Image(systemName: "calendar")
//                            .foregroundColor(.white)
//                            .font(.system(size: 22))
//                    )
//            }
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(playlist.name)
//                    .font(.body).bold()
//                
//                if let desc = playlist.standardDescription {
//                    Text(desc)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .lineLimit(2)
//                }
//            }
//            
//            Spacer()
//            
//            Image(systemName: "chevron.right")
//                .foregroundColor(.secondary.opacity(0.5))
//                .font(.caption)
//        }
//        .padding(.vertical, 6)
//    }
//}
//
//// MARK: - RoundedRectangle 특정 코너 Helper
//
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}
//
//struct RectCorner: OptionSet {
//    let rawValue: Int
//    static let topLeft = RectCorner(rawValue: 1 << 0)
//    static let topRight = RectCorner(rawValue: 1 << 1)
//    static let bottomRight = RectCorner(rawValue: 1 << 2)
//    static let bottomLeft = RectCorner(rawValue: 1 << 3)
//    static let all: RectCorner = [.topLeft, .topRight, .bottomRight, .bottomLeft]
//}
//
//struct RoundedCorner: Shape {
//    var radius: CGFloat
//    var corners: RectCorner
//    
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let tl = corners.contains(.topLeft) ? radius : 0
//        let tr = corners.contains(.topRight) ? radius : 0
//        let bl = corners.contains(.bottomLeft) ? radius : 0
//        let br = corners.contains(.bottomRight) ? radius : 0
//        
//        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
//        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
//        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
//        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
//        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
//        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
//        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
//        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
//        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
//        path.closeSubpath()
//        return path
//    }
//}
//
//// MARK: - Preview
//
//#Preview {
//    ContentView()
//}
