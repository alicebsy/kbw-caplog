# CapLog 보류 기능과 복원 체크리스트

> 이 문서는 개발 속도를 위해 현재 빌드에서 잠시 제외한 기능을 잊지 않고 다시 완성하기 위한 기록이다.

## Apple·Google·Kakao 소셜 로그인

### 현재 상태

- 상태: 미완성, 기본 빌드와 사용자 화면에서 비활성화
- 비활성화일: 2026-07-30
- 이유:
  - 백엔드 계정 통합이 완성되지 않은 버튼을 사용자에게 노출하지 않기 위해
  - 사용하지 않는 Google·Kakao SDK와 하위 패키지의 해석·컴파일 시간을 줄이기 위해
- 현재 사용할 수 있는 인증: 이메일 회원가입·로그인

### 보존한 코드

다음 파일의 소셜 로그인 코드는 `#if SOCIAL_LOGIN_ENABLED` 안에 남겨 두었다.

- `App/caplogApp.swift`: Kakao SDK 초기화와 Google·Kakao URL callback
- `Core/Auth/AuthService.swift`: Google·Kakao SDK 로그인
- `Features/Register/Register2View.swift`: 회원가입 화면 소셜 로그인 버튼
- `Features/Register/Register3View.swift`: 로그인 화면 소셜 로그인 버튼
- `Core/APIs/AuthAPI.swift`: 공급자 토큰을 서버로 전달할 교환 요청

### 현재 제외한 의존성

- Google Sign-In iOS SDK
- Kakao iOS SDK의 Common, Auth, User 모듈

Apple 로그인은 시스템 프레임워크를 사용하지만 Google·Kakao와 함께 계정 통합 정책을 완성한 뒤 노출하기 위해 현재 버튼을 숨겼다.

### 다시 작업할 때 필요한 순서

- [ ] Apple, Google, Kakao 중 실제 지원할 공급자 확정
- [ ] 공급자별 공식 iOS SDK를 Xcode Swift Package Dependencies에 다시 추가
- [ ] 필요한 제품 모듈을 Caplog 앱 타깃에 연결
- [ ] Debug와 Release 빌드 설정에 `SOCIAL_LOGIN_ENABLED` 플래그 추가
- [ ] 백엔드에 공급자별 토큰 검증 endpoint 구현
- [ ] 기존 이메일 계정과 소셜 계정 연결 정책 정의
- [ ] 같은 이메일의 계정 충돌·병합 정책 정의
- [ ] nonce, state 및 공급자별 보안 검증 적용
- [ ] 회원 탈퇴 시 공급자 연결 해제와 토큰 폐기 구현
- [ ] 로그인 취소·실패·재시도 UX 구현
- [ ] 실제 기기에서 신규 가입, 기존 계정 연결, 재로그인 검증
- [ ] 검증 완료 후에만 로그인·회원가입 화면에 버튼 노출

### 완료 조건

소셜 로그인은 버튼이 실행되는 것만으로 완료로 판단하지 않는다. 공급자 토큰을 백엔드에서 검증하고, CapLog 사용자 계정과 안전하게 연결하며, 재로그인과 탈퇴까지 정상 동작해야 완료 상태로 변경한다.

---

## 빌드 검사에서 발견한 후속 정리

### 이미지 에셋 파일명 정리

- 상태: 빌드는 성공하지만 일부 기존 이미지 세트에서 경고 발생
- 원인: `Contents.json`에 기록된 한글 파일명과 실제 파일명의 Unicode 정규화 방식이 다르거나, 이미지 세트 안에 할당되지 않은 파일이 함께 존재함
- 영향: 현재 빌드를 막지는 않지만 해당 Mock·브랜드 이미지가 표시되지 않을 수 있고 에셋 컴파일 경고가 반복됨
- 다음 작업:
  - [ ] 경고가 발생한 이미지 세트의 실제 사용 여부 확인
  - [ ] 사용하는 이미지는 파일명과 `Contents.json` 참조를 동일하게 정리
  - [ ] 사용하지 않는 졸업프로젝트 Mock 이미지는 안전하게 제거
  - [ ] 에셋 경고가 없는 상태로 iOS 빌드 재검증
