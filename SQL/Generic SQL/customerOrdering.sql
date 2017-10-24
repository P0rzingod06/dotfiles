select header_id,STATUS_MESSAGE,status,customer_po_number,customer_name,attribute13,SHIP_TO_CONTACT_LAST_NAME,ORDERED_BY_CONTACT_FIRST_NAME,ORDERED_BY_CONTACT_LAST_NAME,ATTRIBUTE9,creation_Date
from apps.wwt_orig_order_headers_v
where 1=1
and process_group_id = 2924
and creation_Date > sysdate - 150
--and lower(customer_name) like '%mol%'
order by creation_date desc
;
update apps.wwt_stg_order_headers
set ORDERED_BY_CONTACT_FIRST_NAME = 'test',ORDERED_BY_CONTACT_LAST_NAME = 'test',status='UNPROCESSED',status_message = null
where 1=1
and header_id = 21838758
;
select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_CUSTOMER_INVENTORY_STORE_SPECIFIC_OTOS_DEFAULTS'
;
select * from wwt_quote.quote_batch_transaction
where 1=1
and creation_Date > sysdate - 10
;
wwt_svc_inventory_pkg
;