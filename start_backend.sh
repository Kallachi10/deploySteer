#!/bin/bash

# Quick start script for SteerMate backend

echo "Starting SteerMate Backend..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

# Start services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 5

# Check if backend is running
if curl -s http://localhost:8000/health > /dev/null; then
    echo "✅ Backend is running at http://localhost:8000"
    echo "📚 API docs available at http://localhost:8000/docs"
else
    echo "⚠️  Backend may still be starting. Check logs with: docker-compose logs -f backend"
fi

echo ""
echo "To stop services, run: docker-compose down"
