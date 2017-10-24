select * from apps.wwt_po_ack_headers
where 1=1
and creation_date > sysdate - 1
order by creation_Date desc
;
select * from apps.wwt_punchin_info
where 1=1
--and description LIKE '%AT&T%'
and customer_name = 'Charter Communications'
order by punchin_id desc
;
update apps.wwt_punchin_info
set internal_sales_rep = 'McDonough, Shamus S',last_updated_by=55386,last_update_date=sysdate
where 1=1
and customer_name = 'Charter Communications'
;
select * from fnd_user
where 1=1
and user_name like '%GASSERTM%'--55386
;
update apps.wwt_punchin_info
set source = 'POI_TO_COP',sales_territory='Comm - ESP Brian Daus'
where 1=1
and punchin_id = 87
;

WWT_PO_ACK_OB_EXTRACT;

WWT_OM_JOB;

WWT_ORDER_IMPORT_PKG;

WWT_POACK_OUTBOUND;

select * from apps.WWT_PURCHASE_ORDER_ACK
where 1=1
and last_update_date > sysdate - 10
order by last_update_date desc
;
SELECT *   
FROM APPS.wwt_poack_outbound_headers wpoh
--,apps.wwt_poack_outbound_lines wpol
WHERE 1=1
--and process_status = 'UNPROCESSED'  
and wpoh.creation_date > sysdate - 2
AND  wpoh.communication_method = 'CXML'
AND  wpoh.TRADING_PARTNER_ID is not null
--and wpoh.header_id = wpol.header_id
order by wpoh.creation_Date desc
;
update wwt_poack_outbound_headers
set process_status = 'UNPROCESSED'
where 1=1
and header_id = 865313
;
SELECT a.attribute4 CREDENTIALTOID
     , a.attribute5 CREDENTIALTODOMAIN
     , a.attribute3 ENTERPRISENETWORKACCOUNTNAME
     , b.attribute2 ENTERPRISENETWORK
     , b.attribute3 CREDENTIALFROMID
     , b.attribute4 CREDENTIALFROMDOMAIN
     , b.attribute5 CREDENTIALSENDERID
     , b.attribute6 CREDENTIALSENDERDOMAIN
     , b.attribute7 SHAREDSECRET
FROM apps.wwt_lookups b
    , apps.wwt_lookups a
WHERE trunc(SYSDATE) BETWEEN TRUNC(NVL(b.start_date_active, SYSDATE))
  AND TRUNC(NVL(b.end_date_active, SYSDATE))
  AND NVL(b.enabled_flag, 'N') = 'Y'
  AND b.attribute2 = a.attribute3
  AND b.lookup_type = 'WWT_CXML_ENTERPRISE_NETWORK_ACCOUNT'
  AND trunc(SYSDATE) BETWEEN TRUNC(NVL(a.start_date_active, SYSDATE))
  AND TRUNC(NVL(a.end_date_active, SYSDATE))
  AND NVL(a.enabled_flag, 'N') = 'Y'
  AND a.attribute2 = UPPER(?) -- environment
  AND a.attribute1 = ? -- partnerID
  AND a.lookup_type = 'WWT_CXML_PARTNER_ENVIRONMENT'
;
SELECT a.HEADER_ID, a.LINE_ID, a.INVENTORY_ITEM_ID, 
       a.QUANTITY_FLAG, a.PRICE_FLAG, a.ORDERED_QUANTITY,
       TO_CHAR(h.ORDERED_DATE , 'DD-MON-YYYY' ) DATE_ORDERED, 	
       h.ORDER_NUMBER, h.CUST_PO_NUMBER,
       UPPER(sd.attribute45) SENDER_ID,
       sd.attribute46 PAYLOAD_ID
FROM APPS.OE_ORDER_HEADERS_ALL h,  
     APPS.OE_ORDER_LINES_ALL l,
     APPS.WWT_SO_HEADERS_DFF sd,
     APPS.WWT_PURCHASE_ORDER_ACK a 
WHERE 1=1         
AND a.HEADER_ID = ?
AND a.SALES_CHANNEL = ? 
AND NVL(a.EDI_PROCESSED_FLAG, 'N') = 'N'
AND a.HEADER_ID = h.HEADER_ID
AND h.HEADER_ID = sd.HEADER_ID
AND l.split_from_line_id IS NULL
AND a.header_id = l.header_id
AND a.line_id = l.line_id
;
select attribute3 from apps.wwt_lookups_active_v
where 1=1
and lookup_type = 'WWT_CXML_PO_INBOUND_EML_DIST'
and attribute1 = 'cXMLToQuote'
and attribute2 = 'Charter'
;
select oola.attribute9 vendor,oola.attribute16 vendorSite,ooha.ordered_date orderedDate
from apps.oe_order_lines_all oola,apps.oe_order_headers_all ooha,apps.wwt_so_headers_dff oohd
where 1=1
and oohd.header_id = ooha.header_id
and ooha.header_id = oola.header_id
and ooha.order_number = 5708139
;
select oola.attribute9 vendor,oola.attribute16 vendorSite,oohd.attribute99 orderedDate
from apps.oe_order_lines_all oola,apps.oe_order_headers_all ooha,apps.wwt_so_headers_dff oohd
where 1=1
and oohd.header_id = ooha.header_id
and ooha.header_id = oola.header_id
and ooha.order_number = 5708139
;
