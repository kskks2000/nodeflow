# NodeFlow

NodeFlow is a TMS application planned as:

`Flutter -> FastAPI -> PostgreSQL`

## Apps

- `apps/frontend`: Flutter client
- `apps/backend`: FastAPI API server

## Frontend

```powershell
cd apps/frontend
flutter run -d chrome --dart-define=NODEFLOW_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

For Android emulator builds, omit the `dart-define`; the app automatically uses
`http://10.0.2.2:8000/api/v1`.

The first screen is the NodeFlow TMS login experience using:

- Primary color: `#1E3A8A`
- Secondary color: `#10B981`
- Login model: company code, login ID, password

## Backend

```powershell
cd apps/backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
Copy-Item .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Local development secrets are in `apps/backend/app/core/local_secrets.py`.

Backend architecture:

`Router -> Service -> Repository -> SQLAlchemy -> PostgreSQL`

Runtime target:

- Python `3.9+`
- PostgreSQL `11+`

Core endpoints:

- `GET /api/v1/health`
- `GET /api/v1/health/db`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`

Local login account:

- Company code: `TEN001`
- Login ID: `user001`
- Password: `TEST_HASH_001`
