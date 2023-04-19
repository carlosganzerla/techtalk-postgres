-- Access methods
SELECT
    *
FROM 
    pg_am;

-- Classes, access method and families from an access method
SELECT
    am.amname access_method,
    opcname class_name,
    opfname family_name,
    amopopr::regoperator
FROM 
    pg_am am
JOIN 
    pg_opfamily opf 
ON
    opfmethod = am.oid
JOIN
    pg_opclass opc 
ON
    opcfamily = opf.oid
JOIN
    pg_amop amop
ON
    amopfamily = opcfamily
WHERE
    am.amname = 'btree'
ORDER BY 
    access_method,
    family_name,
    class_name;

-- Access method level properties
SELECT
    a.amname,
    p.name,
    pg_indexam_has_property(a.oid, p.name)
FROM 
    pg_am a,
    unnest(array['can_order','can_unique','can_multi_col','can_exclude', 'can_include']) p(name)
WHERE
    a.amname = 'brin'
ORDER BY a.amname;

-- Index level properties
SELECT
    p.name,
    pg_index_has_property('test_name_idx'::regclass,p.name)
FROM
    unnest(array[
       'clusterable','index_scan','bitmap_scan','backward_scan'
     ]) p(name);

-- Index column level properties
SELECT
    p.name,
    pg_index_column_has_property('test_name_idx'::regclass,1,p.name)
FROM
    unnest(array[
       'asc','desc','nulls_first','nulls_last','orderable','distance_orderable',
       'returnable','search_array','search_nulls'
     ]) p(name);
