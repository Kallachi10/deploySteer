# SteerMate Setup Guide

Complete setup instructions for SteerMate ADAS system.

## Prerequisites

- Docker & Docker Compose
- Flutter SDK 3.0+
- Python 3.10+
- PostgreSQL 14+ (optional if using Docker)

## Backend Setup

### Option 1: Using Docker (Recommended)

1. **Start services:**
   ```bash
   docker-compose up -d
   ```

2. **Check logs:**
   ```bash
   docker-compose logs -f backend
   ```

3. **Backend will be available at:** `http://localhost:8000`
   - API docs: `http://localhost:8000/docs`

### Option 2: Manual Setup

1. **Create virtual environment:**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. **Run database migrations:**
   ```bash
   alembic upgrade head
   ```

5. **Start server:**
   ```bash
   uvicorn main:app --reload
   ```

## Mobile App Setup

1. **Install Flutter dependencies:**
   ```bash
   cd mobile
   flutter pub get
   ```

2. **Update API endpoint:**
   Edit `lib/config/api_config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000';
   ```
   
   - Android Emulator: `http://10.0.2.2:8000`
   - iOS Simulator: `http://localhost:8000`
   - Physical Device: `http://YOUR_COMPUTER_IP:8000`

3. **Add ML Model (Optional):**
   Place your trained TFLite model at:
   ```
   mobile/assets/models/traffic_sign_model.tflite
   ```
   
   Note: The app will work without the model, but sign detection won't function.

4. **Run on device/emulator:**
   ```bash
   flutter run
   ```

## Database Setup

If not using Docker, create PostgreSQL database:

```sql
CREATE DATABASE steermate_db;
CREATE USER steermate WITH PASSWORD 'steermate_pass';
GRANT ALL PRIVILEGES ON DATABASE steermate_db TO steermate;
```

## Testing

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

## Troubleshooting

### Backend won't start
- Check if PostgreSQL is running
- Verify DATABASE_URL in .env
- Check port 8000 is not in use

### Mobile app can't connect
- Verify backend is running
- Check API endpoint in `api_config.dart`
- For physical devices, ensure phone and computer are on same network
- Check firewall settings

### ML model not working
- Ensure model file exists at `assets/models/traffic_sign_model.tflite`
- Model must be trained and converted to TFLite format
- Check model input/output shapes match expectations

## Development

### Backend Development
- API auto-reloads on code changes (uvicorn --reload)
- Database migrations: `alembic revision --autogenerate -m "description"`
- Apply migrations: `alembic upgrade head`

### Mobile Development
- Hot reload: Press `r` in terminal
- Hot restart: Press `R` in terminal
- Debug logs: Check Flutter console

## Production Deployment

1. **Backend:**
   - Use production-grade ASGI server (Gunicorn + Uvicorn workers)
   - Set strong JWT_SECRET_KEY
   - Enable HTTPS
   - Use production PostgreSQL instance

2. **Mobile:**
   - Build release APK/IPA
   - Update API endpoint to production URL
   - Enable code obfuscation

## Next Steps

1. Train ML model on traffic sign datasets
2. Calibrate EKF parameters for your use case
3. Fine-tune alert thresholds
4. Add more analytics and visualizations
5. Implement offline mode improvements

## Traffic Sign Model Downloader (Optional)

To download a base YOLOv8n model for traffic sign detection experiments:

```bash
cd backend
python -m ml.scripts.download_sign_model
```

The model will be saved under:

- `backend/ml/models/yolov8n.pt`

You can fine-tune this model on traffic sign datasets (e.g., GTSRB/GTSDB),
export a TFLite model, and place it at:

- `mobile/assets/models/traffic_sign_model.tflite`

