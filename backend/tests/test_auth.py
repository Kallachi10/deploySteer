import pytest
from httpx import AsyncClient
from app.main import app


@pytest.mark.asyncio
async def test_register():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test@example.com",
                "password": "testpass123",
                "name": "Test User"
            }
        )
        assert response.status_code == 201
        assert "email" in response.json()


@pytest.mark.asyncio
async def test_login():
    async with AsyncClient(app=app, base_url="http://test") as client:
        # First register
        await client.post(
            "/api/v1/auth/register",
            json={
                "email": "test2@example.com",
                "password": "testpass123",
            }
        )
        
        # Then login
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "email": "test2@example.com",
                "password": "testpass123"
            }
        )
        assert response.status_code == 200
        assert "access_token" in response.json()
