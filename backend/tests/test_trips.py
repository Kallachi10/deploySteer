import pytest
from httpx import AsyncClient
from app.main import app
from datetime import datetime


@pytest.mark.asyncio
async def test_upload_trip():
    async with AsyncClient(app=app, base_url="http://test") as client:
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "tripuser@example.com",
                "password": "testpass123",
            }
        )
        
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "tripuser@example.com",
                "password": "testpass123"
            }
        )
        token = login_response.json()["access_token"]
        
        # Upload trip
        trip_data = {
            "start_time": datetime.now().isoformat(),
            "end_time": datetime.now().isoformat(),
            "duration_seconds": 3600,
            "distance_m": 50000.0,
            "avg_speed_m_s": 13.89,
            "max_speed_m_s": 25.0,
            "unsafe_events": 2,
            "events": [
                {
                    "event_type": "hard_brake",
                    "timestamp": datetime.now().isoformat(),
                    "lat": 40.7128,
                    "lon": -74.0060,
                    "speed_m_s": 20.0,
                    "accel_m_s2": -5.0
                }
            ],
            "sign_detections": []
        }
        
        response = await client.post(
            "/api/v1/trips/upload",
            json=trip_data,
            headers={"Authorization": f"Bearer {token}"}
        )
        assert response.status_code == 201
        assert "id" in response.json()
