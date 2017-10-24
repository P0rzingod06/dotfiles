select *
from apps.wwt_oe_order_headers_all_v
where 1=1
and creation_date > sysdate - 10
and order_number IN (6978890)
;
select wooha.*,woola.*
from apps.wwt_oe_order_headers_all_v wooha, apps.oe_order_lines_all woola
where 1=1
--and creation_date > sysdate - 1
and wooha.header_id = woola.header_id
--and ordered_item LIKE '%AIR-ANT2422DB-R%'
and order_number IN (6979132)
;
select count(*) from apps.wwt_orcp_header woh, apps.wwt_orcp_line wol
where 1=1
and woh.header_id = wol.header_id
and woh.customer_reference = '127973'
--order by last_update_date desc
;