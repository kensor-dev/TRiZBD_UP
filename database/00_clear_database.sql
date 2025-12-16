-- ==========================================
-- Скрипт очистки базы данных trizbd
-- Удаляет все данные, кроме пользователей и ролей
-- ==========================================

-- Отключение проверки внешних ключей на время удаления
SET session_replication_role = 'replica';

-- ==========================================
-- Удаление данных из таблиц (порядок важен из-за внешних ключей)
-- ==========================================

-- Удаление платежей (зависит от bookings)
TRUNCATE TABLE payments CASCADE;
SELECT 'Таблица payments очищена' as status;

-- Удаление бронирований (зависит от rooms и guests)
TRUNCATE TABLE bookings CASCADE;
SELECT 'Таблица bookings очищена' as status;

-- Удаление номеров (зависит от room_types)
TRUNCATE TABLE rooms CASCADE;
SELECT 'Таблица rooms очищена' as status;

-- Удаление типов номеров
TRUNCATE TABLE room_types CASCADE;
SELECT 'Таблица room_types очищена' as status;

-- Удаление гостей
TRUNCATE TABLE guests CASCADE;
SELECT 'Таблица guests очищена' as status;

-- НЕ УДАЛЯЕМ: users (оставляем пользователей)
SELECT 'Таблица users НЕ тронута (пользователи сохранены)' as status;

-- Включение обратно проверки внешних ключей
SET session_replication_role = 'origin';

-- ==========================================
-- Сброс счетчиков SERIAL (автоинкремент)
-- ==========================================

-- Сброс счетчиков для таблиц, которые были очищены
ALTER SEQUENCE room_types_id_seq RESTART WITH 1;
ALTER SEQUENCE rooms_id_seq RESTART WITH 1;
ALTER SEQUENCE guests_id_seq RESTART WITH 1;
ALTER SEQUENCE bookings_id_seq RESTART WITH 1;
ALTER SEQUENCE payments_id_seq RESTART WITH 1;

SELECT 'Все счетчики ID сброшены' as status;

-- ==========================================
-- Проверка результатов
-- ==========================================

SELECT 'room_types' as table_name, COUNT(*) as count FROM room_types
UNION ALL
SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'guests', COUNT(*) FROM guests
UNION ALL
SELECT 'bookings', COUNT(*) FROM bookings
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'users', COUNT(*) FROM users;

SELECT '===== БАЗА ДАННЫХ ОЧИЩЕНА =====' as result;
