DELETE FROM order_details;
DELETE FROM orders;
DELETE FROM products;
DELETE FROM customers;
DELETE FROM suppliers;
UPDATE employees SET reports_to = NULL;
DELETE FROM employees;
DELETE FROM shippers;
DELETE FROM categories;
DELETE FROM countries;

ALTER TABLE shippers      ALTER COLUMN shipper_id  RESTART WITH 1;
ALTER TABLE customers     ALTER COLUMN customer_id RESTART WITH 1;
ALTER TABLE employees     ALTER COLUMN employee_id RESTART WITH 1;
ALTER TABLE suppliers     ALTER COLUMN supplier_id RESTART WITH 1;
ALTER TABLE products      ALTER COLUMN product_id  RESTART WITH 1;
ALTER TABLE orders        ALTER COLUMN order_id    RESTART WITH 1;
