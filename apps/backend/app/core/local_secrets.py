DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "tms"
DB_USER = "postgres"
DB_PASSWORD = "Spring.2024$"

JWT_SECRET_KEY = "nodeflow-local-dev-secret-change-before-production"

CORS_ORIGINS = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
]

CORS_ORIGIN_REGEX = (
    r"^https?://("
    r"localhost|"
    r"127\.0\.0\.1|"
    r"10\.0\.2\.2|"
    r"192\.168\.\d+\.\d+|"
    r"10\.\d+\.\d+\.\d+|"
    r"172\.(1[6-9]|2\d|3[0-1])\.\d+\.\d+"
    r")(:\d+)?$"
)
