# SteerMate Project Structure

```
Project/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── auth.py     # Authentication endpoints
│   │   │       ├── trips.py    # Trip management endpoints
│   │   │       ├── reports.py  # Report generation endpoints
│   │   │       └── users.py   # User profile endpoints
│   │   ├── core/
│   │   │   ├── config.py       # Configuration settings
│   │   │   ├── database.py    # Database connection
│   │   │   └── dependencies.py # FastAPI dependencies
│   │   ├── models/             # SQLAlchemy models
│   │   │   ├── user.py
│   │   │   └── trip.py
│   │   └── schemas/            # Pydantic schemas
│   │       ├── user.py
│   │       └── trip.py
│   ├── alembic/                # Database migrations
│   ├── tests/                  # Backend tests
│   ├── Dockerfile
│   ├── requirements.txt
│   └── main.py                 # FastAPI app entry point
│
├── mobile/                     # Flutter mobile app
│   ├── lib/
│   │   ├── config/
│   │   │   └── api_config.dart # API endpoint configuration
│   │   ├── providers/          # State management
│   │   │   ├── auth_provider.dart
│   │   │   └── trip_provider.dart
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart
│   │   │   ├── trip/
│   │   │   │   ├── trip_active_screen.dart
│   │   │   │   └── trip_report_screen.dart
│   │   │   ├── trips/
│   │   │   │   └── trips_list_screen.dart
│   │   │   └── settings/
│   │   │       └── settings_screen.dart
│   │   └── services/           # Core services
│   │       ├── api_service.dart
│   │       ├── sensor_service.dart
│   │       ├── ekf_service.dart
│   │       ├── alert_service.dart
│   │       ├── trip_logger_service.dart
│   │       ├── ml_service.dart
│   │       └── storage_service.dart
│   ├── assets/
│   │   ├── models/             # TFLite models
│   │   └── sounds/             # Alert sounds
│   ├── android/                # Android configuration
│   ├── ios/                    # iOS configuration
│   └── pubspec.yaml
│
├── docker-compose.yml          # Docker services configuration
├── README.md                   # Main documentation
├── SETUP.md                    # Detailed setup guide
├── start_backend.sh            # Quick start script (Linux/Mac)
└── start_backend.bat           # Quick start script (Windows)
```

## Key Components

### Backend (FastAPI)
- **Authentication**: JWT-based user authentication
- **Trip Management**: Upload, retrieve, and manage driving trips
- **Report Generation**: Analytics and recommendations
- **Database**: PostgreSQL with SQLAlchemy ORM

### Mobile App (Flutter)
- **Sensor Service**: GPS, accelerometer, gyroscope data collection
- **EKF Service**: Extended Kalman Filter for sensor fusion
- **Alert Service**: Real-time unsafe driving detection
- **ML Service**: Traffic sign recognition (TFLite)
- **Trip Logger**: Local trip data logging and upload

## Data Flow

1. **User Authentication**: Register/Login → JWT token
2. **Trip Start**: Sensors activated → EKF fusion → Real-time alerts
3. **During Trip**: ML sign detection → Speed limit updates → Event logging
4. **Trip End**: Data aggregation → Upload to backend → Report generation
5. **Post-Trip**: View analytics, recommendations, and trip history
