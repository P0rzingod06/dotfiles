UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_' || ? 
     , last_update_date = SYSDATE
     , last_updated_by = ? 
WHERE process_status = 'UNPROCESSED'
 AND communication_method = ?
 AND partner_id = ? 
 
select * from apps.wwt_asn_outbound_shipments
where 1=1
and partner_id = 'MSIP'
order by creation_date desc

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_ASN_OUTBOUND_EXTRACT'
--and attribute5 = 'XML'
and description like '%MSIP%'

select * from apps.wwt_oe_order_headers_all_v
where 1=1
and salesrep_id = 100016278
order by creation_date desc

wwt_asn_outbound_extract

apps.WWT_ASN_OUTBOUND_CXML

SELECT  DISTINCT
                  'NON-DROP'            CURSOR_TYPE
                  ,HP.PARTY_NAME        CUSTOMER_NAME
                  ,WDA.DELIVERY_ID     DELIVERY_ID
                  ,TO_NUMBER( NULL )    DROP_SHIPMENT_ID
                  ,NVL( WDI.SEQUENCE_NUMBER, WDD.TRACKING_NUMBER )              BILL_OF_LADING
                  ,WDD.DELIVERY_DETAIL_ID                                           DELIVERY_DETAIL_ID
                  ,COALESCE(WDD.CONTAINER_NAME, WDD2.CONTAINER_NAME, '-1' ) LPN
                  ,OHA.ORDER_NUMBER                                                ORDER_NUMBER
                  ,OHA.HEADER_ID                                                 SO_HEADER_ID
                  ,OLA.LINE_ID                                                     SO_LINE_ID
                  ,OHA.SALESREP_ID                                                 SO_SALESREP_ID
                  ,OHA.ORDERED_DATE                                             ORDERED_DATE
                  ,OLA.LINE_NUMBER                                                 ORDER_LINE_NUMBER
                  ,OLA.CUSTOMER_LINE_NUMBER                                     CUSTOMER_LINE_NUM
                  ,OLA.SHIPMENT_NUMBER                                             ORDER_SHIPMENT_NUMBER
                  ,OHA.CUST_PO_NUMBER                                             CUSTOMER_PO_NUM
                  ,WDD.INVENTORY_ITEM_ID                                         INVENTORY_ITEM_ID
                  ,WDD.ITEM_DESCRIPTION                                         ITEM_DESCRIPTION
                  ,MSI.SEGMENT1                                                 INVENTORY_ITEM_SEGMENT1
                  ,MSI.SEGMENT2                                                 INVENTORY_ITEM_SEGMENT2
                  ,MSI.SEGMENT3                                                 INVENTORY_ITEM_SEGMENT3
                  ,MSI.SEGMENT4                                                 INVENTORY_ITEM_SEGMENT4
                  ,MSI.ATTRIBUTE6                                                 INVENTORY_ITEM_ATTRIBUTE6
                  ,MSI.ATTRIBUTE13                                                 INVENTORY_ITEM_ATTRIBUTE13
                  ,NULL                                                         PURCHASE_ORDER_NUM
                  ,TO_NUMBER( NULL )                                             PO_LINE_NUM
                  ,WDD.TRACKING_NUMBER                                             TRACKING_NUMBER
                  ,WDD.SHIPPED_QUANTITY                                         SHIPPED_QUANTITY
                  ,TRIM(RPAD(WND.WAYBILL,2000))                                        WAYBILL
                  ,OLA.SHIPPING_QUANTITY_UOM                                     SHIPPED_UOM
                  ,OLA.ORDERED_QUANTITY                                         ORDERED_QUANTITY
                  ,OLA.ORDER_QUANTITY_UOM                                         ORDERED_UOM
                  ,OLA.UNIT_LIST_PRICE                                            UNIT_LIST_PRICE
                  ,OLA.UNIT_SELLING_PRICE                                        UNIT_SELLING_PRICE
                  ,MSI.SHIPPABLE_ITEM_FLAG                                        SHIPPABLE_ITEM_FLAG
                  ,WND.SHIP_METHOD_CODE                                         SHIP_METHOD_CODE
                  ,WC.FREIGHT_CODE                                                 CARRIER
                  ,WDD.SHIP_TO_LOCATION_ID                                         SHIP_TO_LOCATION_ID
                  ,WDD.DELIVER_TO_LOCATION_ID                                     DELIVER_TO_LOCATION_ID
                  ,WDD.SHIP_TO_CONTACT_ID                                         SHIP_TO_CONTACT_ID
                  ,WDD.DELIVER_TO_CONTACT_ID                                     DELIVER_TO_CONTACT_ID
                  ,OHA.INVOICE_TO_ORG_ID                                         INVOICE_TO_SITE_USE_ID
                  ,OHA.SOLD_TO_ORG_ID                                             SOLD_TO_SITE_USE_ID
                  ,OHA.SHIP_TO_ORG_ID                                             SHIP_TO_ORG_ID
                  ,TRUNC( WND.CONFIRM_DATE )                                     SHIP_DATE
                  ,TO_CHAR( WND.CONFIRM_DATE, 'HH24:MI:SS' )                         SHIP_TIME
                  ,NVL( WND.NET_WEIGHT, WND.GROSS_WEIGHT )                         DELIVERY_WEIGHT
                  ,WND.WEIGHT_UOM_CODE                                              WEIGHT_UOM
                  ,WND.ATTRIBUTE1                                                 DELIVERY_ATTRIBUTE1
                  ,WND.ATTRIBUTE2                                                 DELIVERY_ATTRIBUTE2
                  ,WND.ATTRIBUTE3                                                 DELIVERY_ATTRIBUTE3
                  ,WND.ATTRIBUTE4                                                 DELIVERY_ATTRIBUTE4
                  ,WND.ATTRIBUTE5                                                 DELIVERY_ATTRIBUTE5
                  ,WND.ATTRIBUTE6                                                 DELIVERY_ATTRIBUTE6
                  ,WND.ATTRIBUTE7                                                 DELIVERY_ATTRIBUTE7
                  ,WND.ATTRIBUTE8                                                 DELIVERY_ATTRIBUTE8
                  ,WND.ATTRIBUTE9                                                 DELIVERY_ATTRIBUTE9
                  ,WND.ATTRIBUTE10                                                 DELIVERY_ATTRIBUTE10
                  ,WND.ATTRIBUTE11                                                 DELIVERY_ATTRIBUTE11
                  ,WND.ATTRIBUTE12                                                 DELIVERY_ATTRIBUTE12
                  ,WND.ATTRIBUTE13                                                 DELIVERY_ATTRIBUTE13
                  ,WND.ATTRIBUTE14                                                 DELIVERY_ATTRIBUTE14
                  ,WND.ATTRIBUTE15                                                 DELIVERY_ATTRIBUTE15
                  ,WDD.ATTRIBUTE1                                                 DELIVERY_DETAILS_ATTRIBUTE1
                  ,WDD.ATTRIBUTE2                                                 DELIVERY_DETAILS_ATTRIBUTE2
                  ,WDD.ATTRIBUTE3                                                 DELIVERY_DETAILS_ATTRIBUTE3
                  ,WDD.ATTRIBUTE4                                                 DELIVERY_DETAILS_ATTRIBUTE4
                  ,WDD.ATTRIBUTE5                                                 DELIVERY_DETAILS_ATTRIBUTE5
                  ,WDD.ATTRIBUTE6                                                 DELIVERY_DETAILS_ATTRIBUTE6
                  ,WDD.ATTRIBUTE7                                                 DELIVERY_DETAILS_ATTRIBUTE7
                  ,WDD.ATTRIBUTE8                                                 DELIVERY_DETAILS_ATTRIBUTE8
                  ,WDD.ATTRIBUTE9                                                 DELIVERY_DETAILS_ATTRIBUTE9
                  ,WDD.ATTRIBUTE10                                                 DELIVERY_DETAILS_ATTRIBUTE10
                  ,WDD.ATTRIBUTE11                                                 DELIVERY_DETAILS_ATTRIBUTE11
                  ,WDD.ATTRIBUTE12                                                 DELIVERY_DETAILS_ATTRIBUTE12
                  ,WDD.ATTRIBUTE13                                                 DELIVERY_DETAILS_ATTRIBUTE13
                  ,WDD.ATTRIBUTE14                                                 DELIVERY_DETAILS_ATTRIBUTE14
                  ,WDD.ATTRIBUTE15                                                 DELIVERY_DETAILS_ATTRIBUTE15
                  ,OHA.ATTRIBUTE1                                                 SOH_ATTRIBUTE1
                  ,OHA.ATTRIBUTE2                                                 SOH_ATTRIBUTE2
                  ,OHA.ATTRIBUTE3                                                 SOH_ATTRIBUTE3
                  ,OHA.ATTRIBUTE4                                                 SOH_ATTRIBUTE4
                  ,OHA.ATTRIBUTE5                                                 SOH_ATTRIBUTE5
                  ,OHA.ATTRIBUTE6                                                 SOH_ATTRIBUTE6
                  ,OHA.ATTRIBUTE7                                                 SOH_ATTRIBUTE7
                  ,OHA.ATTRIBUTE8                                                 SOH_ATTRIBUTE8
                  ,OHA.ATTRIBUTE9                                                 SOH_ATTRIBUTE9
                  ,OHA.ATTRIBUTE10                                                 SOH_ATTRIBUTE10
                  ,OHA.ATTRIBUTE11                                                 SOH_ATTRIBUTE11
                  ,OHA.ATTRIBUTE12                                                 SOH_ATTRIBUTE12
                  ,OHA.ATTRIBUTE13                                                 SOH_ATTRIBUTE13
                  ,OHA.ATTRIBUTE14                                                 SOH_ATTRIBUTE14
                  ,OHA.ATTRIBUTE15                                                 SOH_ATTRIBUTE15
                  ,OHA.ATTRIBUTE16                                                 SOH_ATTRIBUTE16
                  ,OHA.ATTRIBUTE17                                                 SOH_ATTRIBUTE17
                  ,OHA.ATTRIBUTE18                                                 SOH_ATTRIBUTE18
                  ,OHA.ATTRIBUTE19                                                 SOH_ATTRIBUTE19
                  ,OHA.ATTRIBUTE20                                                 SOH_ATTRIBUTE20
                  ,OLA.ATTRIBUTE1                                                 SOL_ATTRIBUTE1
                  ,OLA.ATTRIBUTE2                                                 SOL_ATTRIBUTE2
                  ,OLA.ATTRIBUTE3                                                 SOL_ATTRIBUTE3
                  ,OLA.ATTRIBUTE4                                                 SOL_ATTRIBUTE4
                  ,OLA.ATTRIBUTE5                                                 SOL_ATTRIBUTE5
                  ,OLA.ATTRIBUTE6                                                 SOL_ATTRIBUTE6
                  ,OLA.ATTRIBUTE7                                                 SOL_ATTRIBUTE7
                  ,OLA.ATTRIBUTE8                                                 SOL_ATTRIBUTE8
                  ,OLA.ATTRIBUTE9                                                 SOL_ATTRIBUTE9
                  ,OLA.ATTRIBUTE10                                                 SOL_ATTRIBUTE10
                  ,OLA.ATTRIBUTE11                                                 SOL_ATTRIBUTE11
                  ,OLA.ATTRIBUTE12                                                 SOL_ATTRIBUTE12
                  ,OLA.ATTRIBUTE13                                                 SOL_ATTRIBUTE13
                  ,OLA.ATTRIBUTE14                                                 SOL_ATTRIBUTE14
                  ,OLA.ATTRIBUTE15                                                 SOL_ATTRIBUTE15
                  ,OLA.ATTRIBUTE16                                                 SOL_ATTRIBUTE16
                  ,OLA.ATTRIBUTE17                                                 SOL_ATTRIBUTE17
                  ,OLA.ATTRIBUTE18                                                 SOL_ATTRIBUTE18
                  ,OLA.ATTRIBUTE19                                                 SOL_ATTRIBUTE19
                  ,OLA.ATTRIBUTE20                                                 SOL_ATTRIBUTE20
                  ,WL.ATTRIBUTE4                                                 PARTNER_ID
                  ,WL.ATTRIBUTE5                                                 COMMUNICATION_METHOD
                  ,WL.ATTRIBUTE1                                                 CUSTOMER_ID
                  ,WL.ATTRIBUTE3                                                         SHIP_TO_SITE_USE_ID
                  ,WL.ATTRIBUTE2                                                 SALESREP_ID
                  ,WL.ATTRIBUTE6                                                 EXTENSION_PACKAGE
                  ,WL.ATTRIBUTE7                                                 SHIPMENT_EXT
                  ,WL.ATTRIBUTE8                                                 ORDER_EXT
                  ,WL.ATTRIBUTE9                                                 PACKAGE_EXT
                  ,WL.ATTRIBUTE10                                                 ITEM_EXT
                  ,WL.ATTRIBUTE18                                               ASN_EXCLUSION_EXT_FLAG
          ,WL.ATTRIBUTE12                                               PROCESS_STATUS
                  ,WL.ATTRIBUTE19                                               DROP_SHIP_EXCLUSION_EXT_FLAG
                  ,DECODE( OLA.TOP_MODEL_LINE_ID
                  ,NULL, 'N'
                  ,DECODE( OLA.LINE_ID
                  ,OLA.TOP_MODEL_LINE_ID, 'Y','N' ))    MASTER_ITEM
                  ,OLA.TOP_MODEL_LINE_ID        PARENT_SO_LINE_ID
                  ,WDD.SOURCE_HEADER_NUMBER        DETAIL_ORDER_NUMBER
                  ,TO_NUMBER( NULL )            RCPT_LINE_ID
                  ,TO_NUMBER( NULL )            SHIPMENT_ID
                  ,NULL                                               EXTERNAL_PACKAGE_GROUP_ID
                  ,NULL                                               EXTERNAL_PACKAGE_ID
                  ,TO_NUMBER(NULL)                                    PKG_DISPLAY_QUANTITY
                  ,TO_NUMBER(NULL)                                    PACKAGE_LENGTH
                  ,TO_NUMBER(NULL)                                    PACKAGE_WIDTH
                  ,TO_NUMBER(NULL)                                    PACKAGE_HEIGHT
                  ,TO_NUMBER(NULL)                                    PACKAGE_WEIGHT
                  ,NULL                                               PKG_LENGTH_UOM
                  ,NULL                                               PKG_WIDTH_UOM
                  ,NULL                                               PKG_HEIGHT_UOM
                  ,NULL                                               PKG_WEIGHT_UOM
                  ,NULL                                               OVERPACK_FLAG
                  ,WL.ATTRIBUTE20                                     SPLIT_ON_TRACKING_NUM
                  ,WL.ATTRIBUTE21    INCLUDE_ALL_ROWS
                  ,WL.ATTRIBUTE24    POST_PROCESS_EXT
              FROM APPS.WSH_NEW_DELIVERIES WND
              ,APPS.HZ_CUST_ACCOUNTS HCA
              ,APPS.HZ_PARTIES HP
                  ,APPS.WSH_DELIVERY_DETAILS WDD
                  ,APPS.WSH_DELIVERY_DETAILS WDD2
                  ,APPS.WSH_DELIVERY_ASSIGNMENTS WDA
                  ,APPS.WSH_DELIVERY_LEGS WDL
                  ,APPS.WSH_DOCUMENT_INSTANCES WDI
                  ,APPS.OE_ORDER_LINES_ALL OLA
                  ,APPS.WWT_OE_ORDER_HEADERS_ALL_V OHA
              ,APPS.WWT_SO_LINES_DFF SLD
                  ,APPS.WWT_LOOKUPS_ACTIVE_V WL
                  ,APPS.WWT_LOOKUPS_ACTIVE_V WL2
                  ,APPS.WSH_CARRIERS WC
                  ,APPS.MTL_SYSTEM_ITEMS_B MSI
                  ,APPS.WWT_SO_HEADERS_DFF  SHD
             WHERE 1 = 1
               AND WND.CUSTOMER_ID                  = NVL(WL.ATTRIBUTE1,WND.CUSTOMER_ID)
               AND WDA.DELIVERY_ID                     = WND.DELIVERY_ID
               AND WDA.PARENT_DELIVERY_DETAIL_ID    = WDD2.DELIVERY_DETAIL_ID(+)
               AND (    -- This is for the integration portion
                            OHA.SALESREP_ID                     = WL.ATTRIBUTE2
                            AND (WND.ATTRIBUTE7 IS NULL OR WND.ATTRIBUTE7 = 'R')
                            AND WND.ASN_DATE_SENT IS NULL
                        OR ( -- This is for the reporting piece, which will not update the delivery information
                              WL.ATTRIBUTE2 < 0 AND WL.ATTRIBUTE21 = 'Y'
                              AND NOT EXISTS (SELECT SHIPMENT_ID FROM APPS.WWT_ASN_OUTBOUND_SHIPMENTS
                                                         WHERE DELIVERY_ID = WND.DELIVERY_ID
                                                          AND COMMUNICATION_METHOD = WL.ATTRIBUTE5
                                                          AND PROCESS_STATUS = WL.ATTRIBUTE12)
                            )
                        )
               AND WDD.SHIP_TO_SITE_USE_ID             = NVL( WL.ATTRIBUTE3, WDD.SHIP_TO_SITE_USE_ID )
--               AND (WL.ATTRIBUTE22 IS NULL OR (WL.ATTRIBUTE22 IS NOT NULL AND OLA.SUBINVENTORY  IN  (SELECT /*+ CARDINALITY (ct 3) */ COLUMN_VALUE
--                                                                          FROM TABLE (SELECT CAST (apps.wwt_utilities.wwt_string_to_table_fun
--                                                                                                   (WL.ATTRIBUTE22, ',')
--                                                                                                   AS wwt_string_to_table_type)
--                                                                                        FROM DUAL) ct)))
--               -- Material Designator join
--               AND (WL.ATTRIBUTE25 IS NULL OR (WL.ATTRIBUTE25 IS NOT NULL AND OLA.ATTRIBUTE13  IN  (SELECT /*+ CARDINALITY (ct 3) */ COLUMN_VALUE
--                                                                          FROM TABLE (SELECT CAST (apps.wwt_utilities.wwt_string_to_table_fun
--                                                                                                   (WL.ATTRIBUTE25, ',')
--                                                                                                   AS wwt_string_to_table_type)
--                                                                                        FROM DUAL) ct)))
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
               AND WDD.ORGANIZATION_ID              = MSI.ORGANIZATION_ID
               AND WDD.INVENTORY_ITEM_ID             = MSI.INVENTORY_ITEM_ID
               AND WDA.DELIVERY_DETAIL_ID             = WDD.DELIVERY_DETAIL_ID
               AND WND.STATUS_CODE                     = 'CL'
               AND WDL.DELIVERY_ID                     = WND.DELIVERY_ID
               AND WDI.ENTITY_ID(+)                 = WDL.DELIVERY_LEG_ID
               AND WDI.ENTITY_NAME(+)                 = 'WSH_DELIVERY_LEGS'
               AND WDI.DOCUMENT_TYPE(+)             = 'BOL'
               AND WC.CARRIER_ID(+)                 = WND.CARRIER_ID
               AND WND.CONFIRM_DATE                 >= NVL( null, SYSDATE - 7 )
               AND NVL( WDD.CONTAINER_FLAG, WDD2.CONTAINER_FLAG ) = 'N'
               AND NVL(WDD.INV_INTERFACED_FLAG,'N') IN ('Y','P')
               AND WND.DELIVERY_ID                     = NVL( null, WND.DELIVERY_ID )
               AND (TRUNC(WND.CONFIRM_DATE) >= WL.START_DATE_ACTIVE OR WL.START_DATE_ACTIVE IS NULL)
          ORDER BY COMMUNICATION_METHOD
                  ,DELIVERY_ID
                  ,TRACKING_NUMBER
                  ,ORDER_NUMBER
                  ,LPN
                  ,SO_LINE_ID
                  ,INVENTORY_ITEM_ID;
                  
SELECT /*+ LEADING (WL_SETUP jrs pha ep es pla plla prla ola wl) */
                'DROP'                                                  CURSOR_TYPE
                ,HP.PARTY_NAME                                          CUSTOMER_NAME
                ,-1                                                     DELIVERY_ID
                ,ES.SHIPMENT_ID                                         DROP_SHIPMENT_ID
                ,NULL                                                   BILL_OF_LADING
                ,TO_NUMBER(NULL)                                        DELIVERY_DETAIL_ID
                ,'-1'                                                   LPN
                ,OHA.ORDER_NUMBER                                       ORDER_NUMBER
                ,OHA.HEADER_ID                                          SO_HEADER_ID
                ,OLA.LINE_ID                                            SO_LINE_ID
                ,OHA.SALESREP_ID                                        SO_SALESREP_ID
                ,OHA.ORDERED_DATE                                       ORDERED_DATE
                ,OLA.LINE_NUMBER                                        ORDER_LINE_NUMBER
                ,NVL( OLA.ATTRIBUTE14, OLA.CUSTOMER_LINE_NUMBER )       CUSTOMER_LINE_NUM
                ,OLA.SHIPMENT_NUMBER                                    ORDER_SHIPMENT_NUMBER
                ,OHA.CUST_PO_NUMBER                                     CUSTOMER_PO_NUM
                ,TO_NUMBER( NULL )                                      INVENTORY_ITEM_ID
                ,EP.ERP_ITEM_DESCRIPTION                                ITEM_DESCRIPTION
                ,NULL                                                   INVENTORY_ITEM_SEGMENT1
                ,APPS.wwt_get_delimited_field(ep.erp_item_number,1,'.') INVENTORY_ITEM_SEGMENT2 --CHG30248
                ,NULL                                                   INVENTORY_ITEM_SEGMENT3
                ,NULL                                                   INVENTORY_ITEM_SEGMENT4
                ,NULL                                                   INVENTORY_ITEM_ATTRIBUTE6
                ,NULL                                                   INVENTORY_ITEM_ATTRIBUTE13
                ,EP.ERP_PO_NUMBER                                       PURCHASE_ORDER_NUM
                ,TO_NUMBER( EP.ERP_LINE_NUMBER )                        PO_LINE_NUM
                ,SUBSTR(NVL(EPG.ATTRIBUTE11, EP.ATTRIBUTE11), 0, 30)    TRACKING_NUMBER
                ,EP.QUANTITY                                            SHIPPED_QUANTITY
                ,DECODE( ES.WAYBILL
                        ,NULL, DECODE( ES.ATTRIBUTE11
                                      ,NULL, EP.ATTRIBUTE11
                                      ,ES.ATTRIBUTE11 )
                        ,ES.WAYBILL )                                 WAYBILL
                ,OLA.SHIPPING_QUANTITY_UOM                            SHIPPED_UOM
                ,OLA.ORDERED_QUANTITY                                 ORDERED_QUANTITY
                ,OLA.ORDER_QUANTITY_UOM                               ORDERED_UOM
                ,OLA.UNIT_LIST_PRICE                                  UNIT_LIST_PRICE
                ,OLA.UNIT_SELLING_PRICE                               UNIT_SELLING_PRICE
                ,OLA.SHIPPABLE_FLAG                                   SHIPPABLE_ITEM_FLAG
                ,NULL                                                 SHIP_METHOD_CODE
                ,ES.CARRIER_NAME                                      CARRIER
                ,TO_NUMBER( NULL )                                               SHIP_TO_LOCATION_ID
                ,TO_NUMBER( NULL )                                               DELIVER_TO_LOCATION_ID
                ,TO_NUMBER( NULL )                                               SHIP_TO_CONTACT_ID
                ,TO_NUMBER( NULL )                                               DELIVER_TO_CONTACT_ID
                ,OHA.INVOICE_TO_ORG_ID                                INVOICE_TO_SITE_USE_ID
                ,OHA.SOLD_TO_ORG_ID                                   SOLD_TO_SITE_USE_ID
                ,OHA.SHIP_TO_ORG_ID                                   SHIP_TO_ORG_ID
                ,TRUNC( ES.PICKUP_DATE )                              SHIP_DATE
                ,TO_CHAR( ES.PICKUP_DATE, 'HH24:MI:SS' )              SHIP_TIME
                ,NVL(ES.GROSS_WEIGHT,ES.NET_WEIGHT)                   DELIVERY_WEIGHT
                ,NULL                                                 WEIGHT_UOM
                ,NULL                                                   DELIVERY_ATTRIBUTE1
                ,NULL                                                   DELIVERY_ATTRIBUTE2
                ,NULL                                                   DELIVERY_ATTRIBUTE3
--                ,NULL                                                B   DELIVERY_ATTRIBUTE4
                ,NULL                                                   DELIVERY_ATTRIBUTE5
                ,NULL                                                   DELIVERY_ATTRIBUTE6
                ,NULL                                                   DELIVERY_ATTRIBUTE7
                ,NULL                                                   DELIVERY_ATTRIBUTE8
                ,NULL                                                   DELIVERY_ATTRIBUTE9
                ,NULL                                                   DELIVERY_ATTRIBUTE10
                ,NULL                                                   DELIVERY_ATTRIBUTE11
                ,NULL                                                   DELIVERY_ATTRIBUTE12
                ,NULL                                                   DELIVERY_ATTRIBUTE13
                ,NULL                                                   DELIVERY_ATTRIBUTE14
                ,NULL                                                   DELIVERY_ATTRIBUTE15
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE1
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE2
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE3
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE4
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE5
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE6
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE7
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE8
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE9
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE10
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE11
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE12
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE13
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE14
                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE15
                ,OHA.ATTRIBUTE1                                       SOH_ATTRIBUTE1
                ,OHA.ATTRIBUTE2                                       SOH_ATTRIBUTE2
                ,OHA.ATTRIBUTE3                                       SOH_ATTRIBUTE3
                ,OHA.ATTRIBUTE4                                       SOH_ATTRIBUTE4
                ,OHA.ATTRIBUTE5                                       SOH_ATTRIBUTE5
                ,OHA.ATTRIBUTE6                                       SOH_ATTRIBUTE6
                ,OHA.ATTRIBUTE7                                       SOH_ATTRIBUTE7
                ,OHA.ATTRIBUTE8                                       SOH_ATTRIBUTE8
                ,OHA.ATTRIBUTE9                                       SOH_ATTRIBUTE9
                ,OHA.ATTRIBUTE10                                      SOH_ATTRIBUTE10
                ,OHA.ATTRIBUTE11                                      SOH_ATTRIBUTE11
                ,OHA.ATTRIBUTE12                                      SOH_ATTRIBUTE12
                ,OHA.ATTRIBUTE13                                      SOH_ATTRIBUTE13
                ,OHA.ATTRIBUTE14                                      SOH_ATTRIBUTE14
                ,OHA.ATTRIBUTE15                                      SOH_ATTRIBUTE15
                ,OHA.ATTRIBUTE16                                      SOH_ATTRIBUTE16
                ,OHA.ATTRIBUTE17                                      SOH_ATTRIBUTE17
                ,OHA.ATTRIBUTE18                                      SOH_ATTRIBUTE18
                ,OHA.ATTRIBUTE19                                      SOH_ATTRIBUTE19
                ,OHA.ATTRIBUTE20                                      SOH_ATTRIBUTE20
                ,OLA.ATTRIBUTE1                                       SOL_ATTRIBUTE1
                ,OLA.ATTRIBUTE2                                       SOL_ATTRIBUTE2
                ,OLA.ATTRIBUTE3                                       SOL_ATTRIBUTE3
                ,OLA.ATTRIBUTE4                                       SOL_ATTRIBUTE4
                ,OLA.ATTRIBUTE5                                       SOL_ATTRIBUTE5
                ,OLA.ATTRIBUTE6                                       SOL_ATTRIBUTE6
                ,OLA.ATTRIBUTE7                                       SOL_ATTRIBUTE7
                ,OLA.ATTRIBUTE8                                       SOL_ATTRIBUTE8
                ,OLA.ATTRIBUTE9                                       SOL_ATTRIBUTE9
                ,OLA.ATTRIBUTE10                                      SOL_ATTRIBUTE10
                ,OLA.ATTRIBUTE11                                      SOL_ATTRIBUTE11
                ,OLA.ATTRIBUTE12                                      SOL_ATTRIBUTE12
                ,OLA.ATTRIBUTE13                                      SOL_ATTRIBUTE13
                ,OLA.ATTRIBUTE14                                      SOL_ATTRIBUTE14
                ,OLA.ATTRIBUTE15                                      SOL_ATTRIBUTE15
                ,OLA.ATTRIBUTE16                                      SOL_ATTRIBUTE16
                ,OLA.ATTRIBUTE17                                      SOL_ATTRIBUTE17
                ,OLA.ATTRIBUTE18                                      SOL_ATTRIBUTE18
                ,OLA.ATTRIBUTE19                                      SOL_ATTRIBUTE19
                ,OLA.ATTRIBUTE20                                      SOL_ATTRIBUTE20
                ,WL_SETUP.ATTRIBUTE4                                       PARTNER_ID
                ,WL_SETUP.ATTRIBUTE5                                       COMMUNICATION_METHOD
                ,WL_SETUP.ATTRIBUTE1                                       CUSTOMER_ID
                ,WL_SETUP.ATTRIBUTE3                                       SHIP_TO_SITE_USE_ID
                ,WL_SETUP.ATTRIBUTE2                                       SALESREP_ID
                ,WL_SETUP.ATTRIBUTE6                                       EXTENSION_PACKAGE
                ,WL_SETUP.ATTRIBUTE7                                       SHIPMENT_EXT
                ,WL_SETUP.ATTRIBUTE8                                       ORDER_EXT
                ,WL_SETUP.ATTRIBUTE9                                       PACKAGE_EXT
                ,WL_SETUP.ATTRIBUTE10                                      ITEM_EXT
                ,WL_SETUP.ATTRIBUTE18                                      ASN_EXCLUSION_EXT_FLAG
                ,WL_SETUP.ATTRIBUTE12                                      PROCESS_STATUS
                ,WL_SETUP.ATTRIBUTE19                                      DROP_SHIP_EXCLUSION_EXT_FLAG
                ,NULL                                                 MASTER_ITEM
                ,TO_NUMBER( NULL )                                               PARENT_SO_LINE_ID
                ,NULL                                                 DETAIL_ORDER_NUMBER
                ,EP.PACKAGE_ID                                        RCPT_LINE_ID
                ,ES.SHIPMENT_ID                                       SHIPMENT_ID
                ,EPG.EXTERNAL_PACKAGE_GROUP_ID                        EXTERNAL_PACKAGE_GROUP_ID
                ,EP.EXTERNAL_PACKAGE_ID                               EXTERNAL_PACKAGE_ID
                ,EP.DISPLAY_QUANTITY                                  PKG_DISPLAY_QUANTITY
                ,NVL(EPG.GROUP_LENGTH, EP.PACKAGE_LENGTH)             PACKAGE_LENGTH
                ,NVL(EPG.GROUP_WIDTH, EP.PACKAGE_WIDTH)               PACKAGE_WIDTH
                ,NVL(EPG.GROUP_HEIGHT, EP.PACKAGE_HEIGHT)             PACKAGE_HEIGHT
                ,NVL(EPG.GROUP_WEIGHT, EP.PACKAGE_WEIGHT)             PACKAGE_WEIGHT
                ,NVL(EPG.GROUP_LENGTH_UOM, EP.LENGTH_UOM)             PKG_LENGTH_UOM
                ,NVL(EPG.GROUP_WIDTH_UOM, EP.WIDTH_UOM)               PKG_WIDTH_UOM
                ,NVL(EPG.GROUP_HEIGHT_UOM, EP.HEIGHT_UOM)             PKG_HEIGHT_UOM
                ,NVL(EPG.GROUP_WEIGHT_UOM, EP.WEIGHT_UOM)             PKG_WEIGHT_UOM
                ,NVL2(EPG.PACKAGE_GROUP_ID, 'Y', 'N')                 OVERPACK_FLAG
                ,WL_SETUP.ATTRIBUTE20                                      SPLIT_ON_TRACKING_NUM
                ,WL_SETUP.ATTRIBUTE21    INCLUDE_ALL_ROWS
                ,WL_SETUP.ATTRIBUTE24    POST_PROCESS_EXT
            FROM APPS.WWT_LOOKUPS_ACTIVE_V      WL
                ,APPS.WWT_LOOKUPS_ACTIVE_V      WL_SETUP
                ,APPS.JTF_RS_SALESREPS          JRS
                ,APPS.PO_HEADERS_ALL            PHA
                ,APPS.PO_LINES_ALL              PLA
                ,APPS.PO_LINE_LOCATIONS_ALL     PLLA
                ,APPS.PO_REQUISITION_LINES_ALL  PRLA
                ,APPS.OE_ORDER_LINES_ALL        OLA
                ,APPS.WWT_OE_ORDER_HEADERS_ALL_v      OHA
                ,APPS.END_SHIPMENTS             ES
                ,APPS.END_PACKAGES              EP
                ,APPS.END_PACKAGES_GROUP        EPG
                ,APPS.HZ_CUST_SITE_USES_ALL     SUA
                ,APPS.HZ_CUST_ACCT_SITES_ALL    CAS
                ,APPS.HZ_PARTY_SITES            HPS
                ,APPS.HZ_LOCATIONS              HL
                ,APPS.HZ_PARTIES                HP
                ,APPS.WWT_SO_HEADERS_DFF        SHD
           WHERE 1 = 1
             AND TO_NUMBER(WL_SETUP.ATTRIBUTE2) > 0
             AND JRS.SALESREP_ID                = TO_NUMBER(WL_SETUP.ATTRIBUTE2)
             AND OHA.SALESREP_ID                = JRS.SALESREP_ID
             AND WL.LOOKUP_TYPE                 = 'WWT_OM_LINE_FLOW_CONTROLS'
             AND WL.ATTRIBUTE2                  = 'DROP_SHIP'
             AND OHA.SOLD_TO_ORG_ID             = NVL(WL_SETUP.ATTRIBUTE1, OHA.SOLD_TO_ORG_ID)
             AND WL_SETUP.LOOKUP_TYPE                = 'WWT_ASN_OUTBOUND_EXTRACT'
             AND WL_SETUP.ATTRIBUTE11                = 'Y'
--             AND (WL_SETUP.ATTRIBUTE22 IS NULL OR (WL_SETUP.ATTRIBUTE22 IS NOT NULL AND OLA.SUBINVENTORY  IN  (SELECT /*+ CARDINALITY (ct 3) */ COLUMN_VALUE
--                                                                                                 FROM TABLE (SELECT CAST (apps.wwt_utilities.wwt_string_to_table_fun
--                                                                                                                (WL.ATTRIBUTE22, ',')
--                                                                                                                AS wwt_string_to_table_type)
--                                                                                                              FROM DUAL) ct)))
             AND OLA.SHIP_FROM_ORG_ID = NVL(WL_SETUP.ATTRIBUTE23,OLA.SHIP_FROM_ORG_ID)
             AND OHA.HEADER_ID                  = SHD.HEADER_ID (+)
             AND NVL(SHD.ATTRIBUTE61, 'N/A')    = NVL(WL_SETUP.ATTRIBUTE19, NVL(SHD.ATTRIBUTE61, 'N/A'))
             AND TO_CHAR( OLA.LINE_TYPE_ID )    = WL.ATTRIBUTE1
             AND OLA.ORDERED_QUANTITY > 0
             AND OLA.SPLIT_FROM_LINE_ID IS NULL
             AND OLA.ATTRIBUTE20                = TO_CHAR(PRLA.REQUISITION_LINE_ID)
             AND PLLA.LINE_LOCATION_ID          = PRLA.LINE_LOCATION_ID
             AND PLLA.PO_LINE_ID                = PLA.PO_LINE_ID
             AND PHA.ATTRIBUTE9                 = TO_CHAR( JRS.SALESREP_ID )
             AND OHA.SHIP_TO_ORG_ID             = SUA.SITE_USE_ID (+)
             AND SUA.CUST_ACCT_SITE_ID          = CAS.CUST_ACCT_SITE_ID (+)
             AND CAS.PARTY_SITE_ID              = HPS.PARTY_SITE_ID (+)
             AND HPS.LOCATION_ID                = HL.LOCATION_ID (+)
             AND HP.PARTY_ID                    = HPS.PARTY_ID
             AND OLA.HEADER_ID                  = OHA.HEADER_ID
             AND PHA.PO_HEADER_ID               = PLA.PO_HEADER_ID
             AND EP.ERP_LINE_NUMBER             = PLA.LINE_NUM
             AND EP.ERP_PO_NUMBER               = PHA.SEGMENT1
             AND ES.PICKUP_DATE IS NOT NULL
             AND (ES.STATUS                      NOT IN ('Cancelled', 'Closed', 'Open')
                  OR (ES.STATUS = 'Closed' AND ES.LAST_UPDATE_DATE >= TRUNC(SYSDATE) - 1)
                 )
             AND ES.SHIPMENT_ID                 = EP.SHIPMENT_ID
             AND EP.ATTRIBUTE9                  IS NULL
             AND EP.PACKAGE_GROUP_ID            = EPG.PACKAGE_GROUP_ID (+)
            UNION
            -- This portion is for the ASN report, and will query all rows
            -- This query is basically a copy of the Non Drop query above. It will look at Oracle instead of SCT as the source of shipment information
            -- The downside to looking at the shipments in Oracle as opposed to SCT is that there is a delay, since SCT waits for the Invoice until
            -- it releases the shipment to Oracle. Currently, this delay is acceptable by the business for the reporting section
             SELECT
                  'DROP'            CURSOR_TYPE
                   ,HP.PARTY_NAME        CUSTOMER_NAME
                  ,WDA.DELIVERY_ID     DELIVERY_ID
                  ,TO_NUMBER( NULL )    DROP_SHIPMENT_ID
                  ,NVL( WDI.SEQUENCE_NUMBER, WDD.TRACKING_NUMBER )              BILL_OF_LADING
                  ,WDD.DELIVERY_DETAIL_ID                                           DELIVERY_DETAIL_ID
                  ,COALESCE(WDD.CONTAINER_NAME, WDD2.CONTAINER_NAME, '-1' ) LPN
                  ,OHA.ORDER_NUMBER                                                ORDER_NUMBER
                  ,OHA.HEADER_ID                                                 SO_HEADER_ID
                  ,OLA.LINE_ID                                                     SO_LINE_ID
                  ,OHA.SALESREP_ID                                                 SO_SALESREP_ID
                  ,OHA.ORDERED_DATE                                             ORDERED_DATE
                  ,OLA.LINE_NUMBER                                                 ORDER_LINE_NUMBER
                  ,OLA.CUSTOMER_LINE_NUMBER                                     CUSTOMER_LINE_NUM
                  ,OLA.SHIPMENT_NUMBER                                             ORDER_SHIPMENT_NUMBER
                  ,OHA.CUST_PO_NUMBER                                             CUSTOMER_PO_NUM
                  ,WDD.INVENTORY_ITEM_ID                                         INVENTORY_ITEM_ID
                  ,WDD.ITEM_DESCRIPTION                                         ITEM_DESCRIPTION
                  ,MSI.SEGMENT1                                                 INVENTORY_ITEM_SEGMENT1
                  ,MSI.SEGMENT2                                                 INVENTORY_ITEM_SEGMENT2
                  ,MSI.SEGMENT3                                                 INVENTORY_ITEM_SEGMENT3
                  ,MSI.SEGMENT4                                                 INVENTORY_ITEM_SEGMENT4
                  ,MSI.ATTRIBUTE6                                                 INVENTORY_ITEM_ATTRIBUTE6
                  ,MSI.ATTRIBUTE13                                                 INVENTORY_ITEM_ATTRIBUTE13
                  ,PHA.SEGMENT1                                                        PURCHASE_ORDER_NUM
                  ,PLA.LINE_NUM                                          PO_LINE_NUM
                  ,WDD.TRACKING_NUMBER                                             TRACKING_NUMBER
                  ,WDD.SHIPPED_QUANTITY                                         SHIPPED_QUANTITY
                  ,TRIM(RPAD(WND.WAYBILL,2000))                                        WAYBILL
                  ,OLA.SHIPPING_QUANTITY_UOM                                     SHIPPED_UOM
                  ,OLA.ORDERED_QUANTITY                                         ORDERED_QUANTITY
                  ,OLA.ORDER_QUANTITY_UOM                                         ORDERED_UOM
                  ,OLA.UNIT_LIST_PRICE                                            UNIT_LIST_PRICE
                  ,OLA.UNIT_SELLING_PRICE                                        UNIT_SELLING_PRICE
                  ,MSI.SHIPPABLE_ITEM_FLAG                                        SHIPPABLE_ITEM_FLAG
                  ,WND.SHIP_METHOD_CODE                                         SHIP_METHOD_CODE
                  ,WC.FREIGHT_CODE                                                 CARRIER
                  ,WDD.SHIP_TO_LOCATION_ID                                         SHIP_TO_LOCATION_ID
                  ,WDD.DELIVER_TO_LOCATION_ID                                     DELIVER_TO_LOCATION_ID
                  ,WDD.SHIP_TO_CONTACT_ID                                         SHIP_TO_CONTACT_ID
                  ,WDD.DELIVER_TO_CONTACT_ID                                     DELIVER_TO_CONTACT_ID
                  ,OHA.INVOICE_TO_ORG_ID                                         INVOICE_TO_SITE_USE_ID
                  ,OHA.SOLD_TO_ORG_ID                                             SOLD_TO_SITE_USE_ID
                  ,OHA.SHIP_TO_ORG_ID                                             SHIP_TO_ORG_ID
                  ,TRUNC( WND.CONFIRM_DATE )                                     SHIP_DATE
                  ,TO_CHAR( WND.CONFIRM_DATE, 'HH24:MI:SS' )                         SHIP_TIME
                  ,NVL( WND.NET_WEIGHT, WND.GROSS_WEIGHT )                         DELIVERY_WEIGHT
                  ,WND.WEIGHT_UOM_CODE                                              WEIGHT_UOM
                  ,WND.ATTRIBUTE1                                                 DELIVERY_ATTRIBUTE1
                  ,WND.ATTRIBUTE2                                                 DELIVERY_ATTRIBUTE2
                  ,WND.ATTRIBUTE3                                                 DELIVERY_ATTRIBUTE3
--                  ,WND.ATTRIBUTE4                                                 DELIVERY_ATTRIBUTE4
                  ,WND.ATTRIBUTE5                                                 DELIVERY_ATTRIBUTE5
                  ,WND.ATTRIBUTE6                                                 DELIVERY_ATTRIBUTE6
                  ,WND.ATTRIBUTE7                                                 DELIVERY_ATTRIBUTE7
                  ,WND.ATTRIBUTE8                                                 DELIVERY_ATTRIBUTE8
                  ,WND.ATTRIBUTE9                                                 DELIVERY_ATTRIBUTE9
                  ,WND.ATTRIBUTE10                                                 DELIVERY_ATTRIBUTE10
                  ,WND.ATTRIBUTE11                                                 DELIVERY_ATTRIBUTE11
                  ,WND.ATTRIBUTE12                                                 DELIVERY_ATTRIBUTE12
                  ,WND.ATTRIBUTE13                                                 DELIVERY_ATTRIBUTE13
                  ,WND.ATTRIBUTE14                                                 DELIVERY_ATTRIBUTE14
                  ,WND.ATTRIBUTE15                                                 DELIVERY_ATTRIBUTE15
                  ,WDD.ATTRIBUTE1                                                 DELIVERY_DETAILS_ATTRIBUTE1
                  ,WDD.ATTRIBUTE2                                                 DELIVERY_DETAILS_ATTRIBUTE2
                  ,WDD.ATTRIBUTE3                                                 DELIVERY_DETAILS_ATTRIBUTE3
                  ,WDD.ATTRIBUTE4                                                 DELIVERY_DETAILS_ATTRIBUTE4
                  ,WDD.ATTRIBUTE5                                                 DELIVERY_DETAILS_ATTRIBUTE5
                  ,WDD.ATTRIBUTE6                                                 DELIVERY_DETAILS_ATTRIBUTE6
                  ,WDD.ATTRIBUTE7                                                 DELIVERY_DETAILS_ATTRIBUTE7
                  ,WDD.ATTRIBUTE8                                                 DELIVERY_DETAILS_ATTRIBUTE8
                  ,WDD.ATTRIBUTE9                                                 DELIVERY_DETAILS_ATTRIBUTE9
                  ,WDD.ATTRIBUTE10                                                 DELIVERY_DETAILS_ATTRIBUTE10
                  ,WDD.ATTRIBUTE11                                                 DELIVERY_DETAILS_ATTRIBUTE11
                  ,WDD.ATTRIBUTE12                                                 DELIVERY_DETAILS_ATTRIBUTE12
                  ,WDD.ATTRIBUTE13                                                 DELIVERY_DETAILS_ATTRIBUTE13
                  ,WDD.ATTRIBUTE14                                                 DELIVERY_DETAILS_ATTRIBUTE14
                  ,WDD.ATTRIBUTE15                                                 DELIVERY_DETAILS_ATTRIBUTE15
                  ,OHA.ATTRIBUTE1                                                 SOH_ATTRIBUTE1
                  ,OHA.ATTRIBUTE2                                                 SOH_ATTRIBUTE2
                  ,OHA.ATTRIBUTE3                                                 SOH_ATTRIBUTE3
                  ,OHA.ATTRIBUTE4                                                 SOH_ATTRIBUTE4
                  ,OHA.ATTRIBUTE5                                                 SOH_ATTRIBUTE5
                  ,OHA.ATTRIBUTE6                                                 SOH_ATTRIBUTE6
                  ,OHA.ATTRIBUTE7                                                 SOH_ATTRIBUTE7
                  ,OHA.ATTRIBUTE8                                                 SOH_ATTRIBUTE8
                  ,OHA.ATTRIBUTE9                                                 SOH_ATTRIBUTE9
                  ,OHA.ATTRIBUTE10                                                 SOH_ATTRIBUTE10
                  ,OHA.ATTRIBUTE11                                                 SOH_ATTRIBUTE11
                  ,OHA.ATTRIBUTE12                                                 SOH_ATTRIBUTE12
                  ,OHA.ATTRIBUTE13                                                 SOH_ATTRIBUTE13
                  ,OHA.ATTRIBUTE14                                                 SOH_ATTRIBUTE14
                  ,OHA.ATTRIBUTE15                                                 SOH_ATTRIBUTE15
                  ,OHA.ATTRIBUTE16                                                 SOH_ATTRIBUTE16
                  ,OHA.ATTRIBUTE17                                                 SOH_ATTRIBUTE17
                  ,OHA.ATTRIBUTE18                                                 SOH_ATTRIBUTE18
                  ,OHA.ATTRIBUTE19                                                 SOH_ATTRIBUTE19
                  ,OHA.ATTRIBUTE20                                                 SOH_ATTRIBUTE20
                  ,OLA.ATTRIBUTE1                                                 SOL_ATTRIBUTE1
                  ,OLA.ATTRIBUTE2                                                 SOL_ATTRIBUTE2
                  ,OLA.ATTRIBUTE3                                                 SOL_ATTRIBUTE3
                  ,OLA.ATTRIBUTE4                                                 SOL_ATTRIBUTE4
                  ,OLA.ATTRIBUTE5                                                 SOL_ATTRIBUTE5
                  ,OLA.ATTRIBUTE6                                                 SOL_ATTRIBUTE6
                  ,OLA.ATTRIBUTE7                                                 SOL_ATTRIBUTE7
                  ,OLA.ATTRIBUTE8                                                 SOL_ATTRIBUTE8
                  ,OLA.ATTRIBUTE9                                                 SOL_ATTRIBUTE9
                  ,OLA.ATTRIBUTE10                                                 SOL_ATTRIBUTE10
                  ,OLA.ATTRIBUTE11                                                 SOL_ATTRIBUTE11
                  ,OLA.ATTRIBUTE12                                                 SOL_ATTRIBUTE12
                  ,OLA.ATTRIBUTE13                                                 SOL_ATTRIBUTE13
                  ,OLA.ATTRIBUTE14                                                 SOL_ATTRIBUTE14
                  ,OLA.ATTRIBUTE15                                                 SOL_ATTRIBUTE15
                  ,OLA.ATTRIBUTE16                                                 SOL_ATTRIBUTE16
                  ,OLA.ATTRIBUTE17                                                 SOL_ATTRIBUTE17
                  ,OLA.ATTRIBUTE18                                                 SOL_ATTRIBUTE18
                  ,OLA.ATTRIBUTE19                                                 SOL_ATTRIBUTE19
                  ,OLA.ATTRIBUTE20                                                 SOL_ATTRIBUTE20
                  ,WL_SETUP.ATTRIBUTE4                                                 PARTNER_ID
                  ,WL_SETUP.ATTRIBUTE5                                                 COMMUNICATION_METHOD
                  ,WL_SETUP.ATTRIBUTE1                                                 CUSTOMER_ID
                  ,WL_SETUP.ATTRIBUTE3                                                 SHIP_TO_SITE_USE_ID
                  ,WL_SETUP.ATTRIBUTE2                                                 SALESREP_ID
                  ,WL_SETUP.ATTRIBUTE6                                                 EXTENSION_PACKAGE
                  ,WL_SETUP.ATTRIBUTE7                                                 SHIPMENT_EXT
                  ,WL_SETUP.ATTRIBUTE8                                                 ORDER_EXT
                  ,WL_SETUP.ATTRIBUTE9                                                 PACKAGE_EXT
                  ,WL_SETUP.ATTRIBUTE10                                                 ITEM_EXT
                  ,WL_SETUP.ATTRIBUTE18                                               ASN_EXCLUSION_EXT_FLAG
                  ,WL_SETUP.ATTRIBUTE12                                               PROCESS_STATUS
                  ,WL_SETUP.ATTRIBUTE19                                               DROP_SHIP_EXCLUSION_EXT_FLAG
                  ,DECODE( OLA.TOP_MODEL_LINE_ID
                  ,NULL, 'N'
                  ,DECODE( OLA.LINE_ID
                  ,OLA.TOP_MODEL_LINE_ID, 'Y','N' ))    MASTER_ITEM
                  ,OLA.TOP_MODEL_LINE_ID        PARENT_SO_LINE_ID
                  ,WDD.SOURCE_HEADER_NUMBER        DETAIL_ORDER_NUMBER
                  ,TO_NUMBER( NULL )            RCPT_LINE_ID
                  ,TO_NUMBER( NULL )            SHIPMENT_ID
                  ,NULL                                               EXTERNAL_PACKAGE_GROUP_ID
                  ,NULL                                               EXTERNAL_PACKAGE_ID
                  ,TO_NUMBER(NULL)                                    PKG_DISPLAY_QUANTITY
                  ,TO_NUMBER(NULL)                                    PACKAGE_LENGTH
                  ,TO_NUMBER(NULL)                                    PACKAGE_WIDTH
                  ,TO_NUMBER(NULL)                                    PACKAGE_HEIGHT
                  ,TO_NUMBER(NULL)                                    PACKAGE_WEIGHT
                  ,NULL                                               PKG_LENGTH_UOM
                  ,NULL                                               PKG_WIDTH_UOM
                  ,NULL                                               PKG_HEIGHT_UOM
                  ,NULL                                               PKG_WEIGHT_UOM
                  ,NULL                                               OVERPACK_FLAG
                  ,WL_SETUP.ATTRIBUTE20                                     SPLIT_ON_TRACKING_NUM
                  ,WL_SETUP.ATTRIBUTE21    INCLUDE_ALL_ROWS
                  ,WL_SETUP.ATTRIBUTE24    POST_PROCESS_EXT
              FROM APPS.WSH_NEW_DELIVERIES WND
                  ,APPS.HZ_CUST_ACCOUNTS HCA
                  ,APPS.HZ_PARTIES HP
                  ,APPS.WSH_DELIVERY_DETAILS WDD
                  ,APPS.WSH_DELIVERY_DETAILS WDD2
                  ,APPS.WSH_DELIVERY_ASSIGNMENTS WDA
                  ,APPS.WSH_DELIVERY_LEGS WDL
                  ,APPS.WSH_DOCUMENT_INSTANCES WDI
                  ,APPS.OE_ORDER_LINES_ALL OLA
                  ,APPS.WWT_OE_ORDER_HEADERS_ALL_V OHA
                  ,APPS.WWT_SO_LINES_DFF SLD
                  ,APPS.WWT_LOOKUPS_ACTIVE_V WL_SETUP
                  ,APPS.WWT_LOOKUPS_ACTIVE_V WL2
                  ,APPS.WSH_CARRIERS WC
                  ,APPS.MTL_SYSTEM_ITEMS_B MSI
                  ,APPS.PO_HEADERS_ALL            PHA
                  ,APPS.PO_LINES_ALL              PLA
                  ,APPS.PO_LINE_LOCATIONS_ALL     PLLA
                  ,APPS.PO_REQUISITION_LINES_ALL  PRLA
                  ,APPS.WWT_SO_HEADERS_DFF        SHD
             WHERE 1 = 1
               AND WL_SETUP.LOOKUP_TYPE                     = 'WWT_ASN_OUTBOUND_EXTRACT'
               AND WL_SETUP.ATTRIBUTE2 < 0 AND WL_SETUP.ATTRIBUTE21 = 'Y'
               AND NOT EXISTS (SELECT SHIPMENT_ID FROM APPS.WWT_ASN_OUTBOUND_SHIPMENTS
                                                       WHERE DELIVERY_ID = WND.DELIVERY_ID
                                                       AND COMMUNICATION_METHOD = WL_SETUP.ATTRIBUTE5
                                                       AND PROCESS_STATUS = WL_SETUP.ATTRIBUTE12)
               AND WND.CONFIRM_DATE                     >= SYSDATE - 7
               AND WDA.DELIVERY_ID                     = WND.DELIVERY_ID
               AND WDA.PARENT_DELIVERY_DETAIL_ID    = WDD2.DELIVERY_DETAIL_ID(+)
               AND WDD.SOURCE_LINE_ID         = OLA.LINE_ID
               AND OLA.LINE_ID                        = SLD.LINE_ID(+)
               AND OLA.HEADER_ID                   = OHA.HEADER_ID
               AND OHA.HEADER_ID                  = SHD.HEADER_ID (+)
               AND NVL(SHD.ATTRIBUTE61, 'N/A')    = NVL(WL_SETUP.ATTRIBUTE19, NVL(SHD.ATTRIBUTE61, 'N/A'))
               AND TO_NUMBER( OLA.ATTRIBUTE20)  = PRLA.REQUISITION_LINE_ID
               AND PRLA.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID
               AND PLLA.PO_LINE_ID            = PLA.PO_LINE_ID
               AND PLA.PO_HEADER_ID         = PHA.PO_HEADER_ID
               AND HCA.PARTY_ID                     = HP.PARTY_ID
               AND HCA.CUST_ACCOUNT_ID       = WND.CUSTOMER_ID
               AND HP.PARTY_TYPE                    = 'ORGANIZATION'
               AND WL2.LOOKUP_TYPE               = 'WWT_OM_LINE_FLOW_CONTROLS'
               AND TO_CHAR( OLA.LINE_TYPE_ID )      = WL2.ATTRIBUTE1
               AND WL2.ATTRIBUTE2                          = 'DROP_SHIP'
               AND WDD.ORGANIZATION_ID                = MSI.ORGANIZATION_ID
               AND WDD.INVENTORY_ITEM_ID             = MSI.INVENTORY_ITEM_ID
               AND WDA.DELIVERY_DETAIL_ID             = WDD.DELIVERY_DETAIL_ID
               AND WND.STATUS_CODE                      = 'CL'
               AND WDL.DELIVERY_ID                          = WND.DELIVERY_ID
               AND WDI.ENTITY_ID(+)                         = WDL.DELIVERY_LEG_ID
               AND WDI.ENTITY_NAME(+)                    = 'WSH_DELIVERY_LEGS'
               AND WDI.DOCUMENT_TYPE(+)               = 'BOL'
               AND WC.CARRIER_ID(+)                        = WND.CARRIER_ID
               AND NVL( WDD.CONTAINER_FLAG, WDD2.CONTAINER_FLAG ) = 'N'
               AND NVL(WDD.INV_INTERFACED_FLAG,'N') IN ('Y','P')
               AND (TRUNC(WND.CONFIRM_DATE) >= WL_SETUP.START_DATE_ACTIVE OR WL_SETUP.START_DATE_ACTIVE IS NULL)
            ORDER BY COMMUNICATION_METHOD, PARTNER_ID, CUSTOMER_NAME, DELIVERY_ID, TRACKING_NUMBER, CUSTOMER_PO_NUM, ORDER_LINE_NUMBER;