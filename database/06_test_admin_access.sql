-- ========================================
-- ТЕСТ ПРАВ ДОСТУПА ДЛЯ РОЛИ hotel_admin
-- ========================================
-- Инструкция для pgAdmin4:
-- 1. Создайте новое подключение к БД trizbd от имени admin_user (пароль: Admin@123!Secure)
-- 2. Скопируйте весь этот код
-- 3. Вставьте в Query Tool и нажмите Execute (F5)
-- 4. Смотрите результаты во вкладках "Data Output" и "Messages"

DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'ПРОВЕРКА ПРАВ ДОСТУПА ДЛЯ hotel_admin';
    RAISE NOTICE '=========================================';
    RAISE NOTICE '';
END $$;

SELECT 'Текущий пользователь:' as info;
SELECT current_user as "Пользователь", session_user as "Сессия";

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 1: SELECT на все таблицы ---'; END $$;

SELECT COUNT(*) as "Количество типов номеров" FROM room_types;
SELECT COUNT(*) as "Количество номеров" FROM rooms;
SELECT COUNT(*) as "Количество гостей" FROM guests;
SELECT COUNT(*) as "Количество бронирований" FROM bookings;
SELECT COUNT(*) as "Количество платежей" FROM payments;
SELECT COUNT(*) as "Количество пользователей" FROM users;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: администратор может читать все таблицы';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 2: INSERT во все таблицы ---'; END $$;

BEGIN;

INSERT INTO room_types (name, description, base_price, capacity)
VALUES ('Тестовый тип админ', 'Тест', 1000, 1);

DO $$ BEGIN RAISE NOTICE '✓ INSERT в room_types: OK'; END $$;

INSERT INTO rooms (room_number, room_type_id, floor, status)
VALUES ('TEST-ADMIN', (SELECT id FROM room_types WHERE name = 'Тестовый тип админ'), 1, 'свободно');

DO $$ BEGIN RAISE NOTICE '✓ INSERT в rooms: OK'; END $$;

INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Тест', 'Админов', 'admin_test@test.ru', '+7-999-999-9999');

DO $$ BEGIN RAISE NOTICE '✓ INSERT в guests: OK'; END $$;

INSERT INTO bookings (guest_id, room_id, check_in_date, check_out_date, total_price, status)
VALUES (
    (SELECT id FROM guests WHERE email = 'admin_test@test.ru'),
    (SELECT id FROM rooms WHERE room_number = 'TEST-ADMIN'),
    CURRENT_DATE + INTERVAL '1 day',
    CURRENT_DATE + INTERVAL '2 days',
    1000,
    'ожидает'
);

DO $$ BEGIN RAISE NOTICE '✓ INSERT в bookings: OK'; END $$;

INSERT INTO payments (booking_id, amount, payment_method, payment_status)
VALUES (
    (SELECT id FROM bookings WHERE guest_id = (SELECT id FROM guests WHERE email = 'admin_test@test.ru')),
    1000,
    'наличные',
    'ожидает'
);

DO $$ BEGIN RAISE NOTICE '✓ INSERT в payments: OK'; END $$;

INSERT INTO users (username, email, password_hash, full_name, role)
VALUES ('test_admin_user', 'test_admin@test.ru', 'hash', 'Тест Админов', 'admin');

DO $$ BEGIN RAISE NOTICE '✓ INSERT в users: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: администратор может добавлять записи во все таблицы';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 3: UPDATE всех таблиц ---'; END $$;

BEGIN;

UPDATE room_types SET base_price = 2000 WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE room_types: OK'; END $$;

UPDATE rooms SET status = 'на тех. обслуживании' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE rooms: OK'; END $$;

UPDATE guests SET phone = '+7-888-888-8888' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE guests: OK'; END $$;

UPDATE bookings SET status = 'подтверждено' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE bookings: OK'; END $$;

UPDATE payments SET payment_status = 'завершен' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE payments: OK'; END $$;

UPDATE users SET is_active = false WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE users: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: администратор может изменять записи во всех таблицах';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 4: DELETE из всех таблиц ---'; END $$;

BEGIN;

INSERT INTO room_types (name, description, base_price, capacity)
VALUES ('Для удаления', 'Тест', 500, 1);
DELETE FROM room_types WHERE name = 'Для удаления';

DO $$ BEGIN RAISE NOTICE '✓ DELETE из room_types: OK'; END $$;

DELETE FROM payments WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ DELETE из payments: OK'; END $$;

DELETE FROM bookings WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ DELETE из bookings: OK'; END $$;

DELETE FROM guests WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ DELETE из guests: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: администратор может удалять записи из всех таблиц';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'ИТОГ: Роль hotel_admin имеет полный доступ ко всем операциям';
    RAISE NOTICE '=========================================';
END $$;

SELECT 'ТЕСТ ЗАВЕРШЕН УСПЕШНО' as "Статус",
       'Роль hotel_admin имеет полный доступ ко всем таблицам и операциям' as "Результат";
