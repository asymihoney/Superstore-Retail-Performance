-- Superstore schema (Postgres-compatible DDL)

DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;

CREATE TABLE customers (
    customer_id   TEXT PRIMARY KEY,
    customer_name TEXT,
    segment       TEXT
);

CREATE TABLE products (
    product_id    TEXT PRIMARY KEY,
    product_name  TEXT,
    category      TEXT,
    sub_category  TEXT
);

CREATE TABLE orders (
    row_id        INTEGER PRIMARY KEY,
    order_id      TEXT,
    order_date    DATE,
    ship_date     DATE,
    ship_mode     TEXT,
    customer_id   TEXT REFERENCES customers(customer_id),
    product_id    TEXT REFERENCES products(product_id),
    country       TEXT,
    city          TEXT,
    state         TEXT,
    postal_code   TEXT,
    region        TEXT,
    sales         NUMERIC,
    quantity      INTEGER,
    discount      NUMERIC,
    profit        NUMERIC
);
