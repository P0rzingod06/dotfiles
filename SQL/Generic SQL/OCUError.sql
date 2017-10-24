SELECT WOM.* --WOM.reference_value stg_hdr_id, WOM.message ocu_error_display, WOM.message_type  
FROM APPS.WWT_OM_ERRORS WOM
WHERE 1=1
--and reference_value = 21850725--stg hdr id
--and reference_value like ('19232%')
--and creation_date >= to_date('26-JUL-2013','DD-MON-YYYY')
and creation_date > sysdate - 1
order by creation_date desc
;
select * from APPS.WWT_OM_ERROR_LOG
where 1=1
and creation_Date > sysdate - 260
--and reference_value = 20470494
order by creation_Date desc
;
select * from dba_tables
where 1=1
and table_name LIKE '%WWT_OM%'
;