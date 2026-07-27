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

## 필요한 환경변수

실제 비밀값은 소스 코드나 Git 저장소에 커밋하지 말고, 실행 환경에서 주입해야 합니다.

```bash
export JWT_SECRET="32바이트 이상의 무작위 값"
export SPRING_DATASOURCE_PASSWORD="데이터베이스 비밀번호"
export OPENAI_API_KEY="OpenAI API 키"
export KAKAO_REST_API_KEY="Kakao REST API 키"

# 선택 설정
export OPENAI_MODEL="gpt-4o-mini"
export APP_BASE_URL="http://localhost:8080"
```

## API 및 데이터 변경사항

- `POST /api/screenshots/upload`
  - Bearer 토큰이 필수입니다.
  - `userId` 요청 파라미터를 더 이상 받지 않습니다.
- `GET /api/screenshots/{id}/content`
  - 해당 스크린샷의 소유자만 이미지 원본을 조회할 수 있습니다.
- `POST /api/ai/classify`
  - 인증된 사용자의 분류 요청을 백엔드가 OpenAI로 전달합니다.
- `screenshot_file` 테이블
  - `storage_key`, `content_type`, `size_bytes` 컬럼을 사용합니다.

## 검증 결과

- 백엔드 Gradle 테스트 10개 통과
- iOS 시뮬레이터 대상 Xcode 빌드 성공
- 실제 OpenAI 네트워크 호출은 API 키를 입력하지 않은 상태라 수행하지 않았습니다.

## 아직 남은 보안 작업

다음 항목은 이번 변경에 포함되지 않았으며 후속 작업이 필요합니다.

- iOS 앱에 남아 있는 Google Vision API 키를 백엔드로 이전
- 개발 장비 IP 주소 등 환경별 서버 주소 설정 분리
- 로그인, 업로드, AI 요청 API에 사용자별 요청 횟수 제한 적용
- Swift 6 동시성(actor isolation) 경고 정리
- 저장소에서 누락된 Gradle Wrapper JAR 관리 방식 정리
