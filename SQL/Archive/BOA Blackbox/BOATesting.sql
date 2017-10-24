select * from dba_objects
where 1=1
and object_name LIKE '%BOA%'
and object_type LIKE 'PACKAGE%BODY%'

WWT_BOA_BLACKBOX_UPLOAD_PKG

select batch_Id, count(*) from WWT_BOA_BLACKBOX_SERIAL
group by batch_id

delete from WWT_BOA_BLACKBOX_SERIAL

select batch_Id, count(*) from WWT_BLACKBOX_SERIAL_ARCHIVE
group by batch_id

delete from WWT_BLACKBOX_SERIAL_ARCHIVE

select batch_Id, count(*) from WWT_BOA_BLACKBOX_INVENTORY
group by batch_id

delete from WWT_BOA_BLACKBOX_INVENTORY

select batch_Id, count(*) from WWT_BLACKBOX_INVENTORY_ARCHIVE
group by batch_id

delete from WWT_BLACKBOX_INVENTORY_ARCHIVE

select * from wwt_frolic_status_log
where 1=1
and creation_Date > sysdate - 1
order by creation_date desc

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
and attribute2 = 'CATALOG - TECHDATA'

