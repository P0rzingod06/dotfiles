WWT_BOEING_MSRRAD_MARRYUP;WWT_BOEING_MSRRAD_DII_IMPORT;WWT_BOEING_MSRRAD_INSERT_STG
;
select * from apps.WWT_BOEING_MSRRAD_DII
where 1=1
and creation_date > sysdate - 5
;
select marry_up_status,sspn_po_no,last_update_Date
from apps.WWT_BOEING_MSRRAD_PO_HEADERS
where 1=1
and creation_Date > sysdate - 100
order by creation_Date desc
;
select count(*)
from partner_admin.WWT_BOEING_MSRRAD_PO_HEADERS 
where 1=1
--and sspn_PO_no in ( '1103205804') 
and wwt_Attribute4 IS NOT NULL
and creation_Date > sysdate-800
--and marry_up_status in ( 'PROCESSED','DO NOT PROCESS')
;
select ATTRIBUTE4,ATTRIBUTE8,last_update_date
from partner_admin.WWT_BOEING_MSRRAD_PO_LINES 
where 1=1
--and SSPN_PO_NO = '1102991940' 
and creation_Date > sysdate - 100
--and ATTRIBUTE8 is not null
order by creation_date desc
;
select * from dba_objects
where 1=1
and object_name LIKE '%Unbundle%'