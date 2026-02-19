@echo off
REM Local production-like backend start (Windows)

echo Starting SteerMate Backend (local prod-like)...

docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker first.
    exit /b 1
)

echo Starting Docker services (prod-like overrides)...
docker-compose -f docker-compose.yml -f docker-compose.local-prod.yml up -d --build postgres backend_prod

echo Waiting for services to start...
timeout /t 5 /nobreak >nul

curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo Backend may still be starting. Check logs with: docker-compose logs -f backend_prod
) else (
    echo Backend is running at http://localhost:8000
    echo API docs available at http://localhost:8000/docs
)

echo.
echo To stop services, run: docker-compose down
