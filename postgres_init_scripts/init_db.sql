CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    age INT,
    email VARCHAR(255) UNIQUE,
    country VARCHAR(100),
    postal_code VARCHAR(50),
    pet_type VARCHAR(100),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100),
    last_updated TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS dim_sellers (
    seller_id INT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    country VARCHAR(100),
    postal_code VARCHAR(50),
    last_updated TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS dim_products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255),
    category VARCHAR(100),
    pet_category VARCHAR(100),
    price DECIMAL(10, 2),
    weight DECIMAL(10, 2),
    color VARCHAR(50),
    size_value VARCHAR(50),
    brand VARCHAR(100),
    material VARCHAR(100),
    description TEXT,
    rating DECIMAL(3, 1),
    reviews_count INT,
    release_date DATE,
    expiry_date DATE,
    supplier_name VARCHAR(255),
    supplier_contact VARCHAR(255),
    supplier_email VARCHAR(255),
    supplier_phone VARCHAR(50),
    supplier_address VARCHAR(500),
    supplier_city VARCHAR(100),
    supplier_country VARCHAR(100),
    last_updated TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS dim_stores (
    store_email VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    location VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    phone VARCHAR(50),
    last_updated TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS fact_sales (
    sale_fact_id BIGSERIAL PRIMARY KEY,
    source_event_id INT,
    customer_id INT,
    seller_id INT,
    product_id INT,
    store_email_fk VARCHAR(255),
    sale_date_time TIMESTAMP WITH TIME ZONE,
    quantity_sold INT,
    total_price DECIMAL(10, 2),
    product_list_price_at_sale DECIMAL(10, 2),
    product_stock_quantity_at_sale_time INT,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_seller FOREIGN KEY (seller_id) REFERENCES dim_sellers(seller_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES dim_products(product_id) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_store FOREIGN KEY (store_email_fk) REFERENCES dim_stores(store_email) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX IF NOT EXISTS idx_fact_sales_customer_id ON fact_sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_seller_id ON fact_sales(seller_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_product_id ON fact_sales(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_store_email_fk ON fact_sales(store_email_fk);