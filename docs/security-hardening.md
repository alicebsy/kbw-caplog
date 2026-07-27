# 보안 강화 변경사항

- 작성일: 2026-07-27
- 적용 커밋: `5e896e2`, `399fd1c`
- 적용 범위: Spring Boot 백엔드, iOS 앱, 데이터 접근 및 파일 업로드

## 적용한 변경사항

### 1. 인증 및 비밀번호 보안

- `JWT_SECRET` 환경변수를 필수로 변경했습니다.
- JWT 비밀키는 32바이트 이상이어야 하며, 기본값이나 취약한 값은 서버 시작 시 거부합니다.
- 액세스 토큰과 리프레시 토큰이 로그에 출력되지 않도록 제거했습니다.
- 토큰 갱신 시 리프레시 토큰도 함께 교체하도록 변경했습니다.
- 회원가입과 비밀번호 변경 시 비밀번호 길이를 8~72자로 제한했습니다.
- 기존 비밀번호와 같은 값으로 비밀번호를 변경할 수 없도록 했습니다.

### 2. 스크린샷 업로드 및 파일 접근 보안

- 스크린샷 업로드 API에 JWT 인증을 필수로 적용했습니다.
- 클라이언트가 임의의 `userId`를 전달하지 못하도록 제거하고, JWT의 사용자 정보로 소유자를 결정합니다.
- 업로드 가능한 파일을 실제 JPEG/PNG 이미지로 제한했습니다.
- 파일 크기를 최대 10MB로 제한했습니다.
- 저장 파일명은 UUID 기반으로 생성해 파일명 충돌과 경로 조작 위험을 줄였습니다.
- 이미지 원본은 소유자만 열람할 수 있고, 응답에 `Cache-Control: no-store`를 적용했습니다.
- iOS 앱의 업로드 및 이미지 조회 요청에 JWT를 첨부하도록 변경했습니다.

### 3. 사용자 데이터 격리

- 추천 목록 조회 시 현재 로그인한 사용자의 데이터만 조회하도록 조건을 추가했습니다.
- 위치 변환(geocode) 요청도 본인이 소유한 스크린샷에만 수행할 수 있도록 제한했습니다.

### 4. OpenAI API 키 보호

- iOS 앱에 있던 OpenAI API 키와 OpenAI 직접 호출 코드를 제거했습니다.
- 인증이 필요한 백엔드 엔드포인트 `/api/ai/classify`를 추가했습니다.
- `OPENAI_API_KEY`는 서버 환경변수에서만 읽도록 변경했습니다.
- OpenAI Responses API를 사용하며 모델은 `OPENAI_MODEL`로 설정할 수 있습니다.
- 프롬프트 길이를 최대 30,000자로 제한하고 요청 제한 시간을 90초로 설정했습니다.
- 외부 API의 상세 오류가 클라이언트에 그대로 노출되지 않도록 일반화된 오류로 응답합니다.

### 5. 서버 설정 보안

- 데이터베이스 비밀번호 기본값을 제거하고 `SPRING_DATASOURCE_PASSWORD`를 필수로 변경했습니다.
- Kakao REST API 키는 `KAKAO_REST_API_KEY` 환경변수로만 주입하도록 구성돼 있습니다.
- 서버 주소는 `APP_BASE_URL` 환경변수로 변경할 수 있도록 했습니다.
- 운영 중 민감한 정보가 노출될 수 있는 상세 로그 수준을 낮췄습니다.

### 6. iOS 네트워크 및 설정 파일 보호

- 모든 비보안 네트워크 연결을 허용하던 `NSAllowsArbitraryLoads` 설정을 제거했습니다.
- 로컬 개발 서버 통신에 필요한 로컬 네트워크만 허용하도록 범위를 축소했습니다.
- 더 이상 iOS에서 직접 호출하지 않는 OpenAI 도메인 예외와 `GPT_API_KEY` 설정을 제거했습니다.
- `Secrets.xcconfig`가 앱 리소스에 복사되지 않도록 빌드 설정에서 제외했습니다.

### 7. 개발·배포 API 서버 주소 분리

- Debug 빌드는 설정값이 없을 때 기존 로컬 개발 서버 주소를 사용합니다.
- Release 빌드는 `CAPLOG_API_BASE_URL`에 운영 서버 주소가 반드시 설정돼 있어야 합니다.
- Release 빌드에서는 HTTPS 주소만 허용해 로컬 IP나 일반 HTTP 주소로 잘못 배포되는 것을 차단합니다.
- 운영 서버 주소를 소스 코드에 하드코딩하지 않고 Xcode 빌드 설정으로 주입할 수 있습니다.

### 8. Google Vision API 키 보호

- iOS 앱의 Google Vision API 키와 Google 직접 호출 코드를 제거했습니다.
- 인증이 필요한 백엔드 엔드포인트 `/api/ai/vision/text`, `/api/ai/vision/labels`를 추가했습니다.
- `GOOGLE_VISION_API_KEY`는 서버 환경변수에서만 읽도록 변경했습니다.
- 전달 이미지는 JPEG/PNG 형식과 최대 10MB 제한을 검증합니다.
- Google Vision 오류 본문과 API 키가 클라이언트 로그나 응답에 노출되지 않도록 했습니다.

### 9. Kakao 네이티브 앱 키 설정 분리

- Swift 소스에 하드코딩돼 있던 Kakao 네이티브 앱 키를 제거했습니다.
- 앱 키는 Git에서 제외되는 `Secrets.local.xcconfig`로 주입합니다.
- 키가 누락된 Release 빌드는 실행을 중단해 잘못 설정된 앱이 배포되지 않도록 했습니다.
- 카카오 로그인 SDK와 로그인 화면 및 콜백 코드는 그대로 유지했습니다.

새 개발 환경에서는 예제 파일을 복사한 뒤 본인의 Kakao 네이티브 앱 키를 입력해야 합니다.

```bash
cp Secrets.local.xcconfig.example Secrets.local.xcconfig
```

네이티브 앱 키는 최종 앱 바이너리에 포함되는 식별자이므로 Kakao Developers 콘솔에서 iOS 번들 ID를 제한해야 합니다. 기존 키가 Git 기록에 남아 있으므로 배포 전 키 재발급도 권장합니다.

### 10. 주요 API 요청 횟수 제한

- 로그인은 IP당 분당 5회, 회원가입은 IP당 10분에 3회로 제한했습니다.
- 토큰 갱신은 IP당 분당 10회로 제한했습니다.
- 스크린샷 업로드는 사용자당 분당 10회로 제한했습니다.
- OpenAI 분류는 사용자당 분당 20회, Google Vision 분석은 사용자당 분당 10회로 제한했습니다.
- 한도를 넘으면 `429 Too Many Requests`, `Retry-After`, `Cache-Control: no-store`를 반환합니다.
- 기본적으로 직접 연결 IP만 신뢰하며, 검증된 리버스 프록시를 사용할 때만 전달 헤더를 활성화할 수 있습니다.

### 11. Gradle Wrapper 복구 및 무결성 검증

- 저장소에서 누락됐던 `gradle-wrapper.jar`를 Gradle 8.10 공식 Wrapper로 복구했습니다.
- 모든 개발·CI 환경이 시스템 Gradle 대신 `./gradlew`로 동일한 Gradle 8.10을 사용하도록 했습니다.
- Gradle 배포 ZIP의 공식 SHA-256 체크섬을 `gradle-wrapper.properties`에 고정했습니다.
- 전역 `*.jar` 제외 규칙과 관계없이 공식 Wrapper JAR만 Git에 포함되도록 예외를 추가했습니다.

```bash
./gradlew test
```

### 12. 스크린샷 자동 감지 동시성 안전성

- Photos 프레임워크의 변경 콜백을 `nonisolated` 진입점으로 분리했습니다.
- 백그라운드에서 전달되는 콜백이 앱 상태에 직접 접근하지 않고 MainActor로 전환된 뒤 처리되도록 했습니다.
- 불필요한 `PHAsset` 강제 형변환을 제거했습니다.
- Swift 6에서 오류로 강화될 사진 라이브러리 콜백의 actor isolation 경고를 해소했습니다.

### 13. 공유 화면 상태의 MainActor 격리

- `ShareViewModel`의 저장소, 카드 관리자, 싱글톤 초기화를 MainActor 안에서 수행하도록 통일했습니다.
- 개발용 친구 데이터는 불변 `Sendable` 값으로 명시해 MainActor 상태와 분리했습니다.
- Swift 6에서 오류로 강화될 공유 화면의 actor isolation 경고를 해소했습니다.

### 14. 스크린샷 파이프라인 상태 업데이트 정리

- 스크린샷 인덱서와 진행 상태 객체가 같은 MainActor에서 실행됨을 코드에 명확히 반영했습니다.
- 실제 비동기 작업이 없는 상태 변경에서 불필요한 `await`를 제거했습니다.
- 사진 탐색, 이미지 로드, OCR·GPT 성공 및 실패 상태 표시 동작은 그대로 유지했습니다.

### 15. 홈 만료 카드 날짜 처리 보완

- 날짜만 제공되는 만료 정보는 당일 자정이 아니라 해당 날짜가 끝날 때까지 유효하게 표시합니다.
- `만료일`, `valid_until`, `deadline` 중 비어 있지 않은 첫 값을 공통으로 사용합니다.
- 날짜 문자열의 앞뒤 공백과 줄바꿈을 제거하고 엄격한 Gregorian 달력으로 파싱합니다.
- 만료 카드 정렬 과정의 불필요한 가변 변수를 제거해 컴파일러 경고를 해소했습니다.

### 16. 로컬 스크린샷 전용 처리

- Photos 이미지 요청의 네트워크 접근을 명시적으로 차단했습니다.
- 기기에 원본이 저장된 스크린샷만 처리하며 iCloud 원본은 다운로드하지 않습니다.
- Photos가 전달하는 저화질 중간 이미지는 건너뛰고 최종 고화질 이미지 한 번만 OCR로 처리합니다.
- 사진 요청 취소·오류·빈 결과를 구분해 파이프라인 실패 상태와 로그에 남깁니다.
- 수동 가져오기와 새 스크린샷 자동 감지 경로에 같은 처리 규칙을 적용했습니다.

### 17. 실제 채팅방 생성 및 재사용

- 카드 공유 화면에서 임시 로컬 채팅방 ID를 만들지 않고 서버 채팅방을 생성한 뒤 사용합니다.
- 서버가 채팅방 참여자 ID를 내려줘 이름이 같은 사용자도 정확히 구분합니다.
- 동일한 상대와의 1:1 채팅방이 이미 있으면 새 방을 중복 생성하지 않고 기존 방을 반환합니다.
- 채팅방 참여자 컬렉션을 함께 조회해 지연 로딩으로 목록 조회가 실패하지 않도록 했습니다.
- 구버전 서버 응답에는 제목 기반 매칭을 유지해 배포 전환 중에도 호환됩니다.

### 18. 카드 채팅 메시지 영구 저장

- 카드 공유 메시지를 텍스트 메시지와 동일하게 서버 DB에 저장합니다.
- 전송 시 카드가 현재 사용자의 소유인지 확인해 다른 사용자의 카드 ID를 임의로 공유할 수 없게 했습니다.
- 카드 내용을 메시지 시점의 스냅샷으로 저장해 앱 재실행과 상대방 접속 후에도 같은 카드를 표시합니다.
- 채팅방 목록에도 마지막으로 공유한 카드 제목을 표시합니다.
- 텍스트와 카드가 모두 없는 빈 메시지는 서버에서 거부합니다.

## 필요한 환경변수

실제 비밀값은 소스 코드나 Git 저장소에 커밋하지 말고, 실행 환경에서 주입해야 합니다.

```bash
export JWT_SECRET="32바이트 이상의 무작위 값"
export SPRING_DATASOURCE_PASSWORD="데이터베이스 비밀번호"
export OPENAI_API_KEY="OpenAI API 키"
export GOOGLE_VISION_API_KEY="Google Vision API 키"
export KAKAO_REST_API_KEY="Kakao REST API 키"

# 선택 설정
export OPENAI_MODEL="gpt-4o-mini"
export APP_BASE_URL="http://localhost:8080"

# 신뢰할 수 있는 리버스 프록시가 X-Forwarded-For를 덮어쓰는 환경에서만 사용
export CAPLOG_TRUST_FORWARDED_HEADERS="true"
```

iOS Release 빌드에는 운영 백엔드 주소를 Xcode 빌드 설정으로 전달해야 합니다.

```bash
xcodebuild \
  -project Caplog.xcodeproj \
  -scheme Caplog \
  -configuration Release \
  CAPLOG_API_BASE_URL="https://api.example.com"
```

## API 및 데이터 변경사항

- `POST /api/screenshots/upload`
  - Bearer 토큰이 필수입니다.
  - `userId` 요청 파라미터를 더 이상 받지 않습니다.
- `GET /api/screenshots/{id}/content`
  - 해당 스크린샷의 소유자만 이미지 원본을 조회할 수 있습니다.
- `POST /api/ai/classify`
  - 인증된 사용자의 분류 요청을 백엔드가 OpenAI로 전달합니다.
- `POST /api/ai/vision/text`
  - 인증된 사용자의 OCR 요청을 백엔드가 Google Vision으로 전달합니다.
- `POST /api/ai/vision/labels`
  - 인증된 사용자의 이미지 레이블 요청을 백엔드가 Google Vision으로 전달합니다.
- `screenshot_file` 테이블
  - `storage_key`, `content_type`, `size_bytes` 컬럼을 사용합니다.

## 검증 결과

- 백엔드 Gradle 테스트 16개 통과
- iOS 시뮬레이터 대상 Xcode 빌드 성공
- 실제 OpenAI 및 Google Vision 네트워크 호출은 API 키를 입력하지 않은 상태라 수행하지 않았습니다.

## 아직 남은 보안 작업

다음 항목은 이번 변경에 포함되지 않았으며 후속 작업이 필요합니다.

- Kakao Developers 콘솔에서 네이티브 앱 키 재발급 및 iOS 플랫폼 제한 적용
- 나머지 Swift 컴파일러 경고 정리
