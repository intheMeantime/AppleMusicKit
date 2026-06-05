# MusicKit에 대하여
<https://developer.apple.com/documentation/MusicKit/> 


### MusicKit vs. Apple Music API

| 항목 | MusicKit | Apple Music API |
| :--- | :--- | :--- |
| 형태 | Swift Framework | REST API |
| 사용 환경 | iOS iPadOS MacCatalyst macOS tvOS visionOS watchOS| 모든 플랫폼 |
| 언어 | Swift | 언어 무관 |
| 재생 기능 | O | X |
| UI 컴포넌트 | O | X |
| 네트워크 요청 직접 작성 | 거의 없음 | 필요 |
| 토큰 관리 | 자동 | 직접 |
| Android 지원 | X (별도 Android SDK 사용) | O |
| Web 지원 | X (별도 MusicKit JS 사용) | O |


### 사용자의 애플뮤직 구독 확인??
playSong(_:)에서 ApplicationMusicPlayer.shared로 카탈로그 곡 재생을 시도하고 있고,
실제로 재생이 된다면

기기/계정이 이미 Apple Music 조건을 충족(구독/미디어 접근 가능)하거나
테스트 환경/계정 상태에 따라 프레임워크가 재생을 허용하는 케이스 일 수 있음.



### MusicKit으로 할 수 없는 것

* Apple Music 음원 파일 직접 접근 ❌
    - 스트리밍만 가능
* DRM(Digital Rights Management) 걸린 오디오 PCM(Pulse Code Modulation) 데이터 추출 ❌
     - BPM 분석, 음정분석, 보컬분리, 악기분리 같은 작업을 하기 위해서는 PCM을 추출해야 함
     - PCM: 소리를 컴퓨터가 실제로 처리할 수 있는 원시(raw) 오디오 데이터
* Apple Music 음원을 AVAudioEngine 입력으로 사용 ❌
* 음원 자체 분석(MFCC, Spectrogram 등) ❌
* 음원 다운로드 후 저장 ❌
* 음원 공유 ❌
* AI 학습용 데이터 추출 ❌


### 할 수 있는 것 list

1. Apple Music 카탈로그 검색

* 노래 검색
* 앨범 검색
* 아티스트 검색
* 플레이리스트 검색
* 장르 검색
* 뮤직비디오 검색
* 라디오 스테이션 검색
* 레코드 레이블 검색
* 큐레이터 검색
* 키워드 기반 통합 검색
* 조건(Filter) 기반 검색
* 특정 ID로 음악 정보 조회
* Apple Music API 엔드포인트 직접 호출  

⸻

2. Apple Music 메타데이터 조회

* 곡 제목
* 아티스트 정보
* 앨범 정보
* 발매일
* 장르
* 재생 시간
* 가사 여부
* Explicit 여부
* 에디토리얼 노트
* 미리듣기(Preview) URL
* 앨범 커버 이미지(Artwork)
* 관련 음악 정보 조회  

⸻

3. 음악 재생

ApplicationMusicPlayer

(앱 내부 플레이어)

* 노래 재생
* 일시정지
* 재개
* 정지
* 다음 곡
* 이전 곡
* 재생 큐 관리
* 특정 곡부터 재생
* 앨범 전체 재생
* 플레이리스트 재생
* 셔플
* 반복 재생
* 재생 상태 관찰  

SystemMusicPlayer

(Apple Music 앱 제어)

* Apple Music 앱 재생 상태 제어
* 현재 재생 중인 콘텐츠 제어
* 시스템 플레이어와 연동  

⸻

4. 사용자 음악 보관함(Library) 접근

사용자 권한을 받은 경우

* 라이브러리 내 노래 조회
* 라이브러리 내 앨범 조회
* 라이브러리 내 플레이리스트 조회
* 라이브러리 검색
* 라이브러리 필터링
* 라이브러리 정렬
* 최근 추가 음악 조회  

⸻

5. 라이브러리에 음악 추가

사용자 권한 필요

* 노래 추가
* 앨범 추가
* 플레이리스트 추가
* Apple Music 콘텐츠를 사용자 라이브러리에 저장  

⸻

6. 플레이리스트 기능

사용자 권한 필요

* 플레이리스트 생성
* 플레이리스트 수정
* 플레이리스트에 곡 추가
* 플레이리스트 정보 조회
* 플레이리스트 재생  

⸻

7. 개인화 데이터 접근

사용자 권한 필요

* 추천 음악 조회
* 추천 앨범 조회
* 추천 플레이리스트 조회
* Recently Played 조회
* 사용자 취향 기반 추천 조회  

⸻

8. 차트(Charts) 조회

* 국가별 인기곡
* 국가별 인기 앨범
* 국가별 인기 플레이리스트
* 트렌딩 콘텐츠 조회  

⸻

9. Apple Music Replay 데이터

최근 버전 API 기준

* 연간 Replay 조회
* Top Songs 조회
* Top Albums 조회
* Top Artists 조회
* 연간 음악 통계 조회  

⸻

10. 즐겨찾기(Favorites)

최신 Apple Music API 기준

* 곡 즐겨찾기
* 아티스트 즐겨찾기
* 즐겨찾기 여부 확인
* 즐겨찾기 필터링  

⸻

11. Apple Music 구독 상태 확인

* Apple Music 가입 여부 확인
* 재생 가능 여부 확인
* 기능 사용 가능 여부 확인
* 구독 상태 기반 UI 분기 처리  

⸻

12. Apple Music 체험판/가입 유도

* 앱 내부에서 Apple Music 가입 화면 표시
* 체험판 가입 유도
* 구독 전환 플로우 제공  

⸻

13. Artwork(앨범 커버) 표시

* 앨범 커버 로드
* 아티스트 이미지 표시
* ArtworkImage 뷰 사용
* 고해상도 이미지 제공  

⸻

14. 지원하는 콘텐츠 종류

MusicKit 모델로 다룰 수 있는 객체

* Song
* Album
* Artist
* Playlist
* Music Video
* Genre
* Station
* Radio Show
* Curator
* Record Label
* Track  

⸻

15. 실제 앱에서 만들 수 있는 서비스 예시

* Apple Music 기반 음악 추천 앱
* 플레이리스트 생성 앱
* 음악 취향 분석 앱
* 음악 통계 앱 (Spotify Wrapped 스타일)
* Apple Music 리모컨 앱
* 음악 퀴즈 게임
* 아티스트 탐색 앱
* 음악 발견(Discovery) 앱
* 운동용 음악 플레이어
* 감정 기반 음악 추천 앱
* 음악 SNS 앱
* Apple Music 연동 DJ 앱
* 음악 리뷰 커뮤니티 앱
