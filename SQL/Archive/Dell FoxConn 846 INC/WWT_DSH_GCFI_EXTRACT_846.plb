/* Formatted on 4/30/2015 4:42:57 PM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.wwt_dsh_gcfi_extract_846
AS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_dsh_gcfi_extract_846.plb,v $, $Revision: 1.17 $, $Author: higelm $, $Date: 2013/08/09 13:17:16 $
   /*
    -----------------------------------------------------------------------------
    | This package extracts the data for the outbound Onhand Inventory Feed.    |
    | It extracts data into the wwt_inventory_advice_outbound. It is driven by  |
    | partner id. The data is deleted from the inventory advice table based on  |
    | a wwt_lookup WWT_EDI846_PURGEDAYS.  This process is driven by partner_id. |
    -----------------------------------------------------------------------------
                                                                                */

                                                                            /*
-----------------------------------------------------------------------------
|                                                                           |
| Developer  Date         CHG       Rev   Description                       |
| ---------  -----------  --------  ----  --------------------------------  |
| CROSSENS   25-OCT-2009  CHG14082  1.1   Initial Creation.                 |
|                                                                           |
| CROSSENS   03-NOV-2009  CHG14082  1.2   modified cop query in the cursor  |
|                                         l_inventory_data_cur              |
|                                                                           |
| CROSSENS   17-DEC-2009  CHG14596  1.3   added a replace around the part   |
|                                         number in the l_inventory_data_cur|
|                                         to remove FOX and RBX characters  |
|                                         from the part num                 |
| KARSTS     08-JAN-2010  CHG14621  1.4   Added archive_supplier_onhand_data|
|                                         procedure                         |
|                                         Changed cursor in extract_data to |
|                                         include supplier onhand data when |
|                                         proper partner id is supplier     |
| KARSTS     19-JAN-2010  CHG14871  1.5   Included available_raw_qty in     |
|                                         final calculation for supp onhand |
|                                         piece of main cursor              |
| CROSSENS   1-FEB-2010   CHG15014  1.6   added condition to exclude items  |
|                                         containing -CF in segment2        |
|                                                                           |
| CROSSENS   12-APR-2010  CHG15625  1.8   Modified cursor to select process |
|                                         group id 424 instead of 34.       |
|                                         This sql was provided by Kamal.   |
| KARSTS     14-SEP-2011  CHG20025  1.9   - Changed archive_supplier_onhand_data |
|                                         proc to include new cols location,|
|                                         organization_id,inventory_item_id,|
|                                         part_rev,status,message           |
|                                         - Added PURGE_AFTER_X_DAYS to     |
|                                         archive_supplier_onhand_data proc |
| KARSTS     12-OCT-2011  CHG20457  1.10  - Added location condition into   |
|                                         archiving procedure               |
|                                         - Modified l_inventory_data_cur   |
|                                         cursor definition to include      |
|                                         foxconn org ids when fetching     |
|                                         supp onhand data                  |
| KARSTS     14-OCT-2011  CHG20482  1.11  - Added wwt_util_constants.init to|
|                                         archive proc - this is needed due |
|                                         to proc now being called from WM  |
|                                         DSH_Inbound_Supplier_OnhandQty pkg|
|                                         - Removed call to archive proc    |
|                                         from extract_data proc            |
| KARSTS     17-OCT-2011  CHG20482  1.12  Removed commented code from pkg   |
| KARSTS     16-DEC-2011  CHG20900  1.13  Modified procedure                |
|                                         archive_supplier_onhand_data for  |
|                                         the following:                    |
|                                         - exclude Sundays from            |
|                                           PURGE_AFTER_X_DAYS calculation  |
|                                         - Transmit 0 qtys after age limit |
|                                           (instead of deleting)           |
|                                         - Exclude these bogus 0 qty       |
|                                           records from archive process    |
|                                         Modified main cursor in           |
|                                         extract_data procedure, added     |
|                                         final union clause to pull in     |
|                                         inventory allocated by gcfi item  |
|                                         alloc process.                    |
|                                         Added update statement to         |
|                                         extract_data procedure to set qty |
|                                         to 0 if item is flagged in item   |
|                                         master custom flexfield. This is  |
|                                         needed to resolve item deviation  |
|                                         issue for ECOs.                   |
| HIGELM     7-AUG-2013  CHG26886  1.14   Replaced segment2 values with NVL |
|                                                                        for possible xref value of part |
|                                                                        number       |
| GASSERTM  4-MAY-2015  CHG35683 1.15 Updated cursors to select records where | 
|                                                                      load date is < max_load_date.  Previously, |
|                                                                      cursor would take records where |
|                                                                      load_date <> max_load_date.  Also added |
|                                                                      some debugging. |
-----------------------------------------------------------------------------
                                                                             */

   g_user_id   NUMBER := wwt_util_get_user_id.GET_RUNTIME_USER_ID ('WWT_B2B');

   PROCEDURE archive_supplier_onhand_data
   IS
      CURSOR current_supp_file_date_cur
      IS
           SELECT supplier, location, MAX (file_load_date) load_date
             FROM WWT_DSH_SUPPLIER_ONHAND_QTY
         GROUP BY supplier, location;

      l_purge_days   PLS_INTEGER;
   BEGIN
      -- Initialize constants for the DSH_CONSTANTS lookup type and the GCFI EXTRACT 846 application --
      --------------------------
      wwt_util_constants.init ('DSH_CONSTANTS', 'GCFI EXTRACT 846');
      l_purge_days := wwt_util_constants.get_value ('PURGE_AFTER_X_DAYS');

      FOR current_supp_file_date_rec IN current_supp_file_date_cur
      LOOP
         apps.WWT_APPLICATION_LOGGER.put (
            P_APPLICATION_NAME   => 'WWT_DSH_GCFI_EXTRACT_846.archive_supplier_onhand',
            P_MODULE_NAME        => 'DSH Inbound Supplier Onhand',
            P_SEVERITY_LEVEL     => 0,
            P_LOG_MESSAGE        =>    'Cursor Row Data- Supplier: '
                                    || current_supp_file_date_rec.supplier
                                    || ' Location: '
                                    || current_supp_file_date_rec.location
                                    || ' Load_Date: '
                                    || current_supp_file_date_rec.load_date);

         INSERT INTO WWT_DSH_SUPPLIER_OH_QTY_ARCH (
                        SUPPLIER_QTY_OH_ID,
                        SUPPLIER,
                        VENDOR_ID,
                        DELL_PART_NUMBER,
                        AVAILABLE_FINISHED_GOODS_QTY,
                        AVAILABLE_RAW_QTY,
                        LOCATION,
                        ORGANIZATION_ID,
                        INVENTORY_ITEM_ID,
                        PART_REV,
                        STATUS,
                        MESSAGE,
                        FILENAME,
                        FILE_LOAD_DATE,
                        LAST_UPDATE_DATE,
                        LAST_UPDATED_BY,
                        CREATION_DATE,
                        CREATED_BY,
                        ARCHIVED_DATE,
                        ARCHIVED_BY)
            SELECT SUPPLIER_QTY_OH_ID,
                   SUPPLIER,
                   VENDOR_ID,
                   DELL_PART_NUMBER,
                   AVAILABLE_FINISHED_GOODS_QTY,
                   AVAILABLE_RAW_QTY,
                   LOCATION,
                   ORGANIZATION_ID,
                   INVENTORY_ITEM_ID,
                   PART_REV,
                   STATUS,
                   MESSAGE,
                   FILENAME,
                   FILE_LOAD_DATE,
                   LAST_UPDATE_DATE,
                   LAST_UPDATED_BY,
                   CREATION_DATE,
                   CREATED_BY,
                   SYSDATE,
                   g_user_id
              FROM WWT_DSH_SUPPLIER_ONHAND_QTY
             WHERE     supplier = current_supp_file_date_rec.supplier
                   AND NVL (location, 'NULL_LOCATION') =
                          NVL (current_supp_file_date_rec.location,
                               'NULL_LOCATION')
                   AND ( -- records that will be deleted because they have an older file load than the max load date
                           -- for the same supplier/location
                           file_load_date < --CHG35683
                              current_supp_file_date_rec.load_date
                        OR ( -- records that will be set to qty=0 because they have aged
                            NVL (MESSAGE, 'NULL_MESSAGE') <>
                                   wwt_util_constants.get_value (
                                      'AGED_FEED_MSG')
                            AND l_purge_days <
                                   NVL (
                                      (SELECT COUNT (*)
                                         FROM bom_calendar_dates
                                        WHERE     calendar_code = 'Standard'
                                              AND exception_set_id = -1
                                              AND calendar_date BETWEEN TRUNC (
                                                                           file_load_date)
                                                                    AND TRUNC (
                                                                           SYSDATE)
                                              AND TO_CHAR (calendar_date,
                                                           'DY') NOT IN ('SUN')),
                                      0)));

         apps.WWT_APPLICATION_LOGGER.put (
            P_APPLICATION_NAME   => 'WWT_DSH_GCFI_EXTRACT_846.archive_supplier_onhand',
            P_MODULE_NAME        => 'DSH Inbound Supplier Onhand',
            P_SEVERITY_LEVEL     => 0,
            P_LOG_MESSAGE        =>    'Cursor Row Data- Supplier: '
                                    || current_supp_file_date_rec.supplier
                                    || ' Location: '
                                    || current_supp_file_date_rec.location
                                    || ' Load_Date: '
                                    || current_supp_file_date_rec.load_date
                                    || '. ROWS INSERTED: '
                                    || SQL%ROWCOUNT);

         DELETE FROM WWT_DSH_SUPPLIER_ONHAND_QTY
               WHERE     supplier = current_supp_file_date_rec.supplier
                     AND NVL (location, 'NULL_LOCATION') =
                            NVL (current_supp_file_date_rec.location,
                                 'NULL_LOCATION')
                     AND file_load_date < --CHG35683
                            current_supp_file_date_rec.load_date;

         apps.WWT_APPLICATION_LOGGER.put (
            P_APPLICATION_NAME   => 'WWT_DSH_GCFI_EXTRACT_846.archive_supplier_onhand',
            P_MODULE_NAME        => 'DSH Inbound Supplier Onhand',
            P_SEVERITY_LEVEL     => 0,
            P_LOG_MESSAGE        =>    'Cursor Row Data- Supplier: '
                                    || current_supp_file_date_rec.supplier
                                    || ' Location: '
                                    || current_supp_file_date_rec.location
                                    || ' Load_Date: '
                                    || current_supp_file_date_rec.load_date
                                    || '. ROWS DELETED: '
                                    || SQL%ROWCOUNT);

         UPDATE WWT_DSH_SUPPLIER_ONHAND_QTY
            SET available_finished_goods_qty = 0,
                available_raw_qty = 0,
                filename = wwt_util_constants.get_value ('AGED_FEED_FILENAME'),
                MESSAGE = wwt_util_constants.get_value ('AGED_FEED_MSG'),
                last_update_date = SYSDATE,
                last_updated_by = g_user_id
          WHERE     supplier = current_supp_file_date_rec.supplier
                AND NVL (location, 'NULL_LOCATION') =
                       NVL (current_supp_file_date_rec.location,
                            'NULL_LOCATION')
                AND NVL (MESSAGE, 'NULL_MESSAGE') <>
                       wwt_util_constants.get_value ('AGED_FEED_MSG')
                AND l_purge_days <
                       NVL (
                          (SELECT COUNT (*)
                             FROM bom_calendar_dates
                            WHERE     calendar_code = 'Standard'
                                  AND exception_set_id = -1
                                  AND calendar_date BETWEEN TRUNC (
                                                               file_load_date)
                                                        AND TRUNC (SYSDATE)
                                  AND TO_CHAR (calendar_date, 'DY') NOT IN ('SUN')),
                          0);

         apps.WWT_APPLICATION_LOGGER.put (
            P_APPLICATION_NAME   => 'WWT_DSH_GCFI_EXTRACT_846.archive_supplier_onhand',
            P_MODULE_NAME        => 'DSH Inbound Supplier Onhand',
            P_SEVERITY_LEVEL     => 0,
            P_LOG_MESSAGE        =>    'Cursor Row Data- Supplier: '
                                    || current_supp_file_date_rec.supplier
                                    || ' Location: '
                                    || current_supp_file_date_rec.location
                                    || ' Load_Date: '
                                    || current_supp_file_date_rec.load_date
                                    || '. ROWS UPDATED: '
                                    || SQL%ROWCOUNT);
      END LOOP;
   END archive_supplier_onhand_data;


   PROCEDURE extract_data (x_errbuff         OUT VARCHAR2,
                           x_retcode         OUT NUMBER,
                           p_partner_id   IN     VARCHAR2)
   IS
      /*
       -----------------------------------------------------------------------------
       | This cursor selects the data to be inserted into the                      |
       | wwt_inventory_advice_outbound table.  It selects                          |
       | data from the mtl_onhand_quantities table. Then subtracts the demand data |
       | from apps.wwt_mtl_demand_v.  Then it subtracts data from the COP orders   |
       | that are being processed for that item as well.                           |
       | This cursor is driven by partner_id.                                      |
       -----------------------------------------------------------------------------
                                                                                   */
      CURSOR l_inventory_data_cur (
         cp_foxconn_org_ids   IN VARCHAR2)
      IS
         SELECT wwt_inventory_advice_ob_s.NEXTVAL transaction_id,
                main_data.partner_id,
                main_data.part_number,
                main_data.on_hand_qty onhand_quantity,
                NULL batch_id,
                'UNPROCESSED' process_status,
                NULL process_message,
                'EDI' communication_method,
                SYSDATE creation_date,
                g_user_id created_by,
                SYSDATE last_update_date,
                g_user_id last_updated_by
           FROM (  SELECT REPLACE (
                             REPLACE (
                                DECODE (
                                   oh.strip_rev,
                                   'Y', SUBSTR (
                                           NVL (mcr.cross_reference,
                                                msi.segment2),
                                           1,
                                           DECODE (
                                              INSTR (
                                                 NVL (mcr.cross_reference,
                                                      msi.segment2),
                                                 '-'),
                                              0, LENGTH (
                                                    NVL (mcr.cross_reference,
                                                         msi.segment2)),
                                                INSTR (
                                                   NVL (mcr.cross_reference,
                                                        msi.segment2),
                                                   '-')
                                              - 1)),
                                   NVL (mcr.cross_reference, msi.segment2)),
                                'FOX'),
                             'RBX')
                             part_number,
                          -- FoxConn does not maintain revisions, hence the need to eliminate the version from dell part#
                          oh.partner_id,
                          SUM (
                               NVL (oh.oh_qty, 0)
                             - NVL (dmd.dmd_qty, 0)
                             - NVL (cop.cop_qty, 0))
                             on_hand_qty
                     FROM (                 --- query to fetch current on-hand
                           SELECT   wlav.attribute2 partner_id,
                                    moq.inventory_item_id,
                                    moq.organization_id,
                                    wlav.attribute5 strip_rev, -- Strip revision flag
                                    SUM (moq.transaction_quantity) oh_qty
                               FROM mtl_onhand_quantities moq,
                                    wwt_lookups_active_v wlav
                              WHERE     moq.subinventory_code = wlav.attribute4
                                    AND moq.organization_id =
                                           TO_NUMBER (wlav.attribute3)
                                    AND wlav.attribute2 = p_partner_id
                                    AND wlav.lookup_type = 'WWT_EDI846_ONHAND'
                           GROUP BY wlav.attribute2,
                                    moq.inventory_item_id,
                                    moq.organization_id,
                                    wlav.attribute5) oh,
                          (              --- query to fetch current demand Qty
                           SELECT /*+ ordered use_nl(wmdv) */
                                 wmdv.inventory_item_id,
                                    wmdv.organization_id,
                                    SUM (wmdv.line_item_quantity) dmd_qty
                               FROM wwt_mtl_demand_v wmdv
                              WHERE     wmdv.completed_quantity = 0
                                    AND (  wmdv.primary_uom_quantity
                                         - wmdv.completed_quantity) > 0
                                    AND wmdv.reservation_type = 2
                                    AND wmdv.organization_id IN (SELECT wdolv.organization_id
                                                                   FROM wwt_dell_org_lookup_v wdolv)
                           GROUP BY wmdv.inventory_item_id,
                                    wmdv.organization_id) dmd,
                          ( --- query to fetch COP orders being processed for the same item
                           SELECT   msi.inventory_item_id,
                                    wool.ship_from_org_id organization_id,
                                    SUM (TO_NUMBER (wool.ordered_quantity))
                                       cop_qty
                               FROM mtl_system_items_b msi, -- Added  KN 11/03/09
                                    wwt_orig_order_headers wooh,
                                    wwt_orig_order_lines wool
                              WHERE     wool.header_id = wooh.header_id
                                    -- AND  wooh.SalesRep = 'Dell GCFI' -- modified by KN 03/30/2010
                                    AND wooh.status IN ('IN QUEUE',
                                                        'IN PROCESS',
                                                        'UNPROCESSED',
                                                        'ERROR')
                                    AND wooh.process_group_id = 424 -- -- modified by KN 03/30/2010 changed from 34 to 424
                                    AND wool.ship_from_org_id =
                                           msi.organization_id -- Added KN 11/03/09
                                    AND wool.inventory_item_segment_2 =
                                           msi.segment2   -- Added KN 11/03/09
                                    AND wool.inventory_item_segment_3 =
                                           msi.segment3   -- Added KN 11/03/09
                                    AND wool.inventory_item_segment_4 =
                                           msi.segment4   -- Added KN 11/03/09
                           GROUP BY msi.inventory_item_id,
                                    wool.ship_from_org_id
                           UNION ALL
                             SELECT msi.inventory_item_id,
                                    ----to_number(wsol.wwt_attribute6) inventory_item_id,
                                    wsol.ship_from_org_id organization_id,
                                    SUM (TO_NUMBER (wsol.ordered_quantity))
                                       cop_qty
                               FROM wwt_stg_order_headers_v wsoh,
                                    wwt_stg_order_lines wsol,
                                    mtl_system_items_b msi
                              WHERE     wsol.header_id = wsoh.header_id
                                    -- AND  wsoh.SalesRep = 'Dell GCFI'-- modified by KN 03/30/2010
                                    AND wsoh.status IN ('IN QUEUE',
                                                        'IN PROCESS',
                                                        'UNPROCESSED',
                                                        'ERROR')
                                    AND wsoh.process_group_id = 424 -- modified by KN 03/30/2010 changed from 34 to 424
                                    AND wsol.ship_from_org_id =
                                           msi.organization_id -- Added KN 11/03/09
                                    AND wsol.inventory_item_segment_2 =
                                           msi.segment2   -- Added KN 11/03/09
                                    AND wsol.inventory_item_segment_3 =
                                           msi.segment3   -- Added KN 11/03/09
                                    AND wsol.inventory_item_segment_4 =
                                           msi.segment4   -- Added KN 11/03/09
                           GROUP BY msi.inventory_item_id,
                                    wsol.ship_from_org_id) cop,
                          mtl_system_items_b msi,
                          mtl_cross_references mcr
                    WHERE     msi.organization_id = oh.organization_id
                          AND msi.inventory_item_id = oh.inventory_item_id
                          AND msi.organization_id = dmd.organization_id(+)
                          AND msi.inventory_item_id = dmd.inventory_item_id(+)
                          AND msi.organization_id = cop.organization_id(+)
                          AND msi.inventory_item_id = cop.inventory_item_id(+)
                          AND msi.segment2 NOT LIKE '%-CF%' -- added for CHG15014
                          AND mcr.inventory_item_id(+) = msi.inventory_item_id
                          AND mcr.organization_id IS NULL
                          AND mcr.cross_reference_type(+) =
                                 'DSH Foxconn Dell Xref'
                 GROUP BY oh.partner_id,
                          REPLACE (
                             REPLACE (
                                DECODE (
                                   oh.strip_rev,
                                   'Y', SUBSTR (
                                           NVL (mcr.cross_reference,
                                                msi.segment2),
                                           1,
                                           DECODE (
                                              INSTR (
                                                 NVL (mcr.cross_reference,
                                                      msi.segment2),
                                                 '-'),
                                              0, LENGTH (
                                                    NVL (mcr.cross_reference,
                                                         msi.segment2)),
                                                INSTR (
                                                   NVL (mcr.cross_reference,
                                                        msi.segment2),
                                                   '-')
                                              - 1)),
                                   NVL (mcr.cross_reference, msi.segment2)),
                                'FOX'),
                             'RBX')
                 UNION ALL
                   --- query to fetch supplier onhand data
                   SELECT NVL (mcr.cross_reference, supp_oh.dell_part_number)
                             part_number,
                          wl.partner_id,
                          SUM (
                               NVL (supp_oh.available_finished_goods_qty, 0)
                             + NVL (supp_oh.available_raw_qty, 0))
                             on_hand_qty
                     FROM WWT_DSH_SUPPLIER_ONHAND_QTY supp_oh,
                          (SELECT attribute2 partner_id
                             FROM wwt_lookups_active_v
                            WHERE     lookup_type = 'WWT_EDI846_ONHAND'
                                  AND attribute1 = '050'
                                  AND attribute2 = p_partner_id) wl,
                          mtl_cross_references mcr
                    WHERE     supp_oh.organization_id IN (SELECT COLUMN_VALUE
                                                            FROM TABLE (
                                                                    SELECT CAST (
                                                                              wwt_utilities.wwt_string_to_table_fun (
                                                                                 cp_foxconn_org_ids,
                                                                                 ',') AS wwt_string_to_table_type)
                                                                      FROM DUAL))
                          AND mcr.inventory_item_id(+) =
                                 supp_oh.inventory_item_id
                          AND mcr.organization_id IS NULL
                          AND mcr.cross_reference_type(+) =
                                 'DSH Foxconn Dell Xref'
                 GROUP BY wl.partner_id,
                          supp_oh.dell_part_number,
                          mcr.cross_reference
                 UNION ALL
                   SELECT cust.customer_item_number part_number,
                          wlav1.partner_id,
                          SUM (
                               DECODE (usg.usg_bucket,
                                       '4_Week', alloc.alloc_4_wk,
                                       '8_Week', alloc.alloc_8_wk,
                                       '13_Week', alloc.alloc_13_wk,
                                       '26_Week', alloc.alloc_26_wk,
                                       '52_Week', alloc.alloc_52_wk)
                             + NVL (alloc.consumed_qty, 0)
                             + NVL (alloc.fg_onhand_qty, 0))
                             on_hand_qty
                     FROM wwt_dsh_gcfi_item_alloc alloc,
                          wwt_dsh_gcfi_customer_item cust,
                          (SELECT attribute2 partner_id
                             FROM wwt_lookups_active_v
                            WHERE     lookup_type = 'WWT_EDI846_ONHAND'
                                  AND attribute1 = '030'
                                  AND attribute2 = p_partner_id) wlav1,
                          (SELECT attribute2 usg_bucket
                             FROM wwt_lookups_active_v wlav2
                            WHERE     lookup_type = 'GCFI_CONSTANTS'
                                  AND attribute1 = 'SCP_Usg_Bucket') usg
                    WHERE     alloc.mrp_site_id = 1
                          AND alloc.customer_item_id = cust.customer_item_id
                 GROUP BY wlav1.partner_id, cust.customer_item_number
                   HAVING SUM (
                               DECODE (usg.usg_bucket,
                                       '4_Week', alloc.alloc_4_wk,
                                       '8_Week', alloc.alloc_8_wk,
                                       '13_Week', alloc.alloc_13_wk,
                                       '26_Week', alloc.alloc_26_wk,
                                       '52_Week', alloc.alloc_52_wk)
                             + NVL (alloc.consumed_qty, 0)
                             + NVL (alloc.fg_onhand_qty, 0)) > 0) main_data;

      TYPE l_inventory_data_tabtype IS TABLE OF l_inventory_data_cur%ROWTYPE
         INDEX BY BINARY_INTEGER;

      l_inventory_data_tab       l_inventory_data_tabtype;
      --      l_onhand_too_low           EXCEPTION;
      l_number_of_days_to_keep   NUMBER;
      l_foxconn_org_ids          VARCHAR2 (4000);
   --      l_cursor_count             NUMBER := 0;
   BEGIN
      x_retcode := 0;
      wwt_util_constants.init ('DSH_CONSTANTS', 'GCFI EXTRACT 846');
      l_foxconn_org_ids := wwt_util_constants.get_value ('FOXCONN_ORG_IDS');

      /*
      -------------------------------------------------------------------------------------
      | Collect the inventory data from the outbound table.                               |
      -------------------------------------------------------------------------------------
                                                                                          */

      OPEN l_inventory_data_cur (l_foxconn_org_ids);

      FETCH l_inventory_data_cur BULK COLLECT INTO l_inventory_data_tab;

      apps.WWT_APPLICATION_LOGGER.put (
         P_APPLICATION_NAME   => 'WWT_DSH_GCFI_EXTRACT_846.extract_data',
         P_MODULE_NAME        => 'WWT_DSH_GCFI_EXTRACT_846',
         P_SEVERITY_LEVEL     => 0,
         P_LOG_MESSAGE        =>    'Cursor count is: '
                                 || l_inventory_data_cur%ROWCOUNT
                                 || ' from partner_id: '
                                 || p_partner_id);

      CLOSE l_inventory_data_cur;

      --      /*
      ---------------------------------------------------------------------------------------
      --| Select number of records in l_inventory_data_cur.
      --Then log in wwt_applications log                              |
      ---------------------------------------------------------------------------------------
      --                                                                                    */
      --
      --      BEGIN
      --         SELECT COUNT (*) INTO l_cursor_count FROM l_inventory_data_tab;
      --
      --         apps.WWT_APPLICATION_LOGGER.put (
      --            P_APPLICATION_NAME   => WWT_DSH_GCFI_EXTRACT_846.extract_data,
      --            P_MODULE_NAME        => WWT_DSH_GCFI_EXTRACT_846,
      --            P_SEVERITY_LEVEL     => 0,
      --            P_LOG_MESSAGE        => 'Cursor count is: ' || l_cursor_count);
      --
      --         SELECT attribute2
      --           INTO l_onhand_floor
      --           FROM apps.wwt_lookups_active_v
      --          WHERE attribute1 = 'onhand_count_floor';
      --      EXCEPTION
      --         WHEN OTHERS
      --         THEN
      --            x_retcode := 1;
      --            x_errbuff :=
      --                  'Unable to select record count/log record count due to SQLERRM: '
      --               || SUBSTR (SQLERRM, 1, 100);
      --      END;
      --
      --      IF l_cursor_count < l_onhand_floor
      --      THEN
      --         RAISE l_onhand_too_low;
      --      END IF;

      /*
      -------------------------------------------------------------------------------------
      | bulk insert the good records into the wwt_dsh_gcfi_onhand table                   |
      -------------------------------------------------------------------------------------
                                                                                          */
      FORALL k IN l_inventory_data_tab.FIRST .. l_inventory_data_tab.LAST
         INSERT INTO wwt_inventory_advice_outbound
              VALUES l_inventory_data_tab (k);


      /*
      -------------------------------------------------------------------------------------
      | set onhand qty to 0 for items which are flagged as ECO deviation in item master   |
      | custom dff table                                                                  |
      -------------------------------------------------------------------------------------
                                                                                          */
      UPDATE wwt_inventory_advice_outbound waio
         SET waio.onhand_quantity = 0
       WHERE     waio.process_status = 'UNPROCESSED'
             AND waio.partner_id = p_partner_id
             AND EXISTS
                    (SELECT 1
                       FROM wwt_dell_part_substring wdps,
                            wwt_mtl_system_items_dff dff
                      WHERE     wdps.part = waio.part_number
                            AND dff.source_key_id_1 = wdps.inventory_item_id
                            AND dff.source_key_id_2 = 101
                            AND dff.attribute1 = 'Y'
                            AND dff.context = 'DSH');

      /*
      -------------------------------------------------------------------------------------
      | delete old data from the wwt_inventory_advice_outbound table                      |
      | this is driven by the partner_id and the lookup type 'WWT_EDI846_PURGEDAYS'       |
      -------------------------------------------------------------------------------------
                                                                                          */

      BEGIN
         /*
         -------------------------------------------------------------------------------------
         | this select is not part of the delete statement so that if there are no records in|
         | the lookup type 'WWT_EDI846_PURGEDAYS' then we will be alerted by a warning       |
         -------------------------------------------------------------------------------------
                                                                                             */
         SELECT TO_NUMBER (wlav.attribute2)
           INTO l_number_of_days_to_keep
           FROM wwt_lookups_active_v wlav
          WHERE     lookup_type = 'WWT_EDI846_PURGEDAYS'
                AND attribute1 = p_partner_id;

         DELETE FROM wwt_inventory_advice_outbound
               WHERE     partner_id = p_partner_id
                     AND creation_date < SYSDATE - l_number_of_days_to_keep;
      EXCEPTION
         WHEN INVALID_NUMBER
         THEN
            x_retcode := 1;
            x_errbuff :=
                  'Unable to purge old records from wwt_inventory_advice_outbound because of invalid number of purge days in the WWT_EDI846_PURGEDAYS lookup for partner '
               || p_partner_id;
         WHEN NO_DATA_FOUND
         THEN
            x_retcode := 1;
            x_errbuff :=
                  'Unable to purge old records from wwt_inventory_advice_outbound because no data was found in the WWT_EDI846_PURGEDAYS lookup for partner '
               || p_partner_id;
         WHEN TOO_MANY_ROWS
         THEN
            x_retcode := 1;
            x_errbuff :=
                  'Unable to purge old records from wwt_inventory_advice_outbound because too many rows found in the WWT_EDI846_PURGEDAYS lookup for partner '
               || p_partner_id;
      END;

      COMMIT;
   EXCEPTION
      --      WHEN l_onhand_too_low
      --      THEN
      --         x_errbuff :=
      --               'Onhand cursor does not have enough rows.  Something bad happened!  Row Count: '
      --            || l_cursor_count;
      --         x_retcode := 2;
      --         ROLLBACK;
      WHEN OTHERS
      THEN
         x_errbuff :=
               'Unexpected error occurred in  wwt_dsh_gcfi_extract_846.extract_data '
            || SUBSTR (SQLERRM, 1, 100);
         x_retcode := 2;
         ROLLBACK;
   END extract_data;
END wwt_dsh_gcfi_extract_846;
/