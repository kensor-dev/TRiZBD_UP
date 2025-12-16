# Быстрая инструкция по миграции БД trizbd

## Шаг 1: Откройте pgAdmin4
Запустите pgAdmin4 и подключитесь к серверу PostgreSQL

## Шаг 2: Откройте Query Tool
Правой кнопкой на "PostgreSQL" → "Query Tool"

## Шаг 3: Выполните скрипты по порядку

### Скрипт 1: Создание базы данных
```sql
-- Скопируйте содержимое файла 01_create_database.sql
-- Нажмите F5 для выполнения
```

### Скрипт 2: Подключитесь к новой БД
- Найдите "trizbd" в списке баз данных
- Правой кнопкой → "Query Tool"

### Скрипт 3: Создание таблиц
```sql
-- Скопируйте содержимое файла 02_create_tables.sql
-- Нажмите F5
```

### Скрипт 4: Создание индексов
```sql
-- Скопируйте содержимое файла 03_create_indexes.sql
-- Нажмите F5
```

### Скрипт 5: Заполнение данными
```sql
-- Скопируйте содержимое файла 04_seed_data.sql
-- Нажмите F5
```

### Скрипт 6: Роли и пользователи
```sql
-- Скопируйте содержимое файла 05_roles_and_users.sql
-- Нажмите F5
```

## Шаг 4: Проверка
```sql
-- Проверка таблиц
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Проверка данных
SELECT COUNT(*) FROM room_types;  -- должно быть 5
SELECT COUNT(*) FROM rooms;       -- должно быть 10
SELECT COUNT(*) FROM guests;      -- должно быть 6
SELECT COUNT(*) FROM bookings;    -- должно быть 6
```

## Шаг 5: Запуск backend
```bash
cd C:/Users/Public/projects/TRiZBD_UP/backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Готово!
API доступно по адресу: http://localhost:8000
Документация: http://localhost:8000/docs

---

## Учетные данные

### Пользователи БД:
- **admin_user**: Admin@123!Secure (полный доступ)
- **manager_user**: Manager@123!Secure (управление бронированиями)
- **guest_user**: Guest@123!Secure (просмотр и создание бронирований)

### Подключение:
- База данных: **trizbd**
- Хост: **localhost**
- Порт: **5432**
- Пользователь: **postgres**
