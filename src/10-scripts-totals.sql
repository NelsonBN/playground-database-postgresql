SELECT
    TO_CHAR((SELECT COUNT(*) FROM countries), 'FM999,999,999') AS countries,
    TO_CHAR((SELECT COUNT(*) FROM categories), 'FM999,999,999') AS categories,
    TO_CHAR((SELECT COUNT(*) FROM shippers), 'FM999,999,999') AS shippers,
    TO_CHAR((SELECT COUNT(*) FROM customers), 'FM999,999,999') AS customers,
    TO_CHAR((SELECT COUNT(*) FROM employees), 'FM999,999,999') AS employees,
    TO_CHAR((SELECT COUNT(*) FROM suppliers), 'FM999,999,999') AS suppliers,
    TO_CHAR((SELECT COUNT(*) FROM products), 'FM999,999,999') AS products,
    TO_CHAR((SELECT COUNT(*) FROM orders), 'FM999,999,999') AS orders,
    TO_CHAR((SELECT COUNT(*) FROM order_details), 'FM999,999,999') AS order_details;
