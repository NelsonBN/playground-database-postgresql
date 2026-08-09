-- random() is not seedable per-row in a set-based query, so this small deterministic
-- hash (a Knuth multiplicative hash) stands in for it, returning a value in [0, 1).
CREATE OR REPLACE FUNCTION seeded_rand(seed bigint) RETURNS double precision
LANGUAGE sql IMMUTABLE AS $$
    SELECT ((((seed * 2654435761) % 4294967296) + 4294967296) % 4294967296) / 4294967296.0;
$$;

WITH ins AS (
    INSERT INTO products
    (
        product_name,
        supplier_id,
        category_id,
        description,
        photo_path,
        unit_price,
        units_in_stock,
        discontinued
    )
    WITH config AS (
        -- Change this single value to control how many products get generated.
        SELECT 1000000::bigint AS records_to_insert
    ),
    counts AS (
        SELECT
            (SELECT COUNT(*) FROM suppliers)  AS supplier_count,
            (SELECT COUNT(*) FROM categories) AS category_count
    ),
    numbers AS (
        SELECT generate_series(1, (SELECT records_to_insert FROM config)) AS n
    ),
    product_bases (id, name, family) AS (
        SELECT  1, 'Chai',              'tea'       UNION ALL
        SELECT  2, 'Matcha',            'tea'       UNION ALL
        SELECT  3, 'Green Tea',         'tea'       UNION ALL
        SELECT  4, 'Black Tea',         'tea'       UNION ALL
        SELECT  5, 'Earl Grey',         'tea'       UNION ALL
        SELECT  6, 'Espresso',          'coffee'    UNION ALL
        SELECT  7, 'Americano',         'coffee'    UNION ALL
        SELECT  8, 'Cappuccino',        'coffee'    UNION ALL
        SELECT  9, 'Latte',             'coffee'    UNION ALL
        SELECT 10, 'Mocha',             'coffee'    UNION ALL
        SELECT 11, 'Cola',              'soft drink' UNION ALL
        SELECT 12, 'Lemon Soda',        'soft drink' UNION ALL
        SELECT 13, 'Ginger Ale',        'soft drink' UNION ALL
        SELECT 14, 'Sparkling Water',   'water'     UNION ALL
        SELECT 15, 'Still Water',       'water'     UNION ALL
        SELECT 16, 'Orange Juice',      'juice'     UNION ALL
        SELECT 17, 'Apple Juice',       'juice'     UNION ALL
        SELECT 18, 'Grape Juice',       'juice'     UNION ALL
        SELECT 19, 'Cranberry Juice',   'juice'     UNION ALL
        SELECT 20, 'Kombucha',          'fermented drink' UNION ALL
        SELECT 21, 'Oat Milk',          'dairy alternative' UNION ALL
        SELECT 22, 'Whole Milk',        'dairy'     UNION ALL
        SELECT 23, 'Yogurt',            'dairy'     UNION ALL
        SELECT 24, 'Cheese',            'dairy'     UNION ALL
        SELECT 25, 'Butter',            'dairy'     UNION ALL
        SELECT 26, 'Olive Oil',         'pantry'    UNION ALL
        SELECT 27, 'Pasta',             'pantry'    UNION ALL
        SELECT 28, 'Rice',              'pantry'    UNION ALL
        SELECT 29, 'Bread',             'bakery'    UNION ALL
        SELECT 30, 'Granola',           'snack'     UNION ALL
        SELECT 31, 'Cookies',           'snack'     UNION ALL
        SELECT 32, 'Brownies',          'snack'     UNION ALL
        SELECT 33, 'Chocolate',         'snack'     UNION ALL
        SELECT 34, 'Honey',             'sweetener' UNION ALL
        SELECT 35, 'Jam',               'sweetener' UNION ALL
        SELECT 36, 'Nuts',              'snack'     UNION ALL
        SELECT 37, 'Seeds',             'snack'     UNION ALL
        SELECT 38, 'Salsa',             'condiment' UNION ALL
        SELECT 39, 'Soup',              'prepared food' UNION ALL
        SELECT 40, 'Salad',             'prepared food' UNION ALL
        SELECT 41, 'Shrimp',            'seafood'
    ),
    product_styles (id, name, price_factor, tone) AS (
        SELECT  1, 'Classic',   0.95, 'balanced and familiar' UNION ALL
        SELECT  2, 'Fresh',     1.00, 'freshly prepared' UNION ALL
        SELECT  3, 'Premium',   1.18, 'higher quality' UNION ALL
        SELECT  4, 'Organic',   1.22, 'organic ingredients' UNION ALL
        SELECT  5, 'Artisan',   1.15, 'small-batch crafted' UNION ALL
        SELECT  6, 'Signature', 1.20, 'signature house blend' UNION ALL
        SELECT  7, 'Reserve',   1.28, 'limited reserve selection' UNION ALL
        SELECT  8, 'Light',     0.90, 'lighter profile' UNION ALL
        SELECT  9, 'Bold',      1.08, 'bold flavor' UNION ALL
        SELECT 10, 'Deluxe',    1.25, 'deluxe finish'
    ),
    product_sizes (id, name, price_factor, stock_factor) AS (
        SELECT 1, 'S',  0.90, 0.65 UNION ALL
        SELECT 2, 'M',  1.00, 1.00 UNION ALL
        SELECT 3, 'L',  1.12, 1.25 UNION ALL
        SELECT 4, 'XL', 1.25, 1.55
    ),
    product_notes (id, note) AS (
        SELECT  1, 'clean finish' UNION ALL
        SELECT  2, 'smooth texture' UNION ALL
        SELECT  3, 'natural sweetness' UNION ALL
        SELECT  4, 'bright aroma' UNION ALL
        SELECT  5, 'rich mouthfeel' UNION ALL
        SELECT  6, 'balanced acidity' UNION ALL
        SELECT  7, 'fresh grain notes' UNION ALL
        SELECT  8, 'creamy finish' UNION ALL
        SELECT  9, 'toasted undertones' UNION ALL
        SELECT 10, 'fruity profile' UNION ALL
        SELECT 11, 'soft spice finish' UNION ALL
        SELECT 12, 'slow-cooked depth' UNION ALL
        SELECT 13, 'bright citrus lift' UNION ALL
        SELECT 14, 'earthy body' UNION ALL
        SELECT 15, 'snack-friendly crunch' UNION ALL
        SELECT 16, 'fresh market taste'
    ),
    supplier_ids (supplier_id, rn) AS (
        SELECT supplier_id, ROW_NUMBER() OVER (ORDER BY supplier_id) AS rn
        FROM suppliers
    ),
    category_ids (category_id, rn) AS (
        SELECT category_id, ROW_NUMBER() OVER (ORDER BY category_id) AS rn
        FROM categories
    )
    SELECT
        CONCAT(pb.name, ' ', ps.name, ' ', sz.name, ' #', LPAD(n::text, 6, '0')) AS product_name,
        sup.supplier_id AS supplier_id,
        cat.category_id AS category_id,
        CONCAT(
            pb.name, ' ', ps.name, ' ', sz.name, ' #', LPAD(n::text, 6, '0'),
            ' is a ', ps.tone, ' ', pb.family,
            ' with ', pn.note,
            ' and a ', sz.name, ' format.'
        ) AS description,
        CASE WHEN MOD(n, 3) = 0 THEN
            CONCAT('/images/products/food/', LOWER(REPLACE(pb.name, ' ', '_')), '_', LPAD(n::text, 6, '0'), '.jpg')
        ELSE NULL
        END AS photo_path,
        ROUND(
            (
                (CASE ps.id
                    WHEN 1 THEN 1.49
                    WHEN 2 THEN 2.29
                    WHEN 3 THEN 4.99
                    WHEN 4 THEN 6.49
                    WHEN 5 THEN 7.99
                    WHEN 6 THEN 9.49
                    WHEN 7 THEN 12.99
                    WHEN 8 THEN 3.99
                    WHEN 9 THEN 5.49
                    ELSE 10.99
                END) * ps.price_factor * sz.price_factor * (0.92 + seeded_rand(n * 17) * 0.25)
            )::numeric,
            4
        ) AS unit_price,
        FLOOR((20 + seeded_rand(n * 19) * 480) * sz.stock_factor)::smallint AS units_in_stock,
        (seeded_rand(n * 23) < 0.08) AS discontinued
    FROM numbers
    CROSS JOIN counts
    JOIN product_bases pb
        ON pb.id = MOD(n - 1, 41) + 1
    JOIN product_styles ps
        ON ps.id = MOD(n - 1, 10) + 1
    JOIN product_sizes sz
        ON sz.id = MOD(n - 1, 4) + 1
    JOIN product_notes pn
        ON pn.id = MOD(n - 1, 16) + 1
    JOIN supplier_ids sup
        ON sup.rn = MOD(n - 1, counts.supplier_count) + 1
    JOIN category_ids cat
        ON cat.rn = MOD(n - 1, counts.category_count) + 1
    ON CONFLICT (product_name) DO NOTHING
    RETURNING product_id
)
SELECT COUNT(*) AS inserted_products FROM ins;
