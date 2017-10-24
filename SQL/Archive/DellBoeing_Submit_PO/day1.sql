INSERT INTO apps.WWT_DELL_BOEING_POO_LOG
          ( SO_HEADER_ID,
            CREATION_DATE,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            SALES_ORDER,
            DELL_PO_FLAG,
            ORDER_SPECIFIC_SUBINV,
            MERGE_KEY,
            PO_SENT_FLAG,
            STOCKING_PO_FLAG )
     SELECT SHA.HEADER_ID,
            SYSDATE,
            3984,
            SYSDATE,
            3984,
            SHA.ORDER_NUMBER,
            case
                when MIN(SLA.SUBINVENTORY) in ( 'BOE/DRS','BOE/LAB','BOE-MPS','BOE/REDPLY') 
                    then 'N'
                else
                  (select MAX(DECODE(oola.ATTRIBUTE9,'67','Y','N'))
                    from APPS.OE_ORDER_HEADERS_ALL ooha,
                         APPS.OE_ORDER_LINES_ALL oola
                   where 1=1
                               AND ooha.SOLD_TO_ORG_ID = 1009
                               AND ooha.OPEN_FLAG = 'Y'
                               AND ooha.BOOKED_FLAG = 'Y'
                               AND ooha.ORDER_CATEGORY_CODE IN ('MIXED', 'ORDER')
                     AND ooha.HEADER_ID = oola.HEADER_ID
                     AND ooha.order_number = SHA.order_number
                     AND oola.SUBINVENTORY not in ( 'BOE/DRS','BOE/LAB', 'BOE-MPS','BOE/REDPLY') 
                   GROUP BY ooha.HEADER_ID,
                          ooha.ORDER_NUMBER
                   )
               end,
            MIN(SLA.SUBINVENTORY), DECODE(SHA.SHIPPING_INSTRUCTIONS,'MERGE ORDER',NVL(WSHD.ATTRIBUTE20,'N/A'),'N/A'),
            decode(min(nvl(SLA.ATTRIBUTE9,' ')),' ','H','N'), 'N'
     FROM APPS.WWT_METRIC_PROGRAMS WMP,
          APPS.RA_SALESREPS_ALL RSA,
          APPS.WWT_LOOKUPS WL     ,
          APPS.WWT_SO_HEADERS_DFF WSHD,
          APPS.PO_VENDORS PV,
          APPS.OE_ORDER_HEADERS_ALL SHA,
          APPS.OE_ORDER_LINES_ALL SLA,
          APPS.MTL_PARAMETERS MP
     WHERE 1=1
      AND (
      ( WMP.PROGRAM in ( 'Dell/Boeing', 'Dell/Boeing Mgd Svcs')
        AND MP.ATTRIBUTE3 <> 'Y' ) OR
      ( WMP.PROGRAM =   'Dell/Boeing-MPS'
    AND SLA.SUBINVENTORY in ('BOE-MPS','BOE/REDPLY') ) OR
      ( WMP.PROGRAM =  'Dell/Boeing'
        and SLA.SUBINVENTORY = 'BOE/LAB' 
        AND SLA.SHIP_FROM_ORG_ID in (757,932,583) )
      )
      AND SHA.OPEN_FLAG            = 'Y'
      AND SHA.SOLD_TO_ORG_ID       = 1009
      AND SHA.BOOKED_FLAG          = 'Y'
      AND WL.LOOKUP_TYPE = 'DELL_BOEING_VENDOR_SOURCING'
      AND WL.ENABLED_FLAG = 'Y'
      AND SHA.ORDER_CATEGORY_CODE IN ('MIXED', 'ORDER')
      AND SHA.HEADER_ID            = SLA.HEADER_ID
      AND SLA.SUBINVENTORY         IS NOT NULL
      AND SLA.SHIP_FROM_ORG_ID     = MP.ORGANIZATION_ID
      AND WMP.PROGRAM_ID           = TO_NUMBER(RSA.ATTRIBUTE2)
      AND RSA.SALESREP_ID          = SHA.SALESREP_ID
      AND TO_NUMBER( SLA.ATTRIBUTE9)= TO_NUMBER( WL.ATTRIBUTE6)
      AND TO_NUMBER( WL.ATTRIBUTE6)  = PV.VENDOR_ID
      AND SHA.HEADER_ID            = WSHD.HEADER_ID (+)
      AND SHA.HEADER_ID   NOT   IN  ( SELECT   WDBPL.SO_HEADER_ID FROM
                                        APPS.WWT_DELL_BOEING_POO_LOG WDBPL )
      GROUP BY SHA.HEADER_ID,
            SHA.ORDER_NUMBER,
            DECODE(SHA.SHIPPING_INSTRUCTIONS,'MERGE ORDER',NVL(WSHD.ATTRIBUTE20,'N/A'),'N/A')
            
select min(subinventory) from OE_ORDER_LINES_ALL
            
SELECT WDBPL.SO_HEADER_ID,
       WDBPL.SALES_ORDER,
       WDBPL.DELL_PO_FLAG DELL_PO_FLAG
  FROM apps.WWT_DELL_BOEING_POO_LOG WDBPL
 WHERE PO_SENT_FLAG = 'N'
 
 SELECT DISTINCT
    PHA.PO_HEADER_ID    PO_HEADER_ID,
    PHA.SEGMENT1        PO_NUMBER,
    HR.DESCRIPTION      BILL_TO_NAME,
    WSH.ADDRESS1     BILL_TO_ADDRESS_LINE1, 
    WSH.ADDRESS2     BILL_TO_ADDRESS_LINE2, 
    WSH.ADDRESS3     BILL_TO_ADDRESS_LINE3, 
    WSH.ADDRESS4     BILL_TO_ADDRESS_LINE4, 
    WSH.CITY         BILL_TO_CITY, 
    WSH.STATE         BILL_TO_STATE, 
    WSH.POSTAL_CODE     BILL_TO_POSTAL_CODE,
    WSH.COUNTRY     BILL_TO_COUNTRY
FROM  APPS.OE_ORDER_LINES_ALL SLA
     ,APPS.PO_REQUISITION_LINES_ALL PRLA
     ,APPS.PO_LINE_LOCATIONS_ALL PLLA
     ,APPS.PO_LINES_ALL PLA
     ,APPS.PO_HEADERS_ALL PHA
     ,APPS.WSH_LOCATIONS WSH
     ,APPS.HR_LOCATIONS HR
WHERE 1=1
 AND SLA.HEADER_ID = TO_NUMBER(4845532)
  --AND PHA.VENDOR_ID = 67
  AND TO_NUMBER(SLA.ATTRIBUTE20) = PRLA.REQUISITION_LINE_ID
 -- AND PRLA.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID
  AND PLLA.PO_LINE_ID = PLA.PO_LINE_ID
 -- AND PLA.PO_HEADER_ID = PHA.PO_HEADER_ID
 -- AND PHA.AUTHORIZATION_STATUS  = 'APPROVED'
 -- AND PHA.BILL_TO_LOCATION_ID = WSH.WSH_LOCATION_ID (+)
 -- AND WSH.WSH_LOCATION_ID = HR.LOCATION_ID (+)

select line_location_id from po_requisition_lines_all where requisition_line_id = 22640462

select * from po_line_locations_all where line_location_id = 1418858

select * from po_lines_all where po_line_id = 1376426

select vendor_id, authorization_status, po_header_id, bill_to_location_id from po_headers_all where po_header_id = 411168

select * from wsh_locations wsh, po_headers_all pha where pha.bill_to_location_id = 105 AND PHA.BILL_TO_LOCATION_ID = WSH.WSH_LOCATION_ID (+)

select * from wsh_locations where wsh_location_id = 105

select bill_to_location_id from po_headers_all where po_header_id = 411168


select * from wsh_locations
where wsh_location_id = 411168

select * from hr_locations where location_id = 105

select * from po_headers_all where po_header_id = 411168

update po_headers_all
set vendor_id = 67
where po_header_id = 411168

select * from oe_order_lines_all
where attribute20 = 22640462

select * from po_headers_all
where vendor_id = 67
  
SELECT TO_CHAR(APPS.WWT_NEXT_X_BUSINESS_DAYS(APPS.WWT_NEXT_X_BUSINESS_DAYS(SYSDATE, -1),1),'MMDDRRRR') V_CURR_DATE,
       TO_CHAR(SYSDATE,'HH24MI') V_CURR_TIME,
       TO_CHAR((APPS.WWT_NEXT_X_BUSINESS_DAYS(APPS.WWT_NEXT_X_BUSINESS_DAYS(SYSDATE, -1), 1 + ?)),'MMDDRRRR') V_DUE_DATE,
       '_' || TO_CHAR(SYSDATE,'MMDDRRRRHH24MISS') V_FILE_ID_SUFFIX
FROM DUAL

SELECT DISTINCT
     SHA.HEADER_ID   V_SO_HEADER_ID
FROM APPS.PO_LINES_ALL PLA,
     APPS.PO_LINE_LOCATIONS_ALL PLLA,
     APPS.PO_REQUISITION_LINES_ALL PRLA,
     APPS.OE_ORDER_LINES_ALL SLA,
     APPS.OE_ORDER_HEADERS_ALL SHA
WHERE 1=1
 AND PLA.PO_HEADER_ID = 889024
 AND PLA.PO_LINE_ID = PLLA.PO_LINE_ID
 AND PLLA.LINE_LOCATION_ID = PRLA.LINE_LOCATION_ID
 AND TO_CHAR(PRLA.REQUISITION_LINE_ID) = SLA.ATTRIBUTE20 (+)
 AND SLA.HEADER_ID = SHA.HEADER_ID

SELECT DECODE (SA.AGREEMENT_NUM
              ,'Dell Boeing', 'BOEING_SSPN'
              ,'Dell Boeing - CGO', 'BOEING_CGO'
              ,'Dell Boeing - EBOSS', 'BOEING_EBOSS'
              ,'Dell Boeing - MANUAL', 'BOEING_MANUAL'
              ,'UNKNOWN') CUSTOMER_NAME
      ,NVL (WL.ATTRIBUTE1, 99) DISTRIBUTIONCENTERID
      ,TO_CHAR (DECODE (SHA.AGREEMENT_ID
                       ,3170, SLA.REQUEST_DATE
                       ,DECODE (SIGN (SLA.SCHEDULE_SHIP_DATE
                                      - SLA.REQUEST_DATE)
                               ,NULL, NVL (SLA.SCHEDULE_SHIP_DATE
                                          ,SLA.REQUEST_DATE)
                               ,0, SLA.REQUEST_DATE
                               ,1, SLA.SCHEDULE_SHIP_DATE
                               ,-1, SLA.REQUEST_DATE))
               ,'MMDDRRRR') DUE_DATE
      ,SHD.ATTRIBUTE16 COF_INDICATOR
      ,HL.ADDRESS1 SHIPTO_ADDRESS_LN1
      ,HL.ADDRESS2 SHIPTO_ADDRESS_LN2
      ,HL.ADDRESS3 SHIPTO_ADDRESS_LN3
      ,HL.ADDRESS4 SHIPTO_ADDRESS_LN4
      ,HL2.ADDRESS4 SHIPTO_BUILDING
      ,NULL SHIPTO_BAY
      ,HL.CITY SHIPTO_CITY
      ,HL.STATE SHIPTO_STATE
      ,HL.POSTAL_CODE SHIPTO_ZIP
      , RC3.LAST_NAME || ', ' || RC3.FIRST_NAME SPOC_NAME
      ,SHD.ATTRIBUTE31 SPOC_PHONE
      ,SHD.ATTRIBUTE29 SPOC_EMAIL
      , RC.LAST_NAME || ', ' || RC.FIRST_NAME SITE_CONTACT_NAME
      ,SHD.ATTRIBUTE38 SITE_CONTACT_PHONE
      ,SHD.ATTRIBUTE34 SITE_CONTACT_EMAIL
      ,HL2.ADDRESS1 DELIVERTO_ADDRESS_LN1
      ,HL2.ADDRESS2 DELIVERTO_ADDRESS_LN2
      ,HL2.ADDRESS3 DELIVERTO_ADDRESS_LN3
      ,HL2.ADDRESS4 DELIVERTO_ADDRESS_LN4
      ,SUBSTR (SHD.ATTRIBUTE25
              ,1
              ,25) DELIVERTO_BAY
      ,HL2.CITY DELIVERTO_CITY
      ,HL2.STATE DELIVERTO_STATE
      ,HL2.POSTAL_CODE DELIVERTO_ZIP
      ,HL2.COUNTRY DELIVERTO_COUNTRY
      ,NULL UPGRADE_ERMS
      ,SUBSTR (   SHD.ATTRIBUTE99
               || DECODE (SHD.ATTRIBUTE99
                         ,NULL, NULL
                         ,DECODE (SHD.ATTRIBUTE25
                                 ,NULL, NULL
                                 ,'. '))
               || DECODE (SHD.ATTRIBUTE25
                         ,NULL, NULL
                         , 'DeliverTo_Bay ' || SHD.ATTRIBUTE25)
              ,1
              ,249) CUSTOMER_INSTRUCTIONS
      ,APPS.WWT_GET_DELIMITED_FIELD (REPLACE (SHA.ATTRIBUTE9
                                             ,'||'
                                             ,'|')
                                    ,3
                                    ,'|') SPOC_MAIL_CODE
      ,TO_CHAR (TO_DATE (SHA.ATTRIBUTE1, 'RRRR/MM/DD HH24:MI:SS'), 'MMDDRRRR')
                                                              NEW_LAUNCH_DATE
      ,'1000' NEW_LAUNCH_TIME
  FROM APPS.OE_ORDER_HEADERS_ALL SHA
      ,APPS.WWT_SO_HEADERS_DFF SHD
      ,APPS.OE_ORDER_LINES_ALL SLA
      ,APPS.SO_AGREEMENTS SA
      ,APPS.WWT_LOOKUPS WL
      ,
       -- SHIP TO CONTACT
       APPS.RA_CONTACTS RC
      ,APPS.RA_PHONES RP
      ,
       -- FOR SHIP TO
       APPS.HZ_CUST_ACCT_SITES_ALL HCASA
      ,APPS.HZ_PARTY_SITES HPS
      ,APPS.HZ_LOCATIONS HL
      ,APPS.HZ_CUST_SITE_USES_ALL HCSUA
      ,
       -- For DELIVER TO
       APPS.HZ_CUST_ACCT_SITES_ALL HCASA2
      ,APPS.HZ_PARTY_SITES HPS2
      ,APPS.HZ_LOCATIONS HL2
      ,APPS.HZ_CUST_SITE_USES_ALL HCSUA2
      ,
       -- SOLD TO CONTACT
       APPS.RA_CONTACTS RC3
      ,APPS.RA_PHONES RP3
 WHERE 1 = 1
   AND SHA.HEADER_ID = 889024
   AND SHA.HEADER_ID = SHD.HEADER_ID(+)
   AND SHA.HEADER_ID = SLA.HEADER_ID
   AND SLA.LINE_NUMBER = (SELECT MIN (LINE_NUMBER)
                            FROM APPS.OE_ORDER_LINES_ALL SLA,OE_ORDER_HEADERS_ALL SHA
                           WHERE SLA.HEADER_ID = SHA.HEADER_ID)
   AND WL.LOOKUP_TYPE = 'WWT_DELL_AMC_DIST_CENTER_IDS'
   AND WL.ENABLED_FLAG = 'Y'
   AND TRUNC (SYSDATE) BETWEEN TRUNC (NVL (WL.START_DATE_ACTIVE, SYSDATE - 1))
                           AND TRUNC (NVL (WL.END_DATE_ACTIVE, SYSDATE + 1))
   AND SLA.SHIP_FROM_ORG_ID = WL.ATTRIBUTE2(+)
   AND SHA.AGREEMENT_ID = SA.AGREEMENT_ID(+)
   -- SHIP TO INFO
   AND SHA.SHIP_TO_CONTACT_ID = RC.CONTACT_ID(+)
   AND SHA.SHIP_TO_CONTACT_ID = RP.CONTACT_ID(+)
   AND SHA.SHIP_TO_ORG_ID = HCSUA.SITE_USE_ID(+)
   AND HCSUA.CUST_ACCT_SITE_ID = HCASA.CUST_ACCT_SITE_ID(+)
   AND HCASA.PARTY_SITE_ID = HPS.PARTY_SITE_ID(+)
   AND HPS.LOCATION_ID = HL.LOCATION_ID(+)
   -- Deliver to Info
   AND SHA.DELIVER_TO_ORG_ID = HCSUA2.SITE_USE_ID(+)
   AND HCSUA2.CUST_ACCT_SITE_ID = HCASA2.CUST_ACCT_SITE_ID(+)
   AND HCASA2.PARTY_SITE_ID = HPS2.PARTY_SITE_ID(+)
   AND HPS2.LOCATION_ID = HL2.LOCATION_ID(+)
   -- SOLD TO CONTACTS
   AND SHA.SOLD_TO_CONTACT_ID = RC3.CONTACT_ID(+)
   AND SHA.SOLD_TO_CONTACT_ID = RP3.CONTACT_ID(+)
   
select header_id, agreement_id, ship_to_contact_id, ship_to_org_id, deliver_to_org_id, sold_to_contact_id from APPS.OE_ORDER_HEADERS_ALL where header_id = 889024
select * from oe_order_headers_all where header_id = 889024
update oe_order_headers_all set deliver_to_org_id = 1041 where header_id = 889024
select * from oe_order_lines_all where header_id = 889024
select * from wwt_so_headers_dff where header_id = 889024
select * from HZ_CUST_SITE_USES_ALL
select * from hz_cust_site_uses_all where site_use_id = 1041
select * from hz_cust_acct_sites_all where cust_acct_site_id = 1061
select * from hz_party_sites where party_site_id = 1037
select * from hz_locations where location_id = 211059

SELECT NVL (PLA.PO_LINE_ID, SLA.LINE_ID) PARTNER_LINE_ITEM
      ,NVL (SLA.CUSTOMER_LINE_NUMBER, '1') CUSTOMER_LINE_ITEM
      ,CASE 
    WHEN SLA.SUBINVENTORY IN ('BOE/DRS', 'BOE/LAB') THEN SLA.ATTRIBUTE11
        ELSE MSI.SEGMENT2
    END PART_NUMBER
      ,MSI.DESCRIPTION DESCRIPTION
      ,DECODE (PLA.PO_LINE_ID
              ,NULL, 'N'
              ,'Y') DOMS_REQUIRED
      ,WL.ATTRIBUTE1 VENDOR_ID
      ,DECODE (PLA.PO_LINE_ID
              ,NULL, NVL (SLA.ORDERED_QUANTITY, 0)
              ,PLA.QUANTITY) ORDER_QTY
      ,DECODE (WL.ATTRIBUTE1
              ,'TDC', 0
              ,'FAI', 0
              ,'KAH', 0
              ,'KHL', 0
              ,DECODE (PLA.PO_LINE_ID
                      ,NULL, NVL (SLA.ATTRIBUTE7, 0)
                      ,PLA.UNIT_PRICE)) UNIT_PRICE
      ,'1' SYSTEM_GROUP
      ,SLD.ATTRIBUTE23 LEGACY_ITEM_ID
      ,SLD.ATTRIBUTE21 EXT_SYS_REF_LINE_ITEM
      ,SLD.ATTRIBUTE22 HAZARD_CLASS
      ,NULL UN_NUMBER
      ,SLD.ATTRIBUTE100 UN_NUMBER_DESC
      ,SLA.SHIPMENT_NUMBER SHIPMENT_NUMBER
      ,SLD.ATTRIBUTE24 PROJECT_NUMBER
      ,SLD.ATTRIBUTE28 RELEASE_NUMBER
  FROM APPS.OE_ORDER_LINES_ALL SLA
      ,APPS.WWT_SO_LINES_DFF SLD
      ,APPS.MTL_SYSTEM_ITEMS MSI
      ,APPS.WWT_LOOKUPS WL
      ,APPS.PO_REQUISITION_LINES_ALL PRLA
      ,APPS.PO_LINE_LOCATIONS_ALL PLLA
      ,APPS.PO_LINES_ALL PLA
 WHERE 1 = 1
   AND SLA.HEADER_ID = 889024
   AND NVL (SLA.ORDERED_QUANTITY, 0) != 0
   AND SLA.LINE_ID = SLD.LINE_ID(+)
   AND NVL (SLA.ATTRIBUTE9, '67') = RTRIM (WL.DESCRIPTION)
   AND WL.ENABLED_FLAG = 'Y'
   AND WL.LOOKUP_TYPE = 'DELL_BOEING_VENDOR_SOURCING'
   AND SLA.SHIP_FROM_ORG_ID = MSI.ORGANIZATION_ID
   AND SLA.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
   AND MSI.SHIPPABLE_ITEM_FLAG = 'Y'
   AND TO_NUMBER (SLA.ATTRIBUTE20) = PRLA.REQUISITION_LINE_ID(+)
   AND PRLA.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID(+)
   AND PLLA.PO_LINE_ID = PLA.PO_LINE_ID(+)
   
select header_id, ordered_quantity, line_id, attribute9, ship_from_org_id, inventory_item_id, attribute20 from oe_order_lines_all where header_id = 889024
update oe_order_lines_all set ship_from_org_id = 245 where header_id = 889024
select * from wwt_so_lines_dff where line_id = 2385110
select * from wwt_lookups
update oe_order_lines_all set attribute9 = 50 where header_id = 889024

    SELECT DISTINCT '_' || TO_CHAR (SYSDATE, 'MMDDRRRRHH24MISS') V_FILE_ID_SUFFIX
                   ,3 PARTNER_ID
                   ,TO_CHAR (SYSDATE, 'MMDDRRRR') V_CURR_DATE
                   ,TO_CHAR (SYSDATE, 'HH24MI') V_CURR_TIME
                   , 'SO' || TO_CHAR (SHA.ORDER_NUMBER) PARTNER_PO
                   ,1 PARTNER_SUB_PO_COUNT
                   ,'BOEING_WWT' CUSTOMER_PASSWORD
                   ,DECODE (SA.AGREEMENT_NUM
                           ,'Dell Boeing', 'BOEING_SSPN'
                           ,'Dell Boeing - CGO', 'BOEING_CGO'
                           ,'Dell Boeing - EBOSS', 'BOEING_EBOSS'
                           ,'Dell Boeing - MANUAL', 'BOEING_MANUAL'
                           ,'UNKNOWN') CUSTOMER_NAME
                   ,NVL(WL1.ATTRIBUTE1, 99) DISTRIBUTIONCENTERID
                   ,'Purchase Order' CUSTOMER_ORDER_TYPE
                   ,TO_CHAR (SYSDATE, 'MMDDRRRR') LAUNCH_DATE
                   ,TO_CHAR (SYSDATE, 'HH24MI') LAUNCH_TIME
                   ,TO_CHAR (DECODE (SHA.AGREEMENT_ID
                                    ,3170, SLA.REQUEST_DATE
                                    ,DECODE (SIGN (  SLA.SCHEDULE_SHIP_DATE
                                                   - SLA.REQUEST_DATE)
                                            ,NULL, NVL (SLA.SCHEDULE_SHIP_DATE
                                                       ,SLA.REQUEST_DATE)
                                            ,0, SLA.REQUEST_DATE
                                            ,1, SLA.SCHEDULE_SHIP_DATE
                                            ,-1, SLA.REQUEST_DATE))
                            ,'MMDDRRRR') DUE_DATE
                   ,SHD.ATTRIBUTE16 COF_INDICATOR
                   ,HL.ADDRESS1 SHIPTO_ADDRESS_LN1
                   ,HL.ADDRESS2 SHIPTO_ADDRESS_LN2
                   ,HL.ADDRESS3 SHIPTO_ADDRESS_LN3
                   ,HL.ADDRESS4 SHIPTO_ADDRESS_LN4
                   ,HL2.ADDRESS4 SHIPTO_BUILDING
                   ,NULL SHIPTO_BAY
                   ,HL.CITY SHIPTO_CITY
                   ,HL.STATE SHIPTO_STATE
                   ,HL.POSTAL_CODE SHIPTO_ZIP
                   , RC3.LAST_NAME || ', ' || RC3.FIRST_NAME SPOC_NAME
                   ,SHD.ATTRIBUTE31 SPOC_PHONE
                   ,SHD.ATTRIBUTE29 SPOC_EMAIL
                   , RC.LAST_NAME || ', ' || RC.FIRST_NAME SITE_CONTACT_NAME
                   ,SHD.ATTRIBUTE38 SITE_CONTACT_PHONE
                   ,SHD.ATTRIBUTE34 SITE_CONTACT_EMAIL
                   ,HL3.DESCRIPTION BILLTO_NAME
                   ,WSH.ADDRESS1 BILLTO_ADDRESS_LN1
                   ,WSH.ADDRESS2 BILLTO_ADDRESS_LN2
                   ,WSH.ADDRESS3 BILLTO_ADDRESS_LN3
                   ,WSH.ADDRESS4 BILLTO_ADDRESS_LN4
                   ,WSH.CITY BILLTO_CITY
                   ,WSH.STATE BILLTO_STATE
                   ,WSH.POSTAL_CODE BILLTO_ZIP
                   ,WSH.COUNTRY BILLTO_COUNTRY
                   ,HL2.ADDRESS1 DELIVERTO_ADDRESS_LN1
                   ,HL2.ADDRESS2 DELIVERTO_ADDRESS_LN2
                   ,HL2.ADDRESS3 DELIVERTO_ADDRESS_LN3
                   ,HL2.ADDRESS4 DELIVERTO_ADDRESS_LN4
                   ,SUBSTR (SHD.ATTRIBUTE25
                           ,1
                           ,25) DELIVERTO_BAY
                   ,HL2.CITY DELIVERTO_CITY
                   ,HL2.STATE DELIVERTO_STATE
                   ,HL2.POSTAL_CODE DELIVERTO_ZIP
                   ,HL2.COUNTRY DELIVERTO_COUNTRY
                   ,NULL UPGRADE_ERMS
                   ,SUBSTR (   SHD.ATTRIBUTE99
                            || DECODE (SHD.ATTRIBUTE99
                                      ,NULL, NULL
                                      ,DECODE (SHD.ATTRIBUTE25
                                              ,NULL, NULL
                                              ,'. '))
                            || DECODE (SHD.ATTRIBUTE25
                                      ,NULL, NULL
                                      , 'DeliverTo_Bay ' || SHD.ATTRIBUTE25)
                           ,1
                           ,249) CUSTOMER_INSTRUCTIONS
                   ,APPS.WWT_GET_DELIMITED_FIELD (REPLACE (SHA.ATTRIBUTE9
                                                          ,'||'
                                                          ,'|')
                                                 ,3
                                                 ,'|') SPOC_MAIL_CODE
                   ,SHA.HEADER_ID PARTNER_SUB_PO
                   ,TO_CHAR (TO_DATE (SHA.ATTRIBUTE1, 'RRRR/MM/DD HH24:MI:SS')
                            ,'MMDDRRRR') NEW_LAUNCH_DATE
                   ,'1000' NEW_LAUNCH_TIME
               FROM APPS.OE_ORDER_HEADERS_ALL SHA
                   ,APPS.WWT_SO_HEADERS_DFF SHD
                   ,APPS.SO_AGREEMENTS SA
                   ,APPS.RA_SALESREPS_ALL RSA
                   ,APPS.WWT_METRIC_PROGRAMS WMP
                   ,APPS.OE_ORDER_LINES_ALL SLA
                   ,APPS.WWT_LOOKUPS_ACTIVE_V WL
               ,APPS.WWT_LOOKUPS_ACTIVE_V WL1
                   ,APPS.MTL_SYSTEM_ITEMS MSI
                   ,
                    -- SHIP TO CONTACT
                    APPS.RA_CONTACTS RC
                   ,APPS.RA_PHONES RP
                   ,
                    -- FOR SHIP TO
                    APPS.HZ_CUST_ACCT_SITES_ALL HCASA
                   ,APPS.HZ_PARTY_SITES HPS
                   ,APPS.HZ_LOCATIONS HL
                   ,APPS.HZ_CUST_SITE_USES_ALL HCSUA
                   ,
                    -- FOR BILL TO
                    APPS.WSH_LOCATIONS WSH
                   ,APPS.HR_LOCATIONS HL3
                   ,
                    -- FOR DELIVER TO
                    APPS.HZ_CUST_ACCT_SITES_ALL HCASA2
                   ,APPS.HZ_PARTY_SITES HPS2
                   ,APPS.HZ_LOCATIONS HL2
                   ,APPS.HZ_CUST_SITE_USES_ALL HCSUA2
                   ,
                    -- SOLD TO CONTACT
                    APPS.RA_CONTACTS RC3
                   ,APPS.RA_PHONES RP3
              WHERE 1 = 1
                AND SHA.HEADER_ID = 889024
                AND SHA.SALESREP_ID = RSA.SALESREP_ID
                AND SHA.ORG_ID = RSA.ORG_ID
                AND TO_NUMBER (RSA.ATTRIBUTE2) = WMP.PROGRAM_ID
                AND WMP.PROGRAM IN ('Dell/Boeing-MPS', 'Dell/Boeing','Dell/Boeing Mgd Svcs')
                AND SHA.BOOKED_FLAG = 'Y'
                AND WL1.LOOKUP_TYPE = 'WWT_DELL_AMC_DIST_CENTER_IDS' 
                AND WL1.ATTRIBUTE2 (+) = SLA.SHIP_FROM_ORG_ID
                -- DFF TABLE
                AND SHA.HEADER_ID = SHD.HEADER_ID(+)
                AND SHA.HEADER_ID = SLA.HEADER_ID
                AND SHA.AGREEMENT_ID = SA.AGREEMENT_ID(+)
                -- SHIP TO INFO
                AND SHA.SHIP_TO_CONTACT_ID = RC.CONTACT_ID(+)
                AND SHA.SHIP_TO_CONTACT_ID = RP.CONTACT_ID(+)
                AND SHA.SHIP_TO_ORG_ID = HCSUA.SITE_USE_ID
                AND HCSUA.CUST_ACCT_SITE_ID = HCASA.CUST_ACCT_SITE_ID(+)
                AND HCASA.PARTY_SITE_ID = HPS.PARTY_SITE_ID(+)
                AND HPS.LOCATION_ID = HL.LOCATION_ID(+)
                -- BILL TO INFO
                AND WSH.WSH_LOCATION_ID = 105
                AND WSH.WSH_LOCATION_ID = HL3.LOCATION_ID
                -- DELIVER TO INFO
                AND SHA.DELIVER_TO_ORG_ID = HCSUA2.SITE_USE_ID(+)
                AND HCSUA2.CUST_ACCT_SITE_ID = HCASA2.CUST_ACCT_SITE_ID(+)
                AND HCASA2.PARTY_SITE_ID = HPS2.PARTY_SITE_ID(+)
                AND HPS2.LOCATION_ID = HL2.LOCATION_ID(+)
                -- SOLD TO CONTACTS
                AND SHA.SOLD_TO_CONTACT_ID = RC3.CONTACT_ID(+)
                AND SHA.SOLD_TO_CONTACT_ID = RP3.CONTACT_ID(+)
                AND SLA.ATTRIBUTE9 = RTRIM (WL.DESCRIPTION)
                AND WL.ENABLED_FLAG = 'Y'
                AND WL.LOOKUP_TYPE = 'DELL_BOEING_VENDOR_SOURCING'
                AND SLA.SHIP_FROM_ORG_ID = MSI.ORGANIZATION_ID
                AND SLA.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID

select ship_from_org_id, inventory_item_id, header_id from oe_order_lines_all where header_id = 889024
select * from mtl_system_items where organization_id = 1050 and inventory_item_id = 316378
select * from mtl_system_items where inventory_item_id = 316379
select * from mtl_system_items where inventory_item_id = 415063 and organization_id = 1050 and created_by = 2140
update mtl_system_items set inventory_item_id = 316378 where inventory_item_id = 415063 and organization_id = 1050 and created_by = 2140
            
select header_id, salesrep_id, org_id, booked_flag, sold_to_contact_id, deliver_to_org_id, agreement_id, ship_to_contact_id, ship_to_org_id from oe_order_headers_all where header_id = 889024
select * from wwt_so_headers_dff where header_id = 889024
update oe_order_headers_all set salesrep_id = 2285 where header_id = 889024
select * from MTL_SYSTEM_ITEMS where organization_id = 245 and inventory_item_id = 316378
select ship_from_org_id, inventory_item_id from oe_order_lines_all where header_id = 889024
select ship_from_org_id, attribute9 from oe_order_lines_all where header_id = 889024
update oe_order_lines_all set ship_from_org_id = 1050 where header_id = 889024
select * from wwt_lookups_active_v where rtrim(description) = 50 AND lookup_type = 'DELL_BOEING_VENDOR_SOURCING'
select * from wwt_lookups_active_v where attribute2 = 1050 and lookup_type = 'WWT_DELL_AMC_DIST_CENTER_IDS'
select salesrep_id, org_id, attribute2 from RA_Salesreps_all where salesrep_id = 2285 And org_id = 101
select * from wwt_metric_programs where program_id = 74
update oe_order_headers_all set salesrep_id = 2285 where header_id = 889024            
select * from ra_phones where contact_id = 60017
select * from Hz_cust_site_uses_all where site_use_id = 1041
select cust_acct_site_id, party_site_id from hz_cust_acct_sites_all where cust_acct_site_id = 1061
select * from hz_party_sites where party_site_id = 1061
select * from hz_locations where location_id = 211524
select * from so_agreements where agreement_id = 3174
update so_agreements set agreement_num = 'Dell Boeing' where agreement_id = 3174
select * from ra_phones where contact_id = 60017
select * from hr_locations where location_id = 105
select * from wsh_locations where wsh_location_id = 105
select * from wwt_metric_programs where program_id = 74 and program = 'Dell/Boeing'
select * from wwt_lookups_active_v where attribute2 = 1050 and lookup_type = 'WWT_DELL_AMC_DIST_CENTER_IDS'


select SHA.HEADER_ID
               FROM APPS.OE_ORDER_HEADERS_ALL SHA
                   ,APPS.WWT_SO_HEADERS_DFF SHD
                   ,APPS.SO_AGREEMENTS SA
                   ,APPS.RA_SALESREPS_ALL RSA
                   ,APPS.WWT_METRIC_PROGRAMS WMP
                   ,APPS.OE_ORDER_LINES_ALL SLA
                   ,APPS.WWT_LOOKUPS_ACTIVE_V WL
               ,APPS.WWT_LOOKUPS_ACTIVE_V WL1
                   ,APPS.MTL_SYSTEM_ITEMS MSI
                   ,
                    -- SHIP TO CONTACT
                    APPS.RA_CONTACTS RC
                   ,APPS.RA_PHONES RP
                   ,
                    -- FOR SHIP TO
                    APPS.HZ_CUST_ACCT_SITES_ALL HCASA
                   ,APPS.HZ_PARTY_SITES HPS
                   ,APPS.HZ_LOCATIONS HL
                   ,APPS.HZ_CUST_SITE_USES_ALL HCSUA
                   ,
                    -- FOR BILL TO
                    APPS.WSH_LOCATIONS WSH
                   ,APPS.HR_LOCATIONS HL3
                   ,
                    -- FOR DELIVER TO
                    APPS.HZ_CUST_ACCT_SITES_ALL HCASA2
                   ,APPS.HZ_PARTY_SITES HPS2
                   ,APPS.HZ_LOCATIONS HL2
                   ,APPS.HZ_CUST_SITE_USES_ALL HCSUA2
                   ,
                    -- SOLD TO CONTACT
                    APPS.RA_CONTACTS RC3
                   ,APPS.RA_PHONES RP3
              WHERE 1 = 1
                AND SHA.HEADER_ID = 889024
                AND SHA.SALESREP_ID = RSA.SALESREP_ID
                AND SHA.ORG_ID = RSA.ORG_ID
                AND TO_NUMBER (RSA.ATTRIBUTE2) = WMP.PROGRAM_ID
                AND WMP.PROGRAM IN ('Dell/Boeing-MPS', 'Dell/Boeing','Dell/Boeing Mgd Svcs')
                AND SHA.BOOKED_FLAG = 'Y'
                AND WL1.LOOKUP_TYPE = 'WWT_DELL_AMC_DIST_CENTER_IDS' 
                AND WL1.ATTRIBUTE2 (+) = SLA.SHIP_FROM_ORG_ID
                -- DFF TABLE
                AND SHA.HEADER_ID = SHD.HEADER_ID(+)
                AND SHA.HEADER_ID = SLA.HEADER_ID
                AND SHA.AGREEMENT_ID = SA.AGREEMENT_ID(+)
                -- SHIP TO INFO
                AND SHA.SHIP_TO_CONTACT_ID = RC.CONTACT_ID(+)
                AND SHA.SHIP_TO_CONTACT_ID = RP.CONTACT_ID(+)
                AND SHA.SHIP_TO_ORG_ID = HCSUA.SITE_USE_ID
                AND HCSUA.CUST_ACCT_SITE_ID = HCASA.CUST_ACCT_SITE_ID(+)
                AND HCASA.PARTY_SITE_ID = HPS.PARTY_SITE_ID(+)
                AND HPS.LOCATION_ID = HL.LOCATION_ID(+)
                -- BILL TO INFO
                AND WSH.WSH_LOCATION_ID = 105
                AND WSH.WSH_LOCATION_ID = HL3.LOCATION_ID
                -- DELIVER TO INFO
                AND SHA.DELIVER_TO_ORG_ID = HCSUA2.SITE_USE_ID(+)
                AND HCSUA2.CUST_ACCT_SITE_ID = HCASA2.CUST_ACCT_SITE_ID(+)
                AND HCASA2.PARTY_SITE_ID = HPS2.PARTY_SITE_ID(+)
                AND HPS2.LOCATION_ID = HL2.LOCATION_ID(+)
                -- SOLD TO CONTACTS
                AND SHA.SOLD_TO_CONTACT_ID = RC3.CONTACT_ID(+)
                AND SHA.SOLD_TO_CONTACT_ID = RP3.CONTACT_ID(+)
                AND SLA.ATTRIBUTE9 = RTRIM (WL.DESCRIPTION)
                AND WL.ENABLED_FLAG = 'Y'
                AND WL.LOOKUP_TYPE = 'DELL_BOEING_VENDOR_SOURCING'
              --  AND SLA.SHIP_FROM_ORG_ID = MSI.ORGANIZATION_ID
                --AND SLA.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID