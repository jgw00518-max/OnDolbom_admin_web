"""관리자 프로젝트 루트에서 python -m uvicorn python.main:app --port 8001 로 실행."""

import os
from pathlib import Path

from dotenv import dotenv_values
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from python.features.auth.router import router
from python.features.management.router import router as management_router

app = FastAPI(title="온돌봄 관리자 API")
settings = {**dotenv_values(Path(__file__).resolve().parent / '.env'), **os.environ}
# Flutter 개발 웹 포트를 고정한다. 배포 시 실제 관리자 웹 origin만 설정한다.
origins = [value.strip() for value in settings.get(
    'ADMIN_WEB_ORIGINS', 'http://localhost:5173,http://127.0.0.1:5173'
).split(',') if value.strip()]
app.add_middleware(CORSMiddleware, allow_origins=origins,
                   allow_methods=['GET'], allow_headers=['Authorization'])
app.include_router(router, prefix='/admin/auth', tags=['admin-auth'])
app.include_router(management_router, prefix='/admin/management', tags=['admin-management'])


@app.get('/health')
def health():
    """프로세스 상태만 확인한다. 관리자 권한이나 DB 연결 검사는 아니다."""
    return {'status': 'ok'}
