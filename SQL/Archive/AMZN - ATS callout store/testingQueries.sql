select header_id, source,order_source, freight_charges,status, status_message, ship_to_country, last_update_date from wwt_orig_order_headers
where 1=1
and creation_Date > sysdate - 10
--and process_group_id = 1624
and header_id = 16385118
and order_source = 'Callout Generic'
order by creation_date desc

update wwt_orig_order_headers
set status = 'UNPROCESSED', ship_to_country = 'US'
where 1=1
and header_id = 16385118

select ordered_quantity, unit_selling_price, last_update_date from wwt_orig_order_lines
where 1=1
and creation_date > sysdate - 10
and header_id = 16385118

select header_id, orig_header_id, ship_to_country, freight_charges,last_update_date from wwt_stg_order_headers
where 1=1
and creation_date > sysdate - 10
and process_group_id = 1624
and orig_header_id = 16385118
order by creation_date desc

Amazon ATS Callout

select * from oe_order_headers_all
where 1=1
and creation_date > sysdate - 10
and order_number = 5702733
order by creation_Date desc

select * from apps.oe_lookups
where 1=1
and lookup_type = 'FREIGHT_TERMS'

select ROUND(SUM(ordered_quantity * unit_selling_price),2)
from apps.wwt_orig_order_lines 
where 1=1
and header_id = 16385118

wwt_om_rule_inserts

select * from APPS.WWT_OM_DATASET

select * from APPS.WWT_OM_DATASET_ELEMENTS
where 1=1
and NAME like '%FREIGHT%'

select * from wwt_om_condition_set
where 1=1
and name like '%Freight Charge%'

select * from wwt_stg_order_lines