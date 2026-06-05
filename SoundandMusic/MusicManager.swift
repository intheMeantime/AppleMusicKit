//
//  MusicManager.swift
//  SoundandMusic
//
//  Created by nooy on 6/3/26.
//

import Foundation
import MusicKit
import Combine

// MARK: - 키 로그 엔트리

struct KeyLogEntry: Identifiable {
    let id = UUID()
    let key: String          // 눌린 키 문자
    let action: KeyAction    // 재생 or 일시정지

    enum KeyAction {
        case play
        case pause

        var label: String  { self == .play ? "▶" : "⏸" }
        var isPlay: Bool   { self == .play }
    }
}

// MARK: - MusicManager

@MainActor
class MusicManager: ObservableObject {

    // MARK: Published

    @Published var isAuthorized = false

    /// 탭 1: 검색 결과
    @Published var searchResults: [Song] = []

    /// 탭 2: 아트워크 전용 검색 결과
    @Published var artworkSearchResults: [Song] = []

    /// 탭 3: 개인 추천
    @Published var recommendations: [MusicPersonalRecommendation] = []

    /// 탭 4: Replay 플레이리스트
    @Published var replayPlaylists: [Playlist] = []

    /// 현재 재생 중인 곡
    @Published var nowPlayingSong: Song? = nil
    @Published var isPlaying: Bool = false

    // MARK: 키보드 모드 관련

    /// 클릭으로 선택된 곡 (키보드 조작 대상)
    @Published var selectedSong: Song? = nil

    /// 키보드 모드 ON/OFF
    @Published var isKeyboardModeEnabled: Bool = false

    /// 누른 키 횟수 (홀수 = 재생, 짝수 = 일시정지)
    @Published var keyPressCount: Int = 0
    
    /// 재생 중지 인터벌 ( default ==5 )
    @Published var pauseInterval: Int = 5

    /// 키 입력 로그 (최대 30개, 최신 순)
    @Published var keyLog: [KeyLogEntry] = []

    // MARK: - Authorization

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        switch status {
        case .authorized:
            self.isAuthorized = true
        case .denied, .restricted, .notDetermined:
            self.isAuthorized = false
        @unknown default:
            self.isAuthorized = false
        }
    }

    // MARK: - 탭 1: 검색

    func searchSong(keyword: String) async {
        guard isAuthorized else { return }
        do {
            var request = MusicCatalogSearchRequest(term: keyword, types: [Song.self])
            request.limit = 15
            let response = try await request.response()
            self.searchResults = Array(response.songs)
        } catch {
            print("검색 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 탭 1: 곡 선택 (클릭)

    /// 키보드 모드 여부에 따라 동작이 달라짐:
    /// - 일반 모드: 즉시 재생
    /// - 키보드 모드: 선택만 하고 keyPressCount 초기화
    func handleSongTap(_ song: Song) {
        if isKeyboardModeEnabled {
            selectSong(song)
        } else {
            playSong(song)
        }
    }

    func selectSong(_ song: Song) {
        selectedSong = song
        keyPressCount = 0      // 새 곡 선택 시 리셋
        keyLog = []
        print("선택됨: \(song.title)")
    }

    // MARK: - 재생 제어

    func playSong(_ song: Song) {
        let player = ApplicationMusicPlayer.shared
        // 큐에 있는 곡을 무한반복
        player.state.repeatMode = .all
        
        player.queue = [song]
        nowPlayingSong = song
        isPlaying = true

        Task {
            do {
                try await player.play()
                print("재생 시작: \(song.title)")
            } catch {
                print("재생 실패: \(error.localizedDescription)")
                isPlaying = false
            }
        }
    }

    /// 이미 로드된 곡 재개 (키보드 모드 재생)
    func resumeOrPlay(_ song: Song) {
        if nowPlayingSong?.id == song.id {
            // 같은 곡이면 일시정지에서 재개
            Task {
                do {
                    try await ApplicationMusicPlayer.shared.play()
                    isPlaying = true
                    print("재개: \(song.title)")
                } catch {
                    print("재개 실패: \(error.localizedDescription)")
                }
            }
        } else {
            playSong(song)
        }
    }

    func pausePlayback() {
        ApplicationMusicPlayer.shared.pause()
        isPlaying = false
        print("일시정지")
    }

    func stopPlayback() {
        ApplicationMusicPlayer.shared.stop()
        isPlaying = false
        nowPlayingSong = nil
    }

    // MARK: - 키보드 모드 핵심 로직

    /// 키 하나가 눌릴 때마다 호출.
    /// 홀수 번째 → 재생, 짝수 번째 → 일시정지
    func handleKeyPress(key: String) {
        guard isKeyboardModeEnabled, let song = selectedSong else { return }

        keyPressCount += 1
//        let isPlayAction = (keyPressCount % 2 == 1)
        let isPlayAction = (keyPressCount % pauseInterval != 0)
        let entry = KeyLogEntry(key: key, action: isPlayAction ? .play : .pause)

        // 최신 순 삽입, 최대 30개 유지
        keyLog.insert(entry, at: 0)
        if keyLog.count > 30 { keyLog = Array(keyLog.prefix(30)) }

        if isPlayAction {
            resumeOrPlay(song)
        } else {
            pausePlayback()
        }
    }

    /// 키보드 모드 토글 (OFF → ON 시 상태 초기화)
    func toggleKeyboardMode() {
        isKeyboardModeEnabled.toggle()
        if isKeyboardModeEnabled {
            keyPressCount = 0
            keyLog = []
        } else {
            // 키보드 모드 끄면 재생도 정지
            if isPlaying { pausePlayback() }
        }
    }

    // MARK: - 탭 2: 아트워크 전용 검색

    func searchArtwork(keyword: String) async {
        guard isAuthorized else { return }
        do {
            var request = MusicCatalogSearchRequest(term: keyword, types: [Song.self])
            request.limit = 20
            let response = try await request.response()
            self.artworkSearchResults = Array(response.songs)
        } catch {
            print("아트워크 검색 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 탭 3: 개인 취향 기반 추천

    func fetchRecommendations() async {
        guard isAuthorized else { return }
        do {
            let request = MusicPersonalRecommendationsRequest()
            let response = try await request.response()
            self.recommendations = Array(response.recommendations)
        } catch {
            print("추천 조회 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 탭 4: 연간 Replay

    func fetchReplayPlaylists() async {
        guard isAuthorized else { return }
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 50
            let response = try await request.response()
            self.replayPlaylists = response.items.filter {
                let n = $0.name.lowercased()
                return n.contains("replay") || n.contains("리플레이")
            }
            if self.replayPlaylists.isEmpty { await fetchReplayFromCatalog() }
        } catch {
            await fetchReplayFromCatalog()
        }
    }

    private func fetchReplayFromCatalog() async {
        do {
            var request = MusicCatalogSearchRequest(term: "Apple Music Replay", types: [Playlist.self])
            request.limit = 10
            let response = try await request.response()
            self.replayPlaylists = Array(response.playlists)
        } catch {
            print("카탈로그 Replay 검색 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - 구독 확인

    func checkSubscription() async {
        do {
            let sub = try await MusicSubscription.current
            print(sub.canPlayCatalogContent ? "구독 중" : "구독 안 함")
        } catch {
            print("구독 조회 실패: \(error.localizedDescription)")
        }
    }
}
