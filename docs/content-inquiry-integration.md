# 사용자 앱 담당자 전달용: 공지·FAQ·문의 상태 연동

## 현재 적용 범위

관리자 프로젝트 `C:/My/ondolbom_admin`만 수정했다. 사용자 프로젝트 `C:/My/ondolbom`은 수정하지 않았다.
DB의 공지·문의·답변 구조와 기존 API를 유지한다. 기존 문의 답변 API도 그대로다.
FAQ 테이블과 문의 상태 컬럼의 공유 DB 적용은 사용자가 보류했다.
SQL만 `python/migrations/001_faq.sql`, `002_inquiry_status.sql`, `rollback.sql`에 준비했다.
상태 이름·규칙은 확정됐지만 신규 DB 구조를 쓰는 기능은 아직 운영 활성화 전이다.

## 서버와 인증

- 사용자 서버: 기본 8000. 기존 `/inquiries` 작성·목록·상세 및 답변 조회는 그대로 동작한다.
- 관리자 서버: 기본 8001. 이 문서의 신규 API는 모두 이 서버에 구현돼 있다.
- 모든 관리 API는 Firebase ID 토큰 검증 후 `admin.admin_firebase_uid`를 매 요청 검사한다.
- 신규 사용자 조회 API는 동일 Firebase 프로젝트의 ID 토큰을 Bearer로 전달한다.
  공지·FAQ는 로그인 사용자 전체에게 삭제되지 않은 게시글만 공개한다.
  문의는 UID로 `user`를 조회해 탈퇴하지 않은 본인 문의만 반환한다.
- 토큰·관리자 ID·사용자 ID를 본문에 임의로 넣어 권한을 바꿀 수 없다.
- 사용자 앱을 바로 변경하지 않았다. 연결 시 신규 조회만 관리자 서버 8001에 보내거나,
  사용자 서버에 기능별 조회 라우터를 이식해야 한다. 기존 8000 `/inquiries`를 신규 라우터로
  통째로 대체하면 기존 작성 API와 커서 계약이 사라지므로 그렇게 하지 않는다.

## 공지사항 (현재 DB로 사용 가능)

| 용도 | 메서드·경로 |
| --- | --- |
| 관리자 목록·작성 | GET /admin/notices, POST /admin/notices |
| 관리자 상세·수정·삭제 | GET, PUT, DELETE /admin/notices/{admin_id}/{notice_id} |
| 사용자 목록 | GET /notices |
| 사용자 상세 | GET /notices/{admin_id}/{notice_id} |

작성·수정 본문: `{"notice_title":"제목","notice_content":"본문"}`.
제목·본문은 공백 제거 후 필수, 제목 100자 이내, 본문 utf8 65535바이트 이내다.
기존 utf8mb3에 저장 불가능한 문자를 거절한다. 제목/본문 NULL인 기존 행은 조회 시 그대로 반환한다.
신규 notice_id는 서버 UUID이며 admin_id는 로그인 관리자 ID다.
기존 PK가 `(admin_id, notice_id)`이므로 상세·수정·삭제에는 두 값을 모두 사용한다.
수정·삭제는 기존 공통 관리자 권한을 사용한다. 작성자만 수정 가능한 별도 정책은 추가하지 않았다.
삭제는 DELETE SQL이 아닌 `notice_deleted_at` 갱신이며 사용자·관리자 조회 모두에서 제외한다.
수정 시 `notice_updated_at`을 기록하고 원 작성자 admin_id는 바꾸지 않는다.

목록 쿼리: `limit` 기본 30(1~100), `offset` 기본 0.
응답: `{"items":[...],"has_more":false}`.
행/상세 필드: `admin_id`, `notice_id`, `notice_title`, `notice_content`,
`notice_created_at`, `notice_updated_at`(미수정 시 null).
날짜는 기존 DB 서버의 DATETIME을 ISO 문자열로 직렬화하며 timezone offset은 없다.
정렬: 생성일 내림차순, admin_id, notice_id 순.
생성 201·수정/삭제 200 응답은 `{"admin_id":"...","notice_id":"..."}`다.
기존 `GET /admin/management/notices`도 유지하며 복합 키를 위해 admin_id를 추가했다.

## FAQ (코드 준비 / DB 적용 보류)

| 용도 | 메서드·경로 |
| --- | --- |
| 관리자 목록·작성 | GET /admin/faqs, POST /admin/faqs |
| 관리자 상세·수정·삭제 | GET, PUT, DELETE /admin/faqs/{admin_id}/{faq_id} |
| 사용자 목록·상세 | GET /faqs, GET /faqs/{admin_id}/{faq_id} |

본문: `{"faq_question":"질문","faq_answer":"답변"}`.
질문·답변 모두 필수이며 공지와 같은 길이·문자 검증을 적용한다.
응답은 공지 계약에서 notice_id/title/content/timestamps 대신
`faq_id`, `faq_question`, `faq_answer`, `faq_created_at`, `faq_updated_at`을 사용한다.
생성·수정·삭제 응답은 `{"admin_id":"...","faq_id":"..."}`다.
faq_id는 단일 UUID PK이며 상세 URL에는 원 작성 관리자 ID도 함께 사용한다.
사용자는 조회만 가능하다. 사용자 경로에 쓰기 메서드는 제공하지 않는다.
카테고리·임의 정렬·공개 여부는 추가하지 않았다. 생성일 내림차순으로 제공하며
삭제되지 않은 FAQ를 로그인 사용자에게 공개한다. 새 FAQ는 작성 즉시 공개된다.
공유 DB 미적용 시 503과 `detail`의 ‘FAQ DB 적용 대기’ 안내를 반환하고 쓰기하지 않는다.
적용한 뒤 화면 목록을 새로고침하면 작성 버튼을 사용할 수 있다.

## 문의 처리 상태 (정책 확정 / DB 적용 보류)

| 코드 | 표시명 |
| --- | --- |
| RECEIVED | 접수 |
| IN_REVIEW | 확인 중 |
| NEEDS_INFO | 추가 확인 필요 |
| RESOLVED | 처리 완료 |

모든 상태 간 수동 변경과 재접수를 허용한다. 같은 상태 요청은 최종 변경 시각을 갱신하지 않는다.
답변이 없어도 관리자가 처리 완료를 선택할 수 있고, 답변이 있어도 접수 상태일 수 있다.
답변 등록 시 자동 전환하지 않는다. 추가 확인 필요는 상태 의미만 가지며
자료 업로드·사용자 추가 답변·별도 알림이 구현된 것은 아니다.
모든 기존 문의 및 기존 사용자 작성 API가 이후 생성하는 문의는 DB DEFAULT로 접수가 된다.

- 관리자 목록: 기존 GET /admin/management/questions의 각 행에
  `processing_status`, `processing_status_label`, `status_updated_at`, `status_supported` 추가.
  `answer_count`는 유지한다. 화면에서 답변 대기/완료와 처리 상태를 별도 표시한다.
- 관리자 상세: GET /admin/inquiries/{question_seq}.
- 관리자 변경: PATCH /admin/inquiries/{question_seq}/status.
  본문 예: `{"processing_status":"IN_REVIEW","expected_status":"RECEIVED"}`.
  expected_status는 마지막 조회 상태이며 불일치하면 409(재조회 필요).
  변경 관리자 ID는 서버에서 기록한다. 삭제된 문의는 404.
  성공 200: `{"processing_status":"IN_REVIEW","processing_status_label":"확인 중"}`.
- 사용자 목록(8001): GET /inquiries?limit=30&offset=0.
  응답 `{"items":[...],"has_more":false,"status_supported":true}`.
- 사용자 상세(8001): GET /inquiries/{question_seq}.
  다른 사용자 문의·삭제된 문의는 구분 없이 404.
  목록/상세 필드: question_seq, question_title, question_content, family_room_id,
  questioned_at, answered(boolean), processing_status, processing_status_label,
  status_updated_at, status_supported. 상세에는 answers 배열이 추가된다.
  answers는 answer_seq, answer_content, answered_at을 포함한다.
- 스키마 미적용 시 상태 필드는 null, status_supported=false이며 문의·답변 조회는 유지한다.
  상태 변경은 503으로 차단한다. null을 ‘접수’로 확정해 표시하지 않는다.
- 사용자 서버 8000의 기존 `answered`, `answers`, `next_cursor` 계약은 변경하지 않았다.
  추후 이식 시 SUMMARY와 상세 SELECT에 상태 필드만 추가하고
  본인 문의 검사 및 커서 페이지네이션은 유지해야 한다.

## 공통 오류·저장 주의

401 인증 필요/만료, 403 권한 없음, 404 삭제/미존재, 409 상태 동시 변경,
422 필수값/형식/길이/문자 오류, 503 DB 오류 또는 스키마 적용 대기.
저장 요청은 자동 재시도하지 않는다. 응답이 유실되면 목록·상세를 재조회해 실제 결과부터 확인한다.
수정은 마지막 저장이 반영되는 방식이고 문의 상태 변경에는 expected_status 충돌 검사가 있다.
전체 상태 변경 이력·공지 편집 이력·작성 요청 멱등키는 추가하지 않았다.

## 실제 검증 절차

1. 관리자 8001과 사용자 8000을 각각 실행하고 기존 로그인·문의·답변 동작을 확인한다.
2. 별도 테스트 환경에서 공지 작성 → 목록/상세 → 수정 → 사용자 토큰으로 GET → 삭제 → 양쪽 조회 404 확인.
   공백 제목·본문, 일부 이모지, 일반 사용자 관리 API 접근은 각각 422/403 확인.
3. 현 공유 DB에서는 FAQ 목록이 적용 대기 안내이고 상태 변경이 503인지 확인한다.
   기존 문의 목록·답변이 정상 동작하는지 확인한다.
4. 운영자 승인·백업 후 테스트 DB에 SQL 적용 → FAQ CRUD와 삭제 후 사용자 조회 제외를 확인한다.
5. 문의의 answered와 네 상태가 독립적인지, 답변 등록 후 상태 유지,
   모든 상태 간 변경, 409 충돌, 삭제 문의 404, 타인 문의 404를 확인한다.
6. 이 작업에서는 운영 DB의 데이터 생성·수정·삭제와 DDL을 실행하지 않는다.

## 변경 파일과 검증

- 공지: python/features/content/router.py, lib/vm/management/content_vm.dart,
  lib/view/management/content_manager.dart 및 기존 대시보드 연결.
- FAQ: python/features/faqs/router.py, python/features/schema_support.py,
  같은 ContentManager와 migrations/001_faq.sql.
- 상태: python/features/inquiries/status.py, 기존 management/router.py,
  lib/view/management/inquiry_status.dart 및 migrations/002_inquiry_status.sql.
- 라우터 등록·CORS: python/main.py. PUT/PATCH/DELETE와 Content-Type을 허용한다.
- 테스트: python/tests/test_notices.py, test_faqs.py, test_status.py 및 Flutter 관련 테스트.
- 적용/복구: docs/schema-change-plan.md. Git commit/push는 수행하지 않는다.
