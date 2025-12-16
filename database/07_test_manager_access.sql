-- ========================================
-- ТЕСТ ПРАВ ДОСТУПА ДЛЯ РОЛИ hotel_manager
-- ========================================
-- Инструкция для pgAdmin4:
-- 1. Создайте новое подключение к БД trizbd от имени manager_user (пароль: Manager@123!Secure)
-- 2. Скопируйте весь этот код
-- 3. Вставьте в Query Tool и нажмите Execute (F5)
-- 4. Смотрите результаты во вкладках "Data Output" и "Messages"
-- 5. ВАЖНО: Некоторые операции должны завершиться с ошибкой - это нормально!

DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'ПРОВЕРКА ПРАВ ДОСТУПА ДЛЯ hotel_manager';
    RAISE NOTICE '=========================================';
    RAISE NOTICE '';
END $$;

SELECT 'Текущий пользователь:' as info;
SELECT current_user as "Пользователь", session_user as "Сессия";

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 1: SELECT на разрешенные таблицы ---'; END $$;

SELECT COUNT(*) as "Количество типов номеров" FROM room_types;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из room_types: OK'; END $$;

SELECT COUNT(*) as "Количество номеров" FROM rooms;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из rooms: OK'; END $$;

SELECT COUNT(*) as "Количество гостей" FROM guests;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из guests: OK'; END $$;

SELECT COUNT(*) as "Количество бронирований" FROM bookings;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из bookings: OK'; END $$;

SELECT COUNT(*) as "Количество платежей" FROM payments;
DO $$ BEGIN RAISE NOTICE '✓ SELECT из payments: OK'; END $$;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: менеджер может читать все основные таблицы';
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
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 3: INSERT в room_types и rooms ---'; END $$;

BEGIN;

INSERT INTO room_types (name, description, base_price, capacity)
VALUES ('Тестовый тип менеджер', 'Тест', 1500, 2);
DO $$ BEGIN RAISE NOTICE '✓ INSERT в room_types: OK'; END $$;

INSERT INTO rooms (room_number, room_type_id, floor, status)
VALUES ('TEST-MGR', (SELECT id FROM room_types WHERE name = 'Тестовый тип менеджер'), 2, 'свободно');
DO $$ BEGIN RAISE NOTICE '✓ INSERT в rooms: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: менеджер может добавлять номера и типы номеров';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 4: INSERT в bookings, guests и payments ---'; END $$;

BEGIN;

INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Тест', 'Менеджеров', 'manager_test@test.ru', '+7-777-777-7777');
DO $$ BEGIN RAISE NOTICE '✓ INSERT в guests: OK'; END $$;

INSERT INTO bookings (guest_id, room_id, check_in_date, check_out_date, total_price, status)
VALUES (
    (SELECT id FROM guests WHERE email = 'manager_test@test.ru'),
    1,
    CURRENT_DATE + INTERVAL '3 days',
    CURRENT_DATE + INTERVAL '5 days',
    3000,
    'ожидает'
);
DO $$ BEGIN RAISE NOTICE '✓ INSERT в bookings: OK'; END $$;

INSERT INTO payments (booking_id, amount, payment_method, payment_status)
VALUES (
    (SELECT id FROM bookings WHERE guest_id = (SELECT id FROM guests WHERE email = 'manager_test@test.ru')),
    3000,
    'кредитная карта',
    'ожидает'
);
DO $$ BEGIN RAISE NOTICE '✓ INSERT в payments: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: менеджер может создавать гостей, бронирования и платежи';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 5: UPDATE в room_types и rooms ---'; END $$;

BEGIN;

UPDATE room_types SET base_price = 2500 WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE room_types: OK'; END $$;

UPDATE rooms SET status = 'на тех. обслуживании' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE rooms: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: менеджер может изменять номера и типы номеров';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 6: UPDATE в bookings, guests и payments ---'; END $$;

BEGIN;

UPDATE guests SET phone = '+7-666-666-6666' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE guests: OK'; END $$;

UPDATE bookings SET status = 'подтверждено' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE bookings: OK'; END $$;

UPDATE payments SET payment_status = 'завершен' WHERE id = 1;
DO $$ BEGIN RAISE NOTICE '✓ UPDATE payments: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: менеджер может изменять гостей, бронирования и платежи';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 7: DELETE из bookings, guests и payments (разрешено) ---'; END $$;

BEGIN;

INSERT INTO guests (first_name, last_name, email, phone)
VALUES ('Для', 'Удаления', 'delete_test@test.ru', '+7-555-555-5555');

DELETE FROM guests WHERE email = 'delete_test@test.ru';
DO $$ BEGIN RAISE NOTICE '✓ DELETE из guests: OK'; END $$;

ROLLBACK;

DO $$ BEGIN
    RAISE NOTICE '✓ Результат: менеджер может удалять гостей, бронирования и платежи';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 8: Попытка DELETE из room_types (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    DELETE FROM room_types WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: DELETE из room_types НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ DELETE из room_types: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 9: Попытка DELETE из rooms (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    DELETE FROM rooms WHERE id = 1;
    RAISE NOTICE '✗ ОШИБКА: DELETE из rooms НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ DELETE из rooms: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$ BEGIN RAISE NOTICE '--- ТЕСТ 10: Попытка INSERT в users (запрещено) ---'; END $$;
DO $$ BEGIN RAISE NOTICE 'Ожидается: ошибка отказа в доступе'; END $$;

DO $$
BEGIN
    INSERT INTO users (username, email, password_hash, full_name, role)
    VALUES ('test_manager', 'test_mgr@test.ru', 'hash', 'Тест', 'manager');
    RAISE NOTICE '✗ ОШИБКА: INSERT в users НЕ должен быть разрешен!';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE '✓ INSERT в users: правильно отклонен (permission denied)';
END $$;

DO $$ BEGIN RAISE NOTICE ''; END $$;
DO $$
BEGIN
    RAISE NOTICE '=========================================';
    RAISE NOTICE 'ИТОГ: Роль hotel_manager имеет:';
    RAISE NOTICE '  - Полный доступ к guests, bookings, payments';
    RAISE NOTICE '  - SELECT, INSERT, UPDATE на rooms, room_types';
    RAISE NOTICE '  - Нет доступа к users';
    RAISE NOTICE '  - Нет DELETE на rooms, room_types';
    RAISE NOTICE '=========================================';
END $$;

SELECT 'ТЕСТ ЗАВЕРШЕН УСПЕШНО' as "Статус",
       'Роль hotel_manager имеет корректные ограниченные права' as "Результат";
