//
//  ContentView.swift
//  SoundandMusic
//
//  Created by nooy on 6/2/26.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    @StateObject private var musicManager = MusicManager()
    @State private var searchKeyword = "friends"
    
    var body: some View {
        VStack(spacing: 20) {
            // 권한 상태 표시 및 요청 버튼
            HStack {
                Circle()
                    .fill(musicManager.isAuthorized ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(musicManager.isAuthorized ? "Apple Music 연결됨" : "연결 필요")
//                checkSubscription()
                
                if !musicManager.isAuthorized {
                    Button("권한 요청") {
                        Task { await musicManager.requestAuthorization() }
                    }
                }
                
                musicManager.fetchRecommendations
            }
            .padding()
            
            
            
            // 검색 영역
            HStack {
                TextField("검색할 곡 제목 입력", text: $searchKeyword)
                    .textFieldStyle(.roundedBorder)
                Button("검색") {
                    Task { await musicManager.searchSong(keyword: searchKeyword) }
                }
                .disabled(!musicManager.isAuthorized || searchKeyword.isEmpty)
            }
            .padding(.horizontal)
            
            
            
            // 결과 리스트
            List(musicManager.searchResults) { song in
                HStack {
                    if let artwork = song.artwork {
                        ArtworkImage(artwork, width: 40, height: 40)
                            .cornerRadius(4)
                    }
                    VStack(alignment: .leading) {
                        Text(song.title)
                            .font(.headline)
                        Text(song.artistName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            
            
            
            
            
            
            
            
        }
        .frame(minWidth: 400, minHeight: 500)
        .onAppear {
            Task { await musicManager.requestAuthorization() }
        }
    }
}




#Preview {
    ContentView()
}
