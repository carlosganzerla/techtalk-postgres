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
    generate_series(1,1000000) id
ORDER BY
    random();
	
CREATE INDEX ON test(name);

-- Sequential scan and index scan
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id = 50000;

-- Creating a primary key index
ALTER TABLE test
    ADD CONSTRAINT test_id_pkey PRIMARY KEY (id);

-- Assessing correlation
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
SET enable_seqscan = off;
SET enable_bitmapscan = off;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 2000;

-- Larger index scan, low correlation
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE name <= 'm';

-- Sequential scan faster index scan
SET enable_seqscan = on;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE name <= 'm';

-- Bitmap scan
SET enable_bitmapscan = on;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 2000 

-- Bitmap scan operations
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 2000 AND name = 'b';
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 2000 OR name = 'b';

-- Index only scans and covering indexes
EXPLAIN (COSTS OFF, ANALYZE)  SELECT id FROM test WHERE id = 50000;
