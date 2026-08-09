# Playground Database PostgreSQL

Playground database for PostgreSQL inspired in the Northwind database with a few modifications


## Similar Playground Databases

* [Playground Database MySQL](https://github.com/NelsonBN/playground-database-mysql)


## Scripts

* [`01-seed-gen-products.sql`](./src/01-seed-gen-products.sql) - Generates random products
* [`02-seed-gen-customer.sql`](./src/02-seed-gen-customers.sql) - Generates random customers
* [`03-seed-gen-orders.sql`](./src/03-seed-gen-orders.sql) - Generates random orders and order details


## Dataset

| Table         | Total  |
|---------------|--------|
| countries     | 249    |
| categories    | 20     |
| shippers      | 25     |
| customers     | 500    |
| employees     | 25     |
| suppliers     | 500    |
| products      | 3 746  |
| orders        | 4 935  |
| order_details | 17 385 |


## Schema

```mermaid
erDiagram
  COUNTRIES ||--o{ SHIPPERS : located_in
  COUNTRIES ||--o{ CUSTOMERS : located_in
  COUNTRIES ||--o{ EMPLOYEES : located_in
  COUNTRIES ||--o{ SUPPLIERS : located_in
  COUNTRIES ||--o{ ORDERS : ships_to
  CUSTOMERS ||--o{ ORDERS : places
  ORDERS ||--|{ ORDER_DETAILS : contains
  PRODUCTS ||--o{ ORDER_DETAILS : included_in
  EMPLOYEES ||--o{ ORDERS : handles
  SHIPPERS ||--o{ ORDERS : ships
  CATEGORIES ||--o{ PRODUCTS : categorizes
  SUPPLIERS ||--o{ PRODUCTS : supplies
  EMPLOYEES ||--o{ EMPLOYEES : reports_to


  COUNTRIES {
    char country_code PK
    varchar name
  }

  CATEGORIES {
    char category_id PK
    varchar category_name
    varchar description
  }

  SHIPPERS {
    int shipper_id PK
    varchar company_name
    varchar address
    varchar city
    varchar region
    varchar postal_code
    char country FK
    varchar phone
    varchar email
  }

  CUSTOMERS {
    int customer_id PK
    varchar first_name
    varchar last_name
    varchar address
    varchar city
    varchar region
    varchar postal_code
    char country FK
    varchar phone
    varchar email
  }

  EMPLOYEES {
    int employee_id PK
    varchar first_name
    varchar last_name
    varchar title
    varchar title_of_courtesy
    date birth_date
    date hire_date
    varchar address
    varchar city
    varchar region
    varchar postal_code
    char country FK
    varchar home_phone
    varchar email
    varchar photo_path
    text notes
    int reports_to FK
  }

  SUPPLIERS {
    int supplier_id PK
    varchar company_name
    varchar contact_name
    varchar contact_title
    varchar address
    varchar city
    varchar region
    varchar postal_code
    char country FK
    varchar phone
    varchar email
  }

  PRODUCTS {
    int product_id PK
    varchar product_name
    int supplier_id FK
    char category_id FK
    text description
    varchar photo_path
    decimal unit_price
    smallint units_in_stock
    bit discontinued
  }

  ORDERS {
    int order_id PK
    int customer_id FK
    int employee_id FK
    date order_date
    date required_date
    date shipped_date
    int ship_via FK
    decimal freight
    varchar ship_name
    varchar ship_address
    varchar ship_city
    varchar ship_region
    varchar ship_postal_code
    char ship_country FK
  }

  ORDER_DETAILS {
    int order_id PK, FK
    int product_id PK, FK
    decimal unit_price
    smallint quantity
    decimal discount
  }
```
