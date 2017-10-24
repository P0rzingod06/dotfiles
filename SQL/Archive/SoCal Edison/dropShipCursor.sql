SELECT /*+ LEADING (WL_SETUP jrs pha ep es pla plla prla ola wl) */
--                'DROP'                                                  CURSOR_TYPE
--                ,HP.PARTY_NAME                                          CUSTOMER_NAME
--                ,-1                                                     DELIVERY_ID
--                ,ES.SHIPMENT_ID                                         DROP_SHIPMENT_ID
--                ,NULL                                                   BILL_OF_LADING
--                ,TO_NUMBER(NULL)                                        DELIVERY_DETAIL_ID
--                ,'-1'                                                   LPN
--                ,OHA.ORDER_NUMBER                                       ORDER_NUMBER
--                ,OHA.HEADER_ID                                          SO_HEADER_ID
--                ,OLA.LINE_ID                                            SO_LINE_ID
--                ,OHA.SALESREP_ID                                        SO_SALESREP_ID
--                ,OHA.ORDERED_DATE                                       ORDERED_DATE
--                ,OLA.LINE_NUMBER                                        ORDER_LINE_NUMBER
--                ,NVL( OLA.ATTRIBUTE14, OLA.CUSTOMER_LINE_NUMBER )       CUSTOMER_LINE_NUM
--                ,OLA.SHIPMENT_NUMBER                                    ORDER_SHIPMENT_NUMBER
--                ,OHA.CUST_PO_NUMBER                                     CUSTOMER_PO_NUM
--                ,TO_NUMBER( NULL )                                      INVENTORY_ITEM_ID
--                ,EP.ERP_ITEM_DESCRIPTION                                ITEM_DESCRIPTION
--                ,NULL                                                   INVENTORY_ITEM_SEGMENT1
--                ,APPS.wwt_get_delimited_field(ep.erp_item_number,1,'.') INVENTORY_ITEM_SEGMENT2 --CHG30248
--                ,NULL                                                   INVENTORY_ITEM_SEGMENT3
--                ,NULL                                                   INVENTORY_ITEM_SEGMENT4
--                ,NULL                                                   INVENTORY_ITEM_ATTRIBUTE6
--                ,NULL                                                   INVENTORY_ITEM_ATTRIBUTE13
--                ,EP.ERP_PO_NUMBER                                       PURCHASE_ORDER_NUM
--                ,TO_NUMBER( EP.ERP_LINE_NUMBER )                        PO_LINE_NUM
--                ,SUBSTR(NVL(EPG.ATTRIBUTE11, EP.ATTRIBUTE11), 0, 30)    TRACKING_NUMBER
--                ,EP.QUANTITY                                            SHIPPED_QUANTITY
--                ,DECODE( ES.WAYBILL
--                        ,NULL, DECODE( ES.ATTRIBUTE11
--                                      ,NULL, EP.ATTRIBUTE11
--                                      ,ES.ATTRIBUTE11 )
--                        ,ES.WAYBILL )                                 WAYBILL
--                ,OLA.SHIPPING_QUANTITY_UOM                            SHIPPED_UOM
--                ,OLA.ORDERED_QUANTITY                                 ORDERED_QUANTITY
--                ,OLA.ORDER_QUANTITY_UOM                               ORDERED_UOM
--                ,OLA.UNIT_LIST_PRICE                                  UNIT_LIST_PRICE
--                ,OLA.UNIT_SELLING_PRICE                               UNIT_SELLING_PRICE
--                ,OLA.SHIPPABLE_FLAG                                   SHIPPABLE_ITEM_FLAG
--                ,NULL                                                 SHIP_METHOD_CODE
--                ,ES.CARRIER_NAME                                      CARRIER
--                ,TO_NUMBER( NULL )                                               SHIP_TO_LOCATION_ID
--                ,TO_NUMBER( NULL )                                               DELIVER_TO_LOCATION_ID
--                ,TO_NUMBER( NULL )                                               SHIP_TO_CONTACT_ID
--                ,TO_NUMBER( NULL )                                               DELIVER_TO_CONTACT_ID
--                ,OHA.INVOICE_TO_ORG_ID                                INVOICE_TO_SITE_USE_ID
--                ,OHA.SOLD_TO_ORG_ID                                   SOLD_TO_SITE_USE_ID
--                ,OHA.SHIP_TO_ORG_ID                                   SHIP_TO_ORG_ID
--                ,TRUNC( ES.PICKUP_DATE )                              SHIP_DATE
--                ,TO_CHAR( ES.PICKUP_DATE, 'HH24:MI:SS' )              SHIP_TIME
--                ,NVL(ES.GROSS_WEIGHT,ES.NET_WEIGHT)                   DELIVERY_WEIGHT
--                ,NULL                                                 WEIGHT_UOM
--                ,NULL                                                   DELIVERY_ATTRIBUTE1
--                ,NULL                                                   DELIVERY_ATTRIBUTE2
--                ,NULL                                                   DELIVERY_ATTRIBUTE3
--                ,NULL                                                   DELIVERY_ATTRIBUTE4
--                ,NULL                                                   DELIVERY_ATTRIBUTE5
--                ,NULL                                                   DELIVERY_ATTRIBUTE6
--                ,NULL                                                   DELIVERY_ATTRIBUTE7
--                ,NULL                                                   DELIVERY_ATTRIBUTE8
--                ,NULL                                                   DELIVERY_ATTRIBUTE9
--                ,NULL                                                   DELIVERY_ATTRIBUTE10
--                ,NULL                                                   DELIVERY_ATTRIBUTE11
--                ,NULL                                                   DELIVERY_ATTRIBUTE12
--                ,NULL                                                   DELIVERY_ATTRIBUTE13
--                ,NULL                                                   DELIVERY_ATTRIBUTE14
--                ,NULL                                                   DELIVERY_ATTRIBUTE15
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE1
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE2
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE3
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE4
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE5
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE6
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE7
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE8
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE9
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE10
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE11
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE12
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE13
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE14
--                ,NULL                                                   DELIVERY_DETAILS_ATTRIBUTE15
--                ,OHA.ATTRIBUTE1                                       SOH_ATTRIBUTE1
--                ,OHA.ATTRIBUTE2                                       SOH_ATTRIBUTE2
--                ,OHA.ATTRIBUTE3                                       SOH_ATTRIBUTE3
--                ,OHA.ATTRIBUTE4                                       SOH_ATTRIBUTE4
--                ,OHA.ATTRIBUTE5                                       SOH_ATTRIBUTE5
--                ,OHA.ATTRIBUTE6                                       SOH_ATTRIBUTE6
--                ,OHA.ATTRIBUTE7                                       SOH_ATTRIBUTE7
--                ,OHA.ATTRIBUTE8                                       SOH_ATTRIBUTE8
--                ,OHA.ATTRIBUTE9                                       SOH_ATTRIBUTE9
--                ,OHA.ATTRIBUTE10                                      SOH_ATTRIBUTE10
--                ,OHA.ATTRIBUTE11                                      SOH_ATTRIBUTE11
--                ,OHA.ATTRIBUTE12                                      SOH_ATTRIBUTE12
--                ,OHA.ATTRIBUTE13                                      SOH_ATTRIBUTE13
--                ,OHA.ATTRIBUTE14                                      SOH_ATTRIBUTE14
--                ,OHA.ATTRIBUTE15                                      SOH_ATTRIBUTE15
--                ,OHA.ATTRIBUTE16                                      SOH_ATTRIBUTE16
--                ,OHA.ATTRIBUTE17                                      SOH_ATTRIBUTE17
--                ,OHA.ATTRIBUTE18                                      SOH_ATTRIBUTE18
--                ,OHA.ATTRIBUTE19                                      SOH_ATTRIBUTE19
--                ,OHA.ATTRIBUTE20                                      SOH_ATTRIBUTE20
--                ,OLA.ATTRIBUTE1                                       SOL_ATTRIBUTE1
--                ,OLA.ATTRIBUTE2                                       SOL_ATTRIBUTE2
--                ,OLA.ATTRIBUTE3                                       SOL_ATTRIBUTE3
--                ,OLA.ATTRIBUTE4                                       SOL_ATTRIBUTE4
--                ,OLA.ATTRIBUTE5                                       SOL_ATTRIBUTE5
--                ,OLA.ATTRIBUTE6                                       SOL_ATTRIBUTE6
--                ,OLA.ATTRIBUTE7                                       SOL_ATTRIBUTE7
--                ,OLA.ATTRIBUTE8                                       SOL_ATTRIBUTE8
--                ,OLA.ATTRIBUTE9                                       SOL_ATTRIBUTE9
--                ,OLA.ATTRIBUTE10                                      SOL_ATTRIBUTE10
--                ,OLA.ATTRIBUTE11                                      SOL_ATTRIBUTE11
--                ,OLA.ATTRIBUTE12                                      SOL_ATTRIBUTE12
--                ,OLA.ATTRIBUTE13                                      SOL_ATTRIBUTE13
--                ,OLA.ATTRIBUTE14                                      SOL_ATTRIBUTE14
--                ,OLA.ATTRIBUTE15                                      SOL_ATTRIBUTE15
--                ,OLA.ATTRIBUTE16                                      SOL_ATTRIBUTE16
--                ,OLA.ATTRIBUTE17                                      SOL_ATTRIBUTE17
--                ,OLA.ATTRIBUTE18                                      SOL_ATTRIBUTE18
--                ,OLA.ATTRIBUTE19                                      SOL_ATTRIBUTE19
--                ,OLA.ATTRIBUTE20                                      SOL_ATTRIBUTE20
--                ,WL_SETUP.ATTRIBUTE4                                       PARTNER_ID
--                ,WL_SETUP.ATTRIBUTE5                                       COMMUNICATION_METHOD
--                ,WL_SETUP.ATTRIBUTE1                                       CUSTOMER_ID
--                ,WL_SETUP.ATTRIBUTE3                                       SHIP_TO_SITE_USE_ID
--                ,WL_SETUP.ATTRIBUTE2                                       SALESREP_ID
--                ,WL_SETUP.ATTRIBUTE6                                       EXTENSION_PACKAGE
--                ,WL_SETUP.ATTRIBUTE7                                       SHIPMENT_EXT
--                ,WL_SETUP.ATTRIBUTE8                                       ORDER_EXT
--                ,WL_SETUP.ATTRIBUTE9                                       PACKAGE_EXT
--                ,WL_SETUP.ATTRIBUTE10                                      ITEM_EXT
--                ,WL_SETUP.ATTRIBUTE18                                      ASN_EXCLUSION_EXT_FLAG
--                ,WL_SETUP.ATTRIBUTE12                                      PROCESS_STATUS
--                ,WL_SETUP.ATTRIBUTE19                                      DROP_SHIP_EXCLUSION_EXT_FLAG
--                ,NULL                                                 MASTER_ITEM
--                ,TO_NUMBER( NULL )                                               PARENT_SO_LINE_ID
--                ,NULL                                                 DETAIL_ORDER_NUMBER
--                ,EP.PACKAGE_ID                                        RCPT_LINE_ID
--                ,ES.SHIPMENT_ID                                       SHIPMENT_ID
--                ,EPG.EXTERNAL_PACKAGE_GROUP_ID                        EXTERNAL_PACKAGE_GROUP_ID
--                ,EP.EXTERNAL_PACKAGE_ID                               EXTERNAL_PACKAGE_ID
--                ,EP.DISPLAY_QUANTITY                                  PKG_DISPLAY_QUANTITY
--                ,NVL(EPG.GROUP_LENGTH, EP.PACKAGE_LENGTH)             PACKAGE_LENGTH
--                ,NVL(EPG.GROUP_WIDTH, EP.PACKAGE_WIDTH)               PACKAGE_WIDTH
--                ,NVL(EPG.GROUP_HEIGHT, EP.PACKAGE_HEIGHT)             PACKAGE_HEIGHT
--                ,NVL(EPG.GROUP_WEIGHT, EP.PACKAGE_WEIGHT)             PACKAGE_WEIGHT
--                ,NVL(EPG.GROUP_LENGTH_UOM, EP.LENGTH_UOM)             PKG_LENGTH_UOM
--                ,NVL(EPG.GROUP_WIDTH_UOM, EP.WIDTH_UOM)               PKG_WIDTH_UOM
--                ,NVL(EPG.GROUP_HEIGHT_UOM, EP.HEIGHT_UOM)             PKG_HEIGHT_UOM
--                ,NVL(EPG.GROUP_WEIGHT_UOM, EP.WEIGHT_UOM)             PKG_WEIGHT_UOM
--                ,NVL2(EPG.PACKAGE_GROUP_ID, 'Y', 'N')                 OVERPACK_FLAG
--                ,WL_SETUP.ATTRIBUTE20                                      SPLIT_ON_TRACKING_NUM
--                ,WL_SETUP.ATTRIBUTE21    INCLUDE_ALL_ROWS
--                ,WL_SETUP.ATTRIBUTE24    POST_PROCESS_EXT
hp.party_name,
ES.STATUS,
oha.creation_date,
oha.last_update_date
            FROM APPS.WWT_LOOKUPS_ACTIVE_V      WL
                ,APPS.WWT_LOOKUPS_ACTIVE_V      WL_SETUP
                ,APPS.JTF_RS_SALESREPS          JRS
                ,APPS.PO_HEADERS_ALL            PHA
                ,APPS.PO_LINES_ALL              PLA
                ,APPS.PO_LINE_LOCATIONS_ALL     PLLA
                ,APPS.PO_REQUISITION_LINES_ALL  PRLA
                ,APPS.OE_ORDER_LINES_ALL        OLA
                ,APPS.OE_ORDER_HEADERS_ALL      OHA
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
--             AND TO_NUMBER(WL_SETUP.ATTRIBUTE2) > 0
             and hp.party_name = 'Southern California Edison Co'  -- just socal
             AND JRS.SALESREP_ID                = TO_NUMBER(WL_SETUP.ATTRIBUTE2)
             AND OHA.SALESREP_ID                = JRS.SALESREP_ID
             AND WL.LOOKUP_TYPE                 = 'WWT_OM_LINE_FLOW_CONTROLS'
             AND WL.ATTRIBUTE2                  = 'DROP_SHIP'
             AND OHA.SOLD_TO_ORG_ID             = NVL(WL_SETUP.ATTRIBUTE1, OHA.SOLD_TO_ORG_ID)
             AND WL_SETUP.LOOKUP_TYPE                = 'WWT_ASN_OUTBOUND_EXTRACT'
             AND WL_SETUP.ATTRIBUTE11                = 'Y'
             AND (WL_SETUP.ATTRIBUTE22 IS NULL OR (WL_SETUP.ATTRIBUTE22 IS NOT NULL AND OLA.SUBINVENTORY  IN  (SELECT /*+ CARDINALITY (ct 3) */ COLUMN_VALUE
                                                                                                 FROM TABLE (SELECT CAST (apps.wwt_utilities.wwt_string_to_table_fun
                                                                                                                (WL.ATTRIBUTE22, ',')
                                                                                                                AS wwt_string_to_table_type)
                                                                                                              FROM DUAL) ct)))
             AND OLA.SHIP_FROM_ORG_ID = NVL(WL_SETUP.ATTRIBUTE23,OLA.SHIP_FROM_ORG_ID)
             AND OHA.HEADER_ID                  = SHD.HEADER_ID (+)
             AND NVL(SHD.ATTRIBUTE61, 'N/A')    = NVL(WL_SETUP.ATTRIBUTE19, NVL(SHD.ATTRIBUTE61, 'N/A'))
             AND TO_CHAR( OLA.LINE_TYPE_ID )    = WL.ATTRIBUTE1
--             AND OLA.ORDERED_QUANTITY > 0
--             AND OLA.SPLIT_FROM_LINE_ID IS NULL
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
--             and sales_channel_code = 'SUARESP'
order by oha.last_update_date desc
             
             --sales_channel_code