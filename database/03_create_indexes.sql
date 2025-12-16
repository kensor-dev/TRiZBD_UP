-- Индексы для таблицы rooms
-- Ускоряют поиск доступных номеров по статусу, типу и этажу
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_room_type ON rooms(room_type_id);
CREATE INDEX idx_rooms_floor ON rooms(floor);

-- Индексы для таблицы guests
-- Обеспечивают быстрый поиск гостей по контактным данным и документам
CREATE INDEX idx_guests_email ON guests(email);
CREATE INDEX idx_guests_phone ON guests(phone);
CREATE INDEX idx_guests_passport ON guests(passport_number);

-- Индексы для таблицы bookings
-- Ускоряют выборки бронирований по гостю, номеру, датам и статусу
CREATE INDEX idx_bookings_guest ON bookings(guest_id);
CREATE INDEX idx_bookings_room ON bookings(room_id);
CREATE INDEX idx_bookings_dates ON bookings(check_in_date, check_out_date);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_check_in ON bookings(check_in_date);

-- Индексы для таблицы payments
-- Ускоряют поиск платежей по бронированию, статусу и транзакциям
CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_transaction ON payments(transaction_id);

-- Индексы для таблицы users
-- Обеспечивают быстрый поиск пользователей по имени, email и роли
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
