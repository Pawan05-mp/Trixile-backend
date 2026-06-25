import sys
import pathlib
import time
from contextlib import asynccontextmanager

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

import uvicorn
from fastapi import FastAPI, Request, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.routes import auth, places, recommendations, favorites
from app.core.config import settings
from app.core.logger import get_logger
from app.core.rate_limiter import RateLimiter

# ✅ ADD THESE IMPORTS (IMPORTANT FIX)
from app.db.session import engine
from app.db.base import Base


logger = get_logger("app")

# Mount Static Assets
assets_dir = pathlib.Path(__file__).parent.parent.parent / "assets"

# Global Rate Limiter
limiter = RateLimiter(requests_per_minute=100)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting up Place Recommendation API...")

    # ✅ CREATE TABLES ON STARTUP (FIX FOR 'users does not exist')
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield

    logger.info("Shutting down Place Recommendation API...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
    dependencies=[Depends(limiter)],
)

# Static files
if assets_dir.exists():
    app.mount("/assets", StaticFiles(directory=str(assets_dir)), name="assets")
else:
    logger.warning(f"Assets directory not found at {assets_dir}, static files will not be served.")


# ── CORS ─────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request Logging Middleware ───────────────────────────────
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    client_ip = request.client.host if request.client else "127.0.0.1"

    try:
        response = await call_next(request)
    except Exception as exc:
        duration = time.time() - start_time
        logger.exception(
            f"Client: {client_ip} | Method: {request.method} | Path: {request.url.path} | "
            f"EXCEPTION: {type(exc).__name__} | Duration: {duration:.4f}s"
        )
        raise exc

    duration = time.time() - start_time
    logger.info(
        f"Client: {client_ip} | Method: {request.method} | Path: {request.url.path} | "
        f"Status: {response.status_code} | Duration: {duration:.4f}s"
    )
    return response


# ── Global Exception Handler ───────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    client_ip = request.client.host if request.client else "127.0.0.1"
    logger.error(
        f"Unhandled exception occurred on path {request.url.path} from client {client_ip}: {exc}",
        exc_info=True
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "An unexpected internal server error occurred. Please try again later."}
    )


# ── Routers ──────────────────────────────────────────────────
app.include_router(auth.router, prefix="/auth")
app.include_router(recommendations.router, prefix="/places")
app.include_router(places.router, prefix="/places")
app.include_router(favorites.router, prefix="/favorites")


# ── Health check ─────────────────────────────────────────────
@app.get("/health")
async def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
