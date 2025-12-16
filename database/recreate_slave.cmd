@echo off
chcp 65001 >nul
echo ======================================
echo Пересоздание Slave сервера
echo ======================================
echo.

echo [1/5] Остановка slave сервера...
"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" -D C:\PostgreSQL\data_slave stop -m fast
timeout /t 3 /nobreak >nul

echo.
echo [2/5] Удаление старого каталога данных slave...
if exist "C:\PostgreSQL\data_slave" (
    rmdir /s /q "C:\PostgreSQL\data_slave"
    echo Каталог удален
) else (
    echo Каталог не существует
)

echo.
echo [3/5] Создание нового basebackup...
set PGPASSWORD=postgres
"C:\Program Files\PostgreSQL\17\bin\pg_basebackup" -h 127.0.0.1 -p 5432 -U postgres -D C:\PostgreSQL\data_slave -P -Fp -Xs -R

echo.
echo [4/5] Настройка конфигурации slave...
echo port = 5433 >> C:\PostgreSQL\data_slave\postgresql.auto.conf

echo.
echo [5/5] Запуск slave сервера...
"C:\Program Files\PostgreSQL\17\bin\pg_ctl.exe" -D C:\PostgreSQL\data_slave -l C:\PostgreSQL\data_slave\logfile start

echo.
echo ======================================
echo Готово! Проверяем синхронизацию...
echo ======================================
timeout /t 2 /nobreak >nul

echo.
echo === Sequence на Master ===
psql -h 127.0.0.1 -p 5432 -U postgres -c "SELECT last_value FROM replication_test_id_seq;"

echo.
echo === Sequence на Slave ===
psql -h 127.0.0.1 -p 5433 -U postgres -c "SELECT last_value FROM replication_test_id_seq;"

echo.
echo === Статус репликации ===
psql -h 127.0.0.1 -p 5432 -U postgres -c "SELECT application_name, state, sync_state FROM pg_stat_replication;"

pause
