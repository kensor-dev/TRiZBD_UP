from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import date, datetime
from decimal import Decimal

class RoomTypeBase(BaseModel):
    name: str = Field(..., max_length=50)
    description: Optional[str] = None
    base_price: Decimal = Field(..., ge=0)
    capacity: int = Field(..., gt=0)

class RoomTypeCreate(RoomTypeBase):
    pass

class RoomTypeUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = None
    base_price: Optional[Decimal] = Field(None, ge=0)
    capacity: Optional[int] = Field(None, gt=0)

class RoomType(RoomTypeBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class RoomBase(BaseModel):
    room_number: str = Field(..., max_length=10)
    room_type_id: int
    floor: int = Field(..., gt=0)
    status: str = Field(default="свободно", pattern="^(свободно|занято|на тех. обслуживании|зарезервировано)$")

class RoomCreate(RoomBase):
    pass

class RoomUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern="^(свободно|занято|на тех. обслуживании|зарезервировано)$")

class Room(RoomBase):
    id: int
    created_at: datetime
    room_type: Optional[RoomType] = None
    
    class Config:
        from_attributes = True

class GuestBase(BaseModel):
    first_name: str = Field(..., max_length=100)
    last_name: str = Field(..., max_length=100)
    email: EmailStr
    phone: str = Field(..., max_length=20)
    passport_number: Optional[str] = Field(None, max_length=50)
    date_of_birth: Optional[date] = None

class GuestCreate(GuestBase):
    pass

class GuestUpdate(BaseModel):
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=20)

class Guest(GuestBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class BookingBase(BaseModel):
    guest_id: int
    room_id: int
    check_in_date: date
    check_out_date: date
    total_price: Decimal = Field(..., ge=0)
    status: str = Field(default="ожидает", pattern="^(ожидает|подтверждено|заселен|выселен|отменено)$")
    special_requests: Optional[str] = None

class BookingCreate(BookingBase):
    pass

class BookingUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern="^(ожидает|подтверждено|заселен|выселен|отменено)$")
    special_requests: Optional[str] = None

class Booking(BookingBase):
    id: int
    created_at: datetime
    guest: Optional[Guest] = None
    room: Optional[Room] = None
    
    class Config:
        from_attributes = True

class PaymentBase(BaseModel):
    booking_id: int
    amount: Decimal = Field(..., gt=0)
    payment_method: str = Field(..., pattern="^(наличные|кредитная карта|дебетовая карта|онлайн)$")
    payment_status: str = Field(default="ожидает", pattern="^(ожидает|завершен|отклонен|возврат)$")
    transaction_id: Optional[str] = Field(None, max_length=100)

class PaymentCreate(PaymentBase):
    pass

class PaymentUpdate(BaseModel):
    payment_status: Optional[str] = Field(None, pattern="^(ожидает|завершен|отклонен|возврат)$")
    transaction_id: Optional[str] = Field(None, max_length=100)

class Payment(PaymentBase):
    id: int
    payment_date: datetime
    
    class Config:
        from_attributes = True

class UserBase(BaseModel):
    username: str = Field(..., max_length=50)
    email: EmailStr
    full_name: str = Field(..., max_length=200)
    role: str = Field(..., pattern="^(admin|manager|guest)$")

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True
