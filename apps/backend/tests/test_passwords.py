from app.core.security import verify_password


def test_verify_password_rejects_missing_hash() -> None:
    assert verify_password("secret", None) is False

