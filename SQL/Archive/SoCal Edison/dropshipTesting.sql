select oha.header_id,oha.creation_date,oha.salesrep_id,oha.ship_to_org_id,jrs.salesrep_id,
--,pha.attribute9,pha.attribute9,pha.po_header_id, pla.po_header_id,
--wnd.delivery_id,wnd.confirm_date ,wnd.asn_date_sent,
ola.line_type_id,ola.split_from_line_id,OLA.ORDERED_QUANTITy,ola.split_from_line_id,
es.shipment_id,es.status,es.last_update_date,es.pickup_date,ep.attribute9
from oe_order_headers_all oha,oe_order_lines_all ola,wsh_delivery_details wdd, 
--wsh_delivery_assignments wda,wsh_new_deliveries wnd,
JTF_RS_SALESREPS jrs,
po_headers_all pha,PO_LINES_ALL pla,
END_PACKAGES EP, END_SHIPMENTS es,
PO_REQUISITION_LINES_ALL prla, po_line_locations_all plla
where 1=1
and oha.order_number IN ('5707010')--,'5706484')
and oha.header_id = ola.header_id
and jrs.salesrep_id=oha.salesrep_id
and wdd.source_line_id = ola.line_id
--and wdd.delivery_detail_id = wda.delivery_detail_id
--and wda.delivery_id = wnd.delivery_id
and pla.line_num = ep.erp_line_number
and ep.shipment_id = es.shipment_id
--and es.shipment_id = 2885960
and ola.attribute20 = prla.REQUISITION_LINE_ID
and plla.line_location_ID = prla.line_location_ID
and plla.PO_LINE_ID = pla.po_line_id
and pla.po_header_Id = pha.po_header_id

--and pha.attribute9 = 100014279
--order by es.last_update_date desc

select * from po_headers_all
where 1=1

update po_headers_all
set attribute9 = 100014279
where 1=1
and  po_header_id = 191275
--order by last_update_date desc

update END_SHIPMENTS
set last_update_date = sysdate
where 1=1
and shipment_id = 2885960
--and status NOT IN ('Cancelled', 'Closed', 'Open')
--and last_update_date > sysdate - 150

select * from wsh_new_deliveries
where 1=1
and delivery_id = 865508661

update wsh_new_deliveries
set confirm_date = sysdate
where 1=1
and delivery_id = 865508661

update oe_order_headers_all
set salesrep_id = 100014279
where 1=1
and sold_to_org_id = 2368546

wwt_asn_outbound_extract

select * from dba_directories
where 1=1
and directory_name = 'WWT_DR_PD_NASA_ITEM_LOAD'

DROP DIRECTORY WWT_DR_PD_NASA_ITEM_LOAD

select shipment_id,delivery_id,creation_Date,partner_id from wwt_asn_outbound_shipments
where 1=1
and creation_Date > sysdate - 1
--and partner_id = 'SOCALEDISON'
--and delivery_id = 865508661
--and shipment_id IN (9273539,
--9273540,
--9273541,
--9273542)
order by creation_Date desc

select * from wwt_asn_outbound_orders
where 1=1
and shipment_id IN (9273555,
9273554,
9273553)
and sales_order_num = '5707010'

select * from wsh_new_deliveries
where 1=1
and delivery_id = 1098083682

delete from wwt_asn_outbound_shipments
where 1=1
and shipment_id = 9273550

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_ASN_OUTBOUND_EXTRACT'
and (description LIKE '%SoC%' OR description LIKE '%ASN%Re%')

100403289

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_OM_LINE_FLOW_CONTROLS'
and attribute2 = 'DROP_SHIP'

select * from oe_order_headers_all
where 1=1
and order_number = 5707010
