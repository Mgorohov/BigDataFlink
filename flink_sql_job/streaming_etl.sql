CREATE TABLE kafka_source_events_v2 (
    `id` INT,
    `customer_first_name` STRING,
    `customer_last_name` STRING,
    `customer_age` INT,
    `customer_email` STRING,
    `customer_country` STRING,
    `customer_postal_code` STRING,
    `customer_pet_type` STRING,
    `customer_pet_name` STRING,
    `customer_pet_breed` STRING,
    `seller_first_name` STRING,
    `seller_last_name` STRING,
    `seller_email` STRING,
    `seller_country` STRING,
    `seller_postal_code` STRING,
    `product_name` STRING,
    `product_category` STRING,
    `product_price` DECIMAL(10, 2),
    `product_quantity` INT,
    `sale_date` STRING,             
    `sale_customer_id` INT,
    `sale_seller_id` INT,
    `sale_product_id` INT,
    `sale_quantity` INT,
    `sale_total_price` DECIMAL(10, 2),
    `store_name` STRING,
    `store_location` STRING,
    `store_city` STRING,
    `store_state` STRING,
    `store_country` STRING,
    `store_phone` STRING,
    `store_email` STRING,
    `pet_category` STRING,
    `product_weight` DECIMAL(10, 2),
    `product_color` STRING,
    `product_size` STRING,
    `product_brand` STRING,
    `product_material` STRING,
    `product_description` STRING,
    `product_rating` DECIMAL(3, 1),
    `product_reviews` INT,
    `product_release_date` STRING,
    `product_expiry_date` STRING,
    `supplier_name` STRING,
    `supplier_contact` STRING,
    `supplier_email` STRING,
    `supplier_phone` STRING,
    `supplier_address` STRING,
    `supplier_city` STRING,
    `supplier_country` STRING,
    `event_time_ltz` AS TO_TIMESTAMP_LTZ(UNIX_TIMESTAMP(`sale_date`, 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'''), 3),
    `parsed_product_release_date` AS TRY_CAST(SUBSTRING(`product_release_date` FROM 1 FOR 10) AS DATE FORMAT 'yyyy-MM-dd'),
    `parsed_product_expiry_date` AS TRY_CAST(SUBSTRING(`product_expiry_date` FROM 1 FOR 10) AS DATE FORMAT 'yyyy-MM-dd'),
    WATERMARK FOR `event_time_ltz` AS `event_time_ltz` - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'source_events_v2',
    'properties.bootstrap.servers' = 'kafka:9092',
    'properties.group.id' = 'flink_consumer_group_v2',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'json',
    'json.fail-on-missing-field' = 'false',
    'json.ignore-parse-errors' = 'true'
);


CREATE TABLE dim_customers_pg (
    customer_id INT PRIMARY KEY NOT ENFORCED,
    first_name STRING,
    last_name STRING,
    age INT,
    email STRING,
    country STRING,
    postal_code STRING,
    pet_type STRING,
    pet_name STRING,
    pet_breed STRING,
    last_updated TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/flinkdb',
    'table-name' = 'dim_customers',
    'username' = 'flinkuser',
    'password' = 'flinkpassword',
    'sink.buffer-flush.max-rows' = '200',
    'sink.buffer-flush.interval' = '2s'
);

CREATE TABLE dim_sellers_pg (
    seller_id INT PRIMARY KEY NOT ENFORCED,
    first_name STRING,
    last_name STRING,
    email STRING,
    country STRING,
    postal_code STRING,
    last_updated TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/flinkdb',
    'table-name' = 'dim_sellers',
    'username' = 'flinkuser',
    'password' = 'flinkpassword',
    'sink.buffer-flush.max-rows' = '200',
    'sink.buffer-flush.interval' = '2s'
);

CREATE TABLE dim_products_pg (
    product_id INT PRIMARY KEY NOT ENFORCED,
    name STRING,
    category STRING,
    pet_category STRING,
    price DECIMAL(10, 2),
    weight DECIMAL(10, 2),
    color STRING,
    size_value STRING,
    brand STRING,
    material STRING,
    description STRING,
    rating DECIMAL(3, 1),
    reviews_count INT,
    release_date DATE,
    expiry_date DATE,
    supplier_name STRING,
    supplier_contact STRING,
    supplier_email STRING,
    supplier_phone STRING,
    supplier_address STRING,
    supplier_city STRING,
    supplier_country STRING,
    last_updated TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/flinkdb',
    'table-name' = 'dim_products',
    'username' = 'flinkuser',
    'password' = 'flinkpassword',
    'sink.buffer-flush.max-rows' = '200',
    'sink.buffer-flush.interval' = '2s'
);

CREATE TABLE dim_stores_pg (
    store_email STRING PRIMARY KEY NOT ENFORCED,
    name STRING,
    location STRING,
    city STRING,
    state STRING,
    country STRING,
    phone STRING,
    last_updated TIMESTAMP_LTZ(3)
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/flinkdb',
    'table-name' = 'dim_stores',
    'username' = 'flinkuser',
    'password' = 'flinkpassword',
    'sink.buffer-flush.max-rows' = '200',
    'sink.buffer-flush.interval' = '2s'
);

CREATE TABLE fact_sales_pg (
    source_event_id INT,
    customer_id INT,
    seller_id INT,
    product_id INT,
    store_email_fk STRING,
    sale_date_time TIMESTAMP_LTZ(3),
    quantity_sold INT,
    total_price DECIMAL(10, 2),
    product_list_price_at_sale DECIMAL(10, 2),
    product_stock_quantity_at_sale_time INT
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/flinkdb',
    'table-name' = 'fact_sales',
    'username' = 'flinkuser',
    'password' = 'flinkpassword',
    'sink.buffer-flush.max-rows' = '500',
    'sink.buffer-flush.interval' = '5s'
);

--  DML FOR TRANSFORMATION 

INSERT INTO dim_customers_pg
SELECT
    `sale_customer_id` AS customer_id,
    `customer_first_name` AS first_name,
    `customer_last_name` AS last_name,
    `customer_age` AS age,
    `customer_email` AS email,
    `customer_country` AS country,
    `customer_postal_code` AS postal_code,
    `customer_pet_type` AS pet_type,
    `customer_pet_name` AS pet_name,
    `customer_pet_breed` AS pet_breed,
    LOCALTIMESTAMP AS last_updated
FROM kafka_source_events_v2
WHERE `sale_customer_id` IS NOT NULL;

INSERT INTO dim_sellers_pg
SELECT
    `sale_seller_id` AS seller_id,
    `seller_first_name` AS first_name,
    `seller_last_name` AS last_name,
    `seller_email` AS email,
    `seller_country` AS country,
    `seller_postal_code` AS postal_code,
    LOCALTIMESTAMP AS last_updated
FROM kafka_source_events_v2
WHERE `sale_seller_id` IS NOT NULL;

INSERT INTO dim_products_pg
SELECT
    `sale_product_id` AS product_id,
    `product_name` AS name,
    `product_category` AS category,
    `pet_category`,
    `product_price` AS price,
    `product_weight` AS weight,
    `product_color` AS color,
    `product_size` AS size_value,
    `product_brand` AS brand,
    `product_material` AS material,
    `product_description` AS description,
    `product_rating` AS rating,
    `product_reviews` AS reviews_count,
    `parsed_product_release_date` AS release_date,
    `parsed_product_expiry_date` AS expiry_date,
    `supplier_name`,
    `supplier_contact`,
    `supplier_email`,
    `supplier_phone`,
    `supplier_address`,
    `supplier_city`,
    `supplier_country`,
    LOCALTIMESTAMP AS last_updated
FROM kafka_source_events_v2
WHERE `sale_product_id` IS NOT NULL;

INSERT INTO dim_stores_pg
SELECT
    `store_email`,
    `store_name` AS name,
    `store_location` AS location,
    `store_city` AS city,
    `store_state` AS state,
    `store_country` AS country,
    `store_phone` AS phone,
    LOCALTIMESTAMP AS last_updated
FROM kafka_source_events_v2
WHERE `store_email` IS NOT NULL AND `store_email` <> '';

INSERT INTO fact_sales_pg
SELECT
    `id` AS source_event_id,
    `sale_customer_id` AS customer_id,
    `sale_seller_id` AS seller_id,
    `sale_product_id` AS product_id,
    `store_email` AS store_email_fk,
    `event_time_ltz` AS sale_date_time,
    `sale_quantity` AS quantity_sold,
    `sale_total_price` AS total_price,
    `product_price` AS product_list_price_at_sale,
    `product_quantity` AS product_stock_quantity_at_sale_time
FROM kafka_source_events_v2
WHERE `sale_customer_id` IS NOT NULL 
  AND `sale_seller_id` IS NOT NULL 
  AND `sale_product_id` IS NOT NULL 
  AND `store_email` IS NOT NULL AND `store_email` <> '';