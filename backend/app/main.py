from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import auth, trips, reports, users
from app.core.config import settings
from app.core.database import Base, engine


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title="SteerMate API",
    description="Advanced Driver Assistance System Backend",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(trips.router, prefix="/api/v1/trips", tags=["Trips"])
app.include_router(reports.router, prefix="/api/v1/reports", tags=["Reports"])
app.include_router(users.router, prefix="/api/v1/users", tags=["Users"])


@app.get("/")
async def root():
    return {"message": "SteerMate API", "version": "1.0.0"}


@app.get("/health")
async def health():
    return {"status": "healthy"}
