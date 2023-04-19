-- Creating and filling table
CREATE TABLE test (
    id integer,
    name text,
    alive boolean
);

INSERT INTO
    test (
        id,
        name,
        alive
    )
SELECT
    id,
    chr((32+random()*94)::integer),
    random() < 0.01
FROM
    generate_series(1,1000000) id;
    
-- Sequential scan and index scan
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id = 50000;

-- Creating a primary key index
ALTER TABLE test
    ADD CONSTRAINT test_id_pkey PRIMARY KEY (id);

-- Creating a normal index
CREATE INDEX ON test(name);

-- Regular index scan
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id = 50000;

-- Assessing correlation
ANALYZE test;

SELECT
    attname,
    correlation
FROM
    pg_stats 
WHERE 
    tablename = 'test'
ORDER BY
    abs(correlation) DESC;

-- Larger Index scan, high correlation
SET enable_seqscan = on;
SET enable_bitmapscan = on;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 35000;

-- Larger index scan, low correlation
DELETE FROM test;

INSERT INTO
    test (
        id,
        name,
        alive
    )
SELECT
    id,
    chr((32+random()*94)::integer),
    random() < 0.01
FROM
    generate_series(1,1000000) id
ORDER BY random();
    
ANALYZE test;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 35000;

-- Sequential scan chosen due to low correlation
SET enable_seqscan = on;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT * FROM test WHERE id <= 35000;

-- Bitmap scan
SET enable_bitmapscan = on;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT * FROM test WHERE id <= 35000;

-- Bitmap scan operations
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE (id <= 20000 OR id >= 950000) AND name = 'b';

-- Index only scans 
EXPLAIN (COSTS OFF, ANALYZE)  SELECT id FROM test WHERE id = 50000;
