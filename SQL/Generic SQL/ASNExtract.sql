SELECT 
oha.header_id,oha.salesrep_id,oha.creation_date,oha.order_number,ola.line_type_id,ola.line_id
--wda.delivery_id,wnd.confirm_date,wnd.asn_date_sent
--wl2.attribute1,wl2.*
FROM 
APPS.WSH_NEW_DELIVERIES WND
,APPS.HZ_CUST_ACCOUNTS HCA
,APPS.HZ_PARTIES HP
,APPS.WSH_DELIVERY_DETAILS WDD
,APPS.WSH_DELIVERY_DETAILS WDD2
,APPS.WSH_DELIVERY_ASSIGNMENTS WDA
--,APPS.WSH_DELIVERY_LEGS WDL
--,APPS.WSH_DOCUMENT_INSTANCES WDI
,APPS.OE_ORDER_LINES_ALL OLA
,APPS.wwt_OE_ORDER_HEADERS_ALL_v OHA
,APPS.WWT_SO_LINES_DFF SLD
,APPS.WWT_LOOKUPS_ACTIVE_V WL
,APPS.WWT_LOOKUPS_ACTIVE_V WL2
--,APPS.WSH_CARRIERS WC
--,APPS.MTL_SYSTEM_ITEMS_B MSI
,APPS.WWT_SO_HEADERS_DFF  SHD
WHERE 1 = 1
--AND OHA.order_number IN (5707498)
AND OHA.SALESREP_ID = WL.ATTRIBUTE2
and oha.cust_po_number = 'PO46700'
AND WND.CUSTOMER_ID                  = NVL(WL.ATTRIBUTE1,WND.CUSTOMER_ID)
AND WDA.DELIVERY_ID                     = WND.DELIVERY_ID
AND WDA.PARENT_DELIVERY_DETAIL_ID    = WDD2.DELIVERY_DETAIL_ID(+)
AND OLA.SHIP_FROM_ORG_ID = NVL(WL.ATTRIBUTE23,OLA.SHIP_FROM_ORG_ID)
AND WDD.SOURCE_LINE_ID                 = OLA.LINE_ID(+)
AND OLA.LINE_ID                        = SLD.LINE_ID(+)
AND OLA.HEADER_ID                     = OHA.HEADER_ID(+)
AND OHA.HEADER_ID                  = SHD.HEADER_ID (+)
AND NVL(SHD.ATTRIBUTE61, 'N/A')    = NVL(WL.ATTRIBUTE19, NVL(SHD.ATTRIBUTE61, 'N/A'))
AND HCA.PARTY_ID                     = HP.PARTY_ID
AND HCA.CUST_ACCOUNT_ID              = WND.CUSTOMER_ID
AND HP.PARTY_TYPE                    = 'ORGANIZATION'
AND WL.LOOKUP_TYPE                     = 'WWT_ASN_OUTBOUND_EXTRACT'
AND WL2.LOOKUP_TYPE(+)                 = 'WWT_OM_LINE_FLOW_CONTROLS'
AND TO_CHAR( OLA.LINE_TYPE_ID )      = WL2.ATTRIBUTE1(+)
AND NVL( WL2.ATTRIBUTE2, 'NULL' )    <> 'DROP_SHIP'
--AND WDD.ORGANIZATION_ID              = MSI.ORGANIZATION_ID
--AND WDD.INVENTORY_ITEM_ID             = MSI.INVENTORY_ITEM_ID
AND WDA.DELIVERY_DETAIL_ID             = WDD.DELIVERY_DETAIL_ID
AND WND.STATUS_CODE                     = 'CL'
--AND WDL.DELIVERY_ID                     = WND.DELIVERY_ID
--AND WDI.ENTITY_ID(+)                 = WDL.DELIVERY_LEG_ID
--AND WDI.ENTITY_NAME(+)                 = 'WSH_DELIVERY_LEGS'
--AND WDI.DOCUMENT_TYPE(+)             = 'BOL'
--AND WC.CARRIER_ID(+)                 = WND.CARRIER_ID
AND WND.CONFIRM_DATE                 >= NVL( null, SYSDATE - 7 )
--AND NVL( WDD.CONTAINER_FLAG, WDD2.CONTAINER_FLAG ) = 'N'
--AND NVL(WDD.INV_INTERFACED_FLAG,'N') IN ('Y','P')
--AND WND.DELIVERY_ID                     = NVL( null, WND.DELIVERY_ID )
AND (TRUNC(WND.CONFIRM_DATE) >= WL.START_DATE_ACTIVE OR WL.START_DATE_ACTIVE IS NULL)
;

--need to ship order
select * from WSH_DELIVERY_DETAILS
where 1=1
and source_line_id = 31671722
--;