select * from dba_objects
where 1=1
and object_name LIKE '%WWT%SO%'
and object_type LIKe '%PACKAGE%'
;
WWT_UPLOAD_SO_UPDATE
;
WWT_SO_UPDATE
;
wwt_util_organization_pkg;

WWT_OM_DEFINE_PROCESS_GROUPS;

WWT_OM_RULE_INSERTS
;
WWT_OM_CASCADE_VALUES_TO_LINES
;
--p_schedule_date has to come in NULL
select * from APPS.WWT_STG_ORDER_HEADERS_V
fnd_date.canonical_to_date
;
select * from apps.wwt_so_update_stg
--group by creation_Date
--where sales_order_num = 5927037
where 1=1
and creation_Date > sysdate - 25
--and sales_order_num = 6170567
--and status = 'U'  
order by creation_Date desc
;
update apps.wwt_so_update_stg
set status = 'U',error_msg=null,last_update_date=sysdate,last_updated_by=55386
where 1=1
and so_id = 68576
--and creation_Date > sysdate - 25
--and status = 'U'
;
select * from apps.wwt_so_update_stg
where 1=1
--and sales_order_num IN (5985852)
order by creation_Date desc
;
select * from apps.wwt_frolic_status_log
where 1=1
and creation_Date > sysdate - 100
and source_name IN ('SALES ORDER UPDATE', 'SO Update')
and process_name = 'Frolic'
--and batch_id = 731383
order by creation_date desc
;
select * from apps.wwt_upload_generic_log
where 1=1
and batch_id = 732722--730237--731383
--and (ID > 2484490196 - 10 AND ID < 2484490206 + 10)
--and message LIKE '%5985852%'
order by ID
;
select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_OXBOW_SOURCING_RULES'
--and description LIKE '%SO%'
--and attribute10 LIKE '%so_uodate%'
--and attribute1 = 219
;
SELECT * 
FROM APPS.FND_USER
WHERE 1=1
--and USER_NAME = UPPER('ZALOGAM')
--and 
and user_id = 53667
;
select user_name from apps.fnd_user where user_id = fnd_global.user_id
;
select user_name from fnd_user where user_id = fnd_global.user_id