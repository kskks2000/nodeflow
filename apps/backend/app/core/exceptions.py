from dataclasses import dataclass


@dataclass
class DomainError(Exception):
    code: str
    message: str
    status_code: int = 400


class AuthenticationFailed(DomainError):
    def __init__(self) -> None:
        super().__init__(
            code="AUTH_INVALID_CREDENTIALS",
            message="Invalid company code, login ID, or password.",
            status_code=401,
        )


class UserAlreadyExists(DomainError):
    def __init__(self) -> None:
        super().__init__(
            code="AUTH_USER_ALREADY_EXISTS",
            message="This login ID is already registered for the company code.",
            status_code=409,
        )


class AccountLocked(DomainError):
    def __init__(self) -> None:
        super().__init__(
            code="AUTH_ACCOUNT_LOCKED",
            message="This account is locked.",
            status_code=423,
        )


class TokenInvalid(DomainError):
    def __init__(self) -> None:
        super().__init__(
            code="AUTH_TOKEN_INVALID",
            message="The authentication token is invalid.",
            status_code=401,
        )
