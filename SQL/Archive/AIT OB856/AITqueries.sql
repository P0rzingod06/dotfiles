select 
distinct DECODE (UPPER (wnd.waybill),
'MULTI', NVL (wdd.attribute11, wdd.tracking_number),
NVL (wdd.attribute11, wdd.tracking_number))
tracking_num,
NVL (wnd.attribute2, wnd.ship_method_code) freight_carrier_code --TD5[1]:TD503
from apps.wwt_oe_order_headers_all_v oha,apps.oe_order_lines_all ola
,apps.wsh_delivery_details wdd,apps.wsh_delivery_assignments wda,apps.wsh_new_deliveries wnd
where 1=1
and oha.order_number = 6177173
and oha.header_id = ola.header_id
and wdd.source_line_id = ola.line_id
and wdd.delivery_detail_id = wda.delivery_detail_id
and wda.delivery_id = wnd.delivery_id
;
select isa.ATTRIBUTE7 TRANSPORT
 from apps.WWT_LOOKUPS_ACTIVE_V isa
 where isa.LOOKUP_TYPE = 'ISA_ENVELOPE'
 and isa.DESCRIPTION = ?
 and isa.ATTRIBUTE6 = ?
 and isa.ATTRIBUTE1 = ?
;
select waoo.sales_order_num,waos.* from apps.wwt_asn_outbound_shipments waos,apps.wwt_asn_outbound_orders waoo
where 1=1
and waos.creation_date > sysdate - 250
and waos.partner_id IN ('AIIH','AIIHT')
and waos.shipment_id = waoo.shipment_id
--and shipment_id = 9274570
order by waos.creation_date desc
;--6207025
--6207012
--6206992
--6206964
--6177173
--6206877
select * from wwt_asn_outbound_orders
where 1=1
and shipment_id IN (9253460,9253461,9253459,9274570)
order by creation_date desc
;
select * from wwt_asn_outbound_packages
where 1=1
and shipment_id IN (9253460,9253461,9253459)
;
select * from wwt_asn_outbound_items
where 1=1
and shipment_id IN (9253460,9253461,9253459);

update wwt_asn_outbound_shipments
set process_status = 'UNPROCESSED',partner_id='AIIHT'--, SCAC_CODE = null, waybill=null --89767564343234
where 1=1
--and partner_id = 'AIIHT'
and shipment_id = 10153273;

select
distinct DECODE (UPPER (wnd.waybill),
'MULTI', NVL (wdd.attribute11, wdd.tracking_number),
NVL (wdd.attribute11, wdd.tracking_number))
tracking_num
from apps.wsh_new_deliveries wnd,apps.wsh_delivery_details wdd,
apps.wsh_delivery_assignments wda
where 1=1
and wnd.delivery_id = 6198488--don't forget drop ship orders with -1 delivery_id
and wda.delivery_id = wnd.delivery_id
and wda.delivery_detail_id = wdd.delivery_detail_id
;

select * from wwt_orig_order_headers
where 1=1
and creation_date > sysdate - 10
--and process_group_id = 2285
order by creation_date desc

select * from oe_order_lines_all
where 1=1
and header_id IN ('13510499','13510498','13510497')
--and creation_date > sysdate - 10
order by creation_date desc

select delivery_id, confirm_date from WSH_NEW_DELIVERIES
where 1=1
and creation_date > sysdate - 1
and delivery_id IN (1097950709,1097950708,1097950707)
order by creation_date desc

update wsh_new_deliveries
set confirm_date = sysdate
where 1=1
and delivery_id IN (1097950709)
              
select * from WWT_ASN_OB_LOG
order by creation_Date desc

UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_' || ?
WHERE process_status = 'UNPROCESSED'
AND communication_method = 'EDI'
AND partner_id = ?

SELECT pd.partner_id,
       APPS.WWT_ASN_OUT_HEADER_BATCH_S.NEXTVAL batch_id
FROM 
    (SELECT DISTINCT partner_id
       FROM apps.wwt_asn_outbound_shipments
      WHERE 1=1
        AND process_status = 'UNPROCESSED'
        AND communication_method = 'EDI'
        AND partner_id is not null 
AND partner_id in (select ATTRIBUTE1 from apps.WWT_LOOKUPS_ACTIVE_V where 
lookup_type = 'WWT_WM95_EDI_PARTNERS'
and ATTRIBUTE3 = 'EDI_OB856')) pd
WHERE 1=1

select * from apps.WWT_LOOKUPS_ACTIVE_v where 
lookup_type = 'WWT_WM95_EDI_PARTNERS'
and ATTRIBUTE3 = 'EDI_OB856'

select * from dba_objects
where status = 'INVALID'
order by owner, object_name, object_type

select * from fnd_user
where 1=1
and user_id = 8157

select * 
from apps.wwt_asn_outbound_shipments
where process_status = 'ERROR_920071'

   select * from wwt_lookups
   where 1=1
   and lookup_type = 'GS_ENVELOPE'
   and start_date_active > sysdate - 30
   
select hla.*  from
apps.wwt_oe_order_headers_all_v ooha
,ont.oe_order_lines_all oola
,apps.hr_organization_units hou
,hr.hr_locations_all hla
where ooha.header_id = oola.header_id
and ooha.order_number = '5702775'
and oola.ship_from_org_id = hou.organization_id
and hou.location_id = hla.location_id

hla.address_line_1 "ASN_VALUES/N3[1]:N301", hla.address_line_2 "ASN_VALUES/N3[1]:N302", 

select  hla.address_line_1 "ASN_VALUES/N1[2]:N3[2]:N301",
hla.address_line_2 "ASN_VALUES/N1[2]:N3[2]:N302",
hla.TOWN_OR_CITY "ASN_VALUES/N1[2]:N4[2]:N401", 
hla.REGION_2 "ASN_VALUES/N1[2]:N4[2]:N402:code", 
hla.POSTAL_CODE "ASN_VALUES/N1[2]:N4[2]:N403:code"
from
apps.wwt_oe_order_headers_all_v ooha
,ont.oe_order_lines_all oola
,apps.hr_organization_units hou
,hr.hr_locations_all hla
where ooha.header_id = oola.header_id
and ooha.order_number = %Order/SALES_ORDER_NUM%
and oola.ship_from_org_id = hou.organization_id
and hou.location_id = hla.location_id

select  hla.address_line_1 "N1[SF]:N3[1]:N301"
from
apps.wwt_oe_order_headers_all_v ooha
,ont.oe_order_lines_all oola
,apps.hr_organization_units hou
,hr.hr_locations_all hla
where ooha.header_id = oola.header_id
and ooha.order_number = 6198488
and oola.ship_from_org_id = hou.organization_id
and hou.location_id = hla.location_id
;