select * from apps.wwt_asn_outbound_shipments
where 1=1
and creation_date > sysdate - .5
--and delivery_id = 1103834140
and partner_id = 'RBSCitizens'
--and delivery_id = 1104349112
--and process_status NOT IN ('ROUTED_TO_TN','UNPROCESSED')
order by creation_date desc

select * from apps.wwt_asn_outbound_items
where 1=1
--and creation_date > sysdate - 1
--and delivery_id = 1103834140
--and partner_id = 'RBSCitizens'
--and shipment_id IN (9538543,
--9538542,
--9538547,
--9538544,
--9538546,
--9538548)
and item_description = 'UCS B200 M3 Blade Server w/o CPU, mem, HDD, mLOM/mezz (1D)'
and inventory_item_segment2 = 'UCSB-B200-M3-D'
and creation_date > sysdate - .5
--and process_status NOT IN ('ROUTED_TO_TN','UNPROCESSED')
order by shipment_id asc

1091083201
1091083196
1091083263

select * from apps.wwt_oe_order_headers_all_v
where 1=1
and creation_date > sysdate - 5
order by creation_date desc

select * from APPS.WSH_NEW_DELIVERIES
where 1=1
and creation_Date > sysdate - 5
--and delivery_id IN (1104384910,
--1104384912,
--1103834140,
--1104384909,
--1104364552,
--1104364826,
--1104364828,
--1104352135)
order by creation_date asc

select * from apps.wwt_lookups
where 1=1
and lookup_type LIKE 'WWT_ASN_OUTBOUND_EXTRACT'
and description LIKE '%RBS%'

select * from APPS.OE_ORDER_LINES_ALL
where 1=1
and creation_Date > sysdate - 10
and salesrep_id = 100308284

select * from apps.wwt_asn_outbound_extensions
where 1=1
and creation_Date > sysdate - 1

select * from apps.wwt_asn_outbound_serial_nums
where 1=1
and creation_Date > sysdate - 1

apps.wwt_asn_outbound_rbs_citzn_pkg

apps.wwt_asn_outbound_extract

select * from APPS.WSH_NEW_DELIVERIES
where 1=1
and creation_date > sysdate - 1
order by creation_date desc

SELECT waos.SHIPMENT_ID
FROM APPS.WWT_ASN_OUTBOUND_SHIPMENTS waos,apps.WSH_NEW_DELIVERIES wwnd
WHERE     waos.DELIVERY_ID = wwnd.delivery_id
AND wwnd.customer_id = 4951678
AND COMMUNICATION_METHOD = 'FLAT FILE'
AND PROCESS_STATUS = 'UNPROCESSED'
AND WND.CUSTOMER_ID = NVL (WL.ATTRIBUTE1, WND.CUSTOMER_ID)

SELECT serial_number, asset_tag
        FROM apps.wwt_xxwms_serial_shipping_v
       WHERE     DELIVERY_DETAIL_ID IN (984581726,984581729)
             AND INVENTORY_ITEM_ID IN (17174163,17385671)

