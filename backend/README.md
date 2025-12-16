# Backend API - Система бронирования отелей

## Описание

RESTful API для управления системой бронирования отелей. Реализовано на FastAPI с использованием PostgreSQL в качестве СУБД.

## Возможности

- CRUD операции для всех сущностей (типы номеров, номера, гости, бронирования, платежи)
- Поиск свободных номеров по датам
- Фильтрация по статусам
- Пагинация результатов
- Автоматическая валидация данных
- Интерактивная документация API (Swagger UI)
- Защита от SQL-инъекций
- Русская локализация

## Стек технологий

- **FastAPI 0.104.1** - веб-фреймворк
- **SQLAlchemy 2.0.23** - ORM для работы с БД
- **PostgreSQL** - СУБД
- **Pydantic 2.5.0** - валидация данных
- **Uvicorn 0.24.0** - ASGI сервер
- **Alembic 1.12.1** - миграции БД

## Установка и запуск

### 1. Установка зависимостей

```bash
cd backend
pip install -r requirements.txt
```

### 2. Настройка БД

Создайте файл `.env` в папке `backend/app/`:

```env
DATABASE_URL=postgresql://postgres:ваш_пароль@localhost:5432/hotel_booking
```

### 3. Создание БД

Выполните SQL-скрипты из папки `database/`:

```bash
psql -U postgres
\i database/01_create_database.sql
\c hotel_booking
\i database/02_create_tables.sql
\i database/03_create_indexes.sql
\i database/04_seed_data.sql
\i database/05_roles_and_users.sql
```

### 4. Запуск сервера

```bash
uvicorn app.main:app --reload
```

API доступен по адресу: `http://localhost:8000`

## Документация

### Интерактивная документация

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Дополнительная документация

- [Инструкция по использованию API](../docs/04_api/api_guide.md)
- [Техническая документация](../docs/04_api/api_implementation.md)
- [Примеры запросов](../docs/04_api/api_testing.http)

## Структура проекта

```
backend/
├── app/
│   ├── __init__.py       # Инициализация пакета
│   ├── main.py           # Основной файл, эндпоинты
│   ├── models.py         # SQLAlchemy модели
│   ├── schemas.py        # Pydantic схемы
│   ├── crud.py           # CRUD операции
│   ├── database.py       # Подключение к БД
│   ├── deps.py           # Зависимости
│   └── .env              # Переменные окружения
├── alembic/              # Миграции
├── requirements.txt      # Зависимости
└── README.md
```

## Основные эндпоинты

### Типы номеров
- `GET /room-types/` - список типов номеров
- `GET /room-types/{id}` - получить тип номера
- `POST /room-types/` - создать тип номера
- `PUT /room-types/{id}` - обновить тип номера
- `DELETE /room-types/{id}` - удалить тип номера

### Номера
- `GET /rooms/` - список номеров
- `GET /rooms/{id}` - получить номер
- `POST /rooms/` - создать номер
- `PUT /rooms/{id}` - обновить номер
- `DELETE /rooms/{id}` - удалить номер
- `GET /rooms/available/` - свободные номера по датам

### Гости
- `GET /guests/` - список гостей
- `GET /guests/{id}` - получить гостя
- `POST /guests/` - создать гостя
- `PUT /guests/{id}` - обновить гостя
- `DELETE /guests/{id}` - удалить гостя

### Бронирования
- `GET /bookings/` - список бронирований
- `GET /bookings/{id}` - получить бронирование
- `POST /bookings/` - создать бронирование
- `PUT /bookings/{id}` - обновить бронирование
- `DELETE /bookings/{id}` - удалить бронирование

### Платежи
- `GET /payments/` - список платежей
- `GET /payments/{id}` - получить платеж
- `POST /payments/` - создать платеж
- `PUT /payments/{id}` - обновить платеж
- `DELETE /payments/{id}` - удалить платеж

## Примеры использования

### Создать гостя

```bash
curl -X POST http://localhost:8000/guests/ \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Иван",
    "last_name": "Иванов",
    "email": "ivan@example.com",
    "phone": "+79001234567"
  }'
```

### Найти свободные номера

```bash
curl "http://localhost:8000/rooms/available/?check_in=2024-02-01&check_out=2024-02-05"
```

### Создать бронирование

```bash
curl -X POST http://localhost:8000/bookings/ \
  -H "Content-Type: application/json" \
  -d '{
    "guest_id": 1,
    "room_id": 1,
    "check_in_date": "2024-02-01",
    "check_out_date": "2024-02-05",
    "total_price": 60000.00,
    "status": "ожидает"
  }'
```

## Статусы и значения

### Статусы номеров
- `свободно`
- `занято`
- `на тех. обслуживании`
- `зарезервировано`

### Статусы бронирований
- `ожидает`
- `подтверждено`
- `заселен`
- `выселен`
- `отменено`

### Методы оплаты
- `наличные`
- `кредитная карта`
- `дебетовая карта`
- `онлайн`

### Статусы платежей
- `ожидает`
- `завершен`
- `отклонен`
- `возврат`

## Разработка

### Миграции БД

Создать новую миграцию:
```bash
alembic revision --autogenerate -m "описание изменений"
```

Применить миграции:
```bash
alembic upgrade head
```

Откатить миграцию:
```bash
alembic downgrade -1
```

### Режим разработки

Запуск с автоперезагрузкой:
```bash
uvicorn app.main:app --reload --port 8000
```

### Логирование

Включить отладочные логи:
```bash
uvicorn app.main:app --reload --log-level debug
```

## Безопасность

- Все параметры запросов валидируются через Pydantic
- Используются параметризованные SQL-запросы (защита от SQL-инъекций)
- CORS настроен для работы с фронтендом
- Пароли хешируются через bcrypt
- Переменные окружения хранятся в .env (не коммитятся в Git)

## Решение проблем

### Ошибка подключения к БД

Проверьте:
1. PostgreSQL запущен
2. Правильный пароль в .env
3. База данных hotel_booking создана
4. Порт 5432 доступен

### Порт 8000 занят

Запустите на другом порту:
```bash
uvicorn app.main:app --reload --port 8001
```

### Ошибки импорта

Переустановите зависимости:
```bash
pip install -r requirements.txt --force-reinstall
```

## Требования

- Python 3.8+
- PostgreSQL 12+
- pip

## Автор

Проект выполнен в рамках учебного курса "Технологии разработки и защиты баз данных"

## Лицензия

MIT
