-- Удаление существующих ролей (если есть)
-- Обеспечивает чистое создание ролей при повторном запуске скрипта
DROP ROLE IF EXISTS hotel_admin;
DROP ROLE IF EXISTS hotel_manager;
DROP ROLE IF EXISTS hotel_guest;

-- Создание ролей
-- Три основные роли с различным уровнем доступа
CREATE ROLE hotel_admin;
CREATE ROLE hotel_manager;
CREATE ROLE hotel_guest;

-- Привилегии для роли администратора
-- Полный доступ ко всем объектам базы данных
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hotel_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hotel_admin;
GRANT ALL PRIVILEGES ON DATABASE trizbd TO hotel_admin;

-- Привилегии для роли менеджера
-- Управление номерами и полный доступ к бронированиям, платежам и гостям
GRANT SELECT, INSERT, UPDATE ON rooms, room_types TO hotel_manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON bookings, payments, guests TO hotel_manager;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hotel_manager;

-- Привилегии для роли гостя
-- Просмотр номеров, создание бронирований и просмотр своих платежей
GRANT SELECT ON rooms, room_types TO hotel_guest;
GRANT SELECT, INSERT ON bookings, guests TO hotel_guest;
GRANT SELECT ON payments TO hotel_guest;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hotel_guest;

-- Удаление существующих пользователей (если есть)
-- Обеспечивает чистое создание пользователей при повторном запуске скрипта
DROP USER IF EXISTS admin_user;
DROP USER IF EXISTS manager_user;
DROP USER IF EXISTS guest_user;

-- Создание пользователей с паролями
-- Тестовые учетные записи для каждой роли
CREATE USER admin_user WITH PASSWORD 'Admin@123!Secure';
CREATE USER manager_user WITH PASSWORD 'Manager@123!Secure';
CREATE USER guest_user WITH PASSWORD 'Guest@123!Secure';

-- Назначение ролей пользователям
-- Связывание созданных пользователей с соответствующими ролями
GRANT hotel_admin TO admin_user;
GRANT hotel_manager TO manager_user;
GRANT hotel_guest TO guest_user;

-- Настройка схемы по умолчанию
-- Установка public как схемы по умолчанию для удобства работы
ALTER USER admin_user SET search_path TO public;
ALTER USER manager_user SET search_path TO public;
ALTER USER guest_user SET search_path TO public;
