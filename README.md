# Система бронирования отелей (Hotel Booking System)

Учебный проект по дисциплине "Технологии разработки и защиты баз данных"

## Стек технологий

Backend
FastAPI - современный веб-фреймворк
SQLAlchemy - ORM для работы с БД
PostgreSQL - реляционная база данных
Pydantic - валидация данных
Alembic - миграции базы данных
Uvicorn - ASGI сервер
Frontend
Next.js 15 - React фреймворк с серверным рендерингом
TypeScript - типизированный JavaScript
Material-UI (MUI) - компоненты интерфейса
Axios - HTTP клиент
Tailwind CSS - утилитарные стили

## Структура проекта

```continue
TRiZBD_UP/
├── docs/                          # Документация
│   ├── 00_tech_stack.md           # Стек технологий
│   ├── 01_business_analysis.md    # Анализ предметной области
│   ├── 02_er_diagram.md           # ER-диаграмма (нотация Чена)
│   ├── 03_data_diagram.md         # Диаграмма данных
│   └── 04_normalization.md        # Нормализация до 3НФ
│
├── database/                      # SQL-скрипты
│   ├── 01_create_database.sql     # Создание БД
│   ├── 02_create_tables.sql       # Создание таблиц
│   ├── 03_create_indexes.sql      # Индексы
│   ├── 04_seed_data.sql           # Тестовые данные
│   └── 05_roles_and_users.sql     # Роли и пользователи
│
├── backend/                       # API (будет создано)
├── frontend/                      # Веб-интерфейс (будет создано)
├── tests/                         # Тесты (будет создано)
└── README.md
```

## Быстрый старт

### 1. Создание базы данных

```bash
# Подключение к PostgreSQL
psql -U postgres

# Выполнение скриптов по порядку
\i database/01_create_database.sql
\c hotel_booking
\i database/02_create_tables.sql
\i database/03_create_indexes.sql
\i database/04_seed_data.sql
\i database/05_roles_and_users.sql
```

### 2. Проверка подключения

```bash
# Подключение под разными пользователями
psql -U admin_user -d hotel_booking
psql -U manager_user -d hotel_booking
psql -U guest_user -d hotel_booking
```

## Сущности базы данных

| Сущность | Описание |
|----------|----------|
| room_types | Типы номеров (Стандарт, Люкс и т.д.) |
| rooms | Номера отеля |
| guests | Гости (клиенты) |
| bookings | Бронирования |
| payments | Платежи |
| users | Персонал (admin, manager) |

## Роли и привилегии

| Роль | Описание | Доступ |
|------|----------|--------|
| hotel_admin | Администратор | Полный доступ ко всем таблицам |
| hotel_manager | Менеджер | Управление бронированиями, гостями, платежами |
| hotel_guest | Гость | Просмотр номеров, создание бронирований |

## Тестовые пользователи

| Пользователь | Пароль | Роль |
|--------------|--------|------|
| admin_user | Admin@123!Secure | hotel_admin |
| manager_user | Manager@123!Secure | hotel_manager |
| guest_user | Guest@123!Secure | hotel_guest |

## Прогресс выполнения

- [x] Часть 1.1: Анализ предметной области
- [x] Часть 1.2: ER-диаграмма и диаграмма данных
- [x] Часть 1.3: Нормализация до 3НФ
- [x] Часть 1.4: SQL-скрипты создания БД
- [x] Часть 1.5: Роли и привилегии
- [x] Часть 3: Разработка API (CRUD для всех сущностей)
- [ ] Часть 2.2: Аутентификация и авторизация
- [ ] Часть 2.3: Frontend
- [ ] Часть 2.4: Тестирование

## Автор

Студент группы _____
Специальность 09.02.07
