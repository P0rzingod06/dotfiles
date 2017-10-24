select customer_po_number, header_id, status, status_message, creation_date from wwt_orig_order_headers
where 1=1
--and customer_po_number = '0080044343'
and customer_name = 'Microsoft Ireland Operations Limite' 
and creation_Date > sysdate - 50

update wwt_orig_order_headers
set status = 'PROCESSED', status_message = 'Successfully Processed - Rules Applied'
where 1=1
and header_id = 16456815

select * from wwt_orig_order_headers
where header_id = 16457282