select ooha.order_number,shd.attribute99,ooha.header_id,ooha.attribute1,ooha.attribute19,ooha.attribute20,ooha.cust_po_number,ooha.creation_date,ooha.order_number,shd.attribute46,shd.attribute40,shd.attribute99,ooha.last_update_Date ,ooha.ordered_date
from apps.wwt_oe_order_headers_all_V ooha,apps.wwt_so_headers_dff shd
where 1=1
and ooha.cust_po_number = 'PO263121'
--and order_number = '5707571'
--and ooha.creation_date > sysdate - 10
and ooha.header_id = shd.header_id
order by ooha.creation_Date desc
;
update apps.oe_order_headers_all
set attribute1 = '2015-10-05T11:59:55-07:00'
where 1=1
and header_id = 13548146
--order by ooha.creation_Date desc
;
select * from apps.wwt_lookups
where 1=1
and lookup_type LIKE 'WWT_ASN_OUTBOUND_EXTRACT'--WWT_OB_PO_ACKS--WWT_ASN_OUTBOUND_EXTRACT--WWT_OUTBOUND_CXML_CONSTANTS--WWT_CXML_PARTNER_ENVIRONMENT
and description LIKE '%Charter%'  
;
select * from dba_objects
where 1=1
and object_name LIKE '%OE%ORDER%HEADER%'
;
select header_id,salesrep_id,cust_po_number,order_number,creation_date from oe_order_headers_all
where 1=1
--and order_number = 5706441
--and cust_po_number = 'PO46605'
--and salesrep_id = 100379288
order by creation_Date desc;

select oola.attribute9 vendor,oola.attribute16 vendorSite,oohd.attribute99 orderedDate
from apps.oe_order_lines_all oola,apps.oe_order_headers_all ooha,apps.wwt_so_headers_dff oohd
where 1=1
and oohd.header_id = ooha.header_id
and ooha.header_id = oola.header_id
and ooha.order_number = 5707571;

select oohd.attribute99,ooha.orig_header_id,ooha.buyer_name,ooha.status,ooha.creation_Date,ooha.customer_name,ooha.source,ooha.ordered_date,ooha.wwt_attribute9,ooha.salesrep,oola.promise_date,
ooha.org_id,ooha.PROCESS_GROUP_ID,ooha.status,ooha.status_message,ooha.customer_po_number
,oohd.attribute46,oohd.attribute19,oola.*
 from apps.wwt_stg_order_headers_v ooha, apps.wwt_stg_order_lines oola, apps.wwt_stg_order_headers_dff oohd
where 1=1
--and salesrep_id = 100379288
--and ooha.header_id = 16494160 
and ooha.header_id = oola.header_id
and oohd.header_id = ooha.header_id
--and source = 'POI_TO_COP'
and ooha.creation_date > sysdate - 25
--and ooha.attribute9 IS NOT NULL
and ooha.customer_po_number IN ('PO46705')
order by ooha.creation_date desc
;--55386
update wwt_stg_order_headers_dff
set attribute46='1439823803818.473279448.000000450@53HXO65xUbrs6oYdijQ6Z2i/8LI='
where 1=1
and header_id = 20542530
;
update wwt_orig_order_headers
set status = 'UNPROCESSED'
where 1=1
and header_id = 16496368
;
select oohd.attribute99,ooha.*
from apps.wwt_orig_order_headers_v ooha,apps.wwt_orig_order_headers_dff oohd
where 1=1
and ooha.header_id = 16501360
and oohd.header_id = ooha.header_id
--and customer_po_number = 'PO46605'
order by ooha.creation_date desc
;
update wwt_orig_order_headers
set status = 'UNPROCESSED',status_message=null,last_update_date = sysdate,PROCESS_GROUP_ID=34
where 1=1
and header_id = 16496354;

select ooha.header_id,ooha.status,ooha.status_message,ooha.customer_po_number,
ooha.customer_name,ooha.creation_date,ooha.last_update_date,ooha.ship_to_address1,
oola.promise_date
 from apps.wwt_orig_order_headers_v ooha, apps.wwt_orig_order_lines oola
where 1=1
--and salesrep_id = 100379288
--and ooha.header_id = 16494160
and ooha.header_id = oola.header_id
--and ooha.creation_date > sysdate - 65
and ooha.customer_po_number = 'PO109025'
order by creation_date desc;

