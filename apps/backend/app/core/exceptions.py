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


class PermissionDenied(DomainError):
    def __init__(self) -> None:
        super().__init__(
            code="AUTH_PERMISSION_DENIED",
            message="You do not have permission to perform this action.",
            status_code=403,
        )


class ResourceNotFound(DomainError):
    def __init__(self, resource_name: str = "Resource") -> None:
        super().__init__(
            code="RESOURCE_NOT_FOUND",
            message=f"{resource_name} was not found.",
            status_code=404,
        )


class ResourceConflict(DomainError):
    def __init__(self, message: str = "The resource conflicts with existing data.") -> None:
        super().__init__(
            code="RESOURCE_CONFLICT",
            message=message,
            status_code=409,
        )


class ValidationFailed(DomainError):
    def __init__(self, message: str = "The request is invalid.") -> None:
        super().__init__(
            code="VALIDATION_FAILED",
            message=message,
            status_code=422,
        )
