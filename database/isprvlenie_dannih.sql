-- ==========================================
-- Скрипт исправления данных
-- Перевод статусов на русский язык и обновление дат
-- ==========================================

-- ==========================================
-- ШАГ 1: Удаление старых CHECK ограничений
-- ==========================================

-- Удаление ограничения на статус номеров
ALTER TABLE rooms DROP CONSTRAINT IF EXISTS rooms_status_check;

-- Удаление ограничения на статус бронирований
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

-- Удаление ограничения на статус платежей
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_payment_status_check;

-- Удаление ограничения на метод оплаты
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_payment_method_check;

-- ==========================================
-- ШАГ 2: Обновление статусов номеров (rooms.status)
-- ==========================================

UPDATE rooms SET status = 'свободно' WHERE status = 'available';
UPDATE rooms SET status = 'занято' WHERE status = 'occupied';
UPDATE rooms SET status = 'зарезервировано' WHERE status = 'reserved';
UPDATE rooms SET status = 'на тех. обслуживании' WHERE status = 'maintenance';

-- ==========================================
-- ШАГ 3: Обновление статусов бронирований (bookings.status)
-- ==========================================

UPDATE bookings SET status = 'заселен' WHERE status = 'checked_in';
UPDATE bookings SET status = 'подтверждено' WHERE status = 'confirmed';
UPDATE bookings SET status = 'выселен' WHERE status = 'checked_out';
UPDATE bookings SET status = 'ожидает' WHERE status = 'pending';
UPDATE bookings SET status = 'отменено' WHERE status = 'cancelled';

-- ==========================================
-- ШАГ 4: Обновление статусов платежей (payments.payment_status)
-- ==========================================

UPDATE payments SET payment_status = 'завершен' WHERE payment_status = 'completed';
UPDATE payments SET payment_status = 'ожидает' WHERE payment_status = 'pending';
UPDATE payments SET payment_status = 'отклонен' WHERE payment_status = 'failed';
UPDATE payments SET payment_status = 'возврат' WHERE payment_status = 'refunded';

-- ==========================================
-- ШАГ 5: Обновление методов оплаты (payments.payment_method)
-- ==========================================

UPDATE payments SET payment_method = 'кредитная карта' WHERE payment_method = 'credit_card';
UPDATE payments SET payment_method = 'дебетовая карта' WHERE payment_method = 'debit_card';
UPDATE payments SET payment_method = 'наличные' WHERE payment_method = 'cash';
UPDATE payments SET payment_method = 'онлайн' WHERE payment_method = 'online';

-- ==========================================
-- ШАГ 6: Создание новых CHECK ограничений с русскими значениями
-- ==========================================

-- Новое ограничение для статуса номеров
ALTER TABLE rooms 
ADD CONSTRAINT rooms_status_check 
CHECK (status IN ('свободно', 'занято', 'зарезервировано', 'на тех. обслуживании'));

-- Новое ограничение для статуса бронирований
ALTER TABLE bookings 
ADD CONSTRAINT bookings_status_check 
CHECK (status IN ('ожидает', 'подтверждено', 'заселен', 'выселен', 'отменено'));

-- Новое ограничение для статуса платежей
ALTER TABLE payments 
ADD CONSTRAINT payments_payment_status_check 
CHECK (payment_status IN ('ожидает', 'завершен', 'отклонен', 'возврат'));

-- Новое ограничение для метода оплаты
ALTER TABLE payments 
ADD CONSTRAINT payments_payment_method_check 
CHECK (payment_method IN ('наличные', 'кредитная карта', 'дебетовая карта', 'онлайн'));

-- ==========================================
-- ШАГ 7: Обновление значений по умолчанию
-- ==========================================

-- Изменение DEFAULT для статуса номеров
ALTER TABLE rooms ALTER COLUMN status SET DEFAULT 'свободно';

-- Изменение DEFAULT для статуса бронирований
ALTER TABLE bookings ALTER COLUMN status SET DEFAULT 'ожидает';

-- Изменение DEFAULT для статуса платежей
ALTER TABLE payments ALTER COLUMN payment_status SET DEFAULT 'ожидает';

-- ==========================================
-- ШАГ 8: Обновление дат с 2024 на 2025 год
-- ==========================================

-- Обновление дат заезда и выезда в бронированиях
UPDATE bookings 
SET check_in_date = check_in_date + INTERVAL '1 year'
WHERE EXTRACT(YEAR FROM check_in_date) = 2024;

UPDATE bookings 
SET check_out_date = check_out_date + INTERVAL '1 year'
WHERE EXTRACT(YEAR FROM check_out_date) = 2024;

-- Обновление дат платежей
UPDATE payments 
SET payment_date = payment_date + INTERVAL '1 year'
WHERE payment_date IS NOT NULL 
  AND EXTRACT(YEAR FROM payment_date) = 2024;

-- Обновление ID транзакций (замена 2024 на 2025 в TXN)
UPDATE payments 
SET transaction_id = REPLACE(transaction_id, 'TXN2024', 'TXN2025')
WHERE transaction_id LIKE 'TXN2024%';

-- ==========================================
-- Проверка результатов обновления
-- ==========================================

-- Проверка статусов номеров
SELECT 'Статусы номеров:' as info;
SELECT DISTINCT status, COUNT(*) as count FROM rooms GROUP BY status;

-- Проверка статусов бронирований
SELECT 'Статусы бронирований:' as info;
SELECT DISTINCT status, COUNT(*) as count FROM bookings GROUP BY status;

-- Проверка статусов платежей
SELECT 'Статусы платежей:' as info;
SELECT DISTINCT payment_status, COUNT(*) as count FROM payments GROUP BY payment_status;

-- Проверка методов оплаты
SELECT 'Методы оплаты:' as info;
SELECT DISTINCT payment_method, COUNT(*) as count FROM payments GROUP BY payment_method;

-- Проверка дат бронирований
SELECT 'Даты бронирований:' as info;
SELECT MIN(check_in_date) as min_date, MAX(check_out_date) as max_date FROM bookings;

-- Проверка ID транзакций
SELECT 'ID транзакций:' as info;
SELECT transaction_id FROM payments WHERE transaction_id IS NOT NULL;
