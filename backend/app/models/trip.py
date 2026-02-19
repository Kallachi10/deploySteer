from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class Trip(Base):
    __tablename__ = "trips"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    start_time = Column(DateTime(timezone=True))
    end_time = Column(DateTime(timezone=True))
    duration_seconds = Column(Integer)
    distance_m = Column(Float)
    avg_speed_m_s = Column(Float)
    max_speed_m_s = Column(Float)
    unsafe_events = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    events = relationship("TripEvent", back_populates="trip", cascade="all, delete-orphan")
    sign_detections = relationship("SignDetection", back_populates="trip", cascade="all, delete-orphan")


class TripEvent(Base):
    __tablename__ = "trip_events"
    
    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=False)
    event_type = Column(String, nullable=False)  # 'hard_brake', 'overspeed', 'harsh_accel', 'unsafe_curve'
    timestamp = Column(DateTime(timezone=True))
    lat = Column(Float)
    lon = Column(Float)
    speed_m_s = Column(Float)
    accel_m_s2 = Column(Float)
    
    trip = relationship("Trip", back_populates="events")


class SignDetection(Base):
    __tablename__ = "sign_detections"
    
    id = Column(Integer, primary_key=True, index=True)
    trip_id = Column(Integer, ForeignKey("trips.id"), nullable=False)
    ts = Column(DateTime(timezone=True))
    class_name = Column(String)  # e.g. 'speed_limit_60'
    confidence = Column(Float)
    bbox = Column(JSON)  # JSONB in PostgreSQL
    
    trip = relationship("Trip", back_populates="sign_detections")
