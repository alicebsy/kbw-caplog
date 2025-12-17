# CapLog

OCR·GPT-4 기반 개인화 스크린샷 정보 관리 서비스  
사용자의 스크린샷 속 정보를 자동 분석하여, 위치·시간·일정 등 생활 맥락에 따라 맞춤 정보를 제공하는 iOS 기반 개인화 정보 추천 플랫폼

---

## Team Info

- **Course Project Team**: 24팀  
- **Team Name**: 강배우  
- **Advisor**: 민동보 교수님  

### Team Members
- 강다혜 – 팀장, AI·백엔드  
- 배서연 – 팀원, AI·백엔드  
- 우민하 – 팀원, 프론트엔드(iOS)

---

## Project Summary

CapLog는 사용자가 무의식적으로 저장해 두고 활용하지 못하는 스크린샷을  
AI 기반으로 자동 정리하고, 실제 생활 맥락에 맞게 다시 제공하는 개인화 정보 관리 서비스이다.

기존 갤러리 및 메모 서비스는 스크린샷을 단순 저장하거나 이미지 단위로 분류하는 데 그치며,  
유효기간·위치·일정과 같은 맥락 정보를 반영하지 못한다는 한계를 가진다.

본 프로젝트는 VisionKit OCR, Google Vision API, GPT-4를 결합한 멀티모달 분석을 통해  
스크린샷 속 정보를 구조화하고, 사용자의 위치·시간·일정을 반영한 추천과 알림을 제공함으로써  
스크린샷을 실제로 “다시 쓰이는 정보 자산”으로 전환하는 것을 목표로 한다.

---

## Key Features

- VisionKit OCR 기반 스크린샷 텍스트 자동 추출
- Google Vision API 기반 객체 인식 보조 분석
- GPT-4 기반 의미 분석 및 카테고리·메타데이터 자동 생성
- 위치(CoreLocation)·일정(EventKit) 기반 개인화 추천
- 유효기간 및 마감일 기반 알림
- 사용자 정의 카테고리 및 태그
- 공유 폴더 및 채팅 기반 정보 공유

---

## System Architecture

### Frontend
- iOS (SwiftUI)
- Photos Framework
- VisionKit OCR
- CoreLocation / EventKit

### Backend
- Spring Boot (Java 17)
- Spring Security + JWT
- JPA

### Database
- MySQL (Docker)
- user, screenshot, category, folder, share, metadata, tag

### External APIs
- GPT-4 API
- Google Vision API
- VisionKit OCR

---

## How to Install

### Backend
1. Java 17 설치
2. MySQL 실행 (Docker)
3. 환경 변수 또는 application.yml 설정
4. Spring Boot 실행

### iOS App
1. Xcode에서 프로젝트 열기
2. 실제 기기 또는 시뮬레이터 선택
3. Run

---

## How to Build

### Backend
```bash
./gradlew build
```

### iOS App
- **Xcode에서 Build (Cmd + B)**

---

## How to Test
- **실제 iOS 기기에서 앱 실행**
- **스크린샷 선택 후 OCR 및 GPT 기반 분석 수행**
- **홈 화면에서 자동 생성된 카드 확인**
- **위치 변경 후 추천 카드 변경 여부 확인**
- **카드 공유 기능 정상 동작 여부 확인**

---

## Sample Data
- **테스트용 스크린샷 약 200장 사용**
- **카테고리별 스크린샷 데이터 수집**
- **분류 정확도 및 메타데이터 추출 결과 검증**

---

## Database
- **MySQL 사용**
- **Docker 기반 MySQL 컨테이너 운영**
- **주요 테이블**
  - **user**
  - **screenshot**
  - **category**
  - **folder**
  - **share**
  - **metadata**
  - **tag**

---

## Open Source Used
- **Spring Boot**
- **Spring Security**
- **Hibernate (JPA)**
- **SwiftUI**
- **VisionKit**
- **CoreLocation**
- **EventKit**

---

## Evaluation Summary
- **스크린샷 자동 분류 정확도: 약 95%**
- **위치 기반 추천 동작 성공률: 약 90%**
- **iOS 앱–백엔드–데이터 처리 흐름 정상 동작 확인**

---

## Conclusion

**CapLog는 스크린샷을 단순 저장 데이터가 아닌  
AI 기반으로 재구성되는 생활 맥락 정보 자산으로 전환하는 서비스이다.**

**OCR과 GPT 기반 자동 분류, 위치·시간 중심의 추천 구조를 통해  
사용자가 저장한 정보를 실제 생활에서 다시 활용할 수 있음을 검증하였다.**

**향후에는 일정 및 사용 패턴 데이터를 포함한 학습 기반 추천 모델 도입과  
GPT 호출 비용 및 응답 지연에 대한 성능 최적화를 통해  
보다 완성도 높은 개인화 정보 관리 플랫폼으로 확장할 예정이다.**
