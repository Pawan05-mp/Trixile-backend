from uuid import UUID
from pydantic import BaseModel, EmailStr


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    # True when this call just created the account (used by the mobile
    # app to route first-time social sign-ins through onboarding instead
    # of straight to the home screen).
    is_new_user: bool = False


class SocialLoginRequest(BaseModel):
    # The Supabase session access_token obtained client-side after
    # supabase_flutter completes the Google/Facebook OAuth handshake.
    access_token: str


class UserCreate(BaseModel):
    email: str
    password: str
    name: str


class UserRead(BaseModel):
    id: UUID
    email: str
    name: str

    model_config = {"from_attributes": True}

