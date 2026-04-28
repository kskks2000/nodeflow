from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.user import CurrentTenant, CurrentUser


class LoginRequest(BaseModel):
    company_code: str = Field(min_length=2, max_length=50, examples=["NF-SEOUL"])
    login_id: str = Field(min_length=1, max_length=100, examples=["admin"])
    password: str = Field(min_length=1, max_length=256, examples=["password"])

    @field_validator("company_code")
    @classmethod
    def normalize_company_code(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("login_id")
    @classmethod
    def normalize_login_id(cls, value: str) -> str:
        return value.strip()


class RegisterRequest(BaseModel):
    company_code: str = Field(min_length=2, max_length=50, examples=["KCASTLE"])
    login_id: str = Field(min_length=1, max_length=100, examples=["user001"])
    password: str = Field(min_length=6, max_length=256, examples=["password"])

    @field_validator("company_code")
    @classmethod
    def normalize_company_code(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("login_id")
    @classmethod
    def normalize_login_id(cls, value: str) -> str:
        return value.strip()


class TokenResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: CurrentUser
    tenant: CurrentTenant


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(min_length=1)


class MeResponse(BaseModel):
    user: CurrentUser
