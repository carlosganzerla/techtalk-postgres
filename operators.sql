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

-- Access method properties
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