SELECT DISTINCT 
               OHA.creation_date,
               'NON-DROP' CURSOR_TYPE,
               HP.PARTY_NAME CUSTOMER_NAME,
               WDA.DELIVERY_ID DELIVERY_ID,
               TO_NUMBER (NULL) DROP_SHIPMENT_ID,
               NVL (WDI.SEQUENCE_NUMBER, WDD.TRACKING_NUMBER) BILL_OF_LADING,
               WDD.DELIVERY_DETAIL_ID DELIVERY_DETAIL_ID,
               COALESCE (WDD.CONTAINER_NAME, WDD2.CONTAINER_NAME, '-1') LPN,
               OHA.ORDER_NUMBER ORDER_NUMBER,
               OHA.HEADER_ID SO_HEADER_ID,
               OLA.LINE_ID SO_LINE_ID,
               OHA.SALESREP_ID SO_SALESREP_ID,
               OHA.ORDERED_DATE ORDERED_DATE,
               OLA.LINE_NUMBER ORDER_LINE_NUMBER,
               OLA.CUSTOMER_LINE_NUMBER CUSTOMER_LINE_NUM,
               OLA.SHIPMENT_NUMBER ORDER_SHIPMENT_NUMBER,
               OHA.CUST_PO_NUMBER CUSTOMER_PO_NUM,
               WDD.INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
               WDD.ITEM_DESCRIPTION ITEM_DESCRIPTION,
               MSI.SEGMENT1 INVENTORY_ITEM_SEGMENT1,
               MSI.SEGMENT2 INVENTORY_ITEM_SEGMENT2,
               MSI.SEGMENT3 INVENTORY_ITEM_SEGMENT3,
               MSI.SEGMENT4 INVENTORY_ITEM_SEGMENT4,
               MSI.ATTRIBUTE6 INVENTORY_ITEM_ATTRIBUTE6,
               MSI.ATTRIBUTE13 INVENTORY_ITEM_ATTRIBUTE13,
               NULL PURCHASE_ORDER_NUM,
               TO_NUMBER (NULL) PO_LINE_NUM,
               WDD.TRACKING_NUMBER TRACKING_NUMBER,
               WDD.SHIPPED_QUANTITY SHIPPED_QUANTITY,
               TRIM (RPAD (WND.WAYBILL, 2000)) WAYBILL,
               OLA.SHIPPING_QUANTITY_UOM SHIPPED_UOM,
               OLA.ORDERED_QUANTITY ORDERED_QUANTITY,
               OLA.ORDER_QUANTITY_UOM ORDERED_UOM,
               OLA.UNIT_LIST_PRICE UNIT_LIST_PRICE,
               OLA.UNIT_SELLING_PRICE UNIT_SELLING_PRICE,
               MSI.SHIPPABLE_ITEM_FLAG SHIPPABLE_ITEM_FLAG,
               WND.SHIP_METHOD_CODE SHIP_METHOD_CODE,
               WC.FREIGHT_CODE CARRIER,
               WDD.SHIP_TO_LOCATION_ID SHIP_TO_LOCATION_ID,
               WDD.DELIVER_TO_LOCATION_ID DELIVER_TO_LOCATION_ID,
               WDD.SHIP_TO_CONTACT_ID SHIP_TO_CONTACT_ID,
               WDD.DELIVER_TO_CONTACT_ID DELIVER_TO_CONTACT_ID,
               OHA.INVOICE_TO_ORG_ID INVOICE_TO_SITE_USE_ID,
               OHA.SOLD_TO_ORG_ID SOLD_TO_SITE_USE_ID,
               OHA.SHIP_TO_ORG_ID SHIP_TO_ORG_ID,
               TRUNC (WND.CONFIRM_DATE) SHIP_DATE,
               TO_CHAR (WND.CONFIRM_DATE, 'HH24:MI:SS') SHIP_TIME,
               NVL (WND.NET_WEIGHT, WND.GROSS_WEIGHT) DELIVERY_WEIGHT,
               WND.WEIGHT_UOM_CODE WEIGHT_UOM,
               WND.ATTRIBUTE1 DELIVERY_ATTRIBUTE1,
               WND.ATTRIBUTE2 DELIVERY_ATTRIBUTE2,
               WND.ATTRIBUTE3 DELIVERY_ATTRIBUTE3,
               WND.ATTRIBUTE4 DELIVERY_ATTRIBUTE4,
               WND.ATTRIBUTE5 DELIVERY_ATTRIBUTE5,
               WND.ATTRIBUTE6 DELIVERY_ATTRIBUTE6,
               WND.ATTRIBUTE7 DELIVERY_ATTRIBUTE7,
               WND.ATTRIBUTE8 DELIVERY_ATTRIBUTE8,
               WND.ATTRIBUTE9 DELIVERY_ATTRIBUTE9,
               WND.ATTRIBUTE10 DELIVERY_ATTRIBUTE10,
               WND.ATTRIBUTE11 DELIVERY_ATTRIBUTE11,
               WND.ATTRIBUTE12 DELIVERY_ATTRIBUTE12,
               WND.ATTRIBUTE13 DELIVERY_ATTRIBUTE13,
               WND.ATTRIBUTE14 DELIVERY_ATTRIBUTE14,
               WND.ATTRIBUTE15 DELIVERY_ATTRIBUTE15,
               WDD.ATTRIBUTE1 DELIVERY_DETAILS_ATTRIBUTE1,
               WDD.ATTRIBUTE2 DELIVERY_DETAILS_ATTRIBUTE2,
               WDD.ATTRIBUTE3 DELIVERY_DETAILS_ATTRIBUTE3,
               WDD.ATTRIBUTE4 DELIVERY_DETAILS_ATTRIBUTE4,
               WDD.ATTRIBUTE5 DELIVERY_DETAILS_ATTRIBUTE5,
               WDD.ATTRIBUTE6 DELIVERY_DETAILS_ATTRIBUTE6,
               WDD.ATTRIBUTE7 DELIVERY_DETAILS_ATTRIBUTE7,
               WDD.ATTRIBUTE8 DELIVERY_DETAILS_ATTRIBUTE8,
               WDD.ATTRIBUTE9 DELIVERY_DETAILS_ATTRIBUTE9,
               WDD.ATTRIBUTE10 DELIVERY_DETAILS_ATTRIBUTE10,
               WDD.ATTRIBUTE11 DELIVERY_DETAILS_ATTRIBUTE11,
               WDD.ATTRIBUTE12 DELIVERY_DETAILS_ATTRIBUTE12,
               WDD.ATTRIBUTE13 DELIVERY_DETAILS_ATTRIBUTE13,
               WDD.ATTRIBUTE14 DELIVERY_DETAILS_ATTRIBUTE14,
               WDD.ATTRIBUTE15 DELIVERY_DETAILS_ATTRIBUTE15,
               OHA.ATTRIBUTE1 SOH_ATTRIBUTE1,
               OHA.ATTRIBUTE2 SOH_ATTRIBUTE2,
               OHA.ATTRIBUTE3 SOH_ATTRIBUTE3,
               OHA.ATTRIBUTE4 SOH_ATTRIBUTE4,
               OHA.ATTRIBUTE5 SOH_ATTRIBUTE5,
               OHA.ATTRIBUTE6 SOH_ATTRIBUTE6,
               OHA.ATTRIBUTE7 SOH_ATTRIBUTE7,
               OHA.ATTRIBUTE8 SOH_ATTRIBUTE8,
               OHA.ATTRIBUTE9 SOH_ATTRIBUTE9,
               OHA.ATTRIBUTE10 SOH_ATTRIBUTE10,
               OHA.ATTRIBUTE11 SOH_ATTRIBUTE11,
               OHA.ATTRIBUTE12 SOH_ATTRIBUTE12,
               OHA.ATTRIBUTE13 SOH_ATTRIBUTE13,
               OHA.ATTRIBUTE14 SOH_ATTRIBUTE14,
               OHA.ATTRIBUTE15 SOH_ATTRIBUTE15,
               OHA.ATTRIBUTE16 SOH_ATTRIBUTE16,
               OHA.ATTRIBUTE17 SOH_ATTRIBUTE17,
               OHA.ATTRIBUTE18 SOH_ATTRIBUTE18,
               OHA.ATTRIBUTE19 SOH_ATTRIBUTE19,
               OHA.ATTRIBUTE20 SOH_ATTRIBUTE20,
               OLA.ATTRIBUTE1 SOL_ATTRIBUTE1,
               OLA.ATTRIBUTE2 SOL_ATTRIBUTE2,
               OLA.ATTRIBUTE3 SOL_ATTRIBUTE3,
               OLA.ATTRIBUTE4 SOL_ATTRIBUTE4,
               OLA.ATTRIBUTE5 SOL_ATTRIBUTE5,
               OLA.ATTRIBUTE6 SOL_ATTRIBUTE6,
               OLA.ATTRIBUTE7 SOL_ATTRIBUTE7,
               OLA.ATTRIBUTE8 SOL_ATTRIBUTE8,
               OLA.ATTRIBUTE9 SOL_ATTRIBUTE9,
               OLA.ATTRIBUTE10 SOL_ATTRIBUTE10,
               OLA.ATTRIBUTE11 SOL_ATTRIBUTE11,
               OLA.ATTRIBUTE12 SOL_ATTRIBUTE12,
               OLA.ATTRIBUTE13 SOL_ATTRIBUTE13,
               OLA.ATTRIBUTE14 SOL_ATTRIBUTE14,
               OLA.ATTRIBUTE15 SOL_ATTRIBUTE15,
               OLA.ATTRIBUTE16 SOL_ATTRIBUTE16,
               OLA.ATTRIBUTE17 SOL_ATTRIBUTE17,
               OLA.ATTRIBUTE18 SOL_ATTRIBUTE18,
               OLA.ATTRIBUTE19 SOL_ATTRIBUTE19,
               OLA.ATTRIBUTE20 SOL_ATTRIBUTE20,
               WL.ATTRIBUTE4 PARTNER_ID,
               WL.ATTRIBUTE5 COMMUNICATION_METHOD,
               WL.ATTRIBUTE1 CUSTOMER_ID,
               WL.ATTRIBUTE3 SHIP_TO_SITE_USE_ID,
               WL.ATTRIBUTE2 SALESREP_ID,
               WL.ATTRIBUTE6 EXTENSION_PACKAGE,
               WL.ATTRIBUTE7 SHIPMENT_EXT,
               WL.ATTRIBUTE8 ORDER_EXT,
               WL.ATTRIBUTE9 PACKAGE_EXT,
               WL.ATTRIBUTE10 ITEM_EXT,
               WL.ATTRIBUTE18 ASN_EXCLUSION_EXT_FLAG,
               WL.ATTRIBUTE12 PROCESS_STATUS,
               WL.ATTRIBUTE19 DROP_SHIP_EXCLUSION_EXT_FLAG,
               DECODE (OLA.TOP_MODEL_LINE_ID,
                       NULL, 'N',
                       DECODE (OLA.LINE_ID, OLA.TOP_MODEL_LINE_ID, 'Y', 'N'))
                  MASTER_ITEM,
               OLA.TOP_MODEL_LINE_ID PARENT_SO_LINE_ID,
               WDD.SOURCE_HEADER_NUMBER DETAIL_ORDER_NUMBER,
               TO_NUMBER (NULL) RCPT_LINE_ID,
               TO_NUMBER (NULL) SHIPMENT_ID,
               NULL EXTERNAL_PACKAGE_GROUP_ID,
               NULL EXTERNAL_PACKAGE_ID,
               TO_NUMBER (NULL) PKG_DISPLAY_QUANTITY,
               TO_NUMBER (NULL) PACKAGE_LENGTH,
               TO_NUMBER (NULL) PACKAGE_WIDTH,
               TO_NUMBER (NULL) PACKAGE_HEIGHT,
               TO_NUMBER (NULL) PACKAGE_WEIGHT,
               NULL PKG_LENGTH_UOM,
               NULL PKG_WIDTH_UOM,
               NULL PKG_HEIGHT_UOM,
               NULL PKG_WEIGHT_UOM,
               NULL OVERPACK_FLAG,
               WL.ATTRIBUTE20 SPLIT_ON_TRACKING_NUM,
               WL.ATTRIBUTE21 INCLUDE_ALL_ROWS,
               WL.ATTRIBUTE24 POST_PROCESS_EXT
          FROM APPS.WSH_NEW_DELIVERIES WND,
               APPS.HZ_CUST_ACCOUNTS HCA,
               APPS.HZ_PARTIES HP,
               APPS.WSH_DELIVERY_DETAILS WDD,
               APPS.WSH_DELIVERY_DETAILS WDD2,
               APPS.WSH_DELIVERY_ASSIGNMENTS WDA,
               APPS.WSH_DELIVERY_LEGS WDL,
               APPS.WSH_DOCUMENT_INSTANCES WDI,
               APPS.OE_ORDER_LINES_ALL OLA,
               APPS.WWT_OE_ORDER_HEADERS_ALL_V OHA,
               APPS.WWT_SO_LINES_DFF SLD,
               APPS.WWT_LOOKUPS_ACTIVE_V WL,
               APPS.WWT_LOOKUPS_ACTIVE_V WL2,
               APPS.WSH_CARRIERS WC,
               APPS.MTL_SYSTEM_ITEMS_B MSI,
               APPS.WWT_SO_HEADERS_DFF SHD
         WHERE     1 = 1
               AND WND.CUSTOMER_ID = NVL (WL.ATTRIBUTE1, WND.CUSTOMER_ID)
               AND WDA.DELIVERY_ID = WND.DELIVERY_ID
               AND WDA.PARENT_DELIVERY_DETAIL_ID = WDD2.DELIVERY_DETAIL_ID(+)
               AND (                    -- This is for the integration portion
                    OHA    .SALESREP_ID = WL.ATTRIBUTE2
                       AND (WND.ATTRIBUTE7 IS NULL OR WND.ATTRIBUTE7 = 'R')
                       AND WND.ASN_DATE_SENT IS NULL
                    OR ( -- This is for the reporting piece, which will not update the delivery information
                        WL  .ATTRIBUTE2 < 0
                        AND WL.ATTRIBUTE21 = 'Y'
                        AND NOT EXISTS
                                   (SELECT SHIPMENT_ID
                                      FROM APPS.WWT_ASN_OUTBOUND_SHIPMENTS
                                     WHERE     DELIVERY_ID = WND.DELIVERY_ID
                                           AND COMMUNICATION_METHOD =
                                                  WL.ATTRIBUTE5
                                           AND PROCESS_STATUS = WL.ATTRIBUTE12)))
               AND WDD.SHIP_TO_SITE_USE_ID =
                      NVL (WL.ATTRIBUTE3, WDD.SHIP_TO_SITE_USE_ID)
               AND (   WL.ATTRIBUTE22 IS NULL
                    OR (    WL.ATTRIBUTE22 IS NOT NULL
                        AND OLA.SUBINVENTORY IN (SELECT /*+ CARDINALITY (ct 3) */
                                                        COLUMN_VALUE
                                                   FROM TABLE (
                                                           SELECT  (
                                                                     apps.wwt_utilities.wwt_string_to_table_fun (
                                                                        WL.ATTRIBUTE22,
                                                                        ','))
                                                             FROM DUAL) ct)))
               -- Material Designator join
               AND (   WL.ATTRIBUTE25 IS NULL
                    OR (    WL.ATTRIBUTE25 IS NOT NULL
                        AND OLA.ATTRIBUTE13 IN (SELECT /*+ CARDINALITY (ct 3) */
                                                       COLUMN_VALUE
                                                  FROM TABLE (
                                                          SELECT (
                                                                    apps.wwt_utilities.wwt_string_to_table_fun (
                                                                       WL.ATTRIBUTE25,
                                                                       ','))
                                                            FROM DUAL) ct)))
               AND OLA.SHIP_FROM_ORG_ID =
                      NVL (WL.ATTRIBUTE23, OLA.SHIP_FROM_ORG_ID)
               AND WDD.SOURCE_LINE_ID = OLA.LINE_ID(+)
               AND OLA.LINE_ID = SLD.LINE_ID(+)
               AND OLA.HEADER_ID = OHA.HEADER_ID(+)
               AND OHA.HEADER_ID = SHD.HEADER_ID(+)
               AND NVL (SHD.ATTRIBUTE61, 'N/A') =
                      NVL (WL.ATTRIBUTE19, NVL (SHD.ATTRIBUTE61, 'N/A'))
               AND HCA.PARTY_ID = HP.PARTY_ID
               AND HCA.CUST_ACCOUNT_ID = WND.CUSTOMER_ID
               AND HP.PARTY_TYPE = 'ORGANIZATION'
               AND WL.LOOKUP_TYPE = 'WWT_ASN_OUTBOUND_EXTRACT'
               AND WL2.LOOKUP_TYPE(+) = 'WWT_OM_LINE_FLOW_CONTROLS'
               AND TO_CHAR (OLA.LINE_TYPE_ID) = WL2.ATTRIBUTE1(+)
               AND NVL (WL2.ATTRIBUTE2, 'NULL') <> 'DROP_SHIP'
               AND WDD.ORGANIZATION_ID = MSI.ORGANIZATION_ID
               AND WDD.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
               AND WDA.DELIVERY_DETAIL_ID = WDD.DELIVERY_DETAIL_ID
               AND WND.STATUS_CODE = 'CL'
               AND WDL.DELIVERY_ID = WND.DELIVERY_ID
               AND WDI.ENTITY_ID(+) = WDL.DELIVERY_LEG_ID
               AND WDI.ENTITY_NAME(+) = 'WSH_DELIVERY_LEGS'
               AND WDI.DOCUMENT_TYPE(+) = 'BOL'
               AND WC.CARRIER_ID(+) = WND.CARRIER_ID
               AND WND.CONFIRM_DATE >= NVL (null, SYSDATE - 7)
               AND NVL (WDD.CONTAINER_FLAG, WDD2.CONTAINER_FLAG) = 'N'
               AND NVL (WDD.INV_INTERFACED_FLAG, 'N') IN ('Y', 'P')
               AND WND.DELIVERY_ID = NVL (null, WND.DELIVERY_ID)
               AND (   TRUNC (WND.CONFIRM_DATE) >= WL.START_DATE_ACTIVE
                    OR WL.START_DATE_ACTIVE IS NULL)
      ORDER BY COMMUNICATION_METHOD,
               DELIVERY_ID,
               TRACKING_NUMBER,
               ORDER_NUMBER,
               LPN,
               SO_LINE_ID,
               INVENTORY_ITEM_ID;