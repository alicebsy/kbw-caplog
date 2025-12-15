# 24팀 강배우 2차 보고서

## 📸 CapLog
"잊혀진 스크린샷, 새로운 가치로 재탄생하다": OCR·GPT-4 기반
개인화 스크린샷 정보 관리 서비스

## 📋 목차
1. Team Info<br>
1.1. 과제명<br>
1.2. 팀 정보 (팀 번호, 팀 이름 등)<br>
1.3. 팀 구성원
2. Project-Summary<br>
2.1. 문제 정의: 과제의 배경, 필요성의 당위성<br>
2.2. 기존 연구와의 비교<br>
2.3. 제안 내용<br>
2.4. 기대 효과 및 의의
2.5. 주요 기능 리스트
3. Project-Design<br>
3.1. 요구사항 정의<br>
3.2. 전체시스템 구성<br>
3.3. 주요 엔진 및 기능 설계<br>
3.4. 주요 기능의 구현<br>
3.5. 기타: AI 활용

### Team Info
과제명: 사용자 스크린샷 속 정보를 AI가 자동 분석하여, 위치·시간대·일정 등 생활 맥락에 따라 맞춤 정보를 제공하는 개인화 정보 추천 서비스<br>
- 팀번호: 24
- 팀명: 강배우
- 지도교수: 민동보 교수님
- 팀 구성원: 강다혜(팀장, AI·백엔드), 배서연(팀원, AI·백엔드), 우민하(팀원, 프론트엔드)


### Project-Summary

| 항목 | 내용 |
|---|---|
| 1. 문제 정의 | 본 과제의 Target Customer는 스크린샷을 자주 찍는 20~30대 디지털 네이티브이다. 이들은 SNS, 웹서핑, 쇼핑몰 등에서 얻은 유용한 정보를 스크린샷으로 저장하지만, 시간이 지나면 무작위로 쌓여 원하는 정보를 찾기 어렵다. 특히 쿠폰·이벤트와 같은 유효기간이 있는 정보는 제때 확인하지 못해 무용지물이 되는 경우가 많다. 또한 사용자는 스스로 스크린샷을 분류하고 정리해야 하므로 관리가 번거롭다. 결과적으로 스크린샷은 갤러리에 방치된 채 ‘디지털 무덤’으로 전락한다.<br><br>과제의 필요성을 네 가지 측면에서 정리하면 다음과 같다.<br>첫째, 스크린샷은 단순히 저장에 머물러 있어 필요한 정보를 다시 찾기 어려워 정보 관리가 제대로 이루어지지 않는다.<br>둘째, 쿠폰이나 이벤트처럼 유효기간이 있는 정보는 방치되기 쉬워 활용 기회를 잃게 되며, 사용자는 직접 정리·검색해야 하는 부담을 안게 된다.<br>셋째, 스크린샷은 언제, 어디서 이 정보가 필요한지 맥락을 반영하지 못해 실질적인 활용이 어렵다.<br>넷째, 기존 서비스들은 단순히 사진을 ‘스크린샷’으로 분류하는 수준에 그쳐, 친구나 지인과 정보를 공유하는 기능이 부족하다. 예를 들어 삼성 갤러리는 쿠폰·탑승권 등을 단순 분류할 수 있으나, 맥락 기반 추천이나 유효기간 알림, 구조적 공유 기능은 제공하지 못한다.<br><br>따라서 본 과제는 기존 서비스가 제공하지 못하는 실질적 활용과 공유 기능을 구현하는 데 목적이 있다. 스크린샷 속 정보를 자동으로 분류·정리하고, 유효기간·위치·일정 등 맥락을 반영해 적절한 시점에 다시 제공함으로써, 사용자가 스크린샷을 생활 속에서 효과적으로 활용할 수 있는 개인화 정보 관리 서비스를 실현하고자 한다. |
| 2. 기존연구와의 비교 | **[기존 유사과제]**<br><br>**(1) 삼성 갤러리**<br>장점: 스크린샷을 일반 사진과 구분하며, AI 기반 자동 분류를 제공함<br>단점: 카테고리 세분화 부족, 사용자 임의 카테고리 불가, 의미 기반 분류 불가, 개인화 추천 기능 없음<br><br>**(2) Google 포토**<br>장점: AI 기반 이미지 인식, 자동 앨범 분류, 강력한 검색 기능 제공<br>단점: 스크린샷 구분 불가, 맥락적 활용 불가, 공유는 앨범 단위로 한정<br><br>**(3) Evernote / Notion**<br>장점: 태그, 폴더, 검색 기능 제공<br>단점: 스크린샷 자동 분류 불가, 이미지 맥락 해석 불가, 사용자가 직접 입력해야 함<br><br>**CapLog의 차별성**<br>기존 서비스들이 자동 분류, 맥락적 해석, 개인화 추천, 공유 측면에서 한계를 보이는 반면, CapLog는 **멀티모달 의미 해석과 AI 기반 카테고리/태그 생성**, **위치·시간·유효기간 등 맥락 반영 추천**, **사용자 정의 카테고리 및 공유 기능**을 제공함으로써 기존 서비스와 뚜렷한 차별성을 가진다. |
| 3. 제안 내용 | CapLog는 기존 갤러리/메모 서비스가 단순 저장과 분류에 머무르는 한계를 극복하고, 스크린샷을 생활 속에서 활용 가능한 정보 자산으로 전환하기 위한 서비스이다. 사용자가 스크린샷을 저장만 하고 활용하지 못하는 문제를 해결하기 위해, CapLog는 AI 기반 분석·분류, 맥락 기반 추천, 공유 기능을 결합한 종합적 솔루션을 제안한다.<br><br>**주요 목표**<br>1. 스크린샷 자동 정리<br>• VisionKit OCR로 날짜·장소·텍스트 추출<br>• Google Vision으로 상품·쿠폰 등 객체 탐지<br>• GPT-4 기반 의미 분석 → 카테고리·태그·위치·유효기간 자동 분류<br>• Spring 커스텀 로직으로 태그 정리 및 표준화<br><br>2. 알림 및 리마인드 제공<br>• GPT-4 분류 결과를 기반으로 카테고리 확정<br>• 유효기간·마감일 등 중요한 정보를 적절한 시점에 알림<br><br>3. 생활 패턴·맥락 기반 추천<br>• CoreLocation, EventKit 연동으로 시간·위치·일정 맥락 반영<br>• 세션 로깅을 통한 생활 패턴 분석 및 예측 추천<br><br>4.스크린샷 정보 공유<br>• 친구·그룹 단위 공유 기능 제공<br>• 공유 폴더 기반 협업 지원<br>• 개인 정보에서 그룹 활용성으로 확장<br><br>**주요 기능**<br>1. 멀티모달 정보 추출: VisionKit OCR + Google Vision API<br>2. AI 기반 의미 분류 및 카테고리/태그 생성<br>3. 위치·시간·일정 맥락을 반영한 개인화 추천<br>4. 사용자 정의 추가/수정 기능<br>5. Merge & Share 기반 정보 공유 기능<br><br>따라서 CapLog는 단순한 ‘스크린샷 관리 앱’을 넘어, **정보의 자동 정리 → 필요 시점 알림 → 맥락 기반 추천 → 협업 공유**까지 연결하는 스마트 정보 활용 플랫폼으로 발전할 것이다. |
| 4. 기대효과 및 의의 | CapLog는 스크린샷 정보 활용 가치를 높이고, 자동화·개인화·공유 측면에서 의미가 크다.<br><br>• 잊혀진 정보의 재활용 → 실질적 혜택<br>유효기간 정보를 인식해 적절한 시점에 알림을 제공, 방치되던 쿠폰·이벤트를 실제로 활용 가능<br><br>• 정리 스트레스 감소 → 정보 관리 자동화<br>스크린샷을 자동 분류·추천해 사용자가 별도 정리 없이도 효율적으로 관리 가능<br><br>• 위치 기반 리마인드 → 정보와 행동 연결<br>맛집, 장소 등 위치 맥락을 반영해 실시간 상황에 맞춘 활용 가능<br><br>• 공유 가치 확대 → 협업과 확장성<br>Merge & Share로 친구·팀원과 공동 활용, 개인 정보가 사회적 자산으로 확장<br><br>• 사회적 의의 → 디지털 자원의 재활용<br>방치된 스크린샷을 자산화하여 효율적 정보 관리와 스마트 라이프스타일 지원 |
| 5. 주요 기능 리스트 | **기능1. 스크린샷 정보 추출**<br>VisionKit OCR을 활용해 스크린샷 내 텍스트를 인식하고, Google Vision API로 상품·쿠폰 등 시각적 요소를 보완적으로 탐지하여 정보 추출 정확도를 높인다. <br><br>**기능2. AI 기반 의미 분류**<br>추출된 정보를 GPT-4 API로 분석하여 카테고리와 메타데이터(가게명, 위치, 유효기간 등)를 자동 생성하고 구조화한다.<br><br>**기능3. 개인화 추천/알림**<br>사용자의 위치(CoreLocation)와 일정(EventKit)을 기반으로, 저장된 정보가 필요한 시점에 맞춤 알림과 추천을 제공한다.<br><br>**기능4. 사용자 정의 카테고리**<br>고정된 체계에 국한되지 않고, 사용자가 자신의 관심사에 맞게 카테고리를 추가·수정할 수 있어 개인별 맞춤 관리가 가능하다.<br><br>**기능5. 공유 및 협업**<br>카드·폴더 단위로 정보를 공유하고 공동 관리할 수 있어, 개인적 정보가 팀이나 그룹 단위의 협업 자원으로 확장된다. |

### Project-Design & Implementation

| 항목 | 내용 |
|------|------|
| 1. 요구사항 정의 | **CapLog**은 사용자의 스크린샷을 자동 분류하고, 이를 기반으로 맞춤 추천을 제공하는 서비스다. iOS 앱(SwiftUI) + Spring Boot 백엔드 + MySQL DB로 구현되며, 주요 요구사항은 다음과 같다.<br><br>**회원 관리**<br>• 회원가입: 이메일/비밀번호/아이디/이름 입력 및 필수 동의<br>• 로그인/로그아웃: JWT 기반 인증<br>• 프로필 관리: 이름, 이메일 수정 및 계정 탈퇴<br><br>**스크린샷 관리**<br>• iOS Photos Framework 자동 연동<br>• VisionKit OCR로 텍스트 추출<br>• GPT API로 의미 분석 및 카테고리 분류<br>• 메타데이터(위치, 시간, 태그 등) 저장<br><br>**추천 기능**<br>• 최근 스크린샷 3개 추천<br>• 알림 기능 (적절한 시점에 재제공)<br><br>**검색 기능**<br>• OCR 텍스트 검색<br>• 태그/카테고리 기반 필터링<br><br>**공유 기능**<br>• 스크린샷 카드 공유<br>• 폴더 개인화<br><br>**비기능 요구사항**<br>• 보안성: BCrypt 비밀번호 해싱, JWT 인증<br>• 확장성: 신규 카테고리/기능 추가 용이<br>• 가용성: Docker 기반 MySQL 볼륨 관리<br>• 성능: OCR + GPT API 응답 최적화 |
| 2. 전체 시스템 구성 | **[구성 요소]**<br>**iOS 프론트엔드 (SwiftUI)**<br>• UI: 회원가입/로그인/메인/검색/마이페이지/폴더/친구/스크린샷<br>• Photos Framework로 기기 갤러리 접근<br>• VisionKit OCR<br>• REST API 연동<br><br>**백엔드 (Spring Boot, Java17)**<br>• 모듈: 회원, 로그인, 스크린샷, 추천, 검색, 공유<br>• 보안: Sping Security + JWT<br>• DB 연동: JPA + MySQL<br><br>**DB (MySQL on Docker)**<br>• 주요 테이블: user, screenshot, category, folder, share, metadata, tag<br>• mysql-data 볼륨으로 영속성 보장<br><br>**외부 API**<br>• GPT-4 (텍스트 의미 분석/분류)<br>• VisionKit (OCR)<br><br>![시스템 구성도](https://raw.githubusercontent.com/alicebsy/kbw-caplog/main/docs/images/caplog_system.png) |
| 3. 주요 엔진 및 기능 설계 | **OCR 엔진**<br>• iOS **VisionKit**을 활용하여 스크린샷 이미지 내 텍스트를 추출<br>• 텍스트 인식 결과는 **TextPreprocessor 모듈**에서 정규표현식 기반 후처리(Post-processing) 과정을 통해 불필요한 줄(이모티콘, URL, 특수문자 등)을 제거<br><br>**의미 분석 엔진**<br>• **GPTCategory 모듈**이 GPT-4 API를 호출하여 텍스트의 의미를 분석하고 카테고리, 장소명, 유효기간을 구조화된 JSON 형태로 반환<br>• 예: `{"category":"1.1 장소-맛집", "placeName":"을지로 한우정", "deadline":"2025-01-20"}`<br>• 응답 파싱은 **ResultParser 모듈**에서 수행되며, Swift 구조체(`GPTResult`)로 변환<br><br>**추천 엔진**<br>• CoreLocation과 EventKit 데이터를 결합하여 사용자의 **시간적/공간적 맥락**을 수집<br>• **RecommendationEngine 모듈**에서 Rule-based 로직 수행: 위치 반경, 유효기간, 일정 공백(freeSlots) 조건 매칭<br>• 향후 embedding 기반 유사도 추천(Vector DB)로 확장 예정<br><br>**세션 로깅 엔진**<br>• ScreenTime API 제약을 우회하기 위해 **SwiftUI ScenePhase**를 이용해 직접 세션 상태 감지<br>• UsageLogger 모듈에서 `startTime`, `endTime`, `duration`, `locationCount` 기록 후 CoreLocation 로그와 통합 저장<br><br>**데이터베이스 구조**<br>• user: 회원 계정 정보<br>• screenshot: OCR 및 GPT 결과 메타데이터<br>• category: 계층형 분류 코드 저장<br>• metadata: key-value 형태의 부가 정보(위치, 주소 등)<br>• tag: 사용자 정의 태그<br><br>![ERD](https://raw.githubusercontent.com/alicebsy/kbw-caplog/0b8c6642bea58fe606f37bcb481f98d9998fd17c/docs/images/caplog_erd.png) |
| 4. 주요 기능의 구현 | **① 회원 관리 (로그인/회원가입)**<br>이 기능의 구현을 위하여 Spring Boot 기반의 **Security 모듈**과 **JWT 인증 모듈**을 도입하였고, 사용자 정보를 관리하기 위한 **UserController** 및 **UserRepository**를 구현하였다.<br>• **회원가입:** BCrypt 해싱으로 비밀번호 암호화, 이메일 중복 검사 후 DB 저장<br>• **로그인:** JWT 토큰 발급 및 Authorization 헤더 인증 처리<br>• **프로필 관리:** 이름, 이메일 수정 및 계정 삭제 API 제공<br><br>**② 스크린샷 자동 분류 및 카드 생성 (OCR + GPT)**<br>이 기능의 구현을 위하여 **VisionKit OCR 모듈**과 **GPTCategory 모듈**을 도입하였고, 내부적으로 **TextPreprocessor**(후처리)와 **ResultParser**(응답 파싱) 모듈을 구현하였다.<br>• A1. VisionKit으로 이미지 텍스트 추출<br>• A2. GPT-4 API로 의미 분석 → 카테고리·장소명·유효기간 반환<br>• 결과를 ScreenshotCard 객체로 저장 후 JSON 형태로 클라이언트 전달<br>• 효과: 스크린샷을 정보 단위(Card)로 검색·추천·공유 가능<br><br>**③ 개인화 추천 (RecommendationEngine)**<br>이 기능의 구현을 위하여 **CoreLocation**과 **EventKit** 모듈을 도입하였고, 이를 통합 관리하는 **RecommendationEngine**을 구현하였다.<br>• B1. CoreLocation으로 사용자 위치 좌표 수집<br>• B2. EventKit으로 일정 기반 free time 계산<br>• Rule-based 조건에 따라 알림 또는 추천 수행<br>예: `if deadline.isTodayOrTomorrow → triggerReminder()`<br>• 향후: LSTM 기반 행동 예측 모델로 확장 계획<br><br>**④ 공유 기능 (카드·폴더 협업)**<br>이 기능의 구현을 위하여 **ShareController** 및 **FolderService**를 구현하였다.<br>• 카드 상세 화면 → 공유 버튼 클릭 시 공유 API 호출<br>• 공유방에서 카드 미리보기 및 권한(읽기/쓰기/관리) 부여<br>• 폴더 단위로 협업 가능, WebSocket 실시간 알림 확장 예정<br><br>**⑤ 세션 로깅 (UsageLogger)**<br>이 기능의 구현을 위하여 **SwiftUI ScenePhase 감지 모듈**을 도입하였고, **UsageLogger 모듈**을 구현하였다.<br>• C1. 앱 활성화 시 startTime 기록, 백그라운드 전환 시 endTime 기록<br>• C2. duration 계산 후 DB 저장, locationCount와 병합<br>• 결과: 사용자의 세션 패턴 및 활동 밀도(activityDensity) 데이터 확보 |
| 3.5 AI 활용 내용 | **① VisionKit (OCR)**<br>• **목적:** 스크린샷 이미지 내 텍스트를 자동 인식하여 정보 추출<br>• **입력:** 사용자 갤러리 내 스크린샷 이미지<br>• **출력:** 인식된 문자열 데이터(String)<br>• **활용 모듈:** GPTCategory의 전처리 단계에서 사용<br>• **구현 방식:** iOS VisionKit의 `VNRecognizeTextRequest` API 사용 → 텍스트 블록 단위 인식 결과를 수집하고 문자열로 병합<br>• **후처리:** TextPreprocessor 모듈에서 불필요한 줄·이모티콘·URL 제거 (정규표현식 기반 필터링)<br>• **결과:** 조명, 해상도, 배경색에 따라 인식률 평균 90% 이상 달성<br><br>**② Google Vision API (객체 인식 보조 분석)**<br>• **목적:** OCR이 감지하지 못한 시각적 요소(상품, 로고, 쿠폰 등)를 인식하여 GPT 입력에 보조 정보로 활용<br>• **입력:** 스크린샷 이미지<br>• **출력:** 탐지된 객체 라벨 및 좌표(`label, confidence, bounding_box`)<br>• **활용 모듈:** VisionKit OCR 결과가 불충분할 경우, Google Vision의 `label_detection` API 호출<br>• **구현 방식:** Google Cloud Vision API 연동 → REST 요청으로 이미지 base64 인코딩 후 분석 결과 반환<br>• **결과:** 상품, 쿠폰, 지도, 음식 등 실물 객체 탐지 정확도 평균 87% 달성<br>• **활용 예시:** GPT 입력 프롬프트에 `"detected_object": "coffee_coupon"` 등 보조 키워드로 삽입하여 문맥 해석 정확도 향상<br><br>**③ GPT-4 API (의미 분석 및 분류)**<br>• **목적:** VisionKit 및 Google Vision으로부터 수집된 텍스트·객체 정보를 의미적으로 분석하여 카테고리, 장소명, 유효기간을 구조화<br>• **입력:** OCR 텍스트 + Google Vision 객체 태그<br>• **출력:** `{"category":"1.1 장소-맛집", "placeName":"을지로 한우정", "deadline":"2025-01-20"}` 형태의 JSON<br>• **활용 모듈:** GPTCategory → ResultParser<br>• **구현 방식:** GPT-4 API 호출 시, 프롬프트에 명시적으로 “category, placeName, deadline을 JSON 형식으로 반환” 지시<br>• **후처리:** Swift의 `JSONDecoder()`로 파싱 후 ScreenshotCard 객체에 저장<br>• **개선점:** 1차 대비 구조화된 프롬프트를 적용해 분류 정확도 향상<br><br>**④ RecommendationEngine (AI 확장 계획)**<br>• **목적:** 사용자의 행동·위치·시간 데이터를 바탕으로 개인화 추천 제공<br>• **현재 버전:** Rule-based 추천 알고리즘 (위치 반경 + 유효기간 + 일정 빈 시간 조건)<br>• **활용 예시:** “근처 카페 추천”, “오늘 만료 쿠폰 알림” 등 시나리오 기반 리마인드<br>• **향후 계획:** LSTM 기반 행동 예측 모델 학습 및 GPT 결과와 통합하여 완전한 AI 추천 파이프라인 구축 예정<br>• **AI Pipeline 개요:** VisionKit OCR → Google Vision 객체 인식 → GPT-4 의미 분석 → Rule/LSTM 기반 추천 |
