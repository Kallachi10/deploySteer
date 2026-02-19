@echo off
REM Quick start script for SteerMate backend (Windows)

echo Starting SteerMate Backend...

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker first.
    exit /b 1
)

REM Start services
echo Starting Docker services...
docker-compose up -d

REM Wait for services to be ready
echo Waiting for services to start...
timeout /t 5 /nobreak >nul

REM Check if backend is running
curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo Backend may still be starting. Check logs with: docker-compose logs -f backend
) else (
    echo Backend is running at http://localhost:8000
    echo API docs available at http://localhost:8000/docs
)

echo.
echo To stop services, run: docker-compose down
