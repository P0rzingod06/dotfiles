CREATE OR REPLACE PACKAGE BODY REPOS_ADMIN.wwt_Nasa_Sewp_Import IS
-- CVS Header: $Source: /CVS/oracle11i/database/repos/repos_admin/pkgbody/wwt_nasa_sewp_import.plb,v $, $Revision: 1.42 $, $Author: edgleyk $, $Date: 2014/04/22 20:21:51 $


-- MODIFICATION HISTORY
-- PERSON      DATE    COMMENTS
-- ---------   ------  ------------------------------------------
-- TK          20040617  CREATED
-- KONARIKT    20060308  11I UPGRADE
-- L JONES       20070515     added contract number lookup and Function
--                       max_request_date, max_shipped_date and Freight Amounts
-- L Jones       20070628     added check for WWT Maintenance Orders and
--                              condensed the error alerts from one e-mail per record
--                         to multiple errored records per e-mail.
--                         Also added Exception Report.  ALso checked for SHIPPED
--                         status orders.
-- L Jones     20071108   Added Order Status Report to the URL request process
--                        Also removed the VNDHOLD status from both Order and Status reports
--
--AtoosaM    20100707  CHG12332  Modified LOAD_REC and MAIN procedure to cleanup clinno,  mpin, item_desc column as well as
--                                                 formating the list price, cost and sewp price columns, replaced TAA column valued with Y or N
--                                                 , added condition to not to consider null mfg as in valid value for
--                                                 alert also modified and reformated all the alerts
--
--AtoosaM   20110228    CHG18593 v.1.31 Modified create_order_status proceure added order by on order_number also changed
--                                                 the group by on sysdate to match the select sysdate condition.
--
--AtoosaM   20110310    CHG18058 v1.32 cleaned up all the cursor names and cursor variables, out variables based on pl/sql  naming standards.
--                                                        added DELETE_DUPLICATE_CLINNO procedure to delete the clinnos that already
--                                                        exisit in the table and the eligible record that is about to be inserted contain
--                                                        them as well  . Delete calls REPOS_ADMIN.WWT_NASA_SEWP_DLT_TRG to insert
--                                                        clinno first into the archive table before delete.  cleanecd up load_rec for submitted and
--                                                        and  approved status.  Also added the return value to main
--                                                        procedure to control sending th file based on the return value.
--                                                        create_output_file is changed to added eoldate only if column has value.
--AtoosaM   20110422    CHG18058 v1.35  added a check for null clinno. Will not insert any records when clinno is null.
--edgleyk  20110808  CHG19754 v1.36 Add hard-coded column ENERGYSTAR[ to the output file for the technical refresh report (CIF file)
--edgleyk  20110825  CHG19754 v1.37 Changed column ENERGYSTAR[ to be ENERGYSTARFLAG[
--edgleyk  20110825  CHG19754 v1.38 Updating the change# to be the correct one
--edgleyk  20120828  CHG23142 v1.39 Allow additional value of 'NA' in the TAA input field and remove leading space from backupdataflag
--edgleyk  20120828  CHG23142 v 1.40 Use L_TAA =  'NA' instead of null statement
--edgleyk  20120828  CHG23142 v 1.41 Updating version comments
--edgleyk  20140422  CHG30331 v 1.42 Update cursor g_agreement_lookup_cursor to pull unique contract/agreement combination by
--                                                      specifying language as well as agreemend_id, which will use the unique index on the table
--
------------------------------------------------------------------------------
--  Check wwt_lookups for a valid lookup_type to get the agreement_id
------------------------------------------------------------------------------

   CURSOR g_agreement_lookup_cursor IS
             SELECT oat.NAME                  contract_no,
                   oat.agreement_id          agreement_id
          FROM qp.oe_agreements_tl@erp.world oat, apps.WWT_LOOKUPS@erp.world wl
          WHERE oat.agreement_id = wl.attribute1
          AND wl.lookup_type = 'NASA_SEWP_AGREEMENTS'
          AND wl.enabled_flag = 'Y'
          AND oat.language = 'US'
          AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(wl.start_date_active, SYSDATE))
          AND TRUNC(NVL(wl.end_date_active, SYSDATE));

------------------------------------------------------------------------------
-- PROCEDURE CREATE_ORDER_STATUS will create a report that contains orders  --
-- statuses                                                                 --
------------------------------------------------------------------------------
PROCEDURE CREATE_ORDER_STATUS( P_DATETIME IN VARCHAR2
                              ,P_PO_NUMBER  IN VARCHAR2 DEFAULT NULL
                              ,P_FILEPATH   IN VARCHAR2 DEFAULT NULL)

IS

-- This Cursor brings back all the records that are elligible for ORDER_STATUS or SHIPPING report

-- CHG18593 added order by and changed group by on sysdate to match the select sysdate condition

     CURSOR ORDER_STATUS_CUR (cp_agreement_id IN NUMBER, CP_PO IN VARCHAR2 DEFAULT NULL) IS
          SELECT  ooha.cust_po_number                   ORDERNO
                 ,wshd.attribute16                      S3N
                 ,TO_CHAR(ooha.ordered_date,'YYYYMMDD') ORDERDATE
                 ,ooha.order_number                     VENDORNUMBER
                 ,apps.Wwt_Repos_Utilities_Pkg.get_max_request_date@ERP.WORLD(ooha.header_id, ooha.request_date) REQUESTDATE
                 ,OOHA.BOOKED_DATE                        BOOKEDDATE
                 ,OOHA.BOOKED_FLAG                        BOOKEDFLAG
                 ,TO_CHAR(SYSDATE,'YYYYMMDD')           STATUSDATE
                 ,apps.Wwt_Repos_Utilities_Pkg.get_max_shipped_date@ERP.WORLD(ooha.header_id) ACT_SHIP_DATE
                 ,apps.Wwt_Repos_Utilities_Pkg.get_item_segment_three@ERP.WORLD(ooha.header_id) NON_MNT_COUNT
                 ,apps.Wwt_Repos_Utilities_Pkg.get_item_status_closed@ERP.WORLD(ooha.header_id) NON_CLOSED_COUNT
                 ,ooha.flow_status_code                    FLOWSTATUSCODE
                 ,ooha.open_flag                        OPENFLAG
                 ,wpa.instance_label                    INSTANCELABEL
                 ,wias.end_date                            ENDDATE
                 ,ooha.request_date                        HDRREQUESTDATE
            FROM  apps.oe_order_headers_all@erp.world       ooha
                 ,apps.wwt_so_headers_dff@erp.world         wshd
                 ,apps.wf_item_activity_statuses@erp.world  wias
                 ,apps.wf_process_activities@erp.world      wpa
           WHERE ooha.header_id              = wshd.header_id (+)
             AND wias.item_type              = 'OEOH'
             AND TO_NUMBER(wias.item_key)      = ooha.header_id
             AND ((CP_PO IS NULL) OR (OOHA.CUST_PO_NUMBER = CP_PO))
             AND wias.process_activity          = wpa.instance_id
             AND wpa.process_item_type          = 'OEOH'
             AND wias.activity_status          = 'COMPLETE'
              AND ooha.order_type_id          <> 1280
             AND ooha.order_category_code    <> 'RETURN'
             AND ooha.agreement_id           = cp_agreement_id
              AND
              ((OOHA.CUST_PO_NUMBER = CP_PO)
                 OR
              (ooha.flow_status_code         = 'CLOSED'
               AND ooha.open_flag            = 'N'
               AND wpa.instance_label         = 'CLOSE_HEADER'
               AND wias.end_date LIKE SYSDATE - 1)
                 OR
                   (ooha.flow_status_code     = 'BOOKED'
               AND ooha.open_flag            = 'Y'
               AND
                      (OOHA.BOOKED_DATE LIKE SYSDATE - 1
                 OR
                   (ooha.request_date >= TRUNC(SYSDATE)
                AND ooha.request_date <= TRUNC(SYSDATE) + 6))))
        GROUP BY ooha.cust_po_number
                 ,wshd.attribute16
                 ,TO_CHAR(ooha.ordered_date, 'YYYYMMDD')
                 ,ooha.order_number
                 ,apps.Wwt_Repos_Utilities_Pkg.get_max_request_date@ERP.WORLD(ooha.header_id, ooha.request_date)
                 ,OOHA.BOOKED_DATE
                 ,OOHA.BOOKED_FLAG
                 ,TO_CHAR(SYSDATE,'YYYYMMDD')
                 ,apps.Wwt_Repos_Utilities_Pkg.get_max_shipped_date@ERP.WORLD(ooha.header_id)
                 ,apps.Wwt_Repos_Utilities_Pkg.get_item_segment_three@ERP.WORLD(ooha.header_id)
                 ,apps.Wwt_Repos_Utilities_Pkg.get_item_status_closed@ERP.WORLD(ooha.header_id)
                 ,ooha.flow_status_code
                 ,ooha.open_flag
                 ,wpa.instance_label
                 ,wias.end_date
                 ,ooha.request_date
        ORDER BY  ooha.order_number;

     L_NAME                              VARCHAR2(50);
     L_PHONE                             VARCHAR2(25);
     L_EMAIL                             VARCHAR2(50);
     L_FILE                              UTL_FILE.FILE_TYPE;
     L_FILE_NAME                         VARCHAR2(75);
     L_FILE_PATH                         VARCHAR2(100);
     L_LINEOUT                           VARCHAR2(2000);
     L_HOLD_VENDOR_NUMBER                NUMBER  := 0;
      L_HOLD_VENDOR_NUMBER_SHIPPING       NUMBER  := 0;
     L_SURCHARGE                         VARCHAR2(50);
     L_ORDERTOTAL                        VARCHAR2(50);
     L_CURSOR_ROWCOUNT                   NUMBER;
     L_ORDER_STAT_REC              ORDER_STATUS_CUR%ROWTYPE;
     L_STATUS                             VARCHAR2(10);
     L_POPFLAG                             VARCHAR2(10);
     L_FILE_HEADER                         BOOLEAN := FALSE;
     l_file_open                         BOOLEAN := FALSE;
      L_FILE_SHIPPING                     UTL_FILE.FILE_TYPE;
     L_FILE_NAME_SHIPPING                VARCHAR2(75);
     L_FILE_PATH_SHIPPING                VARCHAR2(100);
     L_FILE_HEADER_SHIPPING                 BOOLEAN := FALSE;
     l_file_open_shipping                 BOOLEAN := FALSE;

BEGIN

     FOR lookup_rec IN g_agreement_lookup_cursor LOOP
     OPEN ORDER_STATUS_CUR(lookup_rec.agreement_id, P_PO_NUMBER);
     FETCH ORDER_STATUS_CUR INTO L_ORDER_STAT_REC;

          L_CURSOR_ROWCOUNT := ORDER_STATUS_CUR%ROWCOUNT;

     CLOSE ORDER_STATUS_CUR;

     ---------------------------------------
     -- SELECT THE CONTACT INFORMATION    --
     ---------------------------------------
     IF L_CURSOR_ROWCOUNT > 0 THEN -- IF 1

          SELECT ATTRIBUTE1
                ,ATTRIBUTE2
                ,ATTRIBUTE3
            INTO L_EMAIL
                ,L_PHONE
                ,L_NAME
            FROM APPS.WWT_PROGRAM_SPECIFIC_LOOKUPS@ERP.WORLD
           WHERE PROGRAM     = 'NASA_SEWP'
             AND LOOKUP_NAME = 'REPORTS';

          FOR ORDER_STATUS_REC IN ORDER_STATUS_CUR(lookup_rec.agreement_id, P_PO_NUMBER) LOOP -- LOOP  ORDER_STATUS_CUR

               ---------------------------------------------
               -- CREATE THE ORDER STATUS FILE AND REPORT --
               ---------------------------------------------

               IF   ((ORDER_STATUS_REC.FLOWSTATUSCODE                   = 'CLOSED'   --  IF 2
                       AND ORDER_STATUS_REC.OPENFLAG                  = 'N'
                     AND ORDER_STATUS_REC.INSTANCELABEL             = 'CLOSE_HEADER'
                     AND
                        (ORDER_STATUS_REC.ENDDATE LIKE SYSDATE - 1
                            OR
                         ORDER_STATUS_REC.ORDERNO                 = P_PO_NUMBER))
                OR
                    (ORDER_STATUS_REC.FLOWSTATUSCODE                 = 'BOOKED'
                     AND ORDER_STATUS_REC.OPENFLAG                  = 'Y'
                    AND
                        (ORDER_STATUS_REC.BOOKEDDATE LIKE SYSDATE - 1
                            OR
                         ORDER_STATUS_REC.ORDERNO                 = P_PO_NUMBER)))
               THEN

                  ---------------------------------------------
                    -- CREATE THE FILE AND OPEN IT FOR WRITING --
                    ---------------------------------------------
          IF l_file_open = FALSE THEN

                    IF P_FILEPATH = '/wwt_data/NasaSewpOrderStatusReport' THEN

                        L_FILE_PATH := 'WWT_NASA_SEWP_ORDER_STATUS_WM';

                    ELSE

                   L_FILE_PATH := 'WWT_DR_PD_NASA_ORD_STAT_RPT';

                    end if;

                   L_FILE_NAME := 'WWT' || P_DATETIME || '.txt';

                   L_FILE := UTL_FILE.FOPEN(L_FILE_PATH, L_FILE_NAME, 'W', 32767);

            l_file_open := TRUE;

        END IF;

                    ------------------------------------------------------
                    -- CREATE THE HEADER RECORD AND WRITE TO THE FILE   --
                    ------------------------------------------------------
                  IF L_FILE_HEADER = FALSE THEN

                        L_LINEOUT := 'REPORTTYPE[ORDERSTATUS'                     || CHR(10) ||
                                        'CONTRACTNO['             || lookup_rec.contract_no || CHR(10) ||
                                       'CONTACTNAME[SEAN OROURKE'                      || CHR(10)      ||
                                       'CONTACTPHONE[314-919-1652'                  || CHR(10)      ||
                                       'CONTACTEMAILADDR[sean.orourke@wwt.com';
                       UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

                       L_LINEOUT := NULL;
                    L_FILE_HEADER := TRUE;

                    END IF;


                 IF ((ORDER_STATUS_REC.BOOKEDDATE LIKE SYSDATE - 1) AND (ORDER_STATUS_REC.BOOKEDFLAG = 'Y') AND
                      (ORDER_STATUS_REC.FLOWSTATUSCODE = 'BOOKED'))
                        OR
                    ((ORDER_STATUS_REC.ORDERNO = P_PO_NUMBER) AND (ORDER_STATUS_REC.BOOKEDFLAG = 'Y') AND
                      (ORDER_STATUS_REC.FLOWSTATUSCODE = 'BOOKED'))
                   THEN

                   IF ORDER_STATUS_REC.NON_MNT_COUNT > 0 THEN
                      L_STATUS := NULL;
                   ELSE
                        L_STATUS := 'POPONLY';
                   END IF;

                  END IF;

                 IF ORDER_STATUS_REC.FLOWSTATUSCODE = 'CLOSED' THEN
                    L_STATUS := 'SHIPPED';
                 END IF;

                 IF ORDER_STATUS_REC.NON_CLOSED_COUNT = 0 THEN
                    L_STATUS := 'SHIPPED';
                 END IF;

                 IF L_HOLD_VENDOR_NUMBER <> ORDER_STATUS_REC.VENDORNUMBER THEN

                      L_LINEOUT := 'ORDERNO['      || ORDER_STATUS_REC.ORDERNO      || CHR(10) ||
                                      'ORDERSEQ['     || ORDER_STATUS_REC.S3N          || CHR(10) ||
                                     'ORDERDATE['    || ORDER_STATUS_REC.ORDERDATE    || CHR(10) ||
                                     'STATUS['       || L_STATUS               || CHR(10) ||
                                     'SHIPDATE['     || TO_CHAR(ORDER_STATUS_REC.ACT_SHIP_DATE,'YYYYMMDD') || CHR(10) ||
                                     'STATUSDATE['     || TO_CHAR(SYSDATE,'YYYYMMDD')                     || CHR(10) ||
                                     'EXPDELDATE['     || TO_CHAR(ORDER_STATUS_REC.REQUESTDATE,'YYYYMMDD')   || CHR(10) ||
                                     'VENDORNUMBER[' || ORDER_STATUS_REC.VENDORNUMBER;

                      UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

                      L_LINEOUT := NULL;

                     L_HOLD_VENDOR_NUMBER := ORDER_STATUS_REC.VENDORNUMBER;

                 END IF;

               END IF; -- IF 2

               --------------------------------------------------
               -- CREATE THE ORDER STATUS SHIP FILE AND REPORT --
               --------------------------------------------------

               IF    ((ORDER_STATUS_REC.FLOWSTATUSCODE  = 'BOOKED'   --  IF 3
                   AND  ORDER_STATUS_REC.OPENFLAG        = 'Y'
                  AND (TRUNC(ORDER_STATUS_REC.HDRREQUESTDATE)  >= TRUNC(SYSDATE)
                  AND  TRUNC(ORDER_STATUS_REC.HDRREQUESTDATE)  <= TRUNC(SYSDATE + 6)))
                    OR
                      (ORDER_STATUS_REC.FLOWSTATUSCODE  = 'BOOKED'   --  IF 3
                   AND  ORDER_STATUS_REC.OPENFLAG        = 'Y'
                AND (ORDER_STATUS_REC.ORDERNO         = P_PO_NUMBER)))
             THEN

                    ---------------------------------------------------------
                    -- CREATE THE STATUS SHIP FILE AND OPEN IT FOR WRITING --
                    ---------------------------------------------------------
                    IF l_file_open_shipping = FALSE THEN

                        L_FILE_PATH_SHIPPING := 'WWT_DR_PD_NASA_ORD_STAT_RPTSHP';

                       L_FILE_NAME_SHIPPING := 'WWT' || P_DATETIME || '.txt';

                       L_FILE_SHIPPING := UTL_FILE.FOPEN(L_FILE_PATH_SHIPPING, L_FILE_NAME_SHIPPING, 'W', 32767);

                     l_file_open_shipping := TRUE;

                  END IF;

                    ------------------------------------------------------
                    -- CREATE THE HEADER RECORD AND WRITE TO THE FILE   --
                    ------------------------------------------------------
                  IF L_FILE_HEADER_SHIPPING = FALSE THEN

                        L_LINEOUT := 'REPORTTYPE[ORDERSTATUS'                           || CHR(10) ||
                                   'CONTRACTNO['             || lookup_rec.contract_no || CHR(10) ||
                                  'CONTACTNAME[MIKE SCHMITT'                      || CHR(10) ||
                                  'CONTACTPHONE[314-919-1448'                  || CHR(10) ||
                                       'CONTACTEMAILADDR[mike.schmitt@wwt.com';
                      UTL_FILE.PUT_LINE(L_FILE_SHIPPING, L_LINEOUT);

                       L_LINEOUT := NULL;
                    L_FILE_HEADER_SHIPPING := TRUE;

                    END IF;

                    L_POPFLAG := 'N';
                    L_STATUS := NULL;

                    IF ORDER_STATUS_REC.NON_MNT_COUNT > 0 THEN
                     L_STATUS := NULL;
                 ELSE
                     L_POPFLAG := 'Y';
                    L_STATUS := 'POPONLY';
                 END IF;

                 IF L_HOLD_VENDOR_NUMBER_SHIPPING <> ORDER_STATUS_REC.VENDORNUMBER THEN

                        L_LINEOUT := ' '                                     || CHR(10) ||
                                     'ORDERNO['      || ORDER_STATUS_REC.ORDERNO       || CHR(10) ||
                                     'ORDERSEQ['     || ORDER_STATUS_REC.S3N           || CHR(10) ||
                                     'ORDERDATE['    || ORDER_STATUS_REC.ORDERDATE     || CHR(10) ||
                                     'EXPDELDATE['     || TO_CHAR(ORDER_STATUS_REC.REQUESTDATE,'YYYYMMDD')      || CHR(10) ||
                                     'VENDORNUMBER[' || ORDER_STATUS_REC.VENDORNUMBER  || CHR(10) ||
                                     'EXCEPTIONFLAG[Y'                              || CHR(10) ||
                                     'EXCEPTIONREMARKS[N'                        || CHR(10) ||
                                     'STATUS['          || L_STATUS                || CHR(10) ||
                                     'STATUSDATE['      || TO_CHAR(SYSDATE,'YYYYMMDD');

                     UTL_FILE.PUT_LINE(L_FILE_SHIPPING, L_LINEOUT);

                     L_LINEOUT := NULL;

                    L_HOLD_VENDOR_NUMBER_SHIPPING := ORDER_STATUS_REC.VENDORNUMBER;

                 END IF;

             END IF; -- IF 3

          END LOOP; -- LOOP ORDER_STATUS_CUR

     END IF; -- IF 1

          IF l_file_open = TRUE
               THEN
                    UTL_FILE.PUT_LINE(L_FILE, 'ENDREPORT[');
                L_FILE_HEADER := FALSE;
          END IF;

          IF l_file_open_shipping = TRUE
               THEN
                UTL_FILE.PUT_LINE(L_FILE_SHIPPING, 'ENDREPORT[');
                 L_FILE_HEADER_SHIPPING := FALSE;
          END IF;

     END LOOP;  --  agreement_lookup_cursor

     IF UTL_FILE.IS_OPEN(l_file)
         THEN
           UTL_FILE.FCLOSE(L_FILE);
     END IF;

     IF UTL_FILE.IS_OPEN(l_file_shipping)
         THEN
            UTL_FILE.FCLOSE(L_FILE_SHIPPING);
     END IF;

EXCEPTION
     WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERROR IN CREATE_ORDER_STATUS:  '||SQLERRM);

END CREATE_ORDER_STATUS; 

------------------------------------------------------------------------------
-- PROCEDURE CREATE_ORDER_REPORT will create a report that contains orders  --
-- which are in booked status                                               --
---------------------------------------QZz---------------------------------------
PROCEDURE CREATE_ORDER_REPORT( P_DATETIME   IN VARCHAR2
                              ,P_PO_NUMBER  IN VARCHAR2 DEFAULT NULL
                              ,P_FILEPATH   IN VARCHAR2 DEFAULT NULL
                              ,X_S3N       OUT VARCHAR2 )

IS

     CURSOR ORDER_REPORT_CUR(cp_agreement_id IN NUMBER, CP_PO IN VARCHAR2 DEFAULT NULL) IS
          SELECT OOHA.CUST_PO_NUMBER                                                                  ORDERNO
                ,WSHD.ATTRIBUTE16                                                                       S3N
                ,TO_CHAR(OOHA.ORDERED_DATE,'YYYYMMDD')                                                   ORDERDATE
                ,OOHA.ORDER_NUMBER                                                                       VENDORNUMBER
                  ,OOLA.LINE_NUMBER||'.'||oola.shipment_number                                          LINE_NUMBER
                ,OOLA.ATTRIBUTE11                                                                     ATTRIBUTE11
                ,OOLA.UNIT_SELLING_PRICE                                                              UNIT_SELLING_PRICE
                ,OOLA.ATTRIBUTE1                                                                      REPOS_ITEM_ID
                 ,DECODE(OOLA.ATTRIBUTE1,
                                   NULL,
                                   'CLIN['||REPLACE(
                                                    REPLACE(
                                                            MSI.SEGMENT2,'[','('),']',')')
                                   ||'['||TO_CHAR(OOLA.UNIT_SELLING_PRICE)||'['||TO_CHAR(OOLA.ORDERED_QUANTITY),
                                     'CLIN['||REPLACE(
                                                    REPLACE(
                                                            'REPOSITEMNUMBER','[','('
                                                           ),']',')'
                                                   )
                                   ||'['||TO_CHAR(OOLA.UNIT_SELLING_PRICE)||'['||TO_CHAR(OOLA.ORDERED_QUANTITY)
                        ) CLIN
                  ,WSHD.ATTRIBUTE24                                                                     "SURCHARGE"
                ,NVL(APPS.Wwt_Repos_Utilities_Pkg.GET_ORDER_TOTAL@ERP.WORLD(OOHA.HEADER_ID),0) ORDERTOTAL
            FROM APPS.OE_ORDER_HEADERS_ALL@ERP.WORLD    OOHA
                  ,APPS.WWT_SO_HEADERS_DFF@ERP.WORLD      WSHD
                  ,APPS.OE_ORDER_LINES_ALL@ERP.WORLD         OOLA
                    ,APPS.MTL_SYSTEM_ITEMS_B@ERP.WORLD         MSI
           WHERE OOHA.HEADER_ID                                       = WSHD.HEADER_ID (+)
             AND OOHA.HEADER_ID                                       = OOLA.HEADER_ID
               AND OOLA.INVENTORY_ITEM_ID                               = MSI.INVENTORY_ITEM_ID
               AND MSI.ORGANIZATION_ID                                  = 101
             AND ((CP_PO IS NULL AND OOHA.BOOKED_DATE LIKE SYSDATE - 1) OR (OOHA.CUST_PO_NUMBER = CP_PO))
               AND OOHA.BOOKED_FLAG                                     = 'Y' -- ORDER IS IN BOOKED STATUS
               AND OOHA.ORDER_TYPE_ID                                  <> 1280 -- TO EXCLUDE OTA-RMA ORDERS USED TO CREATE RMA ORDERS
               AND OOHA.ORDER_CATEGORY_CODE                            <> 'RETURN' -- TO EXCLUDE RMA ORDERS
               AND OOHA.AGREEMENT_ID                                   = cp_agreement_id
             AND MSI.SEGMENT2                                        <> 'SEWPZ'
        GROUP BY OOHA.CUST_PO_NUMBER
                ,WSHD.ATTRIBUTE16
                  ,OOHA.ORDERED_DATE
                  ,OOHA.ORDER_NUMBER
                  ,OOLA.LINE_NUMBER||'.'||oola.shipment_number
                ,apps.Wwt_Repos_Utilities_Pkg.get_max_request_date@ERP.WORLD(ooha.header_id, ooha.request_date)
                ,OOLA.ATTRIBUTE11
                ,OOLA.UNIT_SELLING_PRICE
                ,OOLA.ATTRIBUTE1
                 ,DECODE(OOLA.ATTRIBUTE1,
                                   NULL,
                                   'CLIN['||REPLACE(
                                                    REPLACE(
                                                            MSI.SEGMENT2,'[','('),']',')')
                                   ||'['||TO_CHAR(OOLA.UNIT_SELLING_PRICE)||'['||TO_CHAR(OOLA.ORDERED_QUANTITY),
                                     'CLIN['||REPLACE(
                                                    REPLACE(
                                                            'REPOSITEMNUMBER','[','('
                                                           ),']',')'
                                                   )
                                   ||'['||TO_CHAR(OOLA.UNIT_SELLING_PRICE)||'['||TO_CHAR(OOLA.ORDERED_QUANTITY)
                        )
                  ,WSHD.ATTRIBUTE24
                ,NVL(APPS.Wwt_Repos_Utilities_Pkg.GET_ORDER_TOTAL@ERP.WORLD(OOHA.HEADER_ID),0)
        ORDER BY
                 OOHA.ORDER_NUMBER
                 ,TO_NUMBER(NVL(OOLA.LINE_NUMBER||'.'||oola.shipment_number,'0'));

     L_NAME                              VARCHAR2(50);
     L_PHONE                             VARCHAR2(25);
     L_EMAIL                             VARCHAR2(50);
     L_FILE                              UTL_FILE.FILE_TYPE;
     L_FILE_NAME                         VARCHAR2(75);
     L_FILE_PATH                         VARCHAR2(100);
     L_LINEOUT                           VARCHAR2(2000);
     L_HOLD_VENDOR_NUMBER                NUMBER                := 0;
     L_SURCHARGE                         VARCHAR2(50);
     L_ORDERTOTAL                        VARCHAR2(50);
     L_CURSOR_ROWCOUNT                   NUMBER;
     L_ORDER_REPORT_REC                  ORDER_REPORT_CUR%ROWTYPE;
     L_FILEOPEN                          BOOLEAN := FALSE;
     L_HEADER_CREATED                    BOOLEAN := FALSE;
     L_VENDORORDERNO                     VARCHAR2(100)  := NULL;
     L_price_check                       VARCHAR2(100)  := 'PASS';
     L_max_selling_price                 NUMBER         := 0;
     L_freight_amount                    NUMBER         := 0;
     L_item_number                       VARCHAR2(100)  := NULL;

BEGIN

     ---------------------------------------
     -- SELECT THE CONTACT INFORMATION    --
     ---------------------------------------
     SELECT ATTRIBUTE1
           ,ATTRIBUTE2
           ,ATTRIBUTE3
       INTO L_EMAIL
           ,L_PHONE
           ,L_NAME
       FROM PARTNER_ADMIN.WWT_PROGRAM_SPECIFIC_LOOKUPS@ERP.WORLD
      WHERE PROGRAM     = 'NASA_SEWP'
        AND LOOKUP_NAME = 'REPORTS';

    ---------------------------------------------
    -- CREATE THE FILE AND OPEN IT FOR WRITING --
    ---------------------------------------------

     FOR lookup_rec IN g_agreement_lookup_cursor LOOP
     FOR ORDER_REPORT_REC IN ORDER_REPORT_CUR(lookup_rec.agreement_id, P_PO_NUMBER) LOOP

        IF ORDER_REPORT_REC.VENDORNUMBER <> L_HOLD_VENDOR_NUMBER THEN

             IF L_HOLD_VENDOR_NUMBER <> 0 THEN

                  L_freight_amount := apps.Wwt_Repos_Utilities_Pkg.get_freight_amount@ERP.WORLD(L_HOLD_VENDOR_NUMBER);

                   IF NVL(L_freight_amount,0) <> 0
                       THEN  L_LINEOUT := 'CLIN[DELIVERYZ['  || L_freight_amount || '[1';
                           UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);
                           L_LINEOUT := NULL;
                  END IF;

                   L_LINEOUT := 'SURCHARGE['  || L_SURCHARGE || CHR(10) ||
                               'ORDERTOTAL[' || L_ORDERTOTAL;

                  UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

                  L_LINEOUT := NULL;

                  UTL_FILE.PUT_LINE(L_FILE, 'ENDREPORT[');

                    UTL_FILE.FCLOSE(L_FILE);

                  L_FILEOPEN              := FALSE;

                  L_HEADER_CREATED          := FALSE;

             END IF;

        END IF;

        IF NOT L_FILEOPEN THEN

          IF P_FILEPATH = '/wwt_data/NasaSewpOrderReport' THEN

               L_FILE_PATH := 'WWT_NASA_SEWP_ORDER_WM';

          ELSE

               L_FILE_PATH := 'WWT_DR_PD_NASA_ORD_REPORT';

          END IF;

          L_VENDORORDERNO := REPLACE(ORDER_REPORT_REC.VENDORNUMBER,' ','_');
          L_FILE_NAME := 'WWT' || P_DATETIME ||L_VENDORORDERNO|| '.txt';

          L_FILE := UTL_FILE.FOPEN(L_FILE_PATH, L_FILE_NAME, 'W',32767);

          L_FILEOPEN := TRUE;

        END IF;
        ------------------------------------------------------
        -- CREATE THE HEADER RECORD AND WRITE TO THE FILE   --
        ------------------------------------------------------

        IF NOT L_HEADER_CREATED THEN

            L_LINEOUT := 'REPORTTYPE[ORDERREPORT'                             || CHR(10) ||
                         'CONTRACTNO['             || lookup_rec.contract_no || CHR(10) ||
                         'CONTACTNAME[SEAN OROURKE'                                || CHR(10) ||
                         'CONTACTPHONE[314-919-1652'                            || CHR(10) ||
                         'CONTACTEMAILADDR[sean.orourke@wwt.com';

            UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

            L_LINEOUT := NULL;

            L_HEADER_CREATED := TRUE;

            L_LINEOUT := 'ORDERNO['      || ORDER_REPORT_REC.ORDERNO      || CHR(10) ||
                         'ORDERSEQ['     || ORDER_REPORT_REC.S3N          || CHR(10) ||
                         'ORDERDATE['    || ORDER_REPORT_REC.ORDERDATE    || CHR(10) ||
                         'STATUS['                              || CHR(10) ||
                         'VENDORNUMBER[' || ORDER_REPORT_REC.VENDORNUMBER;

            UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

            L_LINEOUT := NULL;

            L_HOLD_VENDOR_NUMBER := ORDER_REPORT_REC.VENDORNUMBER;

            L_SURCHARGE := ORDER_REPORT_REC.SURCHARGE;

            L_ORDERTOTAL := ORDER_REPORT_REC.ORDERTOTAL;

         END IF;

        L_item_number := ORDER_REPORT_REC.ATTRIBUTE11;
        IF (ORDER_REPORT_REC.UNIT_SELLING_PRICE = 0 or ORDER_REPORT_REC.UNIT_SELLING_PRICE IS NULL) THEN
           L_item_number := 'OPENZ';
        End if;

        IF ORDER_REPORT_REC.REPOS_ITEM_ID IS NOT NULL THEN

           BEGIN
                   SELECT REPLACE(ORDER_REPORT_REC.CLIN,'REPOSITEMNUMBER',REPLACE(REPLACE(REPLACE(L_item_number,'[',')'),']',')'),'(MNT)',''))
                  INTO ORDER_REPORT_REC.CLIN
                  FROM REPOS_ADMIN.ITEM_HEADER
                 WHERE ITEM_ID = TO_NUMBER(ORDER_REPORT_REC.REPOS_ITEM_ID);
           EXCEPTION
                   WHEN OTHERS THEN
                     SELECT REPLACE(ORDER_REPORT_REC.CLIN,'REPOSITEMNUMBER','')
                       INTO ORDER_REPORT_REC.CLIN
                       FROM DUAL;
           END;

        END IF;

 --       DOES ITEM HAVE A PRICE ?

       IF ORDER_REPORT_REC.REPOS_ITEM_ID IS NULL THEN
          L_price_check := 'CHECK';

       ELSE

          BEGIN
                  L_price_check := 'PASS';
               L_max_selling_price  := 0;
          SELECT csp.max_selling_price
              INTO L_max_selling_price
                FROM Repos_admin.CONTRACT_SELLING_PRICE csp
               WHERE TO_CHAR(csp.item_id) = ORDER_REPORT_REC.REPOS_ITEM_ID
              AND csp.contract_id = '248';
          EXCEPTION
                 WHEN OTHERS THEN
                L_price_check := 'FAIL';
          END;

        END IF;

        IF  L_price_check = 'PASS' AND
           (L_max_selling_price = 0 OR L_max_selling_price IS NULL)
        THEN
           L_price_check := 'CHECK';
        END IF;

        IF  L_price_check = 'PASS'
        THEN
            L_price_check := NULL;
        END IF;

             L_LINEOUT := ORDER_REPORT_REC.CLIN         ||    ' '              || L_price_check;

             UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

             L_LINEOUT := NULL;

             X_S3N := ORDER_REPORT_REC.S3N;

     END LOOP; -- LOOP ORDER_REPORT_CUR

          IF  L_FILEOPEN THEN

             L_freight_amount := apps.Wwt_Repos_Utilities_Pkg.get_freight_amount@ERP.WORLD(L_HOLD_VENDOR_NUMBER);

             IF NVL(L_freight_amount,0) <> 0
                THEN  L_LINEOUT := 'CLIN[DELIVERYZ['  || L_freight_amount || '[1';
                      UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);
                      L_LINEOUT := NULL;
             END IF;

             L_LINEOUT := 'SURCHARGE['  || L_SURCHARGE || CHR(10) ||
                          'ORDERTOTAL[' || L_ORDERTOTAL;

             UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

             L_LINEOUT := NULL;

             UTL_FILE.PUT_LINE(L_FILE, 'ENDREPORT[');

               UTL_FILE.FCLOSE(L_FILE);

             L_SURCHARGE             := NULL;
             L_ORDERTOTAL             := NULL;
             L_HOLD_VENDOR_NUMBER     := 0;
             L_FILEOPEN                 := FALSE;
             L_HEADER_CREATED         := FALSE;

        END IF;

     END LOOP;  --  agreement_lookup_cursor

EXCEPTION
     WHEN OTHERS THEN

          DBMS_OUTPUT.PUT_LINE('ERROR IN CREATE_ORDER_REPORT:  '||SQLERRM);

END CREATE_ORDER_REPORT;

/******************************************************************************/
------------------------------------------------------------------------------
--  PROCEDURE CREATE_OUTPUT_FILE creates the file for the technical refresh --
--  report                                                                  --
-- CHG18058 modified to populate eoldate only when column is not null
------------------------------------------------------------------------------
PROCEDURE CREATE_OUTPUT_FILE( P_DATETIME        IN VARCHAR2
                             ,P_DATETIME2       IN DATE
                             ,P_PROCESSDATETIME IN VARCHAR2
                             ,P_FILENAME        IN VARCHAR2
                             ,P_EXCELNAME       IN VARCHAR2)

IS

    ------------------------------------------------
    -- THIS CURSOR WILL SELECT ALL OF THE RECORDS --
    -- THAT WERE JUST LOADED AS THEY NEED TO BE   --
    -- INCLUDED ON THE TR REPORT                  --
    ------------------------------------------------
     CURSOR NASA_SEWP_TR_CUR IS
          SELECT *
            FROM REPOS_ADMIN.WWT_NASA_SEWP
           WHERE CREATION_DATE = P_DATETIME2;

     L_FILE                              UTL_FILE.FILE_TYPE;
     L_FILE_NAME                         VARCHAR2(75);
     L_FILE_PATH                         VARCHAR2(100);
     L_LINEOUT                           VARCHAR2(2000);
     L_LINECOUNT                         NUMBER := 0;
     L_NAME                              VARCHAR2(50);
     L_PHONE                             VARCHAR2(25);
     L_EMAIL                             VARCHAR2(50);

BEGIN

     ---------------------------------------
     -- SELECT THE CONTACT INFORMATION    --
     ---------------------------------------
     SELECT ATTRIBUTE1
           ,ATTRIBUTE2
           ,ATTRIBUTE3
       INTO L_EMAIL
           ,L_PHONE
           ,L_NAME
       FROM PARTNER_ADMIN.WWT_PROGRAM_SPECIFIC_LOOKUPS@ERP.WORLD
      WHERE PROGRAM     = 'NASA_SEWP'
        AND LOOKUP_NAME = 'REPORTS';

     ---------------------------------------------
     -- CREATE THE FILE AND OPEN IT FOR WRITING --
     ---------------------------------------------
     L_FILE_PATH := 'WWT_DR_PD_NASA_ITEM_LOAD_RPT';

     L_FILE_NAME := P_EXCELNAME;

     L_FILE      := UTL_FILE.FOPEN(L_FILE_PATH, L_FILE_NAME, 'W',32767);

     ------------------------------------------------------
     -- CREATE THE HEADER RECORD AND WRITE TO THE FILE   --
     ------------------------------------------------------
     L_LINEOUT := 'REPORTTYPE[TR'           || CHR(10) ||
                  'TRNUMBER['               || APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_EXCELNAME,1,'.',FALSE) || CHR(10) ||
                  'CONTRACTNO[NNG07DA41B'   || CHR(10) ||
                  'TRDESC['                 || APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_EXCELNAME,1,'.',FALSE) || CHR(10) ||
                  'CONTACTNAME['            || L_NAME       || CHR(10) ||
                  'CONTACTPHONE['           || L_PHONE      || CHR(10) ||
                  'CONTACTEMAIL['             || L_EMAIL      || CHR(10) ||
                  'FORWARDNOERROR[Y';

     UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

     L_LINEOUT := NULL;

     --------------------------------------------------------------------
     -- LOOP THROUGH CURSOR AND THEN WRITE EACH RECORD OUT TO THE FILE --
     -- Add new field to the output file called "ENERGYSTARFLAG" per CHG19867
     -- CHG23142 Remove leading space from BACKUPDATAFLAG field
     --------------------------------------------------------------------
     FOR NASA_SEWP_TR_REC IN NASA_SEWP_TR_CUR LOOP -- LOOP NASA_SEWP_TR_CUR

          L_LINECOUNT := L_LINECOUNT + 1;

          IF NASA_SEWP_TR_REC.EOL_DATE IS NOT NULL THEN
          L_LINEOUT :=  'LIN['                                    || L_LINECOUNT                                                       || CHR(10) ||
                                'CLIN['                                  || NASA_SEWP_TR_REC.CLINNO                                || CHR(10) ||
                                'PROVIDER['                || NASA_SEWP_TR_REC.MANUFACTURER                   || CHR(10) ||
                                'PARTNUMBER['                    || NASA_SEWP_TR_REC.MPIN                                    || CHR(10) ||
                                'DISCOUNTCLASS['                      || NASA_SEWP_TR_REC.CLASSIFICATION_CODE         || CHR(10) ||
                                'SUBCLASS['                        || NASA_SEWP_TR_REC.SUBCLASS                            || CHR(10) ||
                                'BMAFLAG['                          || NASA_SEWP_TR_REC.BASEMANDAVAILCODE           || CHR(10) ||
                                'LISTPRICE['                        || NVL(NASA_SEWP_TR_REC.LIST_UNIT_PRICE,'0')      || CHR(10) ||
                                'SEWPPRICE['                      || NVL(NASA_SEWP_TR_REC.SEWP_PRICE,'0')             || CHR(10) ||
                                'CLINTYPE['                          || NASA_SEWP_TR_REC.PSM                                     || CHR(10) ||
--                                'EPEATFLAG['                       || NASA_SEWP_TR_REC.EPEAT                                  || CHR(10) ||
                                'ENERGYSTARFLAG['             || 'Q'                                                                        || CHR(10) ||
--                               'VISIBLEFLAG['                      || NASA_SEWP_TR_REC.VISIBLE                                || CHR(10) ||
--                               'CUSTOMFLAG['                    || NASA_SEWP_TR_REC.CUSTOM                              || CHR(10) ||
                               'BACKUPDATAFLAG['             || NASA_SEWP_TR_REC.BACKUPDATA                        || CHR(10) ||
                               'ITEMDESC['                         || NASA_SEWP_TR_REC.ITEM_DESC                          || CHR(10) ||
                               'DISCOUNTPCT['                   || NASA_SEWP_TR_REC.DISCOUNT_PCT                    || CHR(10) ||
                               'TAAFLAG['                           || NASA_SEWP_TR_REC.TAA                                    || CHR(10) ||
                               'EOLDATE['                           || to_char(NASA_SEWP_TR_REC.EOL_DATE,'RRRRMMDD') ;

          ELSE
          L_LINEOUT :=  'LIN['                                   || L_LINECOUNT                                                       || CHR(10) ||
                                'CLIN['                                  || NASA_SEWP_TR_REC.CLINNO                                || CHR(10) ||
                                'PROVIDER['                || NASA_SEWP_TR_REC.MANUFACTURER                   || CHR(10) ||
                                'PARTNUMBER['                    || NASA_SEWP_TR_REC.MPIN                                    || CHR(10) ||
                                'DISCOUNTCLASS['                      || NASA_SEWP_TR_REC.CLASSIFICATION_CODE         || CHR(10) ||
                                'SUBCLASS['                        || NASA_SEWP_TR_REC.SUBCLASS                            || CHR(10) ||
                                'BMAFLAG['                          || NASA_SEWP_TR_REC.BASEMANDAVAILCODE           || CHR(10) ||
                                'LISTPRICE['                        || NVL(NASA_SEWP_TR_REC.LIST_UNIT_PRICE,'0')      || CHR(10) ||
                                'SEWPPRICE['                      || NVL(NASA_SEWP_TR_REC.SEWP_PRICE,'0')             || CHR(10) ||
                                'CLINTYPE['                          || NASA_SEWP_TR_REC.PSM                                     || CHR(10) ||
--                                'EPEATFLAG['                       || NASA_SEWP_TR_REC.EPEAT                                  || CHR(10) ||
                                'ENERGYSTARFLAG['             || 'Q'                                                                        || CHR(10) ||
--                               'VISIBLEFLAG['                      || NASA_SEWP_TR_REC.VISIBLE                                || CHR(10) ||
--                               'CUSTOMFLAG['                    || NASA_SEWP_TR_REC.CUSTOM                              || CHR(10) ||
                               'BACKUPDATAFLAG['             || NASA_SEWP_TR_REC.BACKUPDATA                       || CHR(10) ||
                               'ITEMDESC['                         || NASA_SEWP_TR_REC.ITEM_DESC                          || CHR(10) ||
                               'DISCOUNTPCT['                   || NASA_SEWP_TR_REC.DISCOUNT_PCT                    || CHR(10) ||
                               'TAAFLAG['                           || NASA_SEWP_TR_REC.TAA;
                     END IF;

          UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

          L_LINEOUT := NULL;

     END LOOP;-- LOOP NASA_SEWP_TR_CUR

     --------------------------------------------
     -- WRITE OUT THE TRAILER RECORD           --
     --------------------------------------------
     L_LINEOUT := 'TOTALCLINS[' || L_LINECOUNT || CHR(10) || 'ENDREPORT[';

     UTL_FILE.PUT_LINE(L_FILE, L_LINEOUT);

     ----------------------
     -- CLOSE THE FILE   --
     ----------------------

     UTL_FILE.FCLOSE(L_FILE);

EXCEPTION
     WHEN OTHERS THEN

          DBMS_OUTPUT.PUT_LINE('ERROR IN CREATE_OUTPUT_FILE:  '||SQLERRM);

END CREATE_OUTPUT_FILE;

-- Proedure delete_duplicate_clinno finds the clin number that already exists in wwt_nasa_sewp
-- and delets them , delete_dup_clin_trg will insert the clins that are going to be deleted
-- to wwt_nasa_sewp_arch.
PROCEDURE DELETE_DUPLICATE_CLINNO (P_CLINNO IN VARCHAR2, X_RETURN_VALUE OUT NUMBER) IS

L_CLIN                   VARCHAR2(80);
l_user_name           VARCHAR2 (25)    := SYS_CONTEXT ('USERENV', 'SESSION_USER') ;

 BEGIN


        X_RETURN_VALUE := 0;
        -- Check to see if the incoming clinno exist in wwt_nasa_sewp
         SELECT clinno
             INTO L_CLIN
         FROM repos_admin.wwt_nasa_sewp
         WHERE NVL(clinno, 'NULL') = NVL(p_clinno, 'NULL');

           IF L_CLIN IS NOT NULL THEN
                -- delets the clins from table that are in incoming file and eligible to be inserted.
                -- deleted triggers WWT_NASA_SEWP_DLT_TRG  to insert record in archive table
                -- before delete
                  DELETE
                  FROM repos_admin.wwt_nasa_sewp
                  WHERE clinno = L_CLIN;
           END IF;

 EXCEPTION
 WHEN NO_DATA_FOUND THEN
       DBMS_OUTPUT.PUT_LINE('NO CLIN FOUND TO DELETE FROM WWT_NASA_SEWP. ' );
       DBMS_OUTPUT.PUT_LINE('SESSION ID IS : ' || L_USER_NAME);

   WHEN OTHERS THEN
       DBMS_OUTPUT.PUT_LINE('ERROR IN DELETE DUPLICATE CLINNO PROCEDURE. ' || SQLERRM);
       DBMS_OUTPUT.PUT_LINE('DELETED CLINNO IS : ' || P_CLINNO);
       DBMS_OUTPUT.PUT_LINE('SESSION ID IS : ' || L_USER_NAME);
       X_RETURN_VALUE := 2;
END DELETE_DUPLICATE_CLINNO;

------------------------------------------------------------------------------
--  PROCEDURE LOAD_REC loads the items into the table                       --
--  CHG18058 cleaned up all the un used out variables and added the call to deleted_duplicate_clinno
------------------------------------------------------------------------------
PROCEDURE LOAD_REC( P_LINE_IN           IN VARCHAR2
                   ,P_PROCESS_DATE_TIME IN DATE
                   ,X_RETURN_VALUE     OUT NUMBER
                   ,P_FILENAME          IN VARCHAR2
                   ,X_BAD_MANFS           OUT VARCHAR2)


IS

     L_DELIM                                                       VARCHAR2(1)        := CHR(9); -- TAB CHARACTER
     L_HEADER_ID                                               NUMBER;
     L_CLIN                                                    REPOS_ADMIN.WWT_NASA_SEWP.CLINNO%TYPE;
     L_PROVIDER                                       REPOS_ADMIN.WWT_NASA_SEWP.MANUFACTURER%TYPE;
     L_PART_NUMBER                                                        REPOS_ADMIN.WWT_NASA_SEWP.MPIN%TYPE;
     L_DISCOUNT_CLASS                             REPOS_ADMIN.WWT_NASA_SEWP.CLASSIFICATION_CODE%TYPE;
     L_DISCOUNT_SUBCLASS                                                REPOS_ADMIN.WWT_NASA_SEWP.SUBCLASS%TYPE;
     L_BMA_FLAG                               REPOS_ADMIN.WWT_NASA_SEWP.BASEMANDAVAILCODE%TYPE;
     L_ITEM_DESC                                               REPOS_ADMIN.WWT_NASA_SEWP.ITEM_DESC%TYPE;
     L_DISCOUNT_PCT                                         REPOS_ADMIN.WWT_NASA_SEWP.DISCOUNT_PCT%TYPE;
     L_LIST_PRICE                                      REPOS_ADMIN.WWT_NASA_SEWP.LIST_UNIT_PRICE%TYPE;
     L_SEWP_PRICE                                             REPOS_ADMIN.WWT_NASA_SEWP.SEWP_PRICE%TYPE;
     L_GSA_PRICE                                               REPOS_ADMIN.WWT_NASA_SEWP.GSA_PRICE%TYPE;
     L_EOL_DATE                                                REPOS_ADMIN.WWT_NASA_SEWP.EOL_DATE%TYPE;
     L_CLIN_TYPE                                                         REPOS_ADMIN.WWT_NASA_SEWP.PSM%TYPE;
--     L_EPEAT                                                      REPOS_ADMIN.WWT_NASA_SEWP.EPEAT%TYPE;
--     L_VISIBLE                                                    REPOS_ADMIN.WWT_NASA_SEWP.VISIBLE%TYPE;
--     L_CUSTOM                                                  REPOS_ADMIN.WWT_NASA_SEWP.CUSTOM%TYPE;
     L_BACKUPDATA                                            REPOS_ADMIN.WWT_NASA_SEWP.BACKUPDATA%TYPE;
     L_TAA_FLAG                                                         REPOS_ADMIN.WWT_NASA_SEWP.TAA%TYPE;
     L_CHECK_FLAG                                            VARCHAR2(20);
     L_FILENAME                                                VARCHAR2(50);
     L_PRICING_CHECK                                       NUMBER;
     L_MANF_COUNT                                          NUMBER;
     L_BODY                                                      VARCHAR2(300);
     L_FILE_STATUS                                          VARCHAR2(25);
     L_CLRF                                                       VARCHAR2(10) := CHR( 13 ) || CHR( 10 );  -- CHG12332  carriage return and linefeed  characters
     L_RETURN_VALUE                                        NUMBER;

BEGIN
          SELECT REPOS_ADMIN.WWT_NASA_SEWP_S.NEXTVAL
            INTO L_HEADER_ID
            FROM DUAL;
           -- CHG12332 replacded rtrim, ltrim with trim , cleaned up single quote, double quote from clinno, mpin, item_desc. formated list_unit_price, sewp_price and
           --                 GSA_price to two digit precision.
           --  CHG18058  modifited the l_eol_date to accept valid date and fromated
           DBMS_OUTPUT.PUT_LINE('In proc'); 
           
           L_CLIN                              := TRIM( repos_admin.table_api.strip_characters(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,1,L_DELIM,FALSE),'"'));
           L_CLIN                              := TRIM( repos_admin.table_api.strip_characters (L_CLIN, ''''));
          DBMS_OUTPUT.PUT_LINE('L_CLIN: ' || L_CLIN); 
           L_PROVIDER                 := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,2,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_PROVIDER: ' || L_PROVIDER);            
           L_PART_NUMBER                                  := TRIM(repos_admin.table_api.strip_characters (APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,3,L_DELIM,FALSE),'"'));
           L_PART_NUMBER                                  := TRIM( repos_admin.table_api.strip_characters (L_PART_NUMBER, ''''));
           DBMS_OUTPUT.PUT_LINE('L_PART_NUMBER: ' || L_PART_NUMBER);
           L_DISCOUNT_CLASS       := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,6,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_DISCOUNT_CLASS: ' || L_DISCOUNT_CLASS);
           L_DISCOUNT_SUBCLASS                          := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,7,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_DISCOUNT_SUBCLASS: ' || L_DISCOUNT_SUBCLASS);
           L_BMA_FLAG        := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,8,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_BMA_FLAG: ' || L_BMA_FLAG);
           L_ITEM_DESC                        := TRIM( repos_admin.table_api.strip_characters (APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,4,L_DELIM,FALSE),'"'));
           DBMS_OUTPUT.PUT_LINE('L_ITEM_DESC: ' || L_ITEM_DESC);
           L_ITEM_DESC                        := TRIM( repos_admin.table_api.strip_characters ( L_ITEM_DESC, ''''));
           L_DISCOUNT_PCT                  := REPLACE(TRANSLATE(TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,11,L_DELIM,FALSE)),'%-',' '),' ','');
           DBMS_OUTPUT.PUT_LINE('L_DISCOUNT_PCT: ' || L_DISCOUNT_PCT);
           L_LIST_PRICE               := TRIM(TO_CHAR(REPLACE(TRANSLATE(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,12,L_DELIM,FALSE),'$,-',' '),' ',''), '999999990.99'));
           DBMS_OUTPUT.PUT_LINE('L_LIST_PRICE: ' || L_LIST_PRICE);
           L_SEWP_PRICE                      := TRIM(TO_CHAR(REPLACE(TRANSLATE(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,15,L_DELIM,FALSE),'$-,',' '),' ',''), '999999990.99'));
           DBMS_OUTPUT.PUT_LINE('L_SEWP_PRICE: ' || L_SEWP_PRICE);
           L_GSA_PRICE                        := TRIM(TO_CHAR(REPLACE(TRANSLATE(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,10,L_DELIM,FALSE),'$-,',' '),' ',''), '999999990.99'));
           DBMS_OUTPUT.PUT_LINE('L_GSA_PRICE: ' || L_GSA_PRICE);
           L_EOL_DATE                         := TO_DATE(TO_CHAR(TO_DATE(TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,9,L_DELIM,FALSE)),'MM-DD-RRRR') ,'DD-MON-YYYY'));
           DBMS_OUTPUT.PUT_LINE('L_EOL_DATE: ' || L_EOL_DATE);
           L_CHECK_FLAG                      := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,1,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_CHECK_FLAG: ' || L_CHECK_FLAG);
           L_CLIN_TYPE                                  := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,16,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_CLIN_TYPE: ' || L_CLIN_TYPE);
--           L_EPEAT                               := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,15,L_DELIM,FALSE));
--           L_VISIBLE                             := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,16,L_DELIM,FALSE));
--           L_CUSTOM                           := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,17,L_DELIM,FALSE));
           L_BACKUPDATA                     := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,17,L_DELIM,FALSE));
           DBMS_OUTPUT.PUT_LINE('L_BACKUPDATA: ' || L_BACKUPDATA);
           L_TAA_FLAG                                  := TRIM(APPS.Wwt_Get_Delimited_Field@ERP.WORLD(P_LINE_IN,18,L_DELIM,TRUE));
           DBMS_OUTPUT.PUT_LINE('L_TAA_FLAG: ' || L_TAA_FLAG);

           -- CHG12332  TAA can be either C or NC
           -- CHG23142  Allow TAA value of NA
           -- If TAA is C, read that as N else (NC) read that as Y
            IF  L_TAA_FLAG =  'C' then
                   L_TAA_FLAG := 'N';

            ELSIF L_TAA_FLAG =  'NA' then
                   L_TAA_FLAG :=  'NA';

            ELSE
                   L_TAA_FLAG := 'Y';
              END IF;

           SELECT COUNT(*)
            INTO L_MANF_COUNT
            FROM REPOS_ADMIN.MANUFACTURER_MAPPING
           WHERE UPPER(MANUFACTURER) = UPPER(L_PROVIDER);

           -- CHG12332 added manufacturer not being null conditon to prevent sending Alert on Null lines that can be
           -- saved at the end of the TR file when we save file from .xls to .txt

          IF L_MANF_COUNT = 0  and L_PROVIDER is not null THEN -- IF 1

               SELECT COUNT(*)
                 INTO L_MANF_COUNT
                 FROM REPOS_ADMIN.WWT_NASA_SEWP
                WHERE UPPER(MANUFACTURER) = UPPER(L_PROVIDER);

               IF L_MANF_COUNT = 0 THEN -- IF 2

                    X_BAD_MANFS := L_CHECK_FLAG || ' - ' || L_PROVIDER || ', ';

               END IF; -- IF 2

          END IF; -- IF 1

          L_PRICING_CHECK := ROUND(TO_NUMBER(L_LIST_PRICE) - (TO_NUMBER(L_LIST_PRICE) * (.01 * TO_NUMBER(L_DISCOUNT_PCT))),2);
          L_PRICING_CHECK := TO_NUMBER(L_SEWP_PRICE) - L_PRICING_CHECK;
          DBMS_OUTPUT.PUT_LINE('L_LIST_PRICE: ' || L_LIST_PRICE); 
          DBMS_OUTPUT.PUT_LINE('L_DISCOUNT_PCT: ' || L_DISCOUNT_PCT); 
          DBMS_OUTPUT.PUT_LINE('L_PRICING_CHECK: ' || L_PRICING_CHECK);
          DBMS_OUTPUT.PUT_LINE('L_SEWP_PRICE: ' || L_SEWP_PRICE);

          IF L_CHECK_FLAG IS NOT NULL THEN -- IF 3

             IF L_CLIN IS NOT NULL THEN  -- IF CLINNO IS NOT NULL -- CHG18058 Not allowing to insert any null value for clin

               IF NVL(L_PRICING_CHECK,0) = 0 THEN  -- IF/ELSE 4


                -- CHG18058  Call to delete duplicate_clinno
                  DELETE_DUPLICATE_CLINNO (L_CLIN,L_RETURN_VALUE);

                  IF L_RETURN_VALUE = 2 THEN
                      X_RETURN_VALUE := L_RETURN_VALUE;
                      RETURN;
                  END IF;


                    X_RETURN_VALUE := 0;

                    INSERT INTO REPOS_ADMIN.WWT_NASA_SEWP
                             (HEADER_ID
                              ,CLINNO
                              ,MANUFACTURER
                              ,MPIN
                              ,CLASSIFICATION_CODE
                              ,SUBCLASS
                              ,BASEMANDAVAILCODE
                              ,ITEM_DESC
                              ,DISCOUNT_PCT
                              ,LIST_UNIT_PRICE
                              ,SEWP_PRICE
                              ,GSA_PRICE
                              ,EOL_DATE
                              ,PSM
                             ,EPEAT
                             ,VISIBLE
                             ,CUSTOM
                             ,BACKUPDATA
                             ,TAA
                             ,CREATION_DATE
                             ,CREATED_BY
                             ,LAST_UPDATE_DATE
                             ,LAST_UPDATED_BY
                             ) VALUES
                            ( L_HEADER_ID
                              ,L_CLIN
                               ,L_PROVIDER
                               ,L_PART_NUMBER
                               ,L_DISCOUNT_CLASS
                               ,L_DISCOUNT_SUBCLASS
                               ,L_BMA_FLAG
                               ,L_ITEM_DESC
                               ,L_DISCOUNT_PCT
                               ,L_LIST_PRICE
                               ,L_SEWP_PRICE
                               ,L_GSA_PRICE
                               ,L_EOL_DATE
                               ,L_CLIN_TYPE
                               ,null
                               ,null
                               ,null
                               ,L_BACKUPDATA
                               ,L_TAA_FLAG
                               ,P_PROCESS_DATE_TIME
                               ,'3444'
                               ,P_PROCESS_DATE_TIME
                               ,'3444');

               ELSE -- IF/ELSE 4

                    X_RETURN_VALUE := 1;

               END IF; -- IF/ELSE 4

            ELSE  -- ELSE IF CLINNO IS NULL

	                   X_RETURN_VALUE := 1;

            END IF;   -- END IF CLINNO IS NULL

          END IF; -- IF 3
          
EXCEPTION
     WHEN OTHERS THEN
           --  X_STATUS_RETURN_ALL := L_STATUS;
             X_RETURN_VALUE := 1;
          DBMS_OUTPUT.PUT_LINE('ERROR IN LOAD_REC:  '||SQLERRM); 
END LOAD_REC;

------------------------------------------------------------------------------
-- PROCEDURE MAIN                                                           --
-- CHG18058  added X_SEND_VAL out variable to main .  X_SEND_VAL value can be 0 (send the file) or -1 (do not send the file)
------------------------------------------------------------------------------
PROCEDURE MAIN( P_DATETIME                 IN VARCHAR2
               ,P_PROCESSDATETIME                IN VARCHAR2
               ,P_FILENAME                              IN VARCHAR2
               ,P_PROCESS                              IN VARCHAR2
              ,X_SEND_VAL                            OUT NUMBER)

IS

     L_PROCESS_DATE_TIME                                           DATE;
     L_LINE_IN                                                                VARCHAR2(2000);
     L_MY_FILE                                                               UTL_FILE.FILE_TYPE;
     L_MY_FILE_NAME                                                     VARCHAR2(100);
     L_MY_FILE_PATH                                                     VARCHAR2(100);
     L_FILENAME                                                            VARCHAR2(75);
     L_RETURN_VALUE                                                    NUMBER;
     L_DUP_CHECK                                                         NUMBER;
     L_REC_COUNT                                                        NUMBER;
     L_S3N                                                                    VARCHAR2(100);
     L_BAD_MANFS                                                        VARCHAR2(4000)        := NULL;
     L_BAD_MANFS_ALL                                                 VARCHAR2(4000)        := NULL;
     L_STATUS_RETURN_ALL                                         VARCHAR2(100)          := NULL;
     L_CLRF                                                                  VARCHAR2(10)           := CHR( 13 ) || CHR( 10 );   -- CHG12332  carriage return and linefeed  characters
     L_CREATE_FILE                                                       VARCHAR2(2)             := 'Y';

BEGIN
     --------------------------------------------------------------
     -- IF I_PROCESS = LOAD THEN WE WILL BE LOADING AN ITEM FILE --
     -- AND SENDING OUT THE TECHNICAL REFRESH REPORT             --
     --------------------------------------------------------------
     -- Setting the out variable to Y meaning of send out the email if all conditions hold true.


     IF P_PROCESS = 'LOAD' THEN

          SELECT COUNT(*)
            INTO L_DUP_CHECK
            FROM REPOS_ADMIN.WWT_NASA_SEWP_FILES
           WHERE FILENAME = P_FILENAME;

          IF L_DUP_CHECK = 0 THEN

               ---------------------------------------------
               -- SET THE PATH TO THE FILE AND FILENAME   --
               -- AND THEN OPEN IT FOR READING            --
               ---------------------------------------------
               L_PROCESS_DATE_TIME := TO_DATE(P_DATETIME,'yyyymmddhh24miss');

               L_FILENAME := P_PROCESSDATETIME || '_' || P_FILENAME;

                L_MY_FILE_PATH := 'WWT_DR_PD_NASA_ITEM_LOAD';

                L_MY_FILE := UTL_FILE.FOPEN(L_MY_FILE_PATH, L_FILENAME, 'r', 2000);

                ----------------------------------------------------------------
                -- GET FIRST LINE AND INGNORE IT BECAUSE IT's just the header --
                ----------------------------------------------------------------
                UTL_FILE.GET_LINE(L_MY_FILE, L_LINE_IN);

                LOOP
                    BEGIN

                         UTL_FILE.GET_LINE(L_MY_FILE, L_LINE_IN);

                    EXCEPTION
                         WHEN NO_DATA_FOUND THEN
                              DBMS_OUTPUT.PUT_LINE('END OF FILE REACHED.');
                              UTL_FILE.FCLOSE(L_MY_FILE);
                              EXIT;
                    END;
                    ---------------------------------------
                    -- CALL PROCEDURE TO LOAD THE RECORD --
                    ---------------------------------------
                    LOAD_REC(L_LINE_IN, L_PROCESS_DATE_TIME, L_RETURN_VALUE, P_FILENAME, L_BAD_MANFS); --, L_STATUS_RETURN_ALL);                  

                    L_BAD_MANFS_ALL := L_BAD_MANFS_ALL || L_BAD_MANFS;

                  -- CHG12332  All subject and email bodies for the all the status are fomated and modifed throught out main procedure.
                   IF LENGTH(L_BAD_MANFS_ALL) > 3750 THEN
                                   REPOS_ADMIN.Smtp_Send_Mail(G_EMAIL_FROM,
                                       NULL,
                                         'Manufacturer name(s) ' ||  L_BAD_MANFS_ALL || ' were just loaded against TR file name ' || P_FILENAME ||
                                          ', however they do not exist in the manufacturer mapping table and they need to be created. ',
                                          'NASA SEWP Manufacturers need to be mapped in file ' || P_FILENAME,
                                          G_EMAIL_LIST);
                                 L_BAD_MANFS_ALL := NULL;
                    END IF;


                    IF L_RETURN_VALUE = 1 or L_RETURN_VALUE = 2 THEN
                           L_CREATE_FILE     := 'N';
                           X_SEND_VAL        :=  -1;
                         EXIT;

                    END IF;

               END LOOP;



               IF L_RETURN_VALUE = 1 THEN

                    REPOS_ADMIN.Smtp_Send_Mail(G_EMAIL_FROM,
		                               NULL,
		                               'DISCOUNT PERCENTAGE OFF OF LIST PRICE DOES NOT EQUAL THE SEWP PRICE  ' ||
		                                L_CLRF ||  L_CLRF  ||
		                                ' OR '     ||
		                                L_CLRF ||  L_CLRF  ||
		                                'EOL DATE FORMAT ISSUE ' ||
		                                L_CLRF ||  L_CLRF  ||
		                                ' OR '  ||
		                                L_CLRF ||  L_CLRF  ||
		                                'CLINNO IS NULL FOR AT LEAST ONE RECORD. ' ,
		                                'FILE NOT LOADED: ' || P_FILENAME,
                                                 G_EMAIL_LIST);

                    ROLLBACK;
               ELSIF L_RETURN_VALUE = 2 THEN
                        REPOS_ADMIN.Smtp_Send_Mail(G_EMAIL_FROM,
                                               NULL,
                                                  L_CLRF ||
                                                 'THE FILE WAS NOT LOADED BECAUSE THERE WERE AND ERROR IN DELETING THE DUPLICATE CLINNO FROM NASA SEWP TABLE..',
                                                 'FILE NOT LOADED: ' || P_FILENAME,
                                                 G_EMAIL_LIST);
                    ROLLBACK;
               ELSE

                    SELECT COUNT(*)
                      INTO L_REC_COUNT
                      FROM REPOS_ADMIN.WWT_NASA_SEWP
                     WHERE CREATION_DATE = L_PROCESS_DATE_TIME;

                    IF L_REC_COUNT > 0 THEN



                         BEGIN

                              UPDATE REPOS_ADMIN.WWT_NASA_SEWP
                                 SET FILENAME = P_FILENAME
                               WHERE CREATION_DATE = L_PROCESS_DATE_TIME;

                              INSERT INTO REPOS_ADMIN.WWT_NASA_SEWP_FILES
                                       (FILENAME,
                                        STATUS,
                                        CREATION_DATE,
                                        CREATED_BY,
                                        LAST_UPDATE_DATE,
                                        LAST_UPDATED_BY) VALUES
                                       (P_FILENAME,
                                        'SUBMITTED',
                                        SYSDATE,
                                        '3444',
                                        SYSDATE,
                                        '3444');



                         EXCEPTION
                              WHEN OTHERS THEN
                                   NULL;

                         END;

                    END IF;

               END IF;


          ELSE

               REPOS_ADMIN.Smtp_Send_Mail(G_EMAIL_FROM,
                                          NULL,
                                          'THE FILE WAS NOT LOADED BECAUSE THIS FILENAME WAS PREVIOUSLY LOADED.',
                                          'FILE NOT LOADED: ' || P_FILENAME,
                                          G_EMAIL_LIST);
                L_CREATE_FILE         := 'N';
                X_SEND_VAL            := -1;
                 DBMS_OUTPUT.PUT_LINE('X_SEND_VAL IS : .' || X_SEND_VAL);
          END IF;

          IF L_CREATE_FILE = 'Y' THEN
                         -------------------------------------------------------
                         -- CALL THE PROCEDURE THAT WILL CREATE THE TR REPORT IN ARCHIVE DIRECTORY --
                         -------------------------------------------------------
                         CREATE_OUTPUT_FILE(P_DATETIME, L_PROCESS_DATE_TIME, P_PROCESSDATETIME, L_FILENAME, P_FILENAME);
                         X_SEND_VAL           := 0;
                         DBMS_OUTPUT.PUT_LINE('X_SEND_VAL IS : ' || X_SEND_VAL);
          END IF;

     ELSIF P_PROCESS = 'ORDERREPORT' THEN

          CREATE_ORDER_REPORT(P_DATETIME, NULL, NULL, L_S3N);
           X_SEND_VAL            := 0;

     ELSIF P_PROCESS = 'ORDERSTATUS' THEN

          CREATE_ORDER_STATUS(P_DATETIME);
           X_SEND_VAL            := 0;

     END IF;

     IF L_BAD_MANFS_ALL IS NOT NULL THEN
                  REPOS_ADMIN.Smtp_Send_Mail(G_EMAIL_FROM,
                                       NULL,
                                           'Manufacturer name(s) ' ||  L_BAD_MANFS_ALL || ' were just loaded against TR file name ' || P_FILENAME ||
                                           ', however they do not exist in the manufacturer mapping table and they need to be created. ',
                                          'NASA SEWP Manufacturers need to be mapped in file ' || P_FILENAME,
                                          G_EMAIL_LIST);
     END IF;

     DBMS_OUTPUT.PUT_LINE('X_SEND_VAL IS : ' || X_SEND_VAL);
EXCEPTION
     WHEN OTHERS THEN

               ROLLBACK;

               REPOS_ADMIN.Smtp_Send_Mail(G_EMAIL_FROM,
                                          NULL,
                                            'AN UNKNOWN PROBLEM OCCURED WITH THIS FILE AND NO ITEMS HAVE BEEN LOADED.  PLEASE MAKE SURE THAT THERE ARE NO QUOTES, EXTRA BLANK LINES, OR ANY STRANGE CHARACTERS IN THE FILE.  ALSO MAKE SURE THE COLUMNS ARE IN THE RIGHT ORDER.  THEN TRY AGAIN.',
                                            'FILE NOT LOADED: ' || P_FILENAME,
                                            G_EMAIL_LIST);

               DBMS_OUTPUT.PUT_LINE('THERE WAS A PROBLEM WITH THE ITEM LOAD.  PLEASE CHECK THE FILE AND TRY AGAIN.');

END MAIN;

END Wwt_Nasa_Sewp_Import;
/