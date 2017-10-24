select * from dba_objects
where 1=1
and object_name LIKE '%EXEC%'
and object_type LIKE '%PACKAGE%'
;
WWT_PROCESS_EXEC_API
;
select * from apps.WWT_PROCESS_EXEC_STATUS
where 1=1
and process_name LIKE '%Salesforce%'
;--10-NOV-15 23:00:01