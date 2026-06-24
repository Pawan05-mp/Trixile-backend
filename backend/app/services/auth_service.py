"""Authentication service — user registration, login, token generation."""

from __future__ import annotations

import secrets
from uuid import UUID

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import create_access_token, hash_password, verify_password
from app.models.user import User


class AuthService:
    """Stateless helper methods for auth workflows."""

    @staticmethod
    async def register(db: AsyncSession, *, email: str, password: str, name: str) -> User:
        user = User(
            email=email,
            password_hash=hash_password(password),
            name=name,
        )
        db.add(user)
        await db.flush()
        await db.refresh(user)
        return user

    @staticmethod
    async def authenticate_user(db: AsyncSession, email: str, password: str) -> str | None:
        """Return a JWT access token if credentials are valid, else None."""
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if user is None or not verify_password(password, user.password_hash):
            return None
        return create_access_token(data={"sub": str(user.id)})

    @staticmethod
    async def authenticate_social(db: AsyncSession, supabase_access_token: str) -> tuple[str, bool] | None:
        """Verify a Supabase session token (issued client-side after a
        Google/Facebook OAuth login via supabase_flutter), then find or
        create a matching local User and issue our own JWT for it.

        Returns (access_token, is_new_user) or None if the Supabase token
        couldn't be verified.
        """
        if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
            # Social login isn't configured on this deployment yet.
            return None

        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(
                    f"{settings.SUPABASE_URL}/auth/v1/user",
                    headers={
                        "Authorization": f"Bearer {supabase_access_token}",
                        "apikey": settings.SUPABASE_ANON_KEY,
                    },
                )
            except httpx.HTTPError:
                return None

        if response.status_code != 200:
            return None

        payload = response.json()
        email = payload.get("email")
        if not email:
            return None

        metadata = payload.get("user_metadata") or {}
        name = (
            metadata.get("full_name")
            or metadata.get("name")
            or email.split("@")[0]
        )

        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        is_new_user = False

        if user is None:
            # Social-only accounts get a random, never-shared password
            # hash so the column stays NOT NULL; they simply never log
            # in with a password unless they later set one.
            user = User(
                email=email,
                password_hash=hash_password(secrets.token_urlsafe(32)),
                name=name,
            )
            db.add(user)
            await db.flush()
            await db.refresh(user)
            is_new_user = True

        token = create_access_token(data={"sub": str(user.id)})
        return token, is_new_user

    @staticmethod
    async def get_user_by_id(db: AsyncSession, user_id: UUID) -> User | None:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()
