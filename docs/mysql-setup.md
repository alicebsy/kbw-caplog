# MySQL 로컬 설정 (Spring Boot bootRun용)

`Access denied for user 'caplog'@'localhost'` 가 나오면 아래 중 하나로 맞추면 됩니다.

## 1) MySQL에 caplog 계정·DB 만들기 (기본값 그대로 쓰고 싶을 때)

MySQL 접속 후:

```sql
CREATE DATABASE IF NOT EXISTS caplog
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'caplog'@'localhost' IDENTIFIED BY 'caplogpw';
GRANT ALL PRIVILEGES ON caplog.* TO 'caplog'@'localhost';
FLUSH PRIVILEGES;
```

이후:

```bash
./gradlew bootRun
```

## 2) 이미 쓰는 계정(예: root)으로 접속하기

`application.yml` 기본값은 `caplog` / `caplogpw` 이고, 환경변수로 덮을 수 있습니다.

```bash
export SPRING_DATASOURCE_USERNAME=root
export SPRING_DATASOURCE_PASSWORD=내비밀번호
./gradlew bootRun
```

DB는 미리 만들어 두어야 합니다.

```sql
CREATE DATABASE IF NOT EXISTS caplog
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 3) 포트/호스트가 다를 때

```bash
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3307/caplog?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul&characterEncoding=utf8
./gradlew bootRun
```

---

## MySQL Workbench에서 스크린샷/카드 데이터 보기

앱이 쓰는 DB는 **`caplog`** 하나뿐입니다. 스크린샷 관련 데이터는 아래 두 테이블에 들어갑니다.

| 테이블 | 용도 |
|--------|------|
| **`screenshot`** | OCR/GPT로 만든 **카드** (제목, 요약, 카테고리, 장소명, 주소 등). POST /api/cards 시 INSERT됨. |
| **`screenshot_file`** | 업로드한 **이미지 파일** 메타정보 (파일명, URL 등). 스크린샷 업로드 API 호출 시 INSERT됨. |

### 1) 접속·DB 선택

- Workbench에서 Spring Boot와 **같은 계정**으로 접속 (예: `root` / `application.yml`에 맞는 비밀번호).
- 왼쪽 스키마에서 **`caplog`** 더블클릭해 기본 스키마로 선택.

### 2) 카드(OCR/GPT 결과) 확인

```sql
USE caplog;
SELECT * FROM screenshot ORDER BY screenshot_id DESC;
```

- 여기서 **한 줄도 안 나오면** → 아직 카드가 한 번도 DB에 저장된 적이 없는 상태입니다.
- 카드가 쌓이려면: iOS 앱에서 **로그인한 뒤** 스크린샷 → “스크린샷에서 카드 가져오기” 또는 새 스크린샷 촬영으로 카드를 만들고, **POST /api/cards**가 성공해야 합니다.
- 백엔드 로그에 `카드 저장 완료 (userNo=..., title=...)` 가 찍혔는지, iOS 콘솔에 `❌ 서버 저장 실패` 가 없는지 확인해 보세요.

### 3) 업로드된 스크린샷 파일 목록 확인

```sql
SELECT * FROM screenshot_file ORDER BY id DESC;
```

### 4) 테이블이 아예 안 보일 때

- **한 번은 `./gradlew bootRun`으로 앱을 실행해 두어야** JPA가 `ddl-auto: update`로 테이블을 만들거나 갱신합니다.
- 실행 후 Workbench에서 스키마 새로고침(F5) 후 `caplog` 안에 `screenshot`, `screenshot_file`, `users`, `refresh_token` 등이 보이는지 확인하세요.
