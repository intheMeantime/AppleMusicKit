////
////  MusicManager.swift
////  SoundandMusic
////
////  Created by nooy on 6/3/26.
////
//
//import Foundation
//import MusicKit
//import Combine
//
//@MainActor
//class MusicManager: ObservableObject {
//    
//    // MARK: - Published Properties
//    
//    @Published var isAuthorized = false
//    
//    /// 탭 1: 검색 결과 (재생 가능)
//    @Published var searchResults: [Song] = []
//    
//    /// 탭 2: 아트워크 전용 검색 결과
//    @Published var artworkSearchResults: [Song] = []
//    
//    /// 탭 3: 개인 추천
//    @Published var recommendations: [MusicPersonalRecommendation] = []
//    
//    /// 탭 4: Replay 플레이리스트
//    @Published var replayPlaylists: [Playlist] = []
//    
//    /// 현재 재생 중인 곡
//    @Published var nowPlayingSong: Song? = nil
//    @Published var isPlaying: Bool = false
//    
//    // MARK: - Authorization
//    
//    func requestAuthorization() async {
//        let status = await MusicAuthorization.request()
//        switch status {
//        case .authorized:
//            self.isAuthorized = true
//            print("MusicKit 권한 승인됨")
//        case .denied, .restricted, .notDetermined:
//            self.isAuthorized = false
//            print("MusicKit 권한 거부 또는 제한됨: \(status)")
//        @unknown default:
//            self.isAuthorized = false
//        }
//    }
//    
//    // MARK: - 탭 1: 검색 + 재생
//    
//    func searchSong(keyword: String) async {
//        guard isAuthorized else { return }
//        do {
//            var request = MusicCatalogSearchRequest(term: keyword, types: [Song.self])
//            request.limit = 15
//            let response = try await request.response()
//            self.searchResults = Array(response.songs)
//        } catch {
//            print("검색 실패: \(error.localizedDescription)")
//        }
//    }
//    
//    func playSong(_ song: Song) {
//        let player = ApplicationMusicPlayer.shared
//        player.queue = [song]
//        nowPlayingSong = song
//        isPlaying = true
//        
//        Task {
//            do {
//                try await player.play()
//                print("재생 시작: \(song.title) - \(song.artistName)")
//            } catch {
//                print("재생 실패: \(error.localizedDescription)")
//                isPlaying = false
//            }
//        }
//    }
//    
//    func stopPlayback() {
//        ApplicationMusicPlayer.shared.stop()
//        isPlaying = false
//        nowPlayingSong = nil
//    }
//    
//    // MARK: - 탭 2: 아트워크 전용 검색
//    
//    func searchArtwork(keyword: String) async {
//        guard isAuthorized else { return }
//        do {
//            var request = MusicCatalogSearchRequest(term: keyword, types: [Song.self])
//            request.limit = 20
//            let response = try await request.response()
//            self.artworkSearchResults = Array(response.songs)
//        } catch {
//            print("아트워크 검색 실패: \(error.localizedDescription)")
//        }
//    }
//    
//    // MARK: - 탭 3: 개인 취향 기반 추천
//    
//    func fetchRecommendations() async {
//        guard isAuthorized else { return }
//        do {
//            let request = MusicPersonalRecommendationsRequest()
//            let response = try await request.response()
//            self.recommendations = Array(response.recommendations)
//            print("추천 카테고리 수: \(self.recommendations.count)")
//        } catch {
//            print("추천 조회 실패: \(error.localizedDescription)")
//        }
//    }
//    
//    // MARK: - 탭 4: 연간 Replay 조회
//    
//    /// Apple Music Replay 플레이리스트는 사용자 보관함에 저장되어 있습니다.
//    /// "Replay" 키워드로 필터링하여 연도별 Replay 목록을 가져옵니다.
//    func fetchReplayPlaylists() async {
//        guard isAuthorized else { return }
//        do {
//            var request = MusicLibraryRequest<Playlist>()
//            request.limit = 50
//            let response = try await request.response()
//            
//            // "Replay" 또는 "리플레이" 가 포함된 플레이리스트 필터링
//            self.replayPlaylists = response.items.filter { playlist in
//                let name = playlist.name.lowercased()
//                return name.contains("replay") || name.contains("리플레이")
//            }
//            
//            print("Replay 플레이리스트 수: \(self.replayPlaylists.count)")
//            
//            // 없을 경우 카탈로그에서 검색 시도
//            if self.replayPlaylists.isEmpty {
//                await fetchReplayFromCatalog()
//            }
//        } catch {
//            print("Replay 조회 실패: \(error.localizedDescription)")
//            await fetchReplayFromCatalog()
//        }
//    }
//    
//    /// 보관함에 없을 경우 카탈로그에서 Apple Music Replay 검색
//    private func fetchReplayFromCatalog() async {
//        do {
//            var request = MusicCatalogSearchRequest(term: "Apple Music Replay", types: [Playlist.self])
//            request.limit = 10
//            let response = try await request.response()
//            self.replayPlaylists = Array(response.playlists)
//            print("카탈로그 Replay 검색 결과: \(self.replayPlaylists.count)")
//        } catch {
//            print("카탈로그 Replay 검색 실패: \(error.localizedDescription)")
//        }
//    }
//    
//    // MARK: - 구독 확인
//    
//    func checkSubscription() async {
//        do {
//            let subscription = try await MusicSubscription.current
//            if subscription.canPlayCatalogContent {
//                print("Apple Music 구독 중 (카탈로그 재생 가능)")
//            } else {
//                print("구독하지 않음 또는 재생 제한됨")
//            }
//        } catch {
//            print("구독 정보 조회 실패: \(error.localizedDescription)")
//        }
//    }
//}
