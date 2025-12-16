DROP DATABASE IF EXISTS trizbd;

CREATE DATABASE trizbd
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Russian_Russia.1251'
    LC_CTYPE = 'Russian_Russia.1251'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

COMMENT ON DATABASE trizbd IS 'База данных системы бронирования отелей';
