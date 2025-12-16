from sqlalchemy.orm import Session
from sqlalchemy import and_
from . import models, schemas
from datetime import date

def get_room_types(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.RoomType).offset(skip).limit(limit).all()

def get_room_type(db: Session, room_type_id: int):
    return db.query(models.RoomType).filter(models.RoomType.id == room_type_id).first()

def create_room_type(db: Session, room_type: schemas.RoomTypeCreate):
    db_room_type = models.RoomType(**room_type.model_dump())
    db.add(db_room_type)
    db.commit()
    db.refresh(db_room_type)
    return db_room_type

def get_rooms(db: Session, skip: int = 0, limit: int = 100, status: str = None):
    query = db.query(models.Room)
    if status:
        query = query.filter(models.Room.status == status)
    return query.offset(skip).limit(limit).all()

def get_room(db: Session, room_id: int):
    return db.query(models.Room).filter(models.Room.id == room_id).first()

def create_room(db: Session, room: schemas.RoomCreate):
    db_room = models.Room(**room.model_dump())
    db.add(db_room)
    db.commit()
    db.refresh(db_room)
    return db_room

def update_room(db: Session, room_id: int, room: schemas.RoomUpdate):
    db_room = get_room(db, room_id)
    if db_room:
        for key, value in room.model_dump(exclude_unset=True).items():
            setattr(db_room, key, value)
        db.commit()
        db.refresh(db_room)
    return db_room

def get_guests(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Guest).offset(skip).limit(limit).all()

def get_guest(db: Session, guest_id: int):
    return db.query(models.Guest).filter(models.Guest.id == guest_id).first()

def get_guest_by_email(db: Session, email: str):
    return db.query(models.Guest).filter(models.Guest.email == email).first()

def create_guest(db: Session, guest: schemas.GuestCreate):
    db_guest = models.Guest(**guest.model_dump())
    db.add(db_guest)
    db.commit()
    db.refresh(db_guest)
    return db_guest

def update_guest(db: Session, guest_id: int, guest: schemas.GuestUpdate):
    db_guest = get_guest(db, guest_id)
    if db_guest:
        for key, value in guest.model_dump(exclude_unset=True).items():
            setattr(db_guest, key, value)
        db.commit()
        db.refresh(db_guest)
    return db_guest

def delete_guest(db: Session, guest_id: int):
    db_guest = get_guest(db, guest_id)
    if db_guest:
        db.delete(db_guest)
        db.commit()
        return True
    return False

def get_bookings(db: Session, skip: int = 0, limit: int = 100, status: str = None):
    query = db.query(models.Booking)
    if status:
        query = query.filter(models.Booking.status == status)
    return query.offset(skip).limit(limit).all()

def get_booking(db: Session, booking_id: int):
    return db.query(models.Booking).filter(models.Booking.id == booking_id).first()

def create_booking(db: Session, booking: schemas.BookingCreate):
    db_booking = models.Booking(**booking.model_dump())
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

def update_booking(db: Session, booking_id: int, booking: schemas.BookingUpdate):
    db_booking = get_booking(db, booking_id)
    if db_booking:
        for key, value in booking.model_dump(exclude_unset=True).items():
            setattr(db_booking, key, value)
        db.commit()
        db.refresh(db_booking)
    return db_booking

def delete_booking(db: Session, booking_id: int):
    db_booking = get_booking(db, booking_id)
    if db_booking:
        db.delete(db_booking)
        db.commit()
        return True
    return False

def get_available_rooms(db: Session, check_in: date, check_out: date):
    booked_rooms = db.query(models.Booking.room_id).filter(
        and_(
            models.Booking.check_in_date < check_out,
            models.Booking.check_out_date > check_in,
            models.Booking.status.in_(['подтверждено', 'заселен'])
        )
    ).all()
    booked_room_ids = [room_id for (room_id,) in booked_rooms]
    return db.query(models.Room).filter(
        models.Room.status == 'свободно',
        models.Room.id.notin_(booked_room_ids)
    ).all()

def get_payments(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Payment).offset(skip).limit(limit).all()

def get_payment(db: Session, payment_id: int):
    return db.query(models.Payment).filter(models.Payment.id == payment_id).first()

def create_payment(db: Session, payment: schemas.PaymentCreate):
    db_payment = models.Payment(**payment.model_dump())
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    return db_payment

def get_user_by_username(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first()

def create_user(db: Session, user: schemas.UserCreate):
    from passlib.context import CryptContext
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    hashed_password = pwd_context.hash(user.password)
    db_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=hashed_password,
        full_name=user.full_name,
        role=user.role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_room_type(db: Session, room_type_id: int, room_type: schemas.RoomTypeUpdate):
    db_room_type = get_room_type(db, room_type_id)
    if db_room_type:
        for key, value in room_type.model_dump(exclude_unset=True).items():
            setattr(db_room_type, key, value)
        db.commit()
        db.refresh(db_room_type)
    return db_room_type

def delete_room_type(db: Session, room_type_id: int):
    db_room_type = get_room_type(db, room_type_id)
    if db_room_type:
        db.delete(db_room_type)
        db.commit()
        return True
    return False

def update_payment(db: Session, payment_id: int, payment: schemas.PaymentUpdate):
    db_payment = get_payment(db, payment_id)
    if db_payment:
        for key, value in payment.model_dump(exclude_unset=True).items():
            setattr(db_payment, key, value)
        db.commit()
        db.refresh(db_payment)
    return db_payment

def delete_payment(db: Session, payment_id: int):
    db_payment = get_payment(db, payment_id)
    if db_payment:
        db.delete(db_payment)
        db.commit()
        return True
    return False

def delete_room(db: Session, room_id: int):
    db_room = get_room(db, room_id)
    if db_room:
        db.delete(db_room)
        db.commit()
        return True
    return False
