# SteerMate Mobile App

Flutter-based mobile application for SteerMate ADAS.

## Setup

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Update API endpoint:**
   Edit `lib/config/api_config.dart` and set the correct backend URL:
   - Android Emulator: `http://10.0.2.2:8000`
   - iOS Simulator: `http://localhost:8000`
   - Physical Device: `http://YOUR_COMPUTER_IP:8000`

3. **Add ML Model:**
   Place your trained TFLite model at:
   ```
   assets/models/traffic_sign_model.tflite
   ```
   Note: The model should be trained on traffic sign datasets (GTSRB, GTSDB, etc.)

4. **Run the app:**
   ```bash
   flutter run
   ```

## Features

- Real-time sensor fusion (EKF)
- Traffic sign recognition (TFLite)
- Unsafe driving detection
- In-trip alerts
- Post-trip analytics
- Offline trip logging

## Permissions

The app requires:
- Location (GPS)
- Camera (for sign detection)
- Motion sensors (accelerometer, gyroscope)
- Vibration (for alerts)

## Testing

Run tests with:
```bash
flutter test
```
