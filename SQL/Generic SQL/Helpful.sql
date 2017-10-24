select *  from dba_synonyms
;
select * from all_db_links
;
select * from sys.all_directories
  where directory_name like '%EPOD%'
; 
select * from dba_users
where 1=1
and username = 'WWT'
;
select * from sys.dba_tables
where 1=1
--and table_name LIKE '%BLACKBOX%'
;
select * from dba_indexes
where 1=1
and index_name LIKE '%BLACKBOX%'
;
select * from sys.dba_objects
where 1=1
and object_type = 'TABLE'
and object_name LIKE '%TRANSACTIONS%LOG%'
;