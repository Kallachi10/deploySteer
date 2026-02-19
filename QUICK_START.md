# SteerMate Quick Start Guide

Get SteerMate up and running in 5 minutes!

## Step 1: Start Backend (2 minutes)

### Option A: Docker (Easiest)

**Windows:**
```bash
start_backend.bat
```

**Linux/Mac:**
```bash
chmod +x start_backend.sh
./start_backend.sh
```

**Or manually:**
```bash
docker-compose up -d
```

**Local production-like mode (still private, better for testing):**

This runs the same services locally, but closer to production behavior (no hot reload, no source bind-mount, multiple workers):

```bash
docker-compose -f docker-compose.yml -f docker-compose.local-prod.yml up -d --build postgres backend_prod
```

✅ Backend running at: `http://localhost:8000`
✅ API docs: `http://localhost:8000/docs`

### Option B: Manual Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your database URL
uvicorn main:app --reload
```

## Step 2: Setup Mobile App (2 minutes)

```bash
cd mobile
flutter pub get
```

**Point the app at the backend (no cloud deploy required):**

You can run the backend locally (Docker or manual) and just point the mobile app at your computer.
The mobile app reads the base URL from a compile-time define:

- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`
- Physical device (same Wi‑Fi): `http://YOUR_COMPUTER_LAN_IP:8000`

## Step 3: Run Mobile App (1 minute)

```bash
flutter run
```

**Examples (recommended):**

- Android Emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

- Physical Android device (replace with your PC IP):
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
```

- iOS Simulator:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

## Step 4: Test It!

1. **Register a new account** in the app
2. **Start a trip** (tap "Start Trip")
3. **Drive or simulate** movement
4. **End trip** and view report

## Troubleshooting

### Backend not starting?
- Check Docker is running: `docker ps`
- Check logs: `docker-compose logs backend`
- Verify port 8000 is free

### Mobile app can't connect?
- Verify backend is running: `curl http://localhost:8000/health`
- Check the `API_BASE_URL` you passed to `flutter run`
- For physical device: ensure same WiFi network

#### Physical device without Wi‑Fi setup (USB port-forward)

If your phone is plugged in over USB, you can forward traffic to your computer without dealing with LAN IPs/firewall.

- Android (ADB reverse):
```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Need help?
See `SETUP.md` for detailed instructions.

## Next Steps

1. **Add ML Model**: Place trained TFLite model at `mobile/assets/models/traffic_sign_model.tflite`
2. **Calibrate EKF**: Adjust parameters in `mobile/lib/services/ekf_service.dart`
3. **Customize Alerts**: Modify thresholds in `mobile/lib/services/alert_service.dart`
4. **Deploy**: Follow production deployment guide in `SETUP.md`

Happy driving! 🚗
