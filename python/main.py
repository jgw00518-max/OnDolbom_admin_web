"""관리자 프로젝트 루트에서 python -m uvicorn python.main:app --port 8001 로 실행."""

import os
from pathlib import Path

from dotenv import dotenv_values
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from python.features.auth.router import router
from python.features.management.router import router as management_router
from python.features.inquiries.router import router as inquiries_router
from python.features.content.router import router as notices_router, public_router as public_notices_router
from python.features.faqs.router import router as faqs_router, public_router as public_faqs_router
from python.features.inquiries.status import router as status_router, user_router as user_inquiries_router

app = FastAPI(title="온돌봄 관리자 API")
settings = {**dotenv_values(Path(__file__).resolve().parent / '.env'), **os.environ}
# Flutter 개발 웹 포트를 고정한다. 배포 시 실제 관리자 웹 origin만 설정한다.
origins = [value.strip() for value in settings.get(
    'ADMIN_WEB_ORIGINS', 'http://localhost:5173,http://127.0.0.1:5173'
).split(',') if value.strip()]
app.add_middleware(CORSMiddleware, allow_origins=origins,
                   allow_methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE'], allow_headers=['Authorization', 'Content-Type'])
app.include_router(router, prefix='/admin/auth', tags=['admin-auth'])
app.include_router(management_router, prefix='/admin/management', tags=['admin-management'])
app.include_router(inquiries_router, prefix='/admin/inquiries', tags=['admin-inquiries'])
app.include_router(notices_router, prefix='/admin/notices', tags=['admin-notices'])
app.include_router(public_notices_router, prefix='/notices', tags=['notices'])
app.include_router(faqs_router, prefix='/admin/faqs', tags=['admin-faqs'])
app.include_router(public_faqs_router, prefix='/faqs', tags=['faqs'])
app.include_router(status_router, prefix='/admin/inquiries', tags=['admin-inquiries'])
app.include_router(user_inquiries_router, prefix='/inquiries', tags=['user-inquiries'])


@app.get('/health')
def health():
    """프로세스 상태만 확인한다. 관리자 권한이나 DB 연결 검사는 아니다."""
    return {'status': 'ok'}
