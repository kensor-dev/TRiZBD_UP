from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date

from . import models, schemas, crud
from .database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Hotel Booking API",
    description="API для системы бронирования отелей",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Hotel Booking API", "version": "1.0.0"}

@app.get("/room-types/", response_model=List[schemas.RoomType])
def read_room_types(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    room_types = crud.get_room_types(db, skip=skip, limit=limit)
    return room_types

@app.get("/room-types/{room_type_id}", response_model=schemas.RoomType)
def read_room_type(room_type_id: int, db: Session = Depends(get_db)):
    db_room_type = crud.get_room_type(db, room_type_id=room_type_id)
    if db_room_type is None:
        raise HTTPException(status_code=404, detail="Тип номера не найден")
    return db_room_type

@app.post("/room-types/", response_model=schemas.RoomType, status_code=status.HTTP_201_CREATED)
def create_room_type(room_type: schemas.RoomTypeCreate, db: Session = Depends(get_db)):
    return crud.create_room_type(db=db, room_type=room_type)

@app.get("/rooms/", response_model=List[schemas.Room])
def read_rooms(skip: int = 0, limit: int = 100, status: Optional[str] = None, db: Session = Depends(get_db)):
    rooms = crud.get_rooms(db, skip=skip, limit=limit, status=status)
    return rooms

@app.get("/rooms/{room_id}", response_model=schemas.Room)
def read_room(room_id: int, db: Session = Depends(get_db)):
    db_room = crud.get_room(db, room_id=room_id)
    if db_room is None:
        raise HTTPException(status_code=404, detail="Номер не найден")
    return db_room

@app.post("/rooms/", response_model=schemas.Room, status_code=status.HTTP_201_CREATED)
def create_room(room: schemas.RoomCreate, db: Session = Depends(get_db)):
    return crud.create_room(db=db, room=room)

@app.put("/rooms/{room_id}", response_model=schemas.Room)
def update_room(room_id: int, room: schemas.RoomUpdate, db: Session = Depends(get_db)):
    db_room = crud.update_room(db, room_id=room_id, room=room)
    if db_room is None:
        raise HTTPException(status_code=404, detail="Номер не найден")
    return db_room

@app.delete("/rooms/{room_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_room(room_id: int, db: Session = Depends(get_db)):
    success = crud.delete_room(db, room_id=room_id)
    if not success:
        raise HTTPException(status_code=404, detail="Номер не найден")
    return None


@app.get("/rooms/available/", response_model=List[schemas.Room])
def read_available_rooms(check_in: date, check_out: date, db: Session = Depends(get_db)):
    if check_in >= check_out:
        raise HTTPException(status_code=400, detail="Дата выезда должна быть позже даты заезда")
    rooms = crud.get_available_rooms(db, check_in=check_in, check_out=check_out)
    return rooms

@app.get("/guests/", response_model=List[schemas.Guest])
def read_guests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    guests = crud.get_guests(db, skip=skip, limit=limit)
    return guests

@app.get("/guests/{guest_id}", response_model=schemas.Guest)
def read_guest(guest_id: int, db: Session = Depends(get_db)):
    db_guest = crud.get_guest(db, guest_id=guest_id)
    if db_guest is None:
        raise HTTPException(status_code=404, detail="Гость не найден")
    return db_guest

@app.post("/guests/", response_model=schemas.Guest, status_code=status.HTTP_201_CREATED)
def create_guest(guest: schemas.GuestCreate, db: Session = Depends(get_db)):
    db_guest = crud.get_guest_by_email(db, email=guest.email)
    if db_guest:
        raise HTTPException(status_code=400, detail="Email уже зарегистрирован")
    return crud.create_guest(db=db, guest=guest)

@app.put("/guests/{guest_id}", response_model=schemas.Guest)
def update_guest(guest_id: int, guest: schemas.GuestUpdate, db: Session = Depends(get_db)):
    db_guest = crud.update_guest(db, guest_id=guest_id, guest=guest)
    if db_guest is None:
        raise HTTPException(status_code=404, detail="Гость не найден")
    return db_guest

@app.delete("/guests/{guest_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_guest(guest_id: int, db: Session = Depends(get_db)):
    success = crud.delete_guest(db, guest_id=guest_id)
    if not success:
        raise HTTPException(status_code=404, detail="Гость не найден")
    return None

@app.get("/bookings/", response_model=List[schemas.Booking])
def read_bookings(skip: int = 0, limit: int = 100, status: Optional[str] = None, db: Session = Depends(get_db)):
    bookings = crud.get_bookings(db, skip=skip, limit=limit, status=status)
    return bookings

@app.get("/bookings/{booking_id}", response_model=schemas.Booking)
def read_booking(booking_id: int, db: Session = Depends(get_db)):
    db_booking = crud.get_booking(db, booking_id=booking_id)
    if db_booking is None:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    return db_booking

@app.post("/bookings/", response_model=schemas.Booking, status_code=status.HTTP_201_CREATED)
def create_booking(booking: schemas.BookingCreate, db: Session = Depends(get_db)):
    if booking.check_in_date >= booking.check_out_date:
        raise HTTPException(status_code=400, detail="Дата выезда должна быть позже даты заезда")
    return crud.create_booking(db=db, booking=booking)

@app.put("/bookings/{booking_id}", response_model=schemas.Booking)
def update_booking(booking_id: int, booking: schemas.BookingUpdate, db: Session = Depends(get_db)):
    db_booking = crud.update_booking(db, booking_id=booking_id, booking=booking)
    if db_booking is None:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    return db_booking

@app.delete("/bookings/{booking_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_booking(booking_id: int, db: Session = Depends(get_db)):
    success = crud.delete_booking(db, booking_id=booking_id)
    if not success:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    return None

@app.get("/payments/", response_model=List[schemas.Payment])
def read_payments(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    payments = crud.get_payments(db, skip=skip, limit=limit)
    return payments

@app.get("/payments/{payment_id}", response_model=schemas.Payment)
def read_payment(payment_id: int, db: Session = Depends(get_db)):
    db_payment = crud.get_payment(db, payment_id=payment_id)
    if db_payment is None:
        raise HTTPException(status_code=404, detail="Платеж не найден")
    return db_payment

@app.post("/payments/", response_model=schemas.Payment, status_code=status.HTTP_201_CREATED)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    db_booking = crud.get_booking(db, booking_id=payment.booking_id)
    if db_booking is None:
        raise HTTPException(status_code=404, detail="Бронирование не найдено")
    return crud.create_payment(db=db, payment=payment)

@app.put("/room-types/{room_type_id}", response_model=schemas.RoomType)
def update_room_type(room_type_id: int, room_type: schemas.RoomTypeUpdate, db: Session = Depends(get_db)):
    db_room_type = crud.update_room_type(db, room_type_id=room_type_id, room_type=room_type)
    if db_room_type is None:
        raise HTTPException(status_code=404, detail="Тип номера не найден")
    return db_room_type

@app.delete("/room-types/{room_type_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_room_type(room_type_id: int, db: Session = Depends(get_db)):
    success = crud.delete_room_type(db, room_type_id=room_type_id)
    if not success:
        raise HTTPException(status_code=404, detail="Тип номера не найден")
    return None

@app.put("/payments/{payment_id}", response_model=schemas.Payment)
def update_payment(payment_id: int, payment: schemas.PaymentUpdate, db: Session = Depends(get_db)):
    db_payment = crud.update_payment(db, payment_id=payment_id, payment=payment)
    if db_payment is None:
        raise HTTPException(status_code=404, detail="Платеж не найден")
    return db_payment

@app.delete("/payments/{payment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_payment(payment_id: int, db: Session = Depends(get_db)):
    success = crud.delete_payment(db, payment_id=payment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Платеж не найден")
    return None
