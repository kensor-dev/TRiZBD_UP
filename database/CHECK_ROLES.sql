-- Проверка созданных ролей
SELECT 
    rolname as "Роль",
    rolcanlogin as "Может входить",
    rolsuper as "Суперпользователь"
FROM pg_roles 
WHERE rolname IN ('hotel_admin', 'hotel_manager', 'hotel_guest', 'admin_user', 'manager_user', 'guest_user')
ORDER BY rolname;

-- Проверка привилегий роли hotel_admin
SELECT 
    'hotel_admin' as "Роль",
    table_name as "Таблица",
    privilege_type as "Привилегия"
FROM information_schema.role_table_grants
WHERE grantee = 'hotel_admin'
ORDER BY table_name, privilege_type;

-- Проверка привилегий роли hotel_manager
SELECT 
    'hotel_manager' as "Роль",
    table_name as "Таблица",
    privilege_type as "Привилегия"
FROM information_schema.role_table_grants
WHERE grantee = 'hotel_manager'
ORDER BY table_name, privilege_type;

-- Проверка привилегий роли hotel_guest
SELECT 
    'hotel_guest' as "Роль",
    table_name as "Таблица",
    privilege_type as "Привилегия"
FROM information_schema.role_table_grants
WHERE grantee = 'hotel_guest'
ORDER BY table_name, privilege_type;

-- Проверка назначения ролей пользователям
SELECT 
    r.rolname as "Пользователь", 
    m.rolname as "Назначенная роль"
FROM pg_roles r
JOIN pg_auth_members am ON r.oid = am.member
JOIN pg_roles m ON am.roleid = m.oid
WHERE r.rolname IN ('admin_user', 'manager_user', 'guest_user')
ORDER BY r.rolname;
