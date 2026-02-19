from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, Dict, Any


class TripEventCreate(BaseModel):
    event_type: str
    timestamp: datetime
    lat: float
    lon: float
    speed_m_s: float
    accel_m_s2: float


class SignDetectionCreate(BaseModel):
    ts: datetime
    class_name: str
    confidence: float
    bbox: Dict[str, Any]


class TripCreate(BaseModel):
    start_time: datetime
    end_time: datetime
    duration_seconds: int
    distance_m: float
    avg_speed_m_s: float
    max_speed_m_s: float
    unsafe_events: int
    events: List[TripEventCreate] = []
    sign_detections: List[SignDetectionCreate] = []


class TripEventResponse(BaseModel):
    id: int
    event_type: str
    timestamp: datetime
    lat: float
    lon: float
    speed_m_s: float
    accel_m_s2: float
    
    class Config:
        from_attributes = True


class SignDetectionResponse(BaseModel):
    id: int
    ts: datetime
    class_name: str
    confidence: float
    bbox: Dict[str, Any]
    
    class Config:
        from_attributes = True


class TripResponse(BaseModel):
    id: int
    user_id: int
    start_time: datetime
    end_time: datetime
    duration_seconds: int
    distance_m: float
    avg_speed_m_s: float
    max_speed_m_s: float
    unsafe_events: int
    created_at: datetime
    events: List[TripEventResponse] = []
    sign_detections: List[SignDetectionResponse] = []
    
    class Config:
        from_attributes = True
