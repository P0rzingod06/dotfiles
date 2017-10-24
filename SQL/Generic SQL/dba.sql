select * from dba_ddl_locks
where 1=1
--and object_name like UPPER('%fnd%log%')
--and object_type = 'TABLE'
--order by object_name
;
SELECT * FROM v$session
WHERE username = 'WWT_CF_INVENTORY_API'
AND status = 'ACTIVE'