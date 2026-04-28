# NodeFlow Frontend

Flutter client for the NodeFlow TMS platform.

## Run

```powershell
flutter run -d chrome --dart-define=NODEFLOW_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

For Android emulator builds, omit the `dart-define`; the app automatically uses
`http://10.0.2.2:8000/api/v1`.

## Current Screen

The app renders a professional login screen for the
`Flutter -> FastAPI -> PostgreSQL` architecture.

The login form calls `POST /api/v1/auth/login` and matches the existing
PostgreSQL tenant login model.

Local login account:

- Company code: `TEN001`
- Login ID: `user001`
- Password: `TEST_HASH_001`
