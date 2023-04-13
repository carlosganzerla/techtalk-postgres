SELECT
    a.amname,
    p.name,
    pg_indexam_has_property(a.oid, p.name)
FROM 
    pg_am a,
    unnest(array['can_order','can_unique','can_multi_col','can_exclude']) p(name)
WHERE
    a.amname = 'btree'
ORDER BY a.amname;
