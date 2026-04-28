from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

import bcrypt
import jwt

from app.core.config import get_settings
from app.core.exceptions import TokenInvalid


def verify_password(plain_password: str, password_hash: Optional[str]) -> bool:
    if not password_hash:
        return False

    password_bytes = plain_password.encode("utf-8")
    hash_bytes = password_hash.encode("utf-8")

    try:
        return bcrypt.checkpw(password_bytes, hash_bytes)
    except ValueError:
        if password_hash.startswith("$2a$"):
            normalized = "$2b$" + password_hash[4:]
            try:
                return bcrypt.checkpw(password_bytes, normalized.encode("utf-8"))
            except ValueError:
                return False
        return False


def hash_password(plain_password: str) -> str:
    password_bytes = plain_password.encode("utf-8")
    return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")


def create_token(
    *,
    subject: str,
    token_type: str,
    expires_delta: timedelta,
    claims: Optional[Dict[str, Any]] = None,
) -> str:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    payload: Dict[str, Any] = {
        "sub": subject,
        "typ": token_type,
        "iat": int(now.timestamp()),
        "exp": int((now + expires_delta).timestamp()),
    }
    if claims:
        payload.update(claims)
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> Dict[str, Any]:
    settings = get_settings()
    try:
        return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError as exc:
        raise TokenInvalid() from exc
