from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── General ──────────────────────────────────────────────
    PROJECT_NAME: str = "Place Recommendation API"
    VERSION: str = "0.1.0"

    # ── Database ─────────────────────────────────────────────
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "Trixile_2026"
    POSTGRES_DB: str = "postgres"
    POSTGRES_HOST: str = "db.ypicbilajipxjgkqxuht.supabase.co"
    POSTGRES_PORT: str = "5432"

    @field_validator("POSTGRES_HOST", mode="before")
    @classmethod
    def _default_host(cls, v: str) -> str:
        return v or "db"

    @property
    def DATABASE_URL(self) -> str:
        """Async database URL for SQLAlchemy + asyncpg."""
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def SYNC_DATABASE_URL(self) -> str:
        """Sync database URL for Alembic migrations."""
        return (
            f"postgresql+psycopg2://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    # ── Security ─────────────────────────────────────────────
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 day

    # ── Supabase (used only to verify Google/Facebook OAuth
    #    sessions created client-side by supabase_flutter — see
    #    AuthService.authenticate_social) ─────────────────────
    SUPABASE_URL: str = "https://ypicbilajipxjgkqxuht.supabase.co"
    SUPABASE_ANON_KEY: str = "sb_publishable_CUj1PhLXnuGiGg-f_nrpKg_RENDSuRQ"


settings = Settings()
