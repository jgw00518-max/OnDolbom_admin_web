# 온돌봄 관리자 웹 OnDolbom Admin

**가족 돌봄 서비스 온돌봄의 사용자·가족 공간·문의·공지사항을 관리하는 웹 애플리케이션**

온돌봄 관리자 웹은 서비스 운영자가 사용자와 가족 공간 현황을 확인하고, 문의에 답변하며 공지사항을 관리하는 운영 도구입니다.

Flutter Web과 FastAPI로 구성하며, 가족 사용자 앱과 분리된 프로젝트로 관리합니다.

- [가족 사용자 앱 저장소](https://github.com/jgw00518-max/OnDolbom)
- [관리자 웹 저장소](https://github.com/jgw00518-max/OnDolbom_admin_web)

## 주요 기능

| 기능 | 주요 내용 |
|---|---|
| 관리자 로그인 | Firebase 이메일·비밀번호 로그인 및 서버 관리자 권한 확인 |
| 사용자 현황 | 가입 사용자 목록 및 관련 정보 조회 |
| 가족 공간 현황 | 가족 공간 목록 및 상세 정보 조회 |
| 문의 관리 | 문의 내역 조회, 기존 답변 확인 및 관리자 답변 등록 |
| 공지사항 관리 | 공지 목록·상세 조회, 작성·수정·논리 삭제 |

### 적용 대기 기능

| 기능 | 현재 상태 |
|---|---|
| FAQ 관리 | 관련 코드 준비, 공유 DB 적용 대기 |
| 문의 처리 상태 | 관련 코드 준비, 공유 DB 적용 대기 |

위 기능은 DB 적용 전까지 화면에 적용 대기 상태를 표시합니다.

## 관리자 인증

관리자 로그인은 다음 순서로 처리합니다.

```text
Firebase 이메일·비밀번호 로그인
                ↓
Firebase ID Token 발급
                ↓
관리자 API에서 토큰 검증
                ↓
MySQL admin 테이블의 Firebase UID 확인
                ↓
관리자 화면 접근
```

Firebase 로그인 성공 후에도 서버에서 관리자 등록 여부를 확인합니다.

관리자 계정은 사전에 발급하고, Firebase UID를 MySQL 관리자 정보에 연결해야 합니다. 공개 관리자 회원가입과 관리자 계정 자동 생성은 제공하지 않습니다.

자세한 등록 절차는 [관리자 로그인 안내](docs/admin-login.md)를 참고합니다.

## 기술 스택

| 구분 | 사용 기술 |
|---|---|
| 프런트엔드 | Flutter Web, Dart |
| 상태 관리 | Riverpod |
| 백엔드 | Python, FastAPI, Uvicorn |
| 데이터베이스 | MySQL, PyMySQL |
| 인증 | Firebase Authentication, Firebase Admin SDK |
| 통신 | HTTP REST API |
| 협업 | Git, GitHub |

## 시스템 구조

```text
Flutter Web
  ├─ View: 로그인 및 관리 화면
  ├─ ViewModel: 인증 상태·업무 처리·API 호출
  ├─ Model: 응답 데이터 및 JSON 변환
  └─ Riverpod: 상태 및 의존성 관리
          │
          │ HTTP REST API / Firebase ID Token
          ▼
FastAPI 관리자 API
  ├─ 인증 토큰 검증
  ├─ 관리자 권한 확인
  ├─ 사용자·가족 공간 조회
  ├─ 문의 조회 및 답변 등록
  └─ 공지사항 관리
          │
          ▼
        MySQL
```

사용자 앱과 관리자 웹은 별도의 API를 사용하며, 관리자 API에서 권한을 확인한 후 데이터를 조회하거나 변경합니다.

## 주요 구현 사항

| 구현 항목 | 적용 내용 |
|---|---|
| 관리자 접근 제어 | Firebase 토큰 검증 후 DB에 등록된 관리자 UID 확인 |
| Riverpod 상태 관리 | 로그인 상태, 관리자 정보 및 관리 화면 데이터 관리 |
| 인증 상태별 화면 전환 | 로그인·권한 확인 결과에 따라 접근 화면 결정 |
| 기능별 API 분리 | 인증, 현황 조회, 문의, 공지 기능을 개별 라우터로 구성 |
| 문의 답변 처리 | 서버에서 답변 작성자를 결정하고 기존 답변 테이블에 저장 |
| 중복 요청 방지 UI | 답변 저장 중 버튼 비활성화 |
| 공지 논리 삭제 | 삭제 상태를 기록하는 방식으로 공지 관리 |

## 프로젝트 구조

```text
lib/
├── main.dart
├── model/                  # 데이터 모델
├── view/
│   ├── auth/               # 관리자 로그인
│   ├── management/         # 관리 화면
│   └── admin_gate.dart     # 인증·권한별 화면 전환
└── vm/                     # Riverpod 상태 관리 및 API 호출

python/
├── main.py                 # FastAPI 앱, CORS 및 라우터 등록
├── database.py             # MySQL 연결
└── features/
    ├── auth/               # 인증 및 관리자 권한 확인
    ├── management/         # 사용자·가족 공간 현황
    ├── inquiries/          # 문의 및 답변
    ├── content/            # 공지사항
    └── faqs/               # FAQ 관련 코드

docs/                       # 설정 및 기능 연동 안내
test/                       # Flutter 테스트
web/                        # 웹 실행 리소스
```

## 실행 방법

### 1. 환경 설정

`python/.env.example`을 참고하여 `python/.env`를 작성합니다.

설정 항목은 다음과 같습니다.

```dotenv
MYSQL_HOST=
MYSQL_PORT=3306
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_DATABASE=

GOOGLE_APPLICATION_CREDENTIALS=
FIREBASE_PROJECT_ID=

ADMIN_WEB_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
```

Firebase 서비스 계정 파일 경로와 사전 등록된 관리자 계정이 필요합니다. `.env`와 서비스 계정 키는 Git에 포함하지 않습니다.

### 2. 의존성 설치

프로젝트 루트에서 실행합니다.

```bash
python -m pip install -r python/requirements-dev.txt
flutter pub get
```

### 3. 관리자 API 실행

```bash
python -m uvicorn python.main:app --host 127.0.0.1 --port 8001 --reload
```

### 4. 관리자 웹 실행

별도 터미널에서 실행합니다.

```bash
flutter run -d chrome --web-port 5173 --dart-define=ADMIN_API_BASE_URL=http://localhost:8001
```

| 구분 | 로컬 주소 |
|---|---|
| 관리자 웹 | `http://localhost:5173` |
| 관리자 API | `http://localhost:8001` |
| API 문서 | `http://localhost:8001/docs` |

웹 실행 주소와 `ADMIN_WEB_ORIGINS`가 일치해야 합니다.

자세한 실행 및 오류 해결 방법은 [관리자 로그인 안내](docs/admin-login.md)를 참고합니다.

## 관련 문서

- [관리자 로그인·계정 등록·실행 안내](docs/admin-login.md)
- [공지·FAQ·문의 처리 연동 안내](docs/content-inquiry-integration.md)
- [온돌봄 사용자 앱](https://github.com/jgw00518-max/OnDolbom)

## 발전 방향

- **FAQ 및 문의 처리 상태 적용**  
  DB 연동을 완료하고 문의 처리 과정을 체계적으로 관리합니다.

- **운영 통계 대시보드**  
  사용자 수, 가족 공간 수, 문의 현황 등을 한눈에 확인할 수 있도록 확장합니다.

- **요양보호사·요양센터 인증 관리**  
  서비스 확장에 맞춰 자격 및 기관 정보의 검토·승인 기능을 도입합니다.

- **관리자 활동 이력**  
  주요 운영 작업의 수행자와 변경 내역을 확인할 수 있도록 개선합니다.
