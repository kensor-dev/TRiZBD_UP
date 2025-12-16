from sqlalchemy import Column, Integer, String, Text, DECIMAL, Date, TIMESTAMP, Boolean, ForeignKey, CheckConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class RoomType(Base):
    __tablename__ = "room_types"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False)
    description = Column(Text)
    base_price = Column(DECIMAL(10, 2), nullable=False)
    capacity = Column(Integer, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())

    rooms = relationship("Room", back_populates="room_type")

class Room(Base):
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    room_number = Column(String(10), unique=True, nullable=False)
    room_type_id = Column(Integer, ForeignKey("room_types.id"), nullable=False, index=True)
    floor = Column(Integer, nullable=False, index=True)
    status = Column(String(30), nullable=False, default="свободно", index=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

    room_type = relationship("RoomType", back_populates="rooms")
    bookings = relationship("Booking", back_populates="room")

class Guest(Base):
    __tablename__ = "guests"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=False, index=True)
    passport_number = Column(String(50), unique=True, index=True)
    date_of_birth = Column(Date)
    created_at = Column(TIMESTAMP, server_default=func.now())

    bookings = relationship("Booking", back_populates="guest")

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    guest_id = Column(Integer, ForeignKey("guests.id"), nullable=False, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id"), nullable=False, index=True)
    check_in_date = Column(Date, nullable=False, index=True)
    check_out_date = Column(Date, nullable=False)
    total_price = Column(DECIMAL(10, 2), nullable=False)
    status = Column(String(20), nullable=False, default="ожидает", index=True)
    special_requests = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())

    guest = relationship("Guest", back_populates="bookings")
    room = relationship("Room", back_populates="bookings")
    payments = relationship("Payment", back_populates="booking")

    __table_args__ = (
        Index('idx_bookings_dates', 'check_in_date', 'check_out_date'),
    )

class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=False, index=True)
    amount = Column(DECIMAL(10, 2), nullable=False)
    payment_method = Column(String(50), nullable=False)
    payment_status = Column(String(20), nullable=False, default="ожидает", index=True)
    transaction_id = Column(String(100), unique=True, index=True)
    payment_date = Column(TIMESTAMP, server_default=func.now(), index=True)

    booking = relationship("Booking", back_populates="payments")

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(200), nullable=False)
    role = Column(String(20), nullable=False, index=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    last_login = Column(TIMESTAMP)
