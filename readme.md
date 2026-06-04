#  Sound and Music


## 재밋어보이는 기능 리스트업

<https://developer.apple.com/documentation/applemusicapi/artwork>
- **아트워크** 
    - bgColor 이미지의 평균 배경색.
    - textColor1 배경색이 표시될 경우 사용되는 기본 텍스트 색상입니다.


<https://developer.apple.com/documentation/applemusicapi/musicsummaries/views-data.dictionary>
- **musicsummaries**
    - 사용자가 지정된 기간 동안 가장 많이 들었던 앨범, 아티스트 및 노래 목록입니다.


---

## MusicKit 시작하기 !
<https://developer.apple.com/documentation/MusicKit/> 

1. 애플 개발자 계정에서 미디어 Identifiers와 개인 키를 생성
- Certificates, Identifiers & Profiles > Identifiers > Media IDs > 새로 생성
- Certificates, Identifiers & Profiles > keys > 새로 생성 (Media Services (MusicKit, ShazamKit, Apple Music Feed))


2. 프로젝트의 App ID에 들어가 MusicKit 활성화
- 만약 배포 전이라 조회되지 않는다면?
    - App IDs를 직접 추가하기
        - Description: 앱 이름 / Bundle ID: 고유 식별자 (e.g., com.yourname.appname)
        - 만들고 있는 Xcode 프로젝트의 Bundle identifier에 똑같이 기입


3. 사용자 권한 요청 문구 추가 (Info.plist)
- Xcode 프로젝트 > Info탭 > 새로운 key 추가(+)
- key name:  Privacy - Music Usage Description
- value 에 안내문구 기입 (e.g., Apple Music 카탈로그 검색 및 음악 재생 기능을 제공하기 위해 음악 보관함 권한이 필요합니다.)


4. macOS 앱 - 샌드박스(App Sandbox) 네트워크 설정 허용
- Targets > macOS > Signing & Capabilities > App Sandbox > Network: Outgoing Connections (Client)
