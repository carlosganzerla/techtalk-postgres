-- Unique indexes and foreign keys

-- -- Foreign keys vs unique constraints
ALTER TABLE test
    ADD COLUMN child_name text REFERENCES test (name);

-- -- UNIQUE vs PRIMARY KEY
ALTER TABLE test
    ADD COLUMN child_id integer UNIQUE REFERENCES test (id);

-- -- Filling some child ids
SELECT * FROM test LIMIT 2;

ANALYZE test;

-- Dealing with nulls
UPDATE
    name
SET
    name = null
WHERE
    id % 77 = 0;

ANALYZE test;

-- -- Showing that B-Tree indexes nulls
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE name IS NULL;


-- Partial index
CREATE INDEX ON test (alive);

ANALYZE test;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE alive;
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE NOT alive;

-- -- Index size
SELECT relpages FROM pg_class WHERE relname='test_alive_idx';

DROP INDEX test_alive_idx;

CREATE INDEX ON test (alive) WHERE alive;

ANALYZE test;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE alive;

SELECT relpages FROM pg_class WHERE relname='test_alive_idx';

-- Expression indexes
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT * FROM test WHERE id % ascii(name) = 0;

CREATE INDEX test_expr_idx ON test ((id % ascii(name)));

ANALYZE test;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT * FROM test WHERE id % ascii(name) = 0
 
-- -- Wont work because it's not IMMUTABLE
CREATE INDEX test_expr_2_idx ON test ((id %  EXTRACT(DAY FROM CURRENT_DATE)::integer));

-- Sorting
DROP INDEX test_name_idx;

ANALYZE test;

-- -- Combining and not using for sorting
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) 
SELECT * FROM test WHERE alive ORDER BY id % ascii(name);

-- -- Using sort and limit
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) 
SELECT * FROM test WHERE alive ORDER BY id % ascii(name) LIMIT 100;

-- Backward index scan
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) 
SELECT * FROM test WHERE alive ORDER BY id % ascii(name) DESC LIMIT 100;

-- -- Using sorting and limit to fetch a single value
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) 
SELECT * FROM test ORDER BY id LIMIT 1;

-- -- Combining other columns on sort
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) 
SELECT * FROM test ORDER BY id, name, alive LIMIT 1;

-- -- Does not work if index is not the first
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) 
SELECT * FROM test ORDER BY name, id, alive LIMIT 1;

-- Multi-column indexes
CREATE INDEX ON test (id, name);

ANALYZE test;

-- -- Uses index scan instead of bitmap scan
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 200 AND name = 'b';
-- -- Does not work with OR
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE id <= 200 OR name = 'b';
-- -- Using union to trigger index
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)
SELECT * FROM test WHERE id <= 200
UNION
SELECT * FROM test WHERE name = 'b';

-- Using INCLUDE to create covering indexes
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT id, name, alive FROM test WHERE id = 200

CREATE INDEX ON test (id) INCLUDE (name, alive);

ANALYZE test;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT id, name, alive FROM test WHERE id = 200

-- -- Doesn't work with wildcard
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT * FROM test WHERE id = 200

-- -- Include can also be used on searches
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)
SELECT id, name, alive FROM test WHERE id IN (200, 300, 400) AND name = 'B';

-- EXCLUDE constraints example
ALTER TABLE test
    ADD COLUMN magic_number integer,
    ADD EXCLUDE (magic_number WITH =);

-- -- Insert a magic number;
SELECT * FROM test LIMIT 2;

ANALYZE test;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS) SELECT * FROM test WHERE magic_number = 3;

-- Clustering
CREATE INDEX ON test (name);

ANALYZE test;

-- -- Assessing correlation again
SELECT
    attname,
    correlation
FROM
    pg_stats 
WHERE 
    tablename = 'test'
ORDER BY
    abs(correlation) DESC;

SET enable_seqscan = off;
SET enable_bitmapscan = off;

EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE name <= 'c';

CLUSTER test USING test_name_idx;

ANALYZE test;
-- -- Assess correlation again ...

-- -- Evaluate performance of correlated query
EXPLAIN (COSTS OFF, ANALYZE, BUFFERS)  SELECT * FROM test WHERE name <= 'c';
