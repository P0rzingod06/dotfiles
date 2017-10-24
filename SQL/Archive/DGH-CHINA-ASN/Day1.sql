select header_id from wwt_orig_order_headers
where 1=1
and source LIKE '%DGH_ASN%'
--and (wwt_attribute3 LIKE '%1%' OR attribute3 LIKE '%1%')
and creation_date < sysdate - 10
order by creation_date DESC

--update wwt_orig_order_headers
--set status = 'UNPROCESSED'
--where header_id IN (15893689, 10841392, 10841419)

update wwt_orig_order_headers
set status = 'UNPROCESSED'
where header_id IN (15939143, 15942693)

select header_id, status, last_update_date, source from wwt_orig_order_headers
where header_id IN (15939143, 15942693)

select * from wwt_orig_order_headers
where header_id IN (15939143, 15942693)

update wwt_orig_order_lines
set wwt_attribute3 = ''
where header_id IN (15939143, 15942693)

--update wwt_orig_order_lines
--set attribute3 = '21'
--where header_id IN (10841392)

select line_id, wwt_attribute3, inventory_item_id, header_id, inventory_item_id from wwt_orig_order_lines
where 1=1
--and line_id IN (25944397)
and header_id IN (15939143, 15942693, 15930671)

update wwt_orig_order_lines
set inventory_item_id = 17149079
where header_id IN (15930671)

select header_id, orig_header_id, last_update_date, program, wwt_attribute10 from wwt_stg_order_headers
where orig_header_id IN (19867202, 19867203, 19867232, 19867233)
and last_update_date > sysdate - 1
order by creation_date DESC

select header_id, orig_header_id, last_update_date, program, salesrep from wwt_stg_order_headers
where orig_header_id IN (15939143, 15942693, 15930671)
and last_update_date > sysdate - 10
order by creation_date DESC

select line_id, header_id, orig_line_id, invoice_to_org_id, invoice_to_customer_name, invoice_to_address1 from wwt_stg_order_lines
where header_id IN (19867237, 19867236)
--and last_update_date > sysdate - 1
order by creation_date DESC

select * from wwt_lookups
where lookup_type = 'WWT_DGH_COP_DEFAULTS'

wwt_order_import_pkg.plb

select site_use_id, org_id from hz_cust_site_uses_all
where site_use_id = 862546

select product_attr_value, product_attribute_context, product_attribute, list_line_id  from qp_pricing_attributes
where 1=1
--and product_attr_value = '17026057'
and list_line_id IN (5051630, 4951599, 5123595)

select list_header_id, attribute4, list_line_id from qp_list_lines
where 1=1
--and list_line_id IN (4827597, 5062597)
and attribute4 LIKE '%ECN-Wistron-Consigned%'
