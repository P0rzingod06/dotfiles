SELECT p.organization_code, 
attribute3 Consigned_flag, 
attribute4, 
attribute5, 
attribute7 dropship_flag, 
p.* 
FROM inv.mtl_parameters p 
WHERE 1 = 1 
and organization_id = '15587'--:oola.ship_from_org_id
--and organization_code in ('103','10','22','25','04') 
ORDER BY p.organization_code

--OE lines has ship_from_org_id

select * from apps.mtl_parameters

select * from apps.oe_order_lines
where 1=1
and line_id = '31645816'

select * from apps.oe_order_headers
where 1=1
--and header_id = 13525694
and order_number = '4500607795'
--and customer_po_number = '4500607795'
;

select * from apps.wwt_asn_outbound_shipments
where 1=1
and partner_id LIKE '%SOCAL%'
--and shipment_id IN (9268016,
--9268020,
--9261033,
--9261034)
and creation_Date > sysdate - 10
--and delivery_id = 119703019
order by creation_Date desc
;2

select * from wwt_asn_outbound_orders
where 1=1
and shipment_id IN (9268016,
9268020,
9261033,
9261034);

select * from apps.wwt_asn_outbound_items
where 1=1
and shipment_id IN (10029712)
;

select * from wwt_lookups
where 1=1
and lookup_type LIKE '%ASN%EXTRACT%'
and description LIKE '%SoCal Edison%'

wwt_asn_outbound_extract

wwt_asn_outbound_sce;

SELECT MIN(waoi.item_id) item_id,
waoi.inventory_item_id,
nvl(waoe.attribute1, waoi.customer_line_num),
waoi.ordered_UOM,
SUM(waoi.quantity_shipped) quantity_shipped
FROM apps.wwt_asn_outbound_items waoi, apps.wwt_asn_outbound_extensions waoe, apps.wwt_asn_outbound_packages waop
WHERE 1=1
and waoi.shipment_id = 10029712
and waoi.item_id = waoe.common_table_id
and waoi.package_id = waop.package_id
GROUP BY  nvl(waoe.attribute1, waoi.customer_line_num), inventory_item_id, Ordered_UOM
;