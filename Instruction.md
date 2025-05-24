## Запуск

1.  **Клонируйте репозиторий.**
2.  **Поместите ваши 10 `mock_data_*.csv` файлов** в директорию `mock_data/`.
3.  **Поместите скачанный PostgreSQL JDBC драйвер** (например, `postgresql-42.6.0.jar`) в директорию `flink_jars/`.
4.  **Сборка и запуск сервисов (кроме продюсера):**
    Откройте терминал в корневой директории проекта и выполните:
    ```bash
    docker-compose up -d zookeeper kafka postgres jobmanager taskmanager
    ```
    Это запустит Zookeeper, Kafka, PostgreSQL (с автоматическим созданием таблиц из `postgres_init_scripts/init_db.sql`) и кластер Flink (JobManager и TaskManager).

5.  **Запуск Flink SQL Job:**
    Откройте **новый терминал** и войдите в контейнер Flink JobManager:
    ```bash
    docker exec -it jobmanager /bin/bash
    ```
    Внутри контейнера выполните:
    ```bash
    # Находясь в /opt/flink в контейнере jobmanager
    ./bin/flink-sql-client.sh -f /opt/flink/sql_job/streaming_etl.sql
    ```

6.  **Запуск Python-продюсера для отправки данных в Kafka:**
    Откройте **еще один новый терминал** в корневой директории проекта и выполните:
    ```bash
    docker-compose --profile producer_runner up --build csv_producer
    ```

## Проверка данных

После того как продюсер отработает (или во время его работы), вы можете проверить данные в PostgreSQL:
Подключитесь к базе данных `flinkdb` и выполните SQL-запросы:
```sql
SELECT COUNT(*) FROM dim_customers;
SELECT * FROM dim_customers LIMIT 5;

SELECT COUNT(*) FROM dim_sellers;
SELECT * FROM dim_sellers LIMIT 5;

SELECT COUNT(*) FROM dim_products;
SELECT * FROM dim_products LIMIT 5;

SELECT COUNT(*) FROM dim_stores;
SELECT * FROM dim_stores LIMIT 5;

SELECT COUNT(*) FROM fact_sales;
SELECT * FROM fact_sales ORDER BY sale_date_time DESC LIMIT 10;