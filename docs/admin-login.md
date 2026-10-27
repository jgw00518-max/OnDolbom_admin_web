# 관리자 로그인 실행·등록 안내

## 구현 범위

Firebase 이메일·비밀번호 로그인 → ID 토큰 전달 → 서버 검증 → MySQL admin UID 조회 → 관리자 화면.
Flutter는 model/view/vm으로, FastAPI는 기능별 router.py로 구성한다.
주요 인증·권한·DB 처리에는 한국어 주석을 작성했다.

관리자 회원가입 API는 제공하지 않는다. Firebase 인증 성공만으로 관리자 권한이 생기지 않는다.
모든 후속 관리자 API는 `python.features.auth.router.require_admin` 의존성을 사용해야 한다.
현재 관리 화면은 사용자 관리, 가족 공간 관리, 문의 내역, 공지사항 조회를 제공한다.
문의 항목을 펼치면 기존 답변 조회와 관리자 답변 등록이 가능하다.
답변 등록은 기존 `answer` 테이블에 저장하며 DB 구조는 변경하지 않는다.
공지사항은 목록·상세·작성·수정·논리 삭제를 제공한다.
FAQ 관리와 문의 처리 상태 코드는 준비했지만 공유 DB 적용이 보류되어 적용 대기를 표시한다.
상세 API·정책·사용자 앱 전달 내용은 [연동 안내](content-inquiry-integration.md)를 참고한다.

답변 작성자 관리자 ID와 문의 작성자 ID는 서버에서 결정한다. 삭제된 문의에는 답변할 수 없다.
현재 `answer`의 utf8mb3 문자셋에서 저장할 수 없는 일부 이모지·문자는 등록 전에 차단한다.
답변 저장 중 버튼은 비활성화되며 저장 요청은 자동 재시도하지 않는다.
통신 오류로 저장 결과가 불명확하면 답변 목록을 새로고침해 확인한 뒤 다시 등록한다.
답변 수정·삭제, 사용자에게 보내는 별도 알림은 이번 기능에 포함하지 않는다.

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

명령은 각자 프로젝트를 내려받은 루트 폴더(`pubspec.yaml`이 있는 폴더)에서 실행한다.
가족용 서버와 겹치지 않도록 관리자 API는 8001을 쓴다.

```powershell
python -m pip install -r python/requirements-dev.txt
flutter pub get
python -m uvicorn python.main:app --host 127.0.0.1 --port 8001 --reload
```

별도 터미널:

```powershell
flutter run -d chrome --web-port 5173 --dart-define=ADMIN_API_BASE_URL=http://localhost:8001
```

웹 포트를 고정해야 CORS 허용 origin과 일치한다. API 주소나 프로젝트 설정을 바꾸면 앱을 재실행한다.
팀원이 자신의 PC에서 웹과 API를 함께 실행할 때도 같은 localhost 주소를 사용한다.
공용 서버에 연결하거나 배포할 때는 API 주소와 ADMIN_WEB_ORIGINS를 실제 주소로 변경하며 HTTPS를 사용한다.
`/health`는 프로세스 확인일 뿐 자격증명·DB·관리자 권한 검사는 아니다.

## 팀원 pull 후 VS Code 실행 안내

1. 프로젝트 루트 폴더를 VS Code로 열고 Flutter·Dart 확장을 준비한다.
2. 위 로컬 환경 안내에 따라 자신의 `python/.env`와 Firebase 서비스 계정 파일 경로를 설정한다.
   다른 사람 PC의 절대경로를 그대로 사용하지 않는다. 비밀키와 `.env`는 Git에 올리지 않는다.
3. 위 의존성 설치 명령을 실행하고 Python 서버를 켠다.
4. 실행 장치를 Chrome으로 선택하고 `lib/main.dart`의 실행 버튼을 누른다.
   또는 실행 및 디버그에서 `온돌봄 관리자 웹`을 선택하고 F5로 실행한다.
5. 브라우저 주소가 `http://localhost:5173`인지 확인하고 사전에 등록된 관리자 계정으로 로그인한다.

`.vscode/settings.json`은 Flutter 실행 시 웹 포트 5173과 API 주소 `http://localhost:8001`을 지정한다.
`.vscode/launch.json`은 Chrome에서 `lib/main.dart`를 실행하는 구성을 제공한다.
두 파일을 함께 커밋·push해야 팀원이 pull한 뒤 동일한 설정을 사용할 수 있다.
VS Code 외의 IDE 또는 터미널에서는 위 `flutter run` 명령을 사용하거나 동일한 실행 인자를 설정한다.

고정 포트는 각자 PC에서 사용하므로 팀원끼리 충돌하지 않는다.
`localhost`는 실행하는 사람 자신의 컴퓨터를 가리키므로 각자 Python 서버도 실행해야 한다.
관리자 로그인에는 Firebase 인증뿐 아니라 DB의 관리자 UID 등록도 필요하다.

### 실행 오류 확인

- 실행 직후 종료되거나 포트 사용 중 오류가 나면 같은 PC에서 5173을 사용하는 기존 실행을 확인한다.
  터미널 실행과 IDE 실행을 동시에 켜지 말고, 기존 실행을 해당 터미널의 Ctrl+C 또는 IDE 중지 버튼으로 종료한다.
- `OPTIONS /admin/auth/me 400`이 나오면 브라우저 주소와 `ADMIN_WEB_ORIGINS`가 일치하는지 확인한다.
  origin에는 프로토콜·호스트·포트가 포함되며 `localhost`와 `127.0.0.1`은 서로 다른 origin이다.
- 웹 포트를 바꾸려면 `.vscode/settings.json`(터미널은 `--web-port`)과
  `python/.env`의 `ADMIN_WEB_ORIGINS`를 함께 변경한다. 변경 후 Flutter와 Python 서버를 재시작한다.
- API 포트를 바꾸려면 uvicorn의 `--port`와 Flutter의 `ADMIN_API_BASE_URL`을 함께 변경한다.
- 실행 인자 변경은 Hot Reload로 적용되지 않으므로 Flutter를 완전히 중지한 뒤 다시 실행한다.

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
2. 발급된 관리자 이메일·비밀번호로 로그인 → 관리자 대시보드 진입 확인.
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