select waoo.ordered_date,waoo.sales_order_num,waoo.customer_po_num,waos.* from apps.wwt_asn_outbound_shipments waos,apps.wwt_asn_outbound_orders waoo
where 1=1
and waos.last_update_date > sysdate - 2
and waos.shipment_id = waoo.shipment_id
--and waoo.customer_po_num = 'PO46706'
--and waos.shipment_id = 9274032
--and shipment_id = 106803
and waos.communication_method = 'cXML'
order by waos.last_update_Date desc
;
update wwt_asn_outbound_shipments
set process_status = 'UNPROCESSED',process_message=null,last_update_date = sysdate
where 1=1
and shipment_id = 9275510
;
select * from wwt_asn_outbound_orders
where 1=1
--and last_update_date > sysdate - 1
and shipment_id = 9273618
order by last_update_Date desc

select * from wwt_asn_outbound_packages
where 1=1
and shipment_id = 9273618
order by last_update_Date desc;

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_ASN_OUTBOUND_EXTRACT'--WWT_CXML_SUPPLIER_TRANSACTION--WWT_ASN_OUTBOUND_EXTRACT
--and attribute1 LIKE '%Charter%'
;

select * from wwt_asn_outbound_items
where 1=1
and shipment_id = 9273618

select * from wwt_asn_outbound_serial_nums
where 1=1
--and shipment_id = 9273618
and item_id=2074748
;
SELECT wcst.attribute2 TRANSACTIONTYPE
, wcst.attribute3 SUBMITURL
, wcst.attribute4 CXMLVERSION
FROM apps.wwt_lookups_active_v wcst
WHERE 1=1 
--and wcst.attribute1 = ?
--AND wcst.attribute2 = ?
AND wcst.lookup_type = 'WWT_CXML_SUPPLIER_TRANSACTION'
;
SELECT *
FROM apps.wwt_lookups_active_v wcst
WHERE 1=1
--and wcst.attribute1 = ?
--  AND wcst.attribute2 = ?
  AND wcst.lookup_type = 'WWT_CXML_SUPPLIER_TRANSACTION'
;
WWT_ASN_OUTBOUND_CXML
;
select * from apps.WWT_ASN_OUTBOUND_EXTENSIONS
where 1=1
and creation_Date > sysdate - 50
and extension_type <> 'ITEM'
and common_table_id = 9275510
;
INSERT INTO apps.WWT_ASN_OUTBOUND_EXTENSIONS(extension_id,common_table_id,common_table_name,extension_Type,attribute4,created_by,creation_Date,last_updated_by,last_update_date)
VALUES(apps.wwt_asn_outbound_extensions_s.nextval,
9275510,
'WWT_ASN_OUTBOUND_SHIPMENTS',
'SHIPMENT',
'1439823803818.473279448.000000450@53HXO65xUbrs6oYdijQ6Z2i/8LI=',
61721,
sysdate,
61721,
sysdate)
;
update apps.WWT_ASN_OUTBOUND_EXTENSIONS
set attribute5 = '1439823803818.473279448.000000450@53HXO65xUbrs6oYdijQ6Z2i/8LI=',attribute4=null,attribute2='01-SEP-15 12:00:00'
where 1=1
and common_table_id = 9275510
;
select oola.attribute9 vendor,oola.attribute16 vendorSite,ooha.attribute1 orderedDate
from apps.oe_order_lines_all oola,apps.oe_order_headers_all ooha,apps.wwt_so_headers_dff oohd
where 1=1
and oohd.header_id = ooha.header_id
and ooha.header_id = oola.header_id
and ooha.order_number = 5708131
;
UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_cXML_ASN'
    , last_update_date = SYSDATE
    , last_updated_by = ?yeah 
WHERE process_status = 'UNPROCESSED'
AND communication_method = 'cXML'
;
select oola.attribute9 vendor,oola.attribute16 vendorSite,oohd.attribute99 orderedDate
from apps.oe_order_lines_all oola,apps.wwt_oe_order_headers_all_v ooha,apps.wwt_so_headers_dff oohd
where 1=1
and oohd.header_id = ooha.header_id
and ooha.header_id = oola.header_id
and ooha.order_number = 6144043
--and rownum = 1
--order by ooha.creation_Date desc
;