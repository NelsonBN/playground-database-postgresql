-- random() is not seedable per-row in a set-based query, so this small deterministic
-- hash (a Knuth multiplicative hash) stands in for it, returning a value in [0, 1).
CREATE OR REPLACE FUNCTION seeded_rand(seed bigint) RETURNS double precision
LANGUAGE sql IMMUTABLE AS $$
    SELECT ((((seed * 2654435761) % 4294967296) + 4294967296) % 4294967296) / 4294967296.0;
$$;

DO $$
BEGIN
    IF (SELECT COUNT(*) FROM customers) = 0 THEN
        RAISE EXCEPTION 'Cannot generate orders: customers table is empty.';
    END IF;

    IF (SELECT COUNT(*) FROM employees) = 0 THEN
        RAISE EXCEPTION 'Cannot generate orders: employees table is empty.';
    END IF;

    IF (SELECT COUNT(*) FROM shippers) = 0 THEN
        RAISE EXCEPTION 'Cannot generate orders: shippers table is empty.';
    END IF;

    IF (SELECT COUNT(*) FROM countries) = 0 THEN
        RAISE EXCEPTION 'Cannot generate orders: countries table is empty.';
    END IF;

    IF (SELECT COUNT(*) FROM products) = 0 THEN
        RAISE EXCEPTION 'Cannot generate orders: products table is empty.';
    END IF;
END $$;

BEGIN;

CREATE TEMP TABLE generated_orders (
    order_id INT PRIMARY KEY
) ON COMMIT DROP;

WITH ins AS (
    INSERT INTO orders
    (
        customer_id,
        employee_id,
        order_date,
        required_date,
        shipped_date,
        ship_via,
        freight,
        ship_name,
        ship_address,
        ship_city,
        ship_region,
        ship_postal_code,
        ship_country
    )
    WITH config AS (
        -- Change these values to control order generation.
        SELECT
            1000000::bigint AS orders_to_insert,
            1::int AS min_details_per_order,
            8::int AS max_details_per_order
    ),
    normalized_config AS (
        SELECT
            GREATEST(1, orders_to_insert) AS orders_to_insert,
            GREATEST(1, min_details_per_order) AS min_details_per_order,
            GREATEST(GREATEST(1, min_details_per_order), max_details_per_order) AS max_details_per_order
        FROM config
    ),
    counts AS (
        SELECT
            (SELECT COUNT(*) FROM customers) AS customer_count,
            (SELECT COUNT(*) FROM employees) AS employee_count,
            (SELECT COUNT(*) FROM shippers) AS shipper_count,
            (SELECT COUNT(*) FROM countries) AS country_count
    ),
    numbers AS (
        SELECT generate_series(1, (SELECT orders_to_insert FROM normalized_config)) AS n
    ),
    customer_ids (customer_id, rn) AS (
        SELECT customer_id, ROW_NUMBER() OVER (ORDER BY customer_id) AS rn
        FROM customers
    ),
    employee_ids (employee_id, rn) AS (
        SELECT employee_id, ROW_NUMBER() OVER (ORDER BY employee_id) AS rn
        FROM employees
    ),
    shipper_ids (shipper_id, rn) AS (
        SELECT shipper_id, ROW_NUMBER() OVER (ORDER BY shipper_id) AS rn
        FROM shippers
    ),
    country_codes (country_code, rn) AS (
        SELECT country_code, ROW_NUMBER() OVER (ORDER BY country_code) AS rn
        FROM countries
    )
    SELECT
        c.customer_id,
        e.employee_id,
        DATE '2024-01-01' + (MOD(numbers.n * 13, 730))::int AS order_date,
        DATE '2024-01-01' + (MOD(numbers.n * 13, 730))::int + (2 + MOD(numbers.n * 7, 12))::int AS required_date,
        DATE '2024-01-01' + (MOD(numbers.n * 13, 730))::int + (1 + MOD(numbers.n * 5, 10))::int AS shipped_date,
        s.shipper_id,
        ROUND((2 + seeded_rand(MOD(numbers.n * 31, 1000000000)::bigint) * 198)::numeric, 4) AS freight,
        CONCAT('Shipment #', LPAD(numbers.n::text, 8, '0')),
        CONCAT(
            FLOOR(1 + MOD(numbers.n * 3, 9999)),
            ' ',
            CASE MOD(numbers.n - 1, 10) + 1
                WHEN 1 THEN 'Oak'
                WHEN 2 THEN 'Maple'
                WHEN 3 THEN 'Cedar'
                WHEN 4 THEN 'Pine'
                WHEN 5 THEN 'Elm'
                WHEN 6 THEN 'Washington'
                WHEN 7 THEN 'Park'
                WHEN 8 THEN 'Lake'
                WHEN 9 THEN 'Hill'
                ELSE 'River'
            END,
            ' ',
            CASE MOD(numbers.n - 1, 6) + 1
                WHEN 1 THEN 'Ave'
                WHEN 2 THEN 'Blvd'
                WHEN 3 THEN 'St'
                WHEN 4 THEN 'Dr'
                WHEN 5 THEN 'Rd'
                ELSE 'Ln'
            END,
            CASE WHEN MOD(numbers.n, 4) = 0 THEN CONCAT(' Apt. ', LPAD(MOD(numbers.n * 5, 999)::text, 3, '0')) ELSE '' END
        ),
        CASE MOD(numbers.n - 1, 10) + 1
            WHEN 1 THEN 'Springfield'
            WHEN 2 THEN 'Franklin'
            WHEN 3 THEN 'Madison'
            WHEN 4 THEN 'Clinton'
            WHEN 5 THEN 'Salem'
            WHEN 6 THEN 'Dover'
            WHEN 7 THEN 'Auburn'
            WHEN 8 THEN 'Bristol'
            WHEN 9 THEN 'Oxford'
            ELSE 'Arlington'
        END,
        CASE MOD(numbers.n - 1, 10) + 1
            WHEN 1 THEN 'California'
            WHEN 2 THEN 'Texas'
            WHEN 3 THEN 'Florida'
            WHEN 4 THEN 'New York'
            WHEN 5 THEN 'Illinois'
            WHEN 6 THEN 'Ohio'
            WHEN 7 THEN 'Georgia'
            WHEN 8 THEN 'Michigan'
            WHEN 9 THEN 'Arizona'
            ELSE 'Virginia'
        END,
        LPAD((10000 + MOD(numbers.n * 7, 90000))::text, 5, '0'),
        cc.country_code
    FROM numbers
    CROSS JOIN counts
    JOIN customer_ids c
        ON c.rn = MOD(numbers.n - 1, counts.customer_count) + 1
    JOIN employee_ids e
        ON e.rn = MOD(numbers.n - 1, counts.employee_count) + 1
    JOIN shipper_ids s
        ON s.rn = MOD(numbers.n - 1, counts.shipper_count) + 1
    JOIN country_codes cc
        ON cc.rn = MOD(numbers.n - 1, counts.country_count) + 1
    RETURNING order_id
)
INSERT INTO generated_orders (order_id)
SELECT order_id
FROM ins;

SELECT COUNT(*) AS inserted_orders FROM generated_orders;

WITH ins AS (
    INSERT INTO order_details
    (
        order_id,
        product_id,
        unit_price,
        quantity,
        discount
    )
    WITH config AS (
        -- Change these values to control details-per-order distribution.
        SELECT
            1::int AS min_details_per_order,
            8::int AS max_details_per_order
    ),
    normalized_config AS (
        SELECT
            GREATEST(1, min_details_per_order) AS min_details_per_order,
            GREATEST(GREATEST(1, min_details_per_order), max_details_per_order) AS max_details_per_order
        FROM config
    ),
    product_ids (product_id, unit_price, rn) AS (
        SELECT
            product_id,
            unit_price,
            ROW_NUMBER() OVER (ORDER BY product_id) AS rn
        FROM products
    ),
    product_count AS (
        SELECT COUNT(*) AS product_count FROM product_ids
    ),
    selected_orders AS (
        SELECT order_id
        FROM generated_orders
    ),
    details_per_order AS (
        SELECT
            so.order_id,
            (
                cfg.min_details_per_order +
                FLOOR(
                    seeded_rand(MOD(so.order_id::bigint * 7919, 1000000000)::bigint) *
                    (
                        LEAST(cfg.max_details_per_order, pc.product_count) -
                        cfg.min_details_per_order + 1
                    )
                )::int
            ) AS detail_count
        FROM selected_orders so
        CROSS JOIN normalized_config cfg
        CROSS JOIN product_count pc
    ),
    expanded_details AS (
        SELECT
            dpo.order_id,
            gs AS line_n,
            pc.product_count,
            MOD(dpo.order_id::bigint * 17, pc.product_count) + 1 AS start_rn
        FROM details_per_order dpo
        CROSS JOIN product_count pc
        CROSS JOIN LATERAL generate_series(1, dpo.detail_count) AS gs
    )
    SELECT
        ed.order_id,
        p.product_id,
        ROUND((p.unit_price * (0.90 + seeded_rand(MOD(ed.order_id::bigint * 53 + ed.line_n::bigint * 97, 1000000000)::bigint) * 0.25))::numeric, 4) AS unit_price,
        FLOOR(1 + seeded_rand(MOD(ed.order_id::bigint * 101 + ed.line_n::bigint * 131, 1000000000)::bigint) * 12)::smallint AS quantity,
        ROUND((seeded_rand(MOD(ed.order_id::bigint * 149 + ed.line_n::bigint * 181, 1000000000)::bigint) * 0.35)::numeric, 3) AS discount
    FROM expanded_details ed
    JOIN product_ids p
        ON p.rn = MOD(ed.start_rn + ed.line_n - 2, ed.product_count) + 1
    ON CONFLICT (order_id, product_id) DO NOTHING
    RETURNING order_id
)
SELECT COUNT(*) AS inserted_order_details FROM ins;

COMMIT;
