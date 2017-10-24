select last_update_date,demand_source_name,last_updated_by,reservation_quantity, primary_reservation_quantity, inventory_item_id--* 
from apps.mtl_reservations
where 1=1
and creation_Date > sysdate - 3
--and inventory_item_id IN (17945826)
order by last_update_date desc
;
select * from dba_objects
where 1=1
and object_name like UPPER('%fnd%log%')
and object_type = 'TABLE'
order by object_name
;
select * from FND_TRACE_LOG
where 1=1
--and creation_Date > sysdate - 1
--and log_level = 5
and timestamp > sysdate - 10
--and message_text like '%l_atr_qty%'
;
select * from FND_LOG_MESSAGES
where 1=1
--and creation_Date > sysdate - 1
--and log_level = 5
and timestamp > sysdate - 10
and message_text like '%l_atr_qty%'
;
select * from wwt_application_log
where 1=1
and creation_Date > sysdate - 1
and application_name = 'WWT_SVC_INVENTORY_PKG'
--and application_name != 'WWT_PARTNER_HUB'
order by creation_date desc
;
