select wsoh.header_id,wsoh.orig_header_id,wsoh.status,wsoh.customer_name,wsoh.status_message,wsoh.wwt_attribute35,wsoh.ship_to_contact_email,wsod.attribute48,wsoh.wwt_attribute34,wsoh.process_group_id,wsoh.creation_Date--header_id,ship_to_contact_email,wwt_attribute11,wwt_attribute34,wwt_attribute9,WWT_ATTRIBUTE11,wwt_attribute48,ship_to_contact_email,sales_channel_code,sales_channel,customer_po_number,process_group_id,source,wwt_attribute13,status,status_message,creation_Date,last_update_date
from apps.wwt_stg_order_headers_v wsoh
,apps.wwt_stg_order_headers_dff wsod
where 1=1
and wsod.header_id = wsoh.header_id
--and customer_po_number IN ('RITM0445261')--PO153741
--and source NOT LIKE '%QSYS%'
--and status_message LIKE '%Order Failed - ERROR: [ART.117.4002] Adapter Runtime (Adapter Service): Unable to invoke adapter service WWT_OrderInbound.adapterServices.stage:insertSTGOrderLine.
--[ADA.1.316] Cannot execute the SQL statement "INSERT INTO  PARTNER_ADMIN.WWT_STG_ORDER_LINES(LINE_ID, HEADER_ID, ORIG_LINE_ID, ACCOUNTING_RULE, ACCOUNTING_RULE_DURATION, ACCOUNTING_RULE_ID, ACTUAL_ARRIVAL_DATE, ACTUAL_FULFILLMENT_DATE, ACTUAL_SHIPMENT_DATE, AGREEMENT, AGREEMENT_ID, ARRIVAL_SET_ID, ARRIVAL_SET_NAME, ATO_LINE_ID, ATTACHMENT, ATTACHMENT_CATEGORY, ATTRIBUTE1, ATTRIBUTE10, ATTRIBUTE11, ATTRIBUTE12, ATTRIBUTE13, ATTRIBUTE14, ATTRIBUTE15, ATTRIBUTE16, ATTRIBUTE17, ATTRIBUTE18, ATTRIBUTE19, ATTRIBUTE2, ATTRIBUTE20, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5, ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE_STATUS, AUTHORIZED_TO_SHIP_FLAG, BILL_TO_CONTACT_FAX, BILL_TO_CONTACT_REF, BLANKET_LINE_NUMBER, BLANKET_NUMBER, BUYER_NAME, CALCULATE_PRICE_FLAG, CANCELLED_FLAG, CANCELLED_QUANTITY, CHANGE_COMMENTS, CHANGE_REASON, CHANGE_REQUEST_CODE, CHANGE_SEQUENCE, CLOSED_FLAG, COMMITMENT_APPLIED_AMOUNT, COMMITMENT_ID, COMPONENT_CODE, COMPONENT_SEQUENCE_ID, CONFIGURATION_ID, CONFIG_HEADER_ID, CONFIG_REV_NBR, CONTEXT, CONTRACT_PO_NUMBER, CREATED_BY, CREATION_DATE, CREDIT_INVOICE_LINE_ID, CUSTOMER_DOCK, CUSTOMER_DOCK_CODE, CUSTOMER_ITEM_ID, CUSTOMER_ITEM_ID_TYPE, CUSTOMER_ITEM_NAME, CUSTOMER_ITEM_NET_PRICE, CUSTOMER_ITEM_REVISION, CUSTOMER_JOB, CUSTOMER_LINE_NUMBER, CUSTOMER_PAYMENT_TERM, CUSTOMER_PAYMENT_TERM_ID, CUSTOMER_PRODUCTION_LINE, CUSTOMER_SHIPMENT_NUMBER, CUST_MODEL_SERIAL_NUMBER, CUST_PO_NUMBER, CUST_PRODUCTION_SEQ_NUM, DELIVERY_ID, DELIVERY_LEAD_TIME, DELIVER_TO_ADDRESS1, DELIVER_TO_ADDRESS2, DELIVER_TO_ADDRESS3, DELIVER_TO_ADDRESS4, DELIVER_TO_CITY, DELIVER_TO_CONTACT, DELIVER_TO_CONTACT_EMAIL, DELIVER_TO_CONTACT_FAX, DELIVER_TO_CONTACT_FIRST_NAME, DELIVER_TO_CONTACT_ID, DELIVER_TO_CONTACT_LAST_NAME, DELIVER_TO_CONTACT_PHONE_EXT, DELIVER_TO_CONTACT_REF, DELIVER_TO_CONTACT_TELEPHONE, DELIVER_TO_COUNTRY, DELIVER_TO_COUNTY, DELIVER_TO_CUSTOMER_ID, DELIVER_TO_CUSTOMER_NAME, DELIVER_TO_CUSTOMER_NUMBER, DELIVER_TO_ORG, DELIVER_TO_ORG_CONTACT_ID, DELIVER_TO_ORG_ID, DELIVER_TO_PARTY_ID, DELIVER_TO_PARTY_NUMBER, DELIVER_TO_PARTY_SITE_ID, DELIVER_TO_PARTY_SITE_USE_ID, DELIVER_TO_POSTAL_CODE, DELIVER_TO_PROVINCE, DELIVER_TO_STATE, DEMAND_BUCKET_TYPE, DEMAND_BUCKET_TYPE_CODE, DEMAND_CLASS, DEMAND_CLASS_CODE, DEMAND_STREAM, DROP_SHIP_FLAG, EARLIEST_ACCEPTABLE_DATE, END_CUSTOMER_ADDRESS1, END_CUSTOMER_ADDRESS2, END_CUSTOMER_ADDRESS3, END_CUSTOMER_ADDRESS4, END_CUSTOMER_CITY, END_CUSTOMER_CONTACT, END_CUSTOMER_CONTACT_FN, END_CUSTOMER_CONTACT_ID, END_CUSTOMER_CONTACT_LN, END_CUSTOMER_COUNTRY, END_CUSTOMER_COUNTY, END_CUSTOMER_EMAIL, END_CUSTOMER_FAX, END_CUSTOMER_ID, END_CUSTOMER_LOCATION, END_CUSTOMER_NAME, END_CUSTOMER_NUMBER, END_CUSTOMER_ORG_CONTACT_ID, END_CUSTOMER_PARTY_ID, END_CUSTOMER_PARTY_NUMBER, END_CUSTOMER_PARTY_SITE_ID, END_CUSTOMER_PARTY_SITE_USE_ID, END_CUSTOMER_PHONE_EXT, END_CUSTOMER_POSTAL_CODE, END_CUSTOMER_PROVINCE, END_CUSTOMER_SITE_USE_ID, END_CUSTOMER_STATE, END_CUSTOMER_TELEPHONE, END_ITEM_UNIT_NUMBER, ERROR_FLAG, EXPLOSION_DATE, FOB_POINT, FOB_POINT_CODE, FREIGHT_CARRIER_CODE, FREIGHT_TERMS, FREIGHT_TERMS_CODE, FULFILLED_FLAG, FULFILLED_QUANTITY, FULFILLMENT_SET, FULFILLMENT_SET_ID, GLOBAL_ATTRIBUTE1, GLOBAL_ATTRIBUTE10, GLOBAL_ATTRIBUTE11, GLOBAL_ATTRIBUTE12, GLOBAL_ATTRIBUTE13, GLOBAL_ATTRIBUTE14, GLOBAL_ATTRIBUTE15, GLOBAL_ATTRIBUTE16, GLOBAL_ATTRIBUTE17, GLOBAL_ATTRIBUTE18, GLOBAL_ATTRIBUTE19, GLOBAL_ATTRIBUTE2, GLOBAL_ATTRIBUTE20, GLOBAL_ATTRIBUTE3, GLOBAL_ATTRIBUTE4, GLOBAL_ATTRIBUTE5, GLOBAL_ATTRIBUTE6, GLOBAL_ATTRIBUTE7, GLOBAL_ATTRIBUTE8, GLOBAL_ATTRIBUTE9, GLOBAL_ATTRIBUTE_CATEGORY, IB_CURRENT_LOCATION, IB_CURRENT_LOCATION_CODE, IB_INSTALLED_AT_LOCATION, IB_INSTALLED_AT_LOCATION_CODE, IB_OWNER, IB_OWNER_CODE, INDUSTRY_ATTRIBUTE1, INDUSTRY_ATTRIBUTE10, INDUSTRY_ATTRIBUTE11, INDUSTRY_ATTRI%'
--and wsoh.header_id = 21863817
--and status_message like '%6933702%'
--and header_id = 17907675
--and wsoh.source IN (
--'El Paso Microsoft Callout',
--'EBAY (DELL/FX) Callout',
--'Quote System 3',
--'SMARTnet Item Callout')
--and wwt_attribute41 IS NOT NULL
and process_group_id IN (1624)
--and orig_header_id = 17880372
--and wsod.attribute48 is not null
and wsoh.creation_Date > sysdate - 20
order by wsoh.creation_Date desc
;
update PARTNER_ADMIN.WWT_ORIG_ORDER_HEADERS
set status = 'UNPROCESSED',status_message = null
where 1=1
and header_id = 17731272
;
select header_id,orig_header_id,salesrep,wwt_attribute9,ship_from_org_id,sales_channel_code,source,process_group_id,sales_channel,customer_po_number,wwt_attribute13,status,status_message,creation_Date,last_update_Date
from apps.wwt_stg_order_headers_v, apps.wwt_stg_order_headers_dff
where 1=1
--and customer_po_number IN ('HW-713')--PO153741
--and status_message LIKE '%6392000%'
and orig_header_id = 22472593
--and header_id = 21562715
--and wwt_attribute41 IS NOT NULL
--and source NOT LIKE '%QSYS%'
--and status NOT LIKE
--and process_group_id IN (2344,2345,11)
and creation_Date > sysdate - 10
order by creation_Date desc
;
select wooh.header_id,wooh.CUSTOMER_NAME,wooh.source,wool.inventory_item_segment_4,wool.inventory_item_segment_2,wooh.process_group_id,wool.unit_selling_price,wooh.salesrep,wooh.status,wooh.status_message,wooh.change_comments headers_change_comment,wooh.customer_po_number,wooh.creation_Date,
wool.change_comments line_change_comment,wool.wwt_attribute13,wool.unit_selling_price,wool.ship_from_org_id,wool.subinventory, woold.*
from apps.wwt_orig_order_headers_v wooh,apps.wwt_orig_order_lines wool, apps.wwt_orig_order_lines_dff woold
where 1=1
and wooh.header_id = wool.header_id
and wool.line_id = woold.line_id
--and wool.inventory_item_segment_2 LIKE '%BOX%'
--and wool.inventory_item_segment_4 = 'SAVV'
--and wooh.customer_name IN ('')
and wooh.process_group_id = 1624
--and wooh.status = 'ERROR'
--and wooh.header_id = 18035955
--and wooh.agreement = 'Dell Boeing'
--and wooh.header_id = 18212318
--and wooh.salesrep = 'Comm - Dell/Boeing'
--and wooh.customer_po_number = '1104451352'--1104027733_MU--1104027733_EDI
--and wool.inventory_item_segment_2 LIKE '%J6E65AA%'
and wooh.creation_Date > sysdate - 1
order by wooh.last_update_date desc
;
select wsoh.header_id,wsoh.orig_header_id,wsoh.shipping_instructions,wsol.inventory_item_segment_4,wsoh.status,wsol.line_id,wsol.unit_list_price,wsol.creation_Date,
wsoh.change_comments,wsol.change_comments,wsol.wwt_attribute13,wsol.unit_selling_price,wsol.ship_from_org_id,wsol.subinventory,wsold.*
from apps.wwt_stg_order_headers_v wsoh,apps.wwt_stg_order_lines wsol, apps.wwt_stg_order_lines_dff wsold
where 1=1
and wsoh.header_id = wsol.header_id
and wsold.line_id = wsol.line_id
--and wsoh.orig_header_id IN (17880372)--,17793361,17785046,17786379,17783198,17781778)
--and wsoh.source = 'CenturyLink Callout'
--and wsol.inventory_item_segment_2 like '%BOX%'
and wsoh.orig_header_id = 18035955
--and customer_po_number IN ('41-106740')
--and wsoh.salesrep = 'Comm - Dell/Boeing'
--and wsol.inventory_item_segment_2 LIKE '%J6E65AA%'
and wsoh.creation_Date > sysdate - 120
order by wsoh.creation_date desc
;
update apps.wwt_orig_order_lines
set inventory_item_segment_4 = 'CTL'
where 1=1
and header_id = 18035955
;
update apps.wwt_orig_order_headers
set status='UNPROCESSED',status_message=null
where 1=1
and header_id = 18035955
;
update wwt_stg_order_headers
set status = 'PENDING REPROCESS', status_message = 'Manually reset stuck order', last_update_date = sysdate, last_updated_by = 55386
where 1=1
and status_message = 'DBMS_SCHEDULER PINWHEEL JOB KICKED OFF'
and creation_Date > sysdate - 1
;