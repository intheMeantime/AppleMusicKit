//
//  MusicManager.swift
//  SoundandMusic
//
//  Created by nooy on 6/3/26.
//

import Foundation
import MusicKit
import Combine

@MainActor
class MusicManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var searchResults: [Song] = []
    
    /// 1. 권한 요청 메서드
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        switch status {
        case .authorized:
            self.isAuthorized = true
            print("MusicKit 권한 승인됨")
        case .denied, .restricted, .notDetermined:
            self.isAuthorized = false
            print("MusicKit 권한 거부 또는 제한됨: \(status)")
        @unknown default:
            self.isAuthorized = false
        }
    }
    
    /// 2. 테스트용 기본 검색 메서드
    func searchSong(keyword: String) async {
        guard isAuthorized else { return }
        
        do {
            var request = MusicCatalogSearchRequest(term: keyword, types: [Song.self])
            request.limit = 10
            let response = try await request.response()
            self.searchResults = Array(response.songs)
        } catch {
            print("검색 실패: \(error.localizedDescription)")
            print("검색 실패 상세 원인 : \(error)")
        }
    }
    
    /// 3. 구독 확인 (안전한 버전)
    func checkSubscription() async {
        do {
            // try await를 함께 사용해야 합니다.
            let subscription = try await MusicSubscription.current
            
            if subscription.canPlayCatalogContent {
                print("Apple Music 구독 중 (카탈로그 재생 가능)")
            } else {
                print("구독하지 않음 또는 재생 제한됨")
            }
        } catch {
            // 네트워크 오류나 인증 오류 등이 발생했을 때의 처리
            print("구독 정보를 가져오는데 실패했습니다: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}
