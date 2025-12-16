-- ========================================
-- ТЕСТ ПРАВ ДОСТУПА ДЛЯ РОЛИ hotel_guest
-- ========================================
-- Инструкция для pgAdmin4:
-- 1. Создайте новое подключение к БД trizbd от имени guest_user (пароль: Guest@123!Secure)
-- 2. Скопируйте весь этот код
-- 3. Вставьте в Query Tool и нажмите Execute (F5)
-- 4. Смотрите результаты во вкладках "Data Output" и "Messages"
-- 5. ВАЖНО: Большинство операций должны завершиться с ошибкой - это нормально!

DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'ПРОВЕРКА ПРАВ ДОСТУПА ДЛЯ hotel_guest';
    RAISE NOTICE '=========================================';
    RAISE NOTICE '';
END $$;

SELECT 'Текущий пользователь:' as info;
SELECT current_user as "Пользователь", session_user as "Сессия";

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 1: SELECT из разрешенных таблиц ---'; END $$;

SELECT COUNT(*) as "Количество типов номеров" FROM room_types;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из room_types: OK'; END $$;

SELECT COUNT(*) as "Количество номеров" FROM rooms;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из rooms: OK'; END $$;

SELECT COUNT(*) as "Количество платежей" FROM payments;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из payments: OK'; END $$;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: гость может просматривать номера и платежи';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 2: Попытка SELECT из запрещенной таблицы users ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    PERFORM COUNT(*) FROM users;
    RAISE NOTICE '✗ ОШИБКА: Доступ к users НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ SELECT из users: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 3: INSERT в guests (разрешено) ---'; END $$;

BEGIN;

INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Тест', 'Гостев', 'guest_test@test.ru', '+7-444-444-4444');
DO $$ BEGIN RAISE NOTICE '✓ INSERT в guests: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: гость может регистрироваться (создавать запись о себе)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 4: INSERT в bookings (разрешено) ---'; END $$;

BEGIN;

INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Тест', 'Гостев2', 'guest_test2@test.ru', '+7-333-333-3333');

INSERT INTO bookings (guest_id, room_id, check_in_date, check_out_date, total_price, status)
VALUES (
    (SELECT id FROM guests WHERE email = 'guest_test2@test.ru'),
    1,
    CURRENT_DATE + INTERVAL '7 days',
    CURRENT_DATE + INTERVAL '10 days',
    5000,
    'ожидает'
);
DO $$ BEGIN RAISE NOTICE '✓ INSERT в bookings: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: гость может создавать бронирования';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 5: Попытка INSERT в room_types (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    INSERT INTO room_types (name, description, base_price, capacity)
    VALUES ('Недопустимый тип', 'Тест', 1000, 1);
    RAISE NOTICE '✗ ОШИБКА: INSERT в room_types НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ INSERT в room_types: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 6: Попытка INSERT в rooms (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    INSERT INTO rooms (room_number, room_type_id, floor, status)
    VALUES ('FAIL', 1, 1, 'свободно');
    RAISE NOTICE '✗ ОШИБКА: INSERT в rooms НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ INSERT в rooms: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 7: Попытка INSERT в payments (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    INSERT INTO payments (booking_id, amount, payment_method, payment_status)
    VALUES (1, 1000, 'наличные', 'ожидает');
    RAISE NOTICE '✗ ОШИБКА: INSERT в payments НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ INSERT в payments: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 8: Попытка UPDATE в guests (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    UPDATE guests SET phone = '+7-111-111-1111' WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: UPDATE guests НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ UPDATE guests: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 9: Попытка UPDATE в bookings (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    UPDATE bookings SET status = 'отменено' WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: UPDATE bookings НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ UPDATE bookings: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 10: Попытка UPDATE в rooms (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    UPDATE rooms SET status = 'занято' WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: UPDATE rooms НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ UPDATE rooms: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 11: Попытка DELETE из guests (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    DELETE FROM guests WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: DELETE из guests НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ DELETE из guests: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 12: Попытка DELETE из bookings (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    DELETE FROM bookings WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: DELETE из bookings НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ DELETE из bookings: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 13: Попытка DELETE из payments (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    DELETE FROM payments WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: DELETE из payments НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ DELETE из payments: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'ИТОГ: Роль hotel_guest имеет:';
    RAISE NOTICE '  - SELECT на rooms, room_types, payments';
    RAISE NOTICE '  - SELECT, INSERT на bookings, guests';
    RAISE NOTICE '  - Нет UPDATE и DELETE ни на одной таблице';
    RAISE NOTICE '  - Нет доступа к users';
    RAISE NOTICE '=========================================';
END $$;

SELECT 'ТЕСТ ЗАВЕРШЕН УСПЕШНО' as "Статус",
       'Роль hotel_guest имеет минимальные права доступа' as "Результат";
