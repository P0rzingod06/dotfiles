SELECT p.organization_code, 
attribute3 Consigned_flag, 
attribute4, 
attribute5, 
attribute7 dropship_flag, 
p.* 
FROM inv.mtl_parameters p 
WHERE 1 = 1 
--and organization_id = '15587'--:oola.ship_from_org_id
and organization_code in ('103','10','22','25','04') 
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

select * from wwt_asn_outbound_shipments
where 1=1
--and partner_id LIKE '%SOCAL%'
and shipment_id IN (9268016,
9268020,
9261033,
9261034)

select * from wwt_asn_outbound_orders
where 1=1
and shipment_id IN (9268016,
9268020,
9261033,
9261034)

select * from wwt_asn_outbound_items
where 1=1
and shipment_id IN (9268016,
9268020,
9261033,
9261034)


--attribute2 < 0 for reporting
select *
from wwt_lookups
where 1=1
and lookup_type LIKE '%ASN%EXTRACT%'
--and description LIKE '%SoCal Edison%'
and attribute11 = 'Y'
--and attribute5 = 'XML'

--WWT_OM_LINE_FLOW_CONTROLS lookup attribute2 = drop_ship
--matched wl2.attribute1 to ola.line_type_id  OE_ORDER_LINES_ALL
---matched ola.line_id tp wdd.source_line_id  OE_ORDER_LINES_ALL OE_ORDER_LINES_ALL    WSH_DELIVERY_DETAILS
--matched wdd.delivery_detail_id to wda.delivery_detail_id  WSH_DELIVERY_DETAILS   WSH_DELIVERY_ASSIGNMENTS
--matched wda.delivery_id tp wnd.delivery_id   WSH_DELIVERY_ASSIGNMENTS    WSH_NEW_DELIVERIES

wwt_asn_outbound_extract

wwt_asn_outbound_sce

update apps.WSH_NEW_DELIVERIES
set ATTRIBUTE7 = NULL , ASN_DATE_SENT = NULL, CONFIRM_DATE = SYSDATE, status_code = ''
where 1=1
and delivery_id IN (1098044612)  --1098044612 --1098044612


select * from wsh_new_deliveries --delivery_id, organization_id, asn_date_sent, attribute7 from wsh_new_deliveries 
--where 1=1
--and creation_Date > sysdate - 4
where 1=1
--and delivery_id IN (1098058632)
--and org_id = 
and confirmed_by = 'SUARESP'
--and status_code NOT IN ('CL')
and creation_Date > sysdate - 50
--and asn_date_sent IS NULL
--and delivery_id IN (1098046797)
order by creation_date desc

select * from HZ_PARTIES
where 1=1
and party_name LIKE '%Edison%'
and party_type = 'ORGANIZATION'

select * from OE_ORDER_HEADERS_ALL
where 1=1
and 

select * from wwt_asn_outbound_shipments
where 1=1
--and creation_Date < sysdate - 1
and delivery_id = 1098044612  --1098044612
and communication_method = 'XML'
and process_status = 'UNPROCESSED'
order by creation_date desc

select wnd.*
from WSH_NEW_DELIVERIES wnd
,APPS.WSH_DELIVERY_DETAILS WDD
,APPS.WSH_DELIVERY_ASSIGNMENTS WDA
,APPS.WWT_LOOKUPS_ACTIVE_V WL2
,APPS.OE_ORDER_LINES_ALL OLA
where 1=1 
--AND delivery_id IN (1098058632)
--and wnd.organization_id IN ('582','583')
and wnd.confirmed_by = 'SUARESP'
and wnd.creation_date > sysdate - 50
AND WL2.LOOKUP_TYPE               = 'WWT_OM_LINE_FLOW_CONTROLS'
AND WL2.ATTRIBUTE2                          = 'DROP_SHIP'
AND TO_CHAR( OLA.LINE_TYPE_ID )      = WL2.ATTRIBUTE1
AND WDD.SOURCE_LINE_ID         = OLA.LINE_ID
AND WDA.DELIVERY_DETAIL_ID             = WDD.DELIVERY_DETAIL_ID
AND WDA.DELIVERY_ID                     = WND.DELIVERY_ID
