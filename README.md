# 🚘 SteerMate - Advanced Driver Assistance System

SteerMate is a smartphone-only ADAS that detects unsafe driving behaviors using on-device ML and sensor fusion.

## 🏗️ Project Structure

```
Project/
├── mobile/              # Flutter app
├── backend/            # FastAPI backend
├── docker-compose.yml  # Docker setup for backend + PostgreSQL
├── .env.example        # Environment variables template
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Flutter SDK (3.0+)
- Python 3.10+
- PostgreSQL 14+ (or use Docker)

### Backend Setup (Docker - Recommended)

**Quick Start:**
- **Windows:** Run `start_backend.bat`
- **Linux/Mac:** Run `chmod +x start_backend.sh && ./start_backend.sh`

**Or manually:**
```bash
docker-compose up -d
```

Backend will be available at: `http://localhost:8000`
- API docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`

**Note:** Database migrations run automatically on startup.

### Backend Setup (Manual)

1. **Install dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Set environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Run migrations:**
   ```bash
   alembic upgrade head
   ```

4. **Start server:**
   ```bash
   uvicorn main:app --reload
   ```

### Mobile App Setup

1. **Install Flutter dependencies:**
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Update API endpoint** in `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000';
   ```

3. **Run on device/emulator:**
   ```bash
   flutter run
   ```

## 📱 Features

- ✅ Real-time sensor fusion (EKF)
- ✅ Traffic sign recognition (TFLite)
- ✅ Unsafe driving detection
- ✅ In-trip alerts
- ✅ Post-trip analytics
- ✅ JWT authentication
- ✅ Offline support

## 🧪 Testing

### Backend Tests
```bash
cd backend
pytest
```

### Mobile Tests
```bash
cd mobile
flutter test
```

## 📚 API Documentation

Once backend is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 🔐 Default Credentials

For testing, you can register a new account via `/auth/register` endpoint.

## 📝 Environment Variables

See `.env.example` for required variables:
- `DATABASE_URL`
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`
- `API_HOST`
- `API_PORT`

## 🐳 Docker Services

- **Backend API:** Port 8000
- **PostgreSQL:** Port 5432
- **pgAdmin (optional):** Port 5050

## 📄 License

MIT License
