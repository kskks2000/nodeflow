# NodeFlow Backend

FastAPI backend for NodeFlow TMS.

Architecture:

`Router -> Service -> Repository -> SQLAlchemy -> PostgreSQL`

Runtime target:

- Python `3.9+`
- PostgreSQL `11+`

## Setup

```powershell
cd apps/backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
Copy-Item .env.example .env
```

Local development secrets are currently hardcoded in
`app/core/local_secrets.py` as requested.

## Run

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open:

- API docs: `http://127.0.0.1:8000/docs`
- Health: `http://127.0.0.1:8000/api/v1/health`
- DB health: `http://127.0.0.1:8000/api/v1/health/db`
- Swagger: `http://127.0.0.1:8000/docs`

## Login Contract

`POST /api/v1/auth/login`

```json
{
  "company_code": "TEN001",
  "login_id": "user001",
  "password": "TEST_HASH_001"
}
```

The service authenticates against:

- `core.tenants.tenant_code`
- `core.users.tenant_id`
- `core.users.login_id`
- `core.users.password_hash`

Additional auth endpoints:

- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`
