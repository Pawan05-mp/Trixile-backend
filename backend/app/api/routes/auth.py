"""Authentication routes — register and login."""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.auth import SocialLoginRequest, TokenResponse, UserCreate, UserRead
from app.services.auth_service import AuthService

router = APIRouter(tags=["auth"])


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
async def register(body: UserCreate, db: AsyncSession = Depends(get_db)):
    user = await AuthService.register(db, email=body.email, password=body.password, name=body.name)
    return user


@router.post("/login", response_model=TokenResponse)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    token = await AuthService.authenticate_user(db, form_data.username, form_data.password)
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return {"access_token": token, "token_type": "bearer"}


@router.post("/social", response_model=TokenResponse)
async def social_login(body: SocialLoginRequest, db: AsyncSession = Depends(get_db)):
    """Exchange a Supabase OAuth session (Google/Facebook, obtained
    client-side) for our own backend JWT, creating the local user record
    on first sign-in.
    """
    result = await AuthService.authenticate_social(db, body.access_token)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not verify social login session.",
        )
    token, is_new_user = result
    return {"access_token": token, "token_type": "bearer", "is_new_user": is_new_user}
