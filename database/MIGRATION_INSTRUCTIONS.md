# Инструкция по миграции базы данных в pgAdmin4

## Предварительные требования

1. Установленный PostgreSQL (версия 12 или выше)
2. Установленный pgAdmin4
3. Пользователь postgres с правами администратора

## Данные для подключения

- **Хост**: localhost
- **Порт**: 5432
- **Пользователь**: postgres
- **Пароль**: ваш пароль для пользователя postgres
- **База данных**: trizbd (будет создана в процессе)

## Шаги выполнения миграции

### Шаг 1: Запуск pgAdmin4

1. Откройте pgAdmin4
2. В левой панели найдите "Servers" → "PostgreSQL"
3. Подключитесь к серверу (введите пароль пользователя postgres)

### Шаг 2: Создание базы данных

**Вариант A: Через Query Tool**

1. Правой кнопкой мыши на "PostgreSQL" → выберите "Query Tool"
2. Откройте файл `01_create_database.sql` в любом текстовом редакторе
3. Скопируйте содержимое и вставьте в Query Tool
4. Нажмите F5 или кнопку "Execute/Refresh" (▶)
5. Должно появиться сообщение: "CREATE DATABASE Query returned successfully"

**Вариант B: Через графический интерфейс**

1. Правой кнопкой мыши на "Databases" → "Create" → "Database..."
2. В поле "Database" введите: `trizbd`
3. Владелец (Owner): `postgres`
4. Encoding: `UTF8`
5. Нажмите "Save"

### Шаг 3: Подключение к новой базе данных

1. В левой панели разверните "Databases"
2. Найдите базу данных "trizbd"
3. Правой кнопкой мыши на "trizbd" → "Query Tool"

### Шаг 4: Создание таблиц

1. В открывшемся Query Tool откройте файл `02_create_tables.sql`
2. Скопируйте всё содержимое файла
3. Вставьте в Query Tool
4. Нажмите F5 для выполнения
5. Проверьте, что все 6 таблиц созданы:
   - room_types
   - rooms
   - guests
   - bookings
   - payments
   - users

**Проверка таблиц:**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### Шаг 5: Создание индексов

1. Откройте новый Query Tool (File → New Query Tool)
2. Откройте файл `03_create_indexes.sql`
3. Скопируйте содержимое и вставьте в Query Tool
4. Нажмите F5 для выполнения

**Проверка индексов:**
```sql
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

### Шаг 6: Заполнение тестовыми данными

1. Откройте файл `04_seed_data.sql`
2. Скопируйте содержимое и вставьте в Query Tool
3. Нажмите F5 для выполнения

**Проверка данных:**
```sql
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
```

Должно получиться:
- room_types: 5 записей
- rooms: 10 записей
- guests: 6 записей
- bookings: 6 записей
- payments: 6 записей
- users: 4 записи

### Шаг 7: Создание ролей и пользователей

1. Откройте файл `05_roles_and_users.sql`
2. Скопируйте содержимое и вставьте в Query Tool
3. Нажмите F5 для выполнения

**Проверка ролей:**
```sql
SELECT rolname FROM pg_roles 
WHERE rolname IN ('hotel_admin', 'hotel_manager', 'hotel_guest');
```

**Проверка пользователей:**
```sql
SELECT usename FROM pg_user 
WHERE usename IN ('admin_user', 'manager_user', 'guest_user');
```

### Шаг 8: Проверка привилегий

**Проверка привилегий роли hotel_admin:**
```sql
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'hotel_admin'
ORDER BY table_name;
```

**Проверка привилегий роли hotel_manager:**
```sql
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'hotel_manager'
ORDER BY table_name;
```

**Проверка привилегий роли hotel_guest:**
```sql
SELECT grantee, privilege_type, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'hotel_guest'
ORDER BY table_name;
```

## Тестирование подключения под разными пользователями

### Тест 1: Подключение от имени admin_user

1. В pgAdmin4 создайте новое подключение: Servers → Create → Server
2. Вкладка "General": Name = "trizbd_Admin"
3. Вкладка "Connection":
   - Host: localhost
   - Port: 5432
   - Database: trizbd
   - Username: admin_user
   - Password: Admin@123!Secure
4. Сохраните и подключитесь
5. Проверьте, что доступны все операции

### Тест 2: Подключение от имени manager_user

1. Создайте новое подключение: Name = "trizbd_Manager"
2. Username: manager_user, Password: Manager@123!Secure
3. Проверьте доступ к таблицам bookings, guests, payments

### Тест 3: Подключение от имени guest_user

1. Создайте новое подключение: Name = "trizbd_Guest"
2. Username: guest_user, Password: Guest@123!Secure
3. Проверьте, что доступен только SELECT для rooms и room_types

## Возможные ошибки и решения

### Ошибка: "database already exists"
**Решение**: Удалите существующую базу:
```sql
DROP DATABASE IF EXISTS trizbd;
```

### Ошибка: "role already exists"
**Решение**: Скрипт 05_roles_and_users.sql уже содержит `DROP ROLE IF EXISTS`

### Ошибка: "permission denied"
**Решение**: Убедитесь, что вы подключены от имени пользователя postgres

### Ошибка при создании ролей через Query Tool
**Решение**: Попробуйте выполнять команды по одной, а не весь скрипт сразу

## После успешной миграции

1. База данных trizbd создана и заполнена тестовыми данными
2. Созданы 3 роли с разными уровнями доступа
3. Созданы 3 тестовых пользователя
4. Можно переходить к запуску backend API

Для запуска backend:
```bash
cd C:/Users/Public/projects/trizbd_UP/backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API будет доступно по адресу: http://localhost:8000
Документация API: http://localhost:8000/docs
