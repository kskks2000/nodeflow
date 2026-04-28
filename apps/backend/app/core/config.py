from functools import lru_cache
from typing import Annotated, Any, List, Optional

from pydantic import BeforeValidator, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.core import local_secrets


def _parse_cors_origins(value: Any) -> List[str]:
    if isinstance(value, str):
        return [origin.strip() for origin in value.split(",") if origin.strip()]
    if isinstance(value, list):
        return value
    return []


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="NODEFLOW_",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "NodeFlow API"
    environment: str = "local"
    debug: bool = False
    api_v1_prefix: str = "/api/v1"

    database_url: str = (
        "postgresql+asyncpg://"
        f"{local_secrets.DB_USER}:{local_secrets.DB_PASSWORD}"
        f"@{local_secrets.DB_HOST}:{local_secrets.DB_PORT}/{local_secrets.DB_NAME}"
    )
    sql_echo: bool = False

    cors_origins: Annotated[List[str], BeforeValidator(_parse_cors_origins)] = Field(
        default_factory=lambda: local_secrets.CORS_ORIGINS
    )
    cors_origin_regex: Optional[str] = local_secrets.CORS_ORIGIN_REGEX

    jwt_secret_key: str = local_secrets.JWT_SECRET_KEY
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 30
    refresh_token_days: int = 14


@lru_cache
def get_settings() -> Settings:
    return Settings()
