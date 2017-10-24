select  WEDV.ASSET_ID ASSET_TAG,
WEDV.GRP_BRANCH GROUPBRANCH,
WXSS.C_ATTRIBUTE9 IMEI,
WXSS.C_ATTRIBUTE10 SIM,
WXSS.C_ATTRIBUTE13 PHONE_NUMBER,
WEDV.DEVICE_CARRIER CARRIER,
WEDV.DEVICE_LANGUAGE LANGUAGE
 from WWT_EHI_DAILY_VENDOR_V WEDV,
 WWT_XXWMS_SERIAL_SHIPPING_V WXSS
 WHERE 1=1
 
 select * from WWT_EHI_DAILY_VENDOR_V
 
 grant select on apps.wwt_ehi_stratix_shipments_v to WWT_B2B;
 
 wwt_ehi_stratix_shipments_v
 
 select * from WWT_XXWMS_SERIAL_SHIPPING_V

 select * from WWT_PROCESS_EXEC_STATUS
 where 1=1
and process_name LIKE '%EHI Stratix Vendor Report%'

update wwt_process_exec_status
set last_run_time = sysdate - 30
where 1=1
and process_name = '5'

select  EHI_ITEM_ID ITEMID,
 ASSET_TAG ,
GROUP_BRANCH,
IMEI_NUMBER IMEI,
ESN_SIM_NUMBER SIM,
PHONE_NUMBER,
DEVICE_CARRIER CARRIER,
DEVICE_LANGUAGE LANGUAGE
 from wwt_ehi_stratix_shipments_v
 
WWT_PROCESS_EXEC_API

select 
apps.wwt_report_context.set_num_context ('p_days_back', 3),
apps.wwt_report_context.set_date_context ('p_begin_date', sysdate-10), 
apps.wwt_report_context.set_date_context ('p_end_date', sysdate) 
from dual

select sysdate from dual

select 
apps.wwt_report_context.get_num_context ('p_days_back'),
apps.wwt_report_context.get_date_context ('p_begin_date'), 
apps.wwt_report_context.get_date_context ('p_end_date')
from dual

2015-02-23 09:10:24

select 
apps.wwt_report_context.set_num_context ('p_days_back', ?),
apps.wwt_report_context.set_date_context ('p_begin_date', ?),
apps.wwt_report_context.set_date_context ('p_end_date', ?) 
from dual