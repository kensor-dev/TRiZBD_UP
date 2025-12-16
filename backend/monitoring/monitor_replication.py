# Скрипт мониторинга репликации PostgreSQL
# Проверяет состояние PRIMARY и STANDBY серверов, отображает метрики репликации

import psycopg2
from datetime import datetime
import time
import sys

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

def check_primary_replication():
    """
    Проверяет состояние репликации на PRIMARY сервере

    Возвращает словарь с информацией о подключенных репликах:
    - status: OK/ERROR
    - message: описание статуса
    - replicas: список подключенных реплик с их метриками
    """
    try:
        # Подключаемся к PRIMARY серверу
        conn = psycopg2.connect(**PRIMARY_CONFIG)
        cur = conn.cursor()

        # Запрашиваем статус репликации из системной таблицы pg_stat_replication
        # Эта таблица показывает все активные подключения для репликации
        cur.execute("""
            SELECT
                client_addr,                                        -- IP-адрес подключенной реплики
                state,                                              -- Состояние (streaming, catchup, etc)
                sent_lsn,                                           -- LSN отправленных данных
                write_lsn,                                          -- LSN записанных данных
                flush_lsn,                                          -- LSN сброшенных на диск данных
                replay_lsn,                                         -- LSN примененных данных
                sync_state,                                         -- Режим синхронизации (async/sync)
                pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes -- Отставание в байтах
            FROM pg_stat_replication;
        """)

        results = cur.fetchall()

        # Если нет активных подключений - это ошибка
        if not results:
            return {
                'status': 'ERROR',
                'message': 'Нет активных подключений репликации',
                'replicas': []
            }

        # Формируем список реплик с их метриками
        replicas = []
        for row in results:
            replicas.append({
                'client_addr': row[0],      # IP-адрес реплики
                'state': row[1],            # Состояние подключения
                'sent_lsn': row[2],         # Отправлено до позиции LSN
                'write_lsn': row[3],        # Записано до позиции LSN
                'flush_lsn': row[4],        # Сброшено на диск до позиции LSN
                'replay_lsn': row[5],       # Применено до позиции LSN
                'sync_state': row[6],       # async - асинхронная, sync - синхронная
                'lag_bytes': row[7] if row[7] is not None else 0  # Отставание в байтах
            })

        cur.close()
        conn.close()

        return {
            'status': 'OK',
            'message': f'Найдено {len(replicas)} активных реплик',
            'replicas': replicas
        }

    except Exception as e:
        # Если не удалось подключиться к PRIMARY - возвращаем ошибку
        return {
            'status': 'ERROR',
            'message': f'Ошибка подключения к PRIMARY: {str(e)}',
            'replicas': []
        }

def check_standby_status():
    """
    Проверяет состояние STANDBY сервера

    Возвращает словарь с информацией о состоянии реплики:
    - status: OK/ERROR/WARNING
    - message: описание статуса
    - is_recovery: находится ли в режиме восстановления
    - wal_receiver: информация о приемнике WAL-логов
    - lag_seconds: задержка репликации в секундах
    """
    try:
        # Подключаемся к STANDBY серверу
        conn = psycopg2.connect(**STANDBY_CONFIG)
        cur = conn.cursor()

        # Проверяем, находится ли сервер в режиме восстановления (recovery)
        # Standby всегда должен быть в recovery mode
        cur.execute("SELECT pg_is_in_recovery();")
        is_recovery = cur.fetchone()[0]

        if not is_recovery:
            # Если standby НЕ в режиме восстановления - это проблема
            return {
                'status': 'WARNING',
                'message': 'Standby НЕ в режиме восстановления!',
                'is_recovery': False
            }

        # Запрашиваем статус WAL receiver - процесса, принимающего WAL-логи с мастера
        cur.execute("""
            SELECT
                status,                 -- Статус receiver (streaming, stopped, etc)
                latest_end_lsn,         -- Последняя полученная позиция LSN
                last_msg_send_time,     -- Время последней отправки со стороны мастера
                last_msg_receipt_time   -- Время последнего получения на standby
            FROM pg_stat_wal_receiver;
        """)

        wal_receiver = cur.fetchone()

        if not wal_receiver:
            # Если WAL receiver не активен - standby не получает данные
            return {
                'status': 'ERROR',
                'message': 'WAL receiver не активен',
                'is_recovery': True,
                'wal_receiver': None
            }

        # Вычисляем задержку репликации в секундах
        # pg_last_xact_replay_timestamp() - время последней примененной транзакции
        # Разница с now() показывает, насколько standby отстает от реального времени
        cur.execute("""
            SELECT
                EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds;
        """)

        lag_result = cur.fetchone()
        lag_seconds = lag_result[0] if lag_result[0] is not None else 0

        cur.close()
        conn.close()

        return {
            'status': 'OK',
            'message': 'Standby работает нормально',
            'is_recovery': True,
            'wal_receiver': {
                'status': wal_receiver[0],
                'received_lsn': wal_receiver[1],
                'last_msg_send_time': wal_receiver[2],
                'last_msg_receipt_time': wal_receiver[3]
            },
            'lag_seconds': lag_seconds
        }

    except Exception as e:
        # Если не удалось подключиться к STANDBY - возвращаем ошибку
        return {
            'status': 'ERROR',
            'message': f'Ошибка подключения к STANDBY: {str(e)}',
            'is_recovery': None
        }

def print_report(primary_status, standby_status):
    """
    Выводит форматированный отчет о состоянии репликации

    Аргументы:
        primary_status: результат check_primary_replication()
        standby_status: результат check_standby_status()

    Возвращает:
        True если все в порядке, False если есть проблемы
    """
    # Печатаем заголовок отчета
    print("\n" + "="*70)
    print(f"  ОТЧЁТ О РЕПЛИКАЦИИ - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*70)

    # Информация о PRIMARY сервере
    print(f"\n[PRIMARY SERVER] {PRIMARY_CONFIG['host']}:{PRIMARY_CONFIG['port']}")
    print(f"  Статус: {primary_status['status']}")
    print(f"  {primary_status['message']}")

    # Если есть активные реплики - показываем детали по каждой
    if primary_status['replicas']:
        for i, replica in enumerate(primary_status['replicas'], 1):
            print(f"\n  Реплика #{i}:")
            print(f"    IP: {replica['client_addr']}")
            print(f"    Состояние: {replica['state']}")  # streaming = активная передача
            print(f"    Режим: {replica['sync_state']}")  # async = асинхронная
            print(f"    Отставание: {replica['lag_bytes']} байт")

    # Информация о STANDBY сервере
    print(f"\n[STANDBY SERVER] {STANDBY_CONFIG['host']}:{STANDBY_CONFIG['port']}")
    print(f"  Статус: {standby_status['status']}")
    print(f"  {standby_status['message']}")

    # Детальная информация о standby (если он в recovery mode)
    if standby_status.get('is_recovery'):
        print(f"  Режим восстановления: ДА")

        # Информация о WAL receiver
        if standby_status.get('wal_receiver'):
            wal = standby_status['wal_receiver']
            print(f"  WAL Receiver: {wal['status']}")
            print(f"  Последний LSN: {wal['received_lsn']}")
            print(f"  Последнее сообщение: {wal['last_msg_receipt_time']}")

        # Показываем задержку репликации и оцениваем её
        if standby_status.get('lag_seconds') is not None:
            lag = standby_status['lag_seconds']
            print(f"  Задержка репликации: {lag:.2f} секунд")

            # Оценка задержки
            if lag < 1:
                print(f"    ✓ Отличная синхронизация!")
            elif lag < 5:
                print(f"    ⚠ Небольшая задержка")
            else:
                print(f"    ✗ ВНИМАНИЕ: Большая задержка!")

    # Определяем общий статус системы
    overall_status = "OK" if (primary_status['status'] == 'OK' and standby_status['status'] == 'OK') else "ПРОБЛЕМА"

    print("\n" + "="*70)
    print(f"  ОБЩИЙ СТАТУС: {overall_status}")
    print("="*70 + "\n")

    return overall_status == "OK"

def monitor_loop(interval=10):
    """
    Запускает непрерывный мониторинг с заданным интервалом

    Аргументы:
        interval: интервал между проверками в секундах (по умолчанию 10)
    """
    print("Запуск мониторинга репликации...")
    print(f"Проверка каждые {interval} секунд. Нажмите Ctrl+C для выхода.\n")

    try:
        while True:
            # Проверяем оба сервера
            primary_status = check_primary_replication()
            standby_status = check_standby_status()

            # Выводим отчет
            is_healthy = print_report(primary_status, standby_status)

            # Если есть проблемы - выводим предупреждение
            if not is_healthy:
                print("⚠ ОБНАРУЖЕНЫ ПРОБЛЕМЫ С РЕПЛИКАЦИЕЙ!")

            # Ждем перед следующей проверкой
            time.sleep(interval)

    except KeyboardInterrupt:
        # Обрабатываем Ctrl+C для корректного выхода
        print("\n\nМониторинг остановлен.")
        sys.exit(0)

# Точка входа в программу
if __name__ == '__main__':
    # Если передан аргумент --once, выполняем одну проверку и выходим
    if len(sys.argv) > 1 and sys.argv[1] == '--once':
        primary_status = check_primary_replication()
        standby_status = check_standby_status()
        print_report(primary_status, standby_status)
    else:
        # Иначе запускаем непрерывный мониторинг
        monitor_loop(interval=10)
