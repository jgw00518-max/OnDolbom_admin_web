# 관리자 로그인 실행·등록 안내

## 구현 범위

Firebase 이메일·비밀번호 로그인 → ID 토큰 전달 → 서버 검증 → MySQL admin UID 조회 → 관리자 화면.
Flutter는 model/view/vm으로, FastAPI는 기능별 router.py로 구성한다.
주요 인증·권한·DB 처리에는 한국어 주석을 작성했다.

관리자 회원가입 API는 제공하지 않는다. Firebase 인증 성공만으로 관리자 권한이 생기지 않는다.
모든 후속 관리자 API는 `python.features.auth.router.require_admin` 의존성을 사용해야 한다.
현재 관리 화면은 인증 결과 확인용이며 사용자 관리 등 운영 기능은 아직 없다.

## 사전 발급 관리자 등록

1. Firebase Console의 Authentication 사용자 목록에서 별도의 관리자 이메일·비밀번호 계정을 발급한다.
2. 발급된 Firebase 사용자 UID를 확인한다.
3. DB 운영자가 실제 `admin` 행의 `admin_firebase_uid`에 해당 UID를 연결한다.
   이메일이 같다는 이유로 자동 연결하지 않는다. 일반 가족 계정을 임의로 관리자로 승격하지 않는다.

현재 확인한 테이블은 `admin_id VARCHAR(50)` PK, `admin_firebase_uid VARCHAR(128)` UNIQUE,
`admin_password VARCHAR(255)` NULL 허용, `admin_email VARCHAR(200)` NULL 허용,
`admin_registered_at` 기본 현재 시각이다. 테이블 변경은 하지 않았다.

신규 관리자 행이 필요한 경우 DB 운영자가 검토 후 아래 예시의 값을 바꾸어 실행한다.
이 SQL은 안내용이며 구현 과정에서 실행하지 않았다.

```sql
INSERT INTO admin (admin_id, admin_firebase_uid, admin_email)
VALUES (UUID(), '발급한_관리자_FIREBASE_UID', '실제_관리자_이메일');
```

기존 관리자 행이 있으면 새 행을 추가하기보다 그 행을 정확히 식별해 UID를 연결한다.
비밀번호는 Firebase에서 관리하므로 MySQL에 복사하지 않는다.
DB의 UID UNIQUE는 현재 collation에 따라 대소문자를 무시할 수 있어 조회에 BINARY를 추가했다.

## 로컬 환경

`python/.env.example`을 참고해 로컬 `python/.env`를 준비한다.
초기 구현 시 기존 가족 프로젝트의 MySQL·서비스 계정 경로 설정만 로컬로 재사용했다.
기존 관리자 .env가 있으면 덮어쓰지 않는다. 실제 값과 서비스 계정 JSON은 Git에 올리지 않는다.
서버 키는 외부 파일을 경로로 참조하며 브라우저 코드에 포함하지 않는다.

필요한 항목:

```dotenv
MYSQL_HOST=
MYSQL_PORT=3306
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_DATABASE=
GOOGLE_APPLICATION_CREDENTIALS=서비스계정_JSON_절대경로
FIREBASE_PROJECT_ID=ondolbom-3125e
ADMIN_WEB_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
```

## 실행

반드시 `C:\My\ondolbom_admin`에서 실행한다. 가족용 서버와 겹치지 않도록 8001을 쓴다.

```powershell
python -m pip install -r python/requirements-dev.txt
python -m uvicorn python.main:app --host 127.0.0.1 --port 8001 --reload
```

별도 터미널:

```powershell
flutter run -d chrome --web-port 5173 --dart-define=ADMIN_API_BASE_URL=http://localhost:8001
```

웹 포트를 고정해야 CORS 허용 origin과 일치한다. API 주소나 프로젝트 설정을 바꾸면 앱을 재실행한다.
다른 PC나 배포 환경은 API 주소와 ADMIN_WEB_ORIGINS를 실제 주소로 변경하며 HTTPS를 사용한다.
`/health`는 프로세스 확인일 뿐 자격증명·DB·관리자 권한 검사는 아니다.

## API

`GET /admin/auth/me`에 `Authorization: Bearer <Firebase ID token>`을 전달한다.

- 200: `{"admin_id": "내부관리자ID", "admin_email": "관리자이메일"}`
- 401: 토큰 없음·만료·무효·철회·Firebase 사용자 사용 불가
- 403: 유효한 로그인이어도 admin_firebase_uid 연결 행 없음
- 503: 인증 서버·자격증명·DB 설정 또는 연결 문제

서버가 매 요청 admin 테이블을 조회한다. UID·이메일·관리자 여부를 클라이언트 입력으로 받지 않는다.
권한 거절 화면에서도 로그아웃·다시 확인이 가능하다. 관리자 화면은 서버 승인 후 표시한다.
브라우저 세션 단위 persistence를 적용한다. 로그아웃은 현재 브라우저의 Firebase 세션 종료이며
모든 기기의 토큰을 강제 철회하는 기능은 아니다. 비밀번호 재설정은 이번 구현 범위에 포함하지 않는다.

## 확인 순서

1. `/health` 200 확인.
2. 발급된 관리자 이메일·비밀번호로 로그인 → 관리자 인증 완료 표시 확인.
3. 새로고침 후에도 서버 관리자 권한 확인을 거쳐 진입하는지 확인.
4. 로그아웃 후 로그인 화면 복귀 확인.
5. 일반 가족 계정은 관리자 전용 화면에 들어가지 못하고 거절되는지 확인.
6. 잘못된 비밀번호·토큰 누락·서버 중단·권한 회수 후 재조회 동작 확인.

자동 테스트는 실제 사용자·권한·DB 데이터를 만들지 않으며 Firebase·DB·HTTP를 대체한다.
실제 관리자 발급과 기기/브라우저 로그인은 사용자가 실행한다.

```powershell
python -m unittest discover -s python/tests -p "test_*.py" -v
dart format lib test
flutter analyze
flutter test
flutter build web
```

참고: https://firebase.google.com/docs/auth/admin/verify-id-tokens
참고: https://fastapi.tiangolo.com/tutorial/cors/
