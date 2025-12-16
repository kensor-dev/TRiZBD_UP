# Веб-панель мониторинга репликации PostgreSQL на FastAPI
# Предоставляет web-интерфейс для просмотра состояния репликации в реальном времени

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import psycopg2
from datetime import datetime

# Создаем FastAPI приложение
app = FastAPI()

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

# HTML шаблон страницы с встроенными стилями
# meta http-equiv="refresh" - автообновление страницы каждые 5 секунд
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>Мониторинг репликации PostgreSQL</title>
    <meta charset="UTF-8">
    <meta http-equiv="refresh" content="5">
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }}
        .container {{
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #333;
            text-align: center;
        }}
        .server-box {{
            border: 2px solid #ddd;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }}
        .status-ok {{
            background: #d4edda;
            border-color: #28a745;
        }}
        .status-error {{
            background: #f8d7da;
            border-color: #dc3545;
        }}
        .status-warning {{
            background: #fff3cd;
            border-color: #ffc107;
        }}
        .metric {{
            margin: 10px 0;
            padding: 8px;
            background: #f8f9fa;
            border-left: 3px solid #007bff;
        }}
        .timestamp {{
            text-align: center;
            color: #666;
            margin: 20px 0;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Мониторинг репликации PostgreSQL</h1>
        <div class="timestamp">Обновлено: {timestamp}</div>

        <div class="server-box {primary_class}">
            <h2>🖥 PRIMARY SERVER ({primary_host}:{primary_port})</h2>
            <div class="metric"><strong>Статус:</strong> {primary_status}</div>
            <div class="metric"><strong>Сообщение:</strong> {primary_message}</div>
            {primary_replicas_html}
        </div>

        <div class="server-box {standby_class}">
            <h2>💾 STANDBY SERVER ({standby_host}:{standby_port})</h2>
            <div class="metric"><strong>Статус:</strong> {standby_status}</div>
            <div class="metric"><strong>Сообщение:</strong> {standby_message}</div>
            {standby_data_html}
        </div>
    </div>
</body>
</html>
'''

def get_primary_status():
    """
    Получает статус репликации с PRIMARY сервера

    Возвращает словарь с информацией о репликах:
    - status: OK/ERROR
    - message: описание
    - replicas: список реплик
    - class: CSS класс для отображения (status-ok/status-error)
    """
    try:
        # Подключаемся к PRIMARY
        conn = psycopg2.connect(**PRIMARY_CONFIG)
        cur = conn.cursor()

        # Запрашиваем базовую информацию о репликах
        cur.execute("""
            SELECT client_addr, state, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
            FROM pg_stat_replication;
        """)

        results = cur.fetchall()
        cur.close()
        conn.close()

        # Если нет реплик - ошибка
        if not results:
            return {'status': 'ERROR', 'message': 'Нет активных реплик', 'replicas': [], 'class': 'status-error'}

        # Формируем список реплик
        replicas = [{'client_addr': r[0], 'state': r[1], 'lag_bytes': r[2] or 0} for r in results]
        return {'status': 'OK', 'message': f'Активных реплик: {len(replicas)}', 'replicas': replicas, 'class': 'status-ok'}

    except Exception as e:
        return {'status': 'ERROR', 'message': str(e), 'replicas': [], 'class': 'status-error'}

def get_standby_status():
    """
    Получает статус STANDBY сервера

    Возвращает словарь с информацией о состоянии:
    - status: OK/ERROR
    - message: описание
    - data: детальная информация (is_recovery, wal_receiver, lag_seconds)
    - class: CSS класс для отображения
    """
    try:
        # Подключаемся к STANDBY
        conn = psycopg2.connect(**STANDBY_CONFIG)
        cur = conn.cursor()

        # Проверяем режим восстановления
        cur.execute("SELECT pg_is_in_recovery();")
        is_recovery = cur.fetchone()[0]

        # Проверяем статус WAL receiver
        cur.execute("SELECT status FROM pg_stat_wal_receiver;")
        wal_result = cur.fetchone()
        wal_receiver = {'status': wal_result[0]} if wal_result else None

        # Вычисляем задержку репликации
        cur.execute("SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds;")
        lag_result = cur.fetchone()
        lag_seconds = lag_result[0] if lag_result and lag_result[0] else 0

        cur.close()
        conn.close()

        return {
            'status': 'OK',
            'message': 'Работает нормально',
            'data': {'is_recovery': is_recovery, 'wal_receiver': wal_receiver, 'lag_seconds': lag_seconds},
            'class': 'status-ok'
        }

    except Exception as e:
        return {'status': 'ERROR', 'message': str(e), 'data': None, 'class': 'status-error'}

@app.get("/", response_class=HTMLResponse)
def index():
    """
    Главная страница - показывает статус репликации

    Собирает данные с обоих серверов и отображает их в HTML
    """
    # Получаем статусы серверов
    primary = get_primary_status()
    standby = get_standby_status()

    # Формируем HTML для списка реплик
    primary_replicas_html = ""
    if primary['replicas']:
        primary_replicas_html = "<h3>Активные реплики:</h3>"
        for replica in primary['replicas']:
            primary_replicas_html += f'''
            <div class="metric">
                <strong>IP:</strong> {replica['client_addr']}<br>
                <strong>Состояние:</strong> {replica['state']}<br>
                <strong>Отставание:</strong> {replica['lag_bytes']} байт
            </div>
            '''

    # Формируем HTML для данных standby
    standby_data_html = ""
    if standby['data']:
        data = standby['data']
        standby_data_html += f'<div class="metric"><strong>Режим восстановления:</strong> {"ДА" if data["is_recovery"] else "НЕТ"}</div>'
        if data['wal_receiver']:
            standby_data_html += f'<div class="metric"><strong>WAL Receiver:</strong> {data["wal_receiver"]["status"]}</div>'
        if data['lag_seconds'] is not None:
            standby_data_html += f'<div class="metric"><strong>Задержка:</strong> {data["lag_seconds"]:.2f} сек</div>'

    # Подставляем данные в шаблон
    html = HTML_TEMPLATE.format(
        timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        primary_host=PRIMARY_CONFIG['host'],
        primary_port=PRIMARY_CONFIG['port'],
        primary_status=primary['status'],
        primary_message=primary['message'],
        primary_replicas_html=primary_replicas_html,
        primary_class=primary['class'],
        standby_host=STANDBY_CONFIG['host'],
        standby_port=STANDBY_CONFIG['port'],
        standby_status=standby['status'],
        standby_message=standby['message'],
        standby_data_html=standby_data_html,
        standby_class=standby['class']
    )

    return html

# Точка входа - запуск веб-сервера
if __name__ == '__main__':
    import uvicorn
    # Запускаем uvicorn на всех интерфейсах (0.0.0.0), порт 8081
    uvicorn.run(app, host='0.0.0.0', port=8081)
