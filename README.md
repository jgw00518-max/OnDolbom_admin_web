# 온돌봄 관리자 웹

가족 사용자 앱과 분리된 Flutter Web + FastAPI 관리자 프로젝트입니다.
Firebase 로그인 후 서버가 MySQL admin.admin_firebase_uid를 확인한 계정만 접근합니다.
관리자 계정 자동 생성·공개 회원가입은 제공하지 않습니다.

- lib/model/auth: 관리자 응답 모델
- lib/view/auth: 로그인 화면
- lib/view/admin_gate.dart: 인증·권한에 따른 화면 전환
- lib/vm/auth: Riverpod 인증 상태·토큰·관리자 조회
- python/main.py: 별도 관리자 API, CORS와 라우터 등록
- python/database.py: .env 기반 DB 연결
- python/features/auth: 토큰 검증·관리자 권한 조회

실행·관리자 사전 발급·검증 절차는 [관리자 로그인 안내](docs/admin-login.md)를 참고하세요.
.env와 서버 서비스 계정 키는 Git에 올리지 않습니다.
