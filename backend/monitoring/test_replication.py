# Скрипт тестирования репликации PostgreSQL
# Вставляет тестовые данные на PRIMARY и проверяет их появление на STANDBY

import psycopg2
import time
from datetime import datetime

# Конфигурация подключения к PRIMARY серверу (мастер)
PRIMARY_CONFIG = {
    'host': '127.0.0.1',
    'port': 5432,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'postgres'
}

# Конфигурация подключения к STANDBY серверу (слейв/реплика)
STANDBY_CONFIG = {
    'host': '127.0.0.1',
    'port': 5433,
    'user': 'postgres',
    'password': 'postgres',
    'database': 'postgres'
}

def test_data_replication():
    """
    Тестирует работу репликации данных

    Процесс:
    1. Создает тестовую таблицу на PRIMARY (если её нет)
    2. Вставляет тестовую запись с текущим временем
    3. Ждет 2 секунды для репликации
    4. Проверяет наличие этой записи на STANDBY

    Возвращает:
        True если данные успешно реплицировались, False иначе
    """
    # Генерируем уникальное тестовое значение с временной меткой
    test_value = f"Test at {datetime.now()}"

    # ШАГ 1: Вставка данных на PRIMARY
    print(f"1. Вставка тестовых данных на PRIMARY...")
    primary_conn = psycopg2.connect(**PRIMARY_CONFIG)
    primary_cur = primary_conn.cursor()

    # Создаем тестовую таблицу, если её еще нет
    # IF NOT EXISTS - не выдаст ошибку, если таблица уже существует
    primary_cur.execute("""
        CREATE TABLE IF NOT EXISTS replication_test (
            id SERIAL PRIMARY KEY,              -- Автоинкрементный первичный ключ
            message TEXT,                        -- Тестовое сообщение
            created_at TIMESTAMP DEFAULT NOW()  -- Время создания записи
        );
    """)
    primary_conn.commit()

    # Вставляем тестовую запись и получаем её ID
    # RETURNING id - возвращает значение id вставленной записи
    primary_cur.execute("INSERT INTO replication_test (message) VALUES (%s) RETURNING id;", (test_value,))
    test_id = primary_cur.fetchone()[0]
    primary_conn.commit()
    print(f"   ✓ Вставлена запись с ID={test_id}")

    # Закрываем подключение к PRIMARY
    primary_cur.close()
    primary_conn.close()

    # ШАГ 2: Ожидание репликации
    # Даем время системе репликации передать данные на STANDBY
    print(f"\n2. Ожидание 2 секунды для репликации...")
    time.sleep(2)

    # ШАГ 3: Проверка данных на STANDBY
    print(f"\n3. Проверка данных на STANDBY...")
    standby_conn = psycopg2.connect(**STANDBY_CONFIG)
    standby_cur = standby_conn.cursor()

    # Ищем нашу тестовую запись по ID
    standby_cur.execute("SELECT message FROM replication_test WHERE id = %s;", (test_id,))
    result = standby_cur.fetchone()

    # Закрываем подключение к STANDBY
    standby_cur.close()
    standby_conn.close()

    # Проверяем результат
    if result and result[0] == test_value:
        # Данные найдены и совпадают - репликация работает!
        print(f"   ✓ УСПЕХ! Данные реплицировались корректно")
        print(f"   Найдено: {result[0]}")
        return True
    else:
        # Данные не найдены - проблема с репликацией
        print(f"   ✗ ОШИБКА! Данные не найдены на STANDBY")
        return False

# Точка входа в программу
if __name__ == '__main__':
    # Запускаем тест и выходим с кодом 0 при успехе, 1 при ошибке
    # Код возврата можно использовать в скриптах автоматизации
    success = test_data_replication()
    exit(0 if success else 1)
