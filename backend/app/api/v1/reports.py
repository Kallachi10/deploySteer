from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import Dict, Any, List
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.trip import Trip, TripEvent, SignDetection
import json
# Optional ML imports
try:
    import tensorflow as tf
    import numpy as np
    from PIL import Image
    ML_AVAILABLE = True
except ImportError:
    ML_AVAILABLE = False

router = APIRouter()


@router.get("/{trip_id}")
async def get_report(
    trip_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Get trip with events and signs
    result = await db.execute(
        select(Trip)
        .where(Trip.id == trip_id, Trip.user_id == current_user.id)
        .options(selectinload(Trip.events), selectinload(Trip.sign_detections))
    )
    trip = result.scalar_one_or_none()
    
    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Trip not found"
        )
    
    # Generate report data
    report = {
        "trip_id": trip.id,
        "summary": {
            "start_time": trip.start_time.isoformat() if trip.start_time else None,
            "end_time": trip.end_time.isoformat() if trip.end_time else None,
            "duration_seconds": trip.duration_seconds,
            "distance_km": round(trip.distance_m / 1000, 2) if trip.distance_m else 0,
            "avg_speed_kmh": round(trip.avg_speed_m_s * 3.6, 2) if trip.avg_speed_m_s else 0,
            "max_speed_kmh": round(trip.max_speed_m_s * 3.6, 2) if trip.max_speed_m_s else 0,
            "unsafe_events": trip.unsafe_events
        },
        "events": [
            {
                "type": event.event_type,
                "timestamp": event.timestamp.isoformat() if event.timestamp else None,
                "location": {"lat": event.lat, "lon": event.lon},
                "speed_kmh": round(event.speed_m_s * 3.6, 2) if event.speed_m_s else 0,
                "acceleration": round(event.accel_m_s2, 2) if event.accel_m_s2 else 0
            }
            for event in trip.events
        ],
        "sign_detections": [
            {
                "timestamp": sign.ts.isoformat() if sign.ts else None,
                "class": sign.class_name,
                "confidence": round(sign.confidence, 3) if sign.confidence else 0,
                "bbox": sign.bbox
            }
            for sign in trip.sign_detections
        ],
        "analytics": {
            "event_breakdown": _get_event_breakdown(trip.events),
            "recommendations": _generate_recommendations(trip)
        }
    }
    
    return report


def _get_event_breakdown(events: List[TripEvent]) -> Dict[str, int]:
    breakdown = {}
    for event in events:
        breakdown[event.event_type] = breakdown.get(event.event_type, 0) + 1
    return breakdown


def _generate_recommendations(trip: Trip) -> List[str]:
    recommendations = []
    
    # Count event types
    event_types = {}
    for event in trip.events:
        event_types[event.event_type] = event_types.get(event.event_type, 0) + 1
    
    if event_types.get("hard_brake", 0) > 3:
        recommendations.append("Try to anticipate stops earlier to reduce hard braking events.")
    
    if event_types.get("harsh_accel", 0) > 3:
        recommendations.append("Accelerate more gradually for better fuel efficiency and safety.")
    
    if event_types.get("overspeed", 0) > 5:
        recommendations.append("Pay closer attention to speed limit signs and maintain safe speeds.")
    
    if event_types.get("unsafe_curve", 0) > 2:
        recommendations.append("Reduce speed before entering curves for safer cornering.")
    
    if not recommendations:
        recommendations.append("Great driving! Keep up the safe driving habits.")
    
    return recommendations


@router.get("/analytics/trends")
async def get_trends(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    limit: int = 10
):
    # Get recent trips
    result = await db.execute(
        select(Trip)
        .where(Trip.user_id == current_user.id)
        .order_by(Trip.created_at.desc())
        .limit(limit)
    )
    trips = result.scalars().all()
    
    trends = {
        "total_trips": len(trips),
        "avg_unsafe_events": sum(t.unsafe_events for t in trips) / len(trips) if trips else 0,
        "total_distance_km": sum(t.distance_m / 1000 for t in trips if t.distance_m),
        "recent_trips": [
            {
                "trip_id": t.id,
                "date": t.start_time.isoformat() if t.start_time else None,
                "unsafe_events": t.unsafe_events,
                "distance_km": round(t.distance_m / 1000, 2) if t.distance_m else 0
            }
            for t in trips
        ]
    }
    
    return trends


@router.post("/predict_sign")
async def predict_sign(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    if not ML_AVAILABLE:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="ML service not available"
        )
    
    # Load image
    image = Image.open(file.file).convert('RGB').resize((224, 224))
    img_array = np.array(image) / 255.0
    img_array = np.expand_dims(img_array, axis=0).astype(np.float32)
    
    # Dummy model prediction (replace with actual model)
    # Assuming model outputs probabilities for classes
    predictions = np.random.rand(1, len(labels))  # Replace with model.predict(img_array)
    predicted_class_idx = np.argmax(predictions[0])
    confidence = predictions[0][predicted_class_idx]
    
    return {
        "class": labels[predicted_class_idx],
        "confidence": float(confidence),
        "bbox": [0.1, 0.1, 0.9, 0.9]  # Dummy bbox
    }


labels = [
    'speed_limit_30',
    'speed_limit_50',
    'speed_limit_60',
    'speed_limit_80',
    'speed_limit_100',
    'speed_limit_120',
    'stop',
    'yield',
    'no_entry',
]
