select source, status
from apps.WWT_orig_ORDER_HEADERS_v h
where H.CUSTOMER_PO_NUMBER IN ('70493','70491', '70494')

select * from wwt_frolic_status_log
where 1=1
and creation_Date > sysdate - 5
order by creation_date desc

select * from wwt_upload_generic_log
where 1=1
and batch_id = 682063

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
and attribute1 = 224
--and description LIKE '%AMAZON%'

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_WORKFLOW'
and attribute1 = 224

select * from wwt_upload_generic_log
where 1=1
and batch_id = 682067

wwt_amazon_vendor_sup_rep
