from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.models.trip import Trip, TripEvent, SignDetection
from app.schemas.trip import TripCreate, TripResponse, TripEventCreate, SignDetectionCreate

router = APIRouter()


@router.post("/upload", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
async def upload_trip(
    trip_data: TripCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Create trip
    new_trip = Trip(
        user_id=current_user.id,
        start_time=trip_data.start_time,
        end_time=trip_data.end_time,
        duration_seconds=trip_data.duration_seconds,
        distance_m=trip_data.distance_m,
        avg_speed_m_s=trip_data.avg_speed_m_s,
        max_speed_m_s=trip_data.max_speed_m_s,
        unsafe_events=trip_data.unsafe_events
    )
    db.add(new_trip)
    await db.flush()
    
    # Create events
    for event_data in trip_data.events:
        event = TripEvent(
            trip_id=new_trip.id,
            event_type=event_data.event_type,
            timestamp=event_data.timestamp,
            lat=event_data.lat,
            lon=event_data.lon,
            speed_m_s=event_data.speed_m_s,
            accel_m_s2=event_data.accel_m_s2
        )
        db.add(event)
    
    # Create sign detections
    for sign_data in trip_data.sign_detections:
        sign = SignDetection(
            trip_id=new_trip.id,
            ts=sign_data.ts,
            class_name=sign_data.class_name,
            confidence=sign_data.confidence,
            bbox=sign_data.bbox
        )
        db.add(sign)
    
    await db.commit()
    await db.refresh(new_trip)

    # Eagerly load related events and sign detections to avoid async
    # lazy-loading during response serialization (MissingGreenlet error).
    result = await db.execute(
        select(Trip)
        .where(Trip.id == new_trip.id)
        .options(selectinload(Trip.events), selectinload(Trip.sign_detections))
    )
    trip_with_relations = result.scalar_one()

    return trip_with_relations


@router.get("/", response_model=List[TripResponse])
async def get_trips(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    skip: int = 0,
    limit: int = 100
):
    result = await db.execute(
        select(Trip)
        .where(Trip.user_id == current_user.id)
        .options(selectinload(Trip.events), selectinload(Trip.sign_detections))
        .order_by(Trip.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    trips = result.scalars().all()
    return trips


@router.get("/{trip_id}", response_model=TripResponse)
async def get_trip(
    trip_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    from sqlalchemy import select
    from sqlalchemy.orm import selectinload
    
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
    
    return trip
