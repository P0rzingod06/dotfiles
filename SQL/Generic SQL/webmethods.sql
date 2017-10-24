select * from dba_objects
where 1=1
and object_name LIKE '%ORDER%IMPORT%'
;
select * from apps.wwt_om_process_groups
where 1=1
--and creation_date > sysdate - 100
--and edi_test_id = '045087574T'
;
select * from apps.wwt_webmethods_services
where 1=1
--and service_name LIKE '%callDefinePr%'
and lower(package_name) LIKE '%dgh%'
--and lower(SQL_TEXT) LIKE '%SDA%'
--and service_type = 'AdapterService'
order by service_name desc
;
select * from apps.wwt_webmethods_constants
where 1=1
and wm_package LIKE '%SAF%'
--and lower(wm_value) LIKE '%purchasing_enabled_flag%'
--and wm_key LIKE '%processingMethod%'
;
select * from dba_objects
where 1=1
and object_name like '%APPLICATION%LOG%'
and object_type = 'TABLE'
;
select * from apps.WWT_APPLICATION_LOG
where 1=1
and creation_date > sysdate - 50
and application_name IN ('Punchin')
order by creation_date desc
;
Run WmTN/wm.tn.delivery:getRegisteredServices to get registered delivery methods in TN
;
select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_EXTRACT_REQUEST_DATA'--WWT_EXTRACT_REQUEST_DATA--DSH_EXTRACT_PARAMETERS
and attribute1 = 'WWT_FOXCONN_SHIPMENTS_ORG_78_82'
;
select * from apps.WWT_WM_PROCESS_LOG
where 1=1
and creation_Date > sysdate - 1
order by creation_date desc
;
select * from WWT.WWT_PROCESS_ERROR_LOG
where 1=1
and creation_date > sysdate - 10
order by creation_date desc
;
WWT_ORDER_IMPORT_PKG;apps.wwt_cisco_booking_header;WWT_BOEING_MSRRAD_INSERT_STG;WWT_ORIG_ORDER_INSERTS;WWT_WM_LOGGING;WWT_OM_DEFINE_PROCESS_GROUPS
;
update apps.wwt_webmethods_constants
set wm_value = '850ToQSYS:{State of Michigan, Texas Instruments, General Motors,ToQSYS_END}
850ToCopStage:{Dell Computer Corporation,850ToCopStage_END}
850ToQuote:{Verizon-044760643,850ToQuote_END}'
where 1=1
and wm_package LIKE '%IB%850%'
--and lower(wm_value) LIKE '%purchasing_enabled_flag%'
and wm_key LIKE '%processingMethod%'
;
select * from wwt_process_exec_status
where 1=1
and creation_Date < sysdate - 10
order by creation_Date desc
;
CFI_Planners@wwt.com,gCFI@wwt.com,Rachel.Seymour@wwt.com,Gail.Mohler@wwt.com,Karen.Isayama@wwt.com,Ramona.Winthrop@wwt.com
;
APPS.EVENT_NOTIFICATIONS.UPDATE_ORDER_EVENT_LOG
;
