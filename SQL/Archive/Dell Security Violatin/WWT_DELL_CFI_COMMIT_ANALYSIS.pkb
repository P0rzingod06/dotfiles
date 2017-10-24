/* Formatted on 5/29/2015 9:33:09 AM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.Wwt_Dell_Cfi_Commit_Analysis
IS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_dell_cfi_commit_analysis.plb,v $, $Revision: 1.14 $, $Author: rays $, $Date: 2011/08/08 20:43:32 $
   --
   --
   -- Purpose: Briefly explain the functionality of the package body
   --
   -- MODIFICATION HISTORY
   -- Person      Date       Version   RFC       Comments
   -- ---------   ------     -------   --------  ------------------------------------------
   -- Scallyt     06-04-2002                     Created
   -- scally      10-17-2002                     FOR multi-location changed c_get_costed_items CURSOR to utilize
   --                                            input parameter FOR location (vp_slc_location)
   -- scally      10-29-2002                     ASR 91108800 WWT_NASHVILLE
   -- Scallyt     01-16-2003                     Added Code FOR Reno
   -- scally      03-04-2003                     FOR PPL process
   -- sosuhk      09-06-2005                     Code change per ASR 91120411
   -- Nandlal     01-27-2006                     Austin MS changes made.
   -- Nandlal     02-01-2006                     Bug Fix FOR non costed org id.CCC 186500
   -- RolfesJ     02-21-2006                     11i conversion; added create_directory function.  Changed the way the
   --                                            fixed lot multiplier was determined per ASR 91121833
   -- Rolfesj     05-26-2006                     select attribute14 for request directory
   -- Ryana       12-01-2006                     Modified Demand validation logic
   -- AtoosaM     02-27-2007                     Modified main procedure added check for session run to
   --                                            prevent deadlock
   -- KarstS      04-14-2010 1.8      CHG15749   Enable Ink Cycle changes
   -- Crossens               1.9                 UNUSED
   -- Karst       04-21-2010 1.10     CHG15885   Corrected bug in derive_org_id function when decode returns -1,
   --                                            by adding GREATEST function.
   -- Karsts      07-15-2010 1.11     CHG16775   Changed c_get_noncosted_items cursor to not call derive_org_id,
   --                                            but rather use org_id from associated costed item
   -- Karsts      02-21-2011 1.12     CHG18513   - Added code at very end of main proc to null out module name
   --                                              from gv$session. Resolves bug where completed sessions are
   --                                              hanging in gv$session as Inactive after completion, sometimes
   --                                              for over 30 minutes. This behavoir was not seen before RAC
   --                                              migration
   --                                            - Added many debug statements throughout main procedure, as well as
   --                                              changed all dbms_output statements to wwt_upload_generic.log
   --                                            - Cleaned up formatting/indenting throughout
   --                                            - Removed g_date_now global variable, as it was not being used
   --                                            - Cleaned up some parameter names to adhere to standards
   --                                            - Removed some variables from main proc which were not being used
   -- Karsts     03-08-2011 1.13     CHG18696    - Re above entry (chg18513), also needed to add WHEN OTHERS
   --                                              exception handling, and null out module name inside exception.
   --                                              Sessions were still hanging when encountering unexpected error.
   --                                            - Added retcode and errbuff parameters to main procedure
   -- Rays       08-04-2011 1.14     CHG19910    - Updated get_sku_demand to take into account organization_id
   --                                              when it determines open demand for vendor sku.
   --Gassertm 04-02-2015 1.15   CHG35292 - Added Debug statements in main to help narrow down a security issue
   --                                                   with UTL_FILE.

   -- KARSTS 20100414 CHG15749 Moved all global variables and cursors from package spec to body
   -- GLOBAL VARIABLES

   CURSOR c_get_costed_items (
      cp_slc_location   IN VARCHAR2)
   IS
      SELECT DISTINCT
             wdcs.item_id,
             wdcs.slc_location,
             wdcs.factory_line,
             wdcs.dell_broker_org,
             wdcs.org_name,
             wdcs.collab_grp_name,
             wdcs.owner_url_type,
             wdcs.data_measure_name,
             wdcs.id,
             wdcs.quantity,
             wdcs.delivery_time,
             wscix.phantom,
             wscix.supplier,
             wscix.costed_flag,
             wscix.item_type,
             DERIVE_ORG_ID (wscix.item_type,
                            TO_NUMBER (wl.attribute1),
                            wdcs.slc_location)
                org_id,
             wscix.dell_vendor,
             wdcs.original_qty,
             wscix.dell_part_id,
             wscix.hub_type_code,
             wscix.supplier_sku_id
        FROM wwt_dell_commit_stg wdcs,
             wwt_lookups wl,
             wwt_supplier_cust_item_xref_v wscix
       WHERE     wdcs.item_id = wscix.dell_part
             AND wl.lookup_type(+) = 'WWT_DELL_INV_ORG_XREF'
             AND SUBSTR (wdcs.id,
                           INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id,
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         - 1) = wl.attribute4(+)
             AND wl.attribute2(+) = cp_slc_location
             AND wl.enabled_flag(+) = 'Y'
             AND NVL (wl.start_date_active(+), SYSDATE) <= TRUNC (SYSDATE)
             AND NVL (wl.end_date_active(+), SYSDATE + 1) > TRUNC (SYSDATE)
             AND SUBSTR (wdcs.id,
                           INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id,
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         - 1) = wscix.dell_vendor
             AND wscix.costed_flag = 'C'
             AND wdcs.slc_location = cp_slc_location
             AND wscix.hub_type_code = 'Std_Hub'
      UNION ALL
      SELECT DISTINCT
             wdcs.item_id,
             wdcs.slc_location,
             wdcs.factory_line,
             wdcs.dell_broker_org,
             wdcs.org_name,
             wdcs.collab_grp_name,
             wdcs.owner_url_type,
             wdcs.data_measure_name,
             wdcs.id,
             wdcs.quantity,
             wdcs.delivery_time,
             wscix.phantom,
             wscix.supplier,
             wscix.costed_flag,
             wscix.item_type,
             DERIVE_ORG_ID (wscix.item_type,
                            TO_NUMBER (wl.attribute1),
                            wdcs.slc_location)
                org_id,
             wscix.dell_vendor,
             wdcs.original_qty,
             wscix.dell_part_id,
             wscix.hub_type_code,
             wscix.supplier_sku_id
        FROM wwt_dell_commit_stg wdcs,
             wwt_lookups wl,
             wwt_supplier_cust_item_xref_v wscix
       WHERE     wdcs.item_id = wscix.dell_part
             AND wl.lookup_type(+) = 'WWT_DLP_INV_ORG_XREF'
             AND SUBSTR (wdcs.id,
                           INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id,
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         - 1) = wl.attribute4(+)
             AND wl.attribute2(+) = cp_slc_location
             AND wl.enabled_flag(+) = 'Y'
             AND NVL (wl.start_date_active(+), SYSDATE) <= TRUNC (SYSDATE)
             AND NVL (wl.end_date_active(+), SYSDATE + 1) > TRUNC (SYSDATE)
             AND SUBSTR (wdcs.id,
                           INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id,
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         - 1) = wscix.dell_vendor
             AND wscix.costed_flag = 'C'
             AND wdcs.slc_location = cp_slc_location
             AND wscix.hub_type_code = 'DLP'
      ORDER BY phantom;

   CURSOR c_get_noncosted_items (
      cp_get_costed_items_rec   IN c_get_costed_items%ROWTYPE,
      cp_slc_location           IN VARCHAR2)
   IS                            -- scally added 10-17-2002 for multi-location
      SELECT DISTINCT wscix.dell_part item_id,
                      cp_get_costed_items_rec.slc_location,
                      wdcs.factory_line,
                      cp_get_costed_items_rec.dell_broker_org,
                      cp_get_costed_items_rec.org_name,
                      cp_get_costed_items_rec.collab_grp_name,
                      cp_get_costed_items_rec.owner_url_type,
                      cp_get_costed_items_rec.data_measure_name,
                      wdcs.id,
                      wdcs.quantity,
                      cp_get_costed_items_rec.delivery_time,
                      wscix.phantom,
                      wscix.supplier,
                      wscix.costed_flag,
                      wscix.item_type,
                      cp_get_costed_items_rec.org_id,
                      wscix.dell_vendor,
                      wdcs.original_qty,
                      wscix.dell_part_id,
                      wscix.hub_type_code,
                      wscix.supplier_sku_id
        FROM wwt_dell_commit_stg wdcs, wwt_supplier_cust_item_xref_v wscix
       WHERE     wdcs.item_id(+) = wscix.dell_part
             AND SUBSTR (wdcs.id(+),
                           INSTR (wdcs.id(+),
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id(+),
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id(+),
                                  '+',
                                  1,
                                  2)
                         - 1) = wscix.dell_vendor
             AND wscix.phantom = cp_get_costed_items_rec.phantom
             AND wscix.supplier = cp_get_costed_items_rec.supplier
             AND wscix.costed_flag = 'NC'
             AND wdcs.slc_location(+) = cp_slc_location
             AND wscix.hub_type_code = 'Std_Hub'
      UNION ALL
      SELECT DISTINCT wscix.dell_part item_id,
                      cp_get_costed_items_rec.slc_location,
                      wdcs.factory_line,
                      cp_get_costed_items_rec.dell_broker_org,
                      cp_get_costed_items_rec.org_name,
                      cp_get_costed_items_rec.collab_grp_name,
                      cp_get_costed_items_rec.owner_url_type,
                      cp_get_costed_items_rec.data_measure_name,
                      wdcs.id,
                      wdcs.quantity,
                      cp_get_costed_items_rec.delivery_time,
                      wscix.phantom,
                      wscix.supplier,
                      wscix.costed_flag,
                      wscix.item_type,
                      cp_get_costed_items_rec.org_id,
                      wscix.dell_vendor,
                      wdcs.original_qty,
                      wscix.dell_part_id,
                      wscix.hub_type_code,
                      wscix.supplier_sku_id
        FROM wwt_dell_commit_stg wdcs, wwt_supplier_cust_item_xref_v wscix
       WHERE     wdcs.item_id(+) = wscix.dell_part
             AND SUBSTR (wdcs.id(+),
                           INSTR (wdcs.id(+),
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id(+),
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id(+),
                                  '+',
                                  1,
                                  2)
                         - 1) = wscix.dell_vendor
             AND wscix.phantom = cp_get_costed_items_rec.phantom     --'5U938'
             AND wscix.supplier = cp_get_costed_items_rec.supplier     --11922
             AND wscix.costed_flag = 'NC'
             AND wdcs.slc_location(+) = cp_slc_location
             AND wscix.hub_type_code = 'DLP';

   --MS version
   CURSOR c_get_supplier_xref (
      cp_get_costed_items_rec   IN c_get_costed_items%ROWTYPE)
   IS
        SELECT wscix.supplier_sku,
               wscix.supplier,
               wscix.supplier_sku_id,
               msi.organization_id org_id,
               SUM (oh.sku_oh_qty) sku_oh_qty,
               MIN (oh.date_rcvd) date_rcvd
          FROM (  SELECT moq.inventory_item_id,
                         moq.subinventory_code,
                         SUM (moq.transaction_quantity) sku_oh_qty,
                         MIN (moq.orig_date_received) date_rcvd
                    FROM mtl_onhand_quantities moq
                   WHERE moq.organization_id = cp_get_costed_items_rec.org_id
                GROUP BY moq.inventory_item_id, moq.subinventory_code) oh,
               mtl_secondary_inventories msi,
               wwt_supplier_cust_item_xref_v wscix
         WHERE     oh.inventory_item_id = wscix.supplier_sku_id
               AND oh.subinventory_code = msi.secondary_inventory_name
               AND msi.availability_type = 1
               AND msi.organization_id = cp_get_costed_items_rec.org_id
               AND wscix.costed_flag = 'C'
               AND wscix.dell_part = cp_get_costed_items_rec.item_id
               AND wscix.supplier = cp_get_costed_items_rec.supplier
      GROUP BY wscix.supplier_sku,
               wscix.supplier,
               wscix.supplier_sku_id,
               msi.organization_id
      ORDER BY MIN (oh.date_rcvd);

   --MS version

   CURSOR c_get_remaining_items (
      cp_slc_location   IN VARCHAR2)
   IS                            -- scally added 10-17-2002 for multi-location
      SELECT DISTINCT
             wdcs.item_id,
             wdcs.slc_location,
             wdcs.factory_line,
             wdcs.dell_broker_org,
             wdcs.org_name,
             wdcs.collab_grp_name,
             wdcs.owner_url_type,
             wdcs.data_measure_name,
             wdcs.id,
             wdcs.quantity,
             wdcs.delivery_time,
             wscix.phantom,
             wscix.supplier,
             wscix.costed_flag,
             wscix.item_type                                   --msi.item_type
                            ,
             NVL (
                TO_NUMBER (wl.attribute1),
                DECODE (wdcs.slc_location,
                        'WWT_AUSTIN', 689,
                        'WWT_AUSTIN_MS', 689,
                        'WWT_NASH', 691,
                        'WWT_NASHVILLE_MS', 691,
                        'WWT_RENO', 730,
                        'WWT_WS1', 881,
                        'WWT_WS1_MS', 881,
                        -1))
                org_id,
             wscix.dell_vendor,
             wdcs.original_qty -- scally added 10-16-2002 for fixed lot multiple
                              ,
             wscix.dell_part_id,
             wscix.hub_type_code,
             wscix.supplier_sku_id
        FROM wwt_dell_commit_stg wdcs,
             wwt_lookups wl,
             wwt_supplier_cust_item_xref_v wscix
       WHERE     wdcs.item_id = wscix.dell_part(+)
             AND wl.lookup_type(+) = 'WWT_DELL_INV_ORG_XREF'
             AND SUBSTR (wdcs.id,
                           INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id,
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         - 1) = wl.attribute4(+)
             AND wl.attribute2(+) = cp_slc_location
             AND wl.enabled_flag(+) = 'Y'
             AND NVL (wl.start_date_active(+), SYSDATE) <= TRUNC (SYSDATE)
             AND NVL (wl.end_date_active(+), SYSDATE + 1) > TRUNC (SYSDATE)
             AND SUBSTR (wdcs.id,
                           INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         + 1,
                           INSTR (wdcs.id,
                                  '-',
                                  1,
                                  2)
                         - INSTR (wdcs.id,
                                  '+',
                                  1,
                                  2)
                         - 1) = wscix.dell_vendor(+)
             AND wdcs.slc_location = cp_slc_location; -- scally 10-17-2002 for multi-location

   -- NOTE: this record is used for both costed and non-costed items so a common call to various procedures
   -- can be made. The fields in cursors c_get_costed_items, c_get_noncosted_items and get_remaining_items
   -- need to be kept in sync.

   item_rec        c_get_costed_items%ROWTYPE;

   --g_date_now         DATE;
   g_user_id       NUMBER
                      := wwt_util_get_user_id.GET_RUNTIME_USER_ID ('WEBMTHDS');
   g_employee_id   NUMBER := 6104;                  -- Webmethods Employee ID.
   g_facility      VARCHAR2 (50); -- scally added 10-17-2002 for multi-location

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Update Table with Fix Lot Multiple Quantity
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE upd_stg_with_flm (p_slc_location IN VARCHAR2)
   IS
      CURSOR c1_cur
      IS
         SELECT /*+ ORDERED */
               wdcs.item_id,
                wdcs.slc_location,
                wdcs.factory_line,
                wdcs.ID,
                wdcs.quantity,
                wdcs.delivery_time,
                wscix.supplier,
                wscix.supplier_sku,
                wscix.supplier_sku_id,
                NVL (msi.fixed_lot_multiplier, 0) flm,
                TO_NUMBER (wl.attribute1) org_id,
                wscix.dell_vendor
           FROM wwt_dell_commit_stg wdcs,
                wwt_supplier_cust_item_xref_v wscix,
                wwt_lookups wl,
                mtl_system_items_b msi
          WHERE     wdcs.item_id = wscix.dell_part
                AND wl.lookup_type(+) = 'WWT_DELL_INV_ORG_XREF'
                AND SUBSTR (wdcs.ID,
                              INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            + 1,
                              INSTR (wdcs.ID,
                                     '-',
                                     1,
                                     2)
                            - INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            - 1) = wl.attribute4(+)
                AND wl.attribute2(+) = wdcs.slc_location
                AND wl.enabled_flag(+) = 'Y'
                AND NVL (wl.start_date_active(+), SYSDATE) <= TRUNC (SYSDATE)
                AND NVL (wl.end_date_active(+), SYSDATE + 1) >
                       TRUNC (SYSDATE)
                AND msi.organization_id =
                       (CASE
                           WHEN wl.attribute1 IS NOT NULL
                           THEN
                              TO_NUMBER (wl.attribute1)
                           ELSE
                              (SELECT TO_NUMBER (wl1.attribute1)
                                 FROM wwt_lookups wl1
                                WHERE     wl1.lookup_type =
                                             'WWT_DELL_INV_ORG_XREF'
                                      AND wl1.attribute2 = wdcs.slc_location
                                      AND wl1.attribute6 = 'C')
                        END)
                AND wscix.supplier_sku = msi.segment2
                AND wscix.supplier = msi.segment1
                AND SUBSTR (wdcs.ID,
                              INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            + 1,
                              INSTR (wdcs.ID,
                                     '-',
                                     1,
                                     2)
                            - INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            - 1) = wscix.dell_vendor
                AND wscix.hub_type_code = 'Std_Hub'
         UNION ALL
         SELECT /*+ ORDERED */
               wdcs.item_id,
                wdcs.slc_location,
                wdcs.factory_line,
                wdcs.ID,
                wdcs.quantity,
                wdcs.delivery_time,
                wscix.supplier,
                wscix.supplier_sku,
                wscix.supplier_sku_id,
                NVL (msi.fixed_lot_multiplier, 0) flm,
                TO_NUMBER (wl.attribute1) org_id,
                wscix.dell_vendor
           FROM wwt_dell_commit_stg wdcs,
                wwt_supplier_cust_item_xref_v wscix,
                wwt_lookups wl,
                mtl_system_items_b msi
          WHERE     wdcs.item_id = wscix.dell_part
                AND wl.lookup_type(+) = 'WWT_DLP_INV_ORG_XREF'
                AND SUBSTR (wdcs.ID,
                              INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            + 1,
                              INSTR (wdcs.ID,
                                     '-',
                                     1,
                                     2)
                            - INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            - 1) = wl.attribute4(+)
                AND wl.attribute2(+) = wdcs.slc_location
                AND wl.enabled_flag(+) = 'Y'
                AND NVL (wl.start_date_active(+), SYSDATE) <= TRUNC (SYSDATE)
                AND NVL (wl.end_date_active(+), SYSDATE + 1) >
                       TRUNC (SYSDATE)
                AND msi.organization_id =
                       (CASE
                           WHEN wl.attribute1 IS NOT NULL
                           THEN
                              TO_NUMBER (wl.attribute1)
                           ELSE
                              (SELECT TO_NUMBER (wl1.attribute1)
                                 FROM wwt_lookups wl1
                                WHERE     wl1.lookup_type =
                                             'WWT_DLP_INV_ORG_XREF'
                                      AND wl1.attribute2 = wdcs.slc_location
                                      AND wl1.attribute6 = 'C')
                        END)
                AND wscix.supplier_sku = msi.segment2
                AND wscix.supplier = msi.segment1
                AND SUBSTR (wdcs.ID,
                              INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            + 1,
                              INSTR (wdcs.ID,
                                     '-',
                                     1,
                                     2)
                            - INSTR (wdcs.ID,
                                     '+',
                                     1,
                                     2)
                            - 1) = wscix.dell_vendor
                AND wscix.hub_type_code = 'DLP';

      l_flm            mtl_system_items_b.fixed_lot_multiplier%TYPE;
      l_new_quantity   wwt_dell_commit_stg.quantity%TYPE;
   BEGIN
      FOR c1_rec IN c1_cur
      LOOP
         l_flm := c1_rec.flm;
         l_new_quantity := c1_rec.quantity;

         IF l_flm = 0
         THEN
            SELECT NVL (fixed_lot_multiplier, 1)
              INTO l_flm
              FROM mtl_system_items_b
             WHERE     organization_id = 101
                   AND inventory_item_id = c1_rec.supplier_sku_id;
         END IF;

         IF c1_rec.quantity < l_flm
         THEN
            l_new_quantity := l_flm;
         ELSIF MOD (c1_rec.quantity, l_flm) <> 0
         THEN
            l_new_quantity := (TRUNC (c1_rec.quantity / l_flm) + 1) * l_flm;
         END IF;

         UPDATE wwt_dell_commit_stg
            SET original_qty = quantity, quantity = l_new_quantity
          WHERE     ID = c1_rec.ID
                AND item_id = c1_rec.item_id
                AND slc_location = c1_rec.slc_location
                AND factory_line = c1_rec.factory_line
                AND delivery_time = c1_rec.delivery_time;
      END LOOP;
   END upd_stg_with_flm;


   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Get all demAND FOR the item
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE get_demand (
      p_get_costed_items_rec   IN     c_get_costed_items%ROWTYPE,
      x_old_dmd                   OUT NUMBER,
      p_slc_location           IN     VARCHAR2)
   IS
   BEGIN
      SELECT SUM (on_order) on_order
        INTO x_old_dmd
        FROM (SELECT SUM (md.line_item_quantity - md.completed_quantity)
                        on_order
                FROM wwt_mtl_demand_v md,
                     mtl_system_items_b msi,
                     wwt_supplier_cust_item_xref_v wscix
               WHERE     md.organization_id = p_get_costed_items_rec.org_id
                     AND md.parent_demand_id IS NULL
                     AND md.inventory_item_id = msi.inventory_item_id
                     AND md.organization_id = msi.organization_id
                     AND wscix.supplier_sku_id = msi.inventory_item_id    --MS
                     AND p_get_costed_items_rec.org_id = msi.organization_id
                     AND wscix.dell_part = p_get_costed_items_rec.item_id
                     AND wscix.supplier = p_get_costed_items_rec.supplier
              UNION ALL
              SELECT SUM (wdccd.ordered_quantity) on_order
                FROM wwt_dsh_cfi_cop_demand_v wdccd
               WHERE     p_get_costed_items_rec.supplier_sku_id =
                            wdccd.vendor_sku_id                           --MS
                     AND p_get_costed_items_rec.org_id =
                            wdccd.ship_from_org_id
              UNION ALL                                                  --new
              SELECT SUM (wdccb.supplier_item_qty) on_order
                FROM wwt_dell_cfi_commit_build wdccb
               WHERE     wdccb.item_id = p_get_costed_items_rec.item_id
                     AND wdccb.supplier = p_get_costed_items_rec.supplier
                     AND (   wdccb.process_flag IS NULL
                          OR wdccb.process_flag IN ('RC', 'RA'))
                     AND wdccb.slc_location = p_slc_location);

      IF x_old_dmd IS NULL
      THEN
         x_old_dmd := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_old_dmd := 0;
   END get_demand;

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Get demAND FOR supplier item
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE get_sku_demand (
      x_supplier_xref_rec   IN OUT c_get_supplier_xref%ROWTYPE,
      x_sku_dmd                OUT NUMBER)
   IS
   BEGIN
      SELECT SUM (on_order) on_order
        INTO x_sku_dmd
        FROM (SELECT SUM (md.line_item_quantity - md.completed_quantity)
                        on_order
                FROM wwt_mtl_demand_v md, mtl_system_items_b msi
               WHERE     md.organization_id = x_supplier_xref_rec.org_id
                     AND md.parent_demand_id IS NULL
                     AND md.inventory_item_id = msi.inventory_item_id
                     AND md.organization_id = msi.organization_id
                     AND x_supplier_xref_rec.supplier_sku_id =
                            msi.inventory_item_id                         --MS
                     AND x_supplier_xref_rec.org_id = msi.organization_id
              UNION ALL
              SELECT SUM (wdccd.ordered_quantity) on_order
                FROM wwt_dsh_cfi_cop_demand_v wdccd
               WHERE     x_supplier_xref_rec.supplier_sku =
                            wdccd.vendor_part_segment2
                     AND x_supplier_xref_rec.supplier_sku_id =
                            wdccd.vendor_sku_id
                     AND x_supplier_xref_rec.org_id = wdccd.ship_from_org_id
              UNION ALL
              SELECT SUM (wdccb.supplier_item_qty) on_order
                FROM wwt_dell_cfi_commit_build wdccb
               WHERE     wdccb.supplier_item =
                            x_supplier_xref_rec.supplier_sku
                     AND wdccb.supplier = x_supplier_xref_rec.supplier
                     AND (   wdccb.process_flag IS NULL
                          OR wdccb.process_flag IN ('RC', 'RA'))
                     AND wdccb.organization_id = x_supplier_xref_rec.org_id);

      IF x_sku_dmd IS NULL
      THEN
         x_sku_dmd := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_sku_dmd := 0;
   END get_sku_demand;

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Get all on-hAND FOR the item
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE get_onhand (
      p_get_costed_items_rec   IN     c_get_costed_items%ROWTYPE,
      x_onhand                    OUT NUMBER)
   IS
   BEGIN
      SELECT SUM (moq.transaction_quantity)
        INTO x_onhand
        FROM mtl_onhand_quantities moq,
             mtl_secondary_inventories msi,
             mtl_system_items_b msi1,
             wwt_supplier_cust_item_xref_v wscix
       WHERE     moq.organization_id = p_get_costed_items_rec.org_id
             AND msi.organization_id = moq.organization_id
             AND moq.inventory_item_id = msi1.inventory_item_id
             AND msi.secondary_inventory_name = moq.subinventory_code
             AND msi.availability_type = 1
             AND wscix.supplier_sku_id = msi1.inventory_item_id           --MS
             AND p_get_costed_items_rec.org_id = msi1.organization_id
             AND wscix.dell_part = p_get_costed_items_rec.item_id
             AND wscix.supplier = p_get_costed_items_rec.supplier;

      IF x_onhand IS NULL
      THEN
         x_onhand := 0;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_onhand := 0;
   END get_onhand;

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Insert Costed Rows
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE insert_build_row (
      p_insert_build_rec     IN     item_rec%TYPE,
      p_commit_flag          IN     VARCHAR2,
      x_comments             IN OUT VARCHAR2,
      p_process_flag         IN     VARCHAR2,
      p_supplier_qty         IN     NUMBER,
      p_my_file              IN     UTL_FILE.FILE_TYPE,
      p_adj_qty              IN     NUMBER,
      p_fixed_lot_multiple   IN     NUMBER,
      p_supplier_sku         IN     VARCHAR2,
      P_onhand               IN     NUMBER)
   IS
      l_build_id       NUMBER;
      l_line_out       VARCHAR2 (2000);
      l_cnt            NUMBER;
      l_factory_line   p_insert_build_rec.factory_line%TYPE
                          := p_insert_build_rec.factory_line;
   BEGIN
      -- for reference - identification of bad factory line is being done in the cfi request shell script.
      SELECT COUNT (*)
        INTO l_cnt
        FROM wwt_lookups wl
       WHERE     LTRIM (RTRIM (wl.attribute1)) =
                    LTRIM (RTRIM (l_factory_line))
             AND wl.lookup_type = 'Dell Factory Locations'
             AND wl.enabled_flag = 'Y'
             AND TRUNC (NVL (wl.start_date_active, SYSDATE)) <=
                    TRUNC (SYSDATE)
             AND TRUNC (NVL (wl.end_date_active, SYSDATE + 1)) >
                    TRUNC (SYSDATE);

      IF l_cnt = 0
      THEN
         BEGIN
            SELECT attribute10
              INTO l_factory_line
              FROM wwt_lookups wl
             WHERE     wl.lookup_type IN ('WWT_DLP_INV_ORG_XREF',
                                          'WWT_DELL_INV_ORG_XREF')
                   AND wl.attribute9 = g_facility
                   AND wl.enabled_flag = 'Y'
                   AND TRUNC (NVL (wl.start_date_active, SYSDATE)) >=
                          TRUNC (SYSDATE)
                   AND TRUNC (NVL (wl.end_date_active, SYSDATE + 1)) <
                          TRUNC (SYSDATE)
                   AND ROWNUM = 1; -- Needed since attribute9 will be same FOR multiple records
         EXCEPTION
            WHEN OTHERS
            THEN
               x_comments :=
                  'Bad Factory Line(' || l_factory_line || ') ' || x_comments;
         END;
      END IF;

      SELECT wwt_dell_cfi_commit_build_seq.NEXTVAL INTO l_build_id FROM DUAL;

      INSERT INTO wwt_dell_cfi_commit_build (cfi_commit_build_id,
                                             slc_location,
                                             delivery_time,
                                             download_id,
                                             factory_line,
                                             phantom_item_id,
                                             item_id,
                                             item_type,
                                             quantity,
                                             fixed_lot_multiplier,
                                             costed_flag,
                                             supplier,
                                             supplier_item,
                                             supplier_item_qty,
                                             comments,
                                             process_flag,
                                             dell_broker_org,
                                             org_name,
                                             collab_grp_name,
                                             owner_url_type,
                                             date_measure_name,
                                             created_by,
                                             creation_date,
                                             last_updated_by,
                                             last_update_date,
                                             onhand_quantity,
                                             original_qty -- scally added 10-16-2002 FOR fixed lot multiple
                                                         ,
                                             organization_id) -- scally added 03-05-2003 FOR the PPL process
           VALUES (l_build_id,
                   p_insert_build_rec.slc_location,
                   p_insert_build_rec.delivery_time,
                   p_insert_build_rec.ID,
                   l_factory_line,
                   p_insert_build_rec.phantom,
                   p_insert_build_rec.item_id,
                   p_insert_build_rec.item_type,
                   p_insert_build_rec.quantity,
                   p_fixed_lot_multiple,
                   p_insert_build_rec.costed_flag,
                   p_insert_build_rec.supplier,
                   p_supplier_sku        --c_get_costed_items_rec.supplier_sku
                                 ,
                   NVL (p_supplier_qty, 0),
                   x_comments,
                   p_process_flag,
                   p_insert_build_rec.dell_broker_org,
                   p_insert_build_rec.org_name,
                   p_insert_build_rec.collab_grp_name,
                   p_insert_build_rec.owner_url_type,
                   p_insert_build_rec.data_measure_name,
                   g_user_id,
                   SYSDATE,
                   g_user_id,
                   SYSDATE,
                   p_onhand,
                   p_insert_build_rec.original_qty -- scally added 10-16-2002 FOR fixed lot multiple
                                                  ,
                   p_insert_build_rec.org_id); -- scally added 03-05-2003 FOR PPL process

      WWT_UPLOAD_GENERIC.LOG (
         3,
            TO_CHAR (SQL%ROWCOUNT)
         || ' rows inserted into wwt_dell_cfi_commit_build table');

      -- Write to the file to be used in Excel by the user
      l_line_out :=
            p_insert_build_rec.slc_location
         || ','
         || x_comments
         || ','
         || p_insert_build_rec.phantom
         || ',';
      l_line_out :=
            l_line_out
         || p_insert_build_rec.item_id
         || ','
         || p_onhand
         || ','
         || p_supplier_sku
         || ',';
      l_line_out :=
            l_line_out
         || p_insert_build_rec.original_qty
         || ','
         || p_supplier_qty
         || ',';
      l_line_out :=
            l_line_out
         || p_insert_build_rec.supplier
         || ','
         || p_insert_build_rec.item_type
         || ',';
      l_line_out :=
            l_line_out
         || p_fixed_lot_multiple
         || ','
         || p_insert_build_rec.costed_flag
         || ','
         || l_factory_line
         || ',';
      l_line_out := l_line_out || p_insert_build_rec.delivery_time || ',';
      l_line_out :=
            l_line_out
         || p_insert_build_rec.ID
         || ','
         || p_insert_build_rec.dell_broker_org
         || ',';
      l_line_out :=
            l_line_out
         || p_insert_build_rec.org_name
         || ','
         || p_insert_build_rec.collab_grp_name
         || ',';
      l_line_out :=
            l_line_out
         || p_insert_build_rec.owner_url_type
         || ','
         || p_insert_build_rec.data_measure_name
         || ',';
      l_line_out := l_line_out || l_build_id;

      IF UTL_FILE.IS_OPEN (p_my_file)
      THEN
         UTL_FILE.PUT_LINE (p_my_file, l_line_out);
      END IF;
   END insert_build_row;

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Delete commit staging records
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE delete_commit_stg (p_delete_rec IN item_rec%TYPE)
   IS
   BEGIN
      DELETE wwt_dell_commit_stg wdcs
       WHERE     item_id = p_delete_rec.item_id
             AND wdcs.ID = p_delete_rec.ID
             AND wdcs.slc_location = p_delete_rec.slc_location;

      WWT_UPLOAD_GENERIC.LOG (
         3,
            TO_CHAR (SQL%ROWCOUNT)
         || ' rows deleted from wwt_dell_commit_stg table');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END delete_commit_stg;

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- Get Fixed Lot Multiple
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE get_fixed_lot_multiple (
      p_inventory_item_id      IN     mtl_system_items_b.inventory_item_id%TYPE,
      p_org_id                 IN     mtl_system_items_b.organization_id%TYPE,
      x_fixed_lot_multiplier      OUT NUMBER)
   IS
   BEGIN
      SELECT NVL (fixed_lot_multiplier, 0)
        INTO x_fixed_lot_multiplier
        FROM mtl_system_items_b msi
       WHERE     p_inventory_item_id = msi.inventory_item_id              --MS
             AND p_org_id = msi.organization_id
             AND NVL (msi.fixed_lot_multiplier, 0) > 0                    --MS
             AND ROWNUM = 1;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         x_fixed_lot_multiplier := 0;
   END get_fixed_lot_multiple;

   -- KARSTS 20100414 CHG15749 New Function
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- IS_INKCYCLE_ITEM_TYPE
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   FUNCTION IS_INKCYCLE_ITEM_TYPE (p_item_type         IN     VARCHAR2,
                                   x_inventory_model      OUT VARCHAR2)
      RETURN BOOLEAN
   IS
   BEGIN
      SELECT attribute4
        INTO x_inventory_model
        FROM wwt_lookups_active_v
       WHERE     lookup_type = 'WWT_DSH_INKCYCLE_ITEM_TYPE'
             AND attribute1 = p_item_type;

      RETURN TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN FALSE;
   END IS_INKCYCLE_ITEM_TYPE;

   -- KARSTS 20100414 CHG15749 New Function
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- DERIVE_ORG_ID
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   FUNCTION derive_org_id (p_item_type   IN VARCHAR2,
                           p_in_org_id   IN NUMBER,
                           p_location    IN VARCHAR2)
      RETURN NUMBER
   IS
      l_inventory_model   VARCHAR2 (1);
      l_decode_org_id     NUMBER;
      l_out_org_id        NUMBER;
   BEGIN
      SELECT DECODE (p_location,
                     'WWT_AUSTIN', 689,
                     'WWT_AUSTIN_MS', 689,
                     'WWT_NASH', 691,
                     'WWT_NASHVILLE_MS', 691,
                     'WWT_RENO', 730,
                     'WWT_WS1', 881,
                     'WWT_WS1_MS', 881,
                     -1)
        INTO l_decode_org_id
        FROM DUAL;

      IF IS_INKCYCLE_ITEM_TYPE (p_item_type, l_inventory_model)
      THEN
         BEGIN
            SELECT v1.organization_id
              INTO l_out_org_id
              FROM wwt_dell_org_lookup_v v1
             WHERE     v1.consign_type = l_inventory_model
                   AND wwt_org_xref (v1.organization_id, 'CITY') =
                          (SELECT wwt_org_xref (v2.organization_id, 'CITY')
                             FROM wwt_dell_org_lookup_v v2
                            WHERE v2.organization_id =
                                     GREATEST (NVL (p_in_org_id, -1),
                                               l_decode_org_id));
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               l_out_org_id := l_decode_org_id;
         END;
      ELSE
         l_out_org_id := NVL (p_in_org_id, l_decode_org_id);
      END IF;

      RETURN l_out_org_id;
   END derive_org_id;

   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   -- MAIN
   --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
   PROCEDURE main (p_in_processdatetime   IN     VARCHAR2,
                   p_in_facility          IN     VARCHAR2,
                   x_retcode                 OUT NUMBER,
                   x_errbuff                 OUT VARCHAR2)
   IS
      v_old_dmd              NUMBER;
      v_onhand               NUMBER;
      v_comments             VARCHAR2 (500);
      v_comment_save         VARCHAR2 (500);
      v_commit_flag          VARCHAR2 (10);
      v_process_flag         VARCHAR2 (10);
      v_adj_qty              NUMBER;
      v_sku_dmd              NUMBER;
      v_fixed_lot_multiple   NUMBER;
      v_cum_oh_qty           NUMBER;
      v_rmng_qty             NUMBER;
      v_supplier_qty         NUMBER;
      v_complete_flag        VARCHAR2 (1);
      v_supplier_sku         VARCHAR2 (35);
      v_fix_mult_sku         VARCHAR2 (35);
      v_fix_mult_suppl       VARCHAR2 (50);
      v_fix_mult_org_id      NUMBER;
      v_count                NUMBER := -1;
      v_flag                 VARCHAR2 (1) := 'Y';
      v_sleep_count          NUMBER := 0;
      v_temp_count           NUMBER := 0;
      l_slc_location         wwt_dell_cfi_commit_build.slc_location%TYPE;
      l_line_out             VARCHAR2 (2000);
      l_my_file_name         VARCHAR2 (100)
         :=    NVL (p_in_processdatetime,
                    TO_CHAR (SYSDATE, 'YYYYMMDDHH24MI'))
            || '.txt';
      l_my_file_path         VARCHAR2 (100);
      l_my_file              UTL_FILE.FILE_TYPE;
      l_username             VARCHAR2 (100);
      l_osuser               VARCHAR2 (100);
      l_status_message       VARCHAR2 (4000);
      l_status               VARCHAR2 (100);
      l_http_response        VARCHAR2 (4000);
      l_os_command           VARCHAR2 (100);
      l_machine              gv$session.machine%TYPE;
      l_counter              NUMBER;
      l_num_retries          NUMBER;
      l_retry_wait           NUMBER;
      l_user_security        EXCEPTION;
      l_exceed_max_retries   EXCEPTION;
      l_curr_time                   VARCHAR2(200);

      PRAGMA EXCEPTION_INIT (l_user_security, -53203);
   BEGIN
      WWT_UPLOAD_GENERIC.LOG (3, 'BEGIN wwt_dell_cfi_commit_analysis.main');
      x_retcode := 0;

      -- 02-16-07  Check to see if WWT_DELL_CFI_COMMIT_CONFIRM process is already running if Yes then
      -- wait until running process is done.
      BEGIN
         SELECT COUNT (*)
           INTO v_temp_count
           FROM gv$session
          WHERE module = 'WWT_DELL_CFI_COMMIT_ANALYSIS';

         WWT_UPLOAD_GENERIC.LOG (
            3,
            TO_CHAR (v_temp_count) || ' current sessions running.');

         WHILE v_temp_count > 0
         LOOP
            DBMS_LOCK.sleep (seconds => 5.01);
            v_sleep_count := v_sleep_count + 1;

            SELECT COUNT (*)
              INTO v_temp_count
              FROM gv$session
             WHERE module = 'WWT_DELL_CFI_COMMIT_ANALYSIS';

            WWT_UPLOAD_GENERIC.LOG (
               3,
                  TO_CHAR (v_temp_count)
               || ' current sessions running. Waiting...'
               || TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));

            IF v_sleep_count = 360
            THEN
               v_flag := 'N';
               EXIT;
            END IF;
         END LOOP;
      END;

      IF v_flag = 'N'
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            0,
            'Load Process Aborted. Load will run next time');
      ELSE
         BEGIN
            DBMS_APPLICATION_INFO.set_module ('WWT_DELL_CFI_COMMIT_ANALYSIS',
                                              NULL);

            WWT_UPLOAD_GENERIC.LOG (0, 'STRING: ' || p_in_processdatetime);
            WWT_UPLOAD_GENERIC.LOG (0, 'LOCATION: ' || p_in_facility);

            /*
                  IF p_in_processdatetime IS NULL THEN
                     g_date_now := SYSDATE;
                  ELSE
                     g_date_now := TO_DATE(p_in_processdatetime,'YYYYMMDDHH24MI');
                  END IF;
            */

            g_facility := p_in_facility;

            SELECT attribute2, attribute14
              INTO l_slc_location, l_my_file_path
              FROM wwt_lookups_active_v
             WHERE     lookup_type IN ('WWT_DLP_INV_ORG_XREF',
                                       'WWT_DELL_INV_ORG_XREF')
                   AND LOWER (attribute9) = LOWER (g_facility)
                   AND ROWNUM = 1;

            WWT_UPLOAD_GENERIC.LOG (0, 'l_slc_location = ' || l_slc_location);
            WWT_UPLOAD_GENERIC.LOG (0, 'l_my_file_path = ' || l_my_file_path);

            --Retrieve number of retries and the delay between each retry from lookup.
            BEGIN
               SELECT attribute1, attribute2
                 INTO l_num_retries, l_retry_wait
                 FROM apps.wwt_lookups_active_v
                WHERE lookup_type = 'DSH_UTL_FILE_RETRIES';
            EXCEPTION
               WHEN OTHERS
               THEN
                  WWT_UPLOAD_GENERIC.LOG (
                     2,
                        'Error selecting number of retires and wait from lookup '
                     || SQLERRM);
                  x_retcode := 2;
                  x_errbuff := SQLERRM;
            END;

            FOR l_counter IN 1 .. l_num_retries
            LOOP
               BEGIN
                  SAVEPOINT user_security;

                  --If on 5th retry, then throw exception
                  IF l_counter = l_num_retries
                  THEN
                     RAISE l_exceed_max_retries;
                  END IF;

                  --increment utl_file retries
                  l_my_file :=
                     UTL_FILE.FOPEN (l_my_file_path, l_my_file_name, 'w');

                  --Used soley for debugging purposes
                  BEGIN
                     SELECT username, osuser, machine
                       INTO l_username, l_osuser, l_machine
                       FROM gv$session
                      WHERE     module = 'WWT_DELL_CFI_COMMIT_ANALYSIS'
                            AND ROWNUM = 1;

                     WWT_UPLOAD_GENERIC.LOG (0,
                                             'l_username = ' || l_username);
                     WWT_UPLOAD_GENERIC.LOG (0, 'l_osuser = ' || l_osuser);
                     WWT_UPLOAD_GENERIC.LOG (0, 'l_machine = ' || l_machine);

                     l_os_command :=
                           'ls -l /ftpdata/WWTHCDEV.dell_cfi_request/nashville/outbox/'
                        || l_my_file_name;

                     WWT_UPLOAD_GENERIC.LOG (
                        0,
                        'l_os_command = ' || l_os_command);

                     APPS.WWT_WM_UTILITIES.CALL_WM_SERVICE (
                        P_SERVICE_NAME     => 'wwtpub.unix:shRunCommand',
                        P_PARM1            => l_os_command,
                        P_PARM2            => NULL,
                        P_PARM3            => NULL,
                        P_PARM4            => NULL,
                        P_PARM5            => NULL,
                        P_PARM6            => NULL,
                        P_PARM7            => NULL,
                        P_PARM8            => NULL,
                        P_PARM9            => NULL,
                        P_PARM10           => NULL,
                        X_STATUS           => l_status,
                        X_STATUS_MESSAGE   => l_status_message,
                        X_HTTP_RESPONSE    => l_http_response,
                        P_WM_ENV           => '95B');

                     WWT_UPLOAD_GENERIC.LOG (
                        0,
                        'l_status_message = ' || l_status_message);
                     WWT_UPLOAD_GENERIC.LOG (
                        0,
                        'l_http_response = ' || l_http_response);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        WWT_UPLOAD_GENERIC.LOG (
                           0,
                              'Error in retrieving username information/file info: '
                           || SQLERRM);
                  END;

                  WWT_UPLOAD_GENERIC.LOG (
                     0,
                     'File has been opened: ' || l_my_file_name);
                  -- Create headers in output table (If these change, upload center needs to change also)
                  l_line_out :=
                     'SLC_LOCATION,COMMENTS,PHANTOM_ITEM_ID,ITEM_ID,ONHAND,SUPPLIER_ITEM,REQ_QTY,';
                  l_line_out :=
                        l_line_out
                     || 'SUPPLIER_ITEM_QTY,SUPPLIER,ITEM_TYPE,FIXED_LOT_MULTIPLIER,COSTED_FLAG,';
                  l_line_out :=
                        l_line_out
                     || 'FACTORY_LINE,DELIVERY_TIME,DOWNLOAD_ID,DELL_BROKER_ORG,';
                  l_line_out :=
                        l_line_out
                     || 'ORG_NAME,COLLAB_GRP_NAME,OWNER_URL_TYPE,DATE_MEASURE_NAME,';
                  l_line_out := l_line_out || 'CFI_COMMIT_BUILD_ID';
                  UTL_FILE.PUT_LINE (l_my_file, l_line_out);
                  EXIT;
               EXCEPTION
                  WHEN l_user_security
                  THEN
                     ROLLBACK TO user_security;
                     WWT_UPLOAD_GENERIC.LOG (
                        1,
                           'Woo!  We caught the user security error.  Lets try again from the beginning with a '
                        || l_retry_wait
                        || ' second delay.');

                     DBMS_LOCK.SLEEP (l_retry_wait);
                  WHEN l_exceed_max_retries
                  THEN
                     WWT_UPLOAD_GENERIC.LOG (
                        2,
                           'Error in UTL_FILE.FOPEN/PUT_LINE or may have exceeded user_security retries: '
                        || SQLERRM);
                     x_retcode := 2;
                     x_errbuff := SQLERRM;
               END;
            END LOOP;


            --------------- Update quantity in WWT_DELL_COMMIT_STG using the fixed lot multiple ---------------
            WWT_UPLOAD_GENERIC.LOG (3, 'Calling upd_stg_with_flm...');
            upd_stg_with_flm (l_slc_location);
            WWT_UPLOAD_GENERIC.LOG (0, 'Done with upd_stg_with_flm');

           --------------- Let's get started ---------------
           <<COSTED_ITEMS_LOOP>>
            FOR c_get_costed_items_rec IN c_get_costed_items (l_slc_location)
            LOOP
               WWT_UPLOAD_GENERIC.LOG (
                  3,
                     'Starting c_get_costed_items loop for item id '
                  || TO_CHAR (c_get_costed_items_rec.item_id)
                  || ' and commit build id '
                  || NVL (c_get_costed_items_rec.id, 'NULL'));

               BEGIN
                  v_comments := NULL;
                  v_fix_mult_sku := NULL;
                  v_fix_mult_suppl := NULL;
                  v_fix_mult_org_id := NULL;

                  --------------- Check to see if this file has already been processed ---------------

                  SELECT COUNT (*)
                    INTO v_count
                    FROM wwt_dell_cfi_commit_build
                   WHERE     slc_location =
                                c_get_costed_items_rec.slc_location
                         AND TO_CHAR (delivery_time, 'YYYYMMDDHH24MISS') =
                                TO_CHAR (
                                   c_get_costed_items_rec.delivery_time,
                                   'YYYYMMDDHH24MISS')
                         AND download_id = c_get_costed_items_rec.ID
                         AND process_flag <> 'RA';

                  WWT_UPLOAD_GENERIC.LOG (
                     3,
                        'count of dup files already processed = '
                     || TO_CHAR (v_count));

                  IF v_count > 0
                  THEN
                     v_process_flag := 'DUP';
                     v_comments := 'DUPLICATE! ALREADY PROCESSED!!';
                  ELSE
                     v_process_flag := 'RA';
                  END IF;

                  --------------- Delete Rows Already there because they want to do it again ---------------
                  DELETE wwt_dell_cfi_commit_build
                   WHERE     slc_location =
                                c_get_costed_items_rec.slc_location
                         AND TO_CHAR (delivery_time, 'YYYYMMDDHH24MISS') =
                                TO_CHAR (
                                   c_get_costed_items_rec.delivery_time,
                                   'YYYYMMDDHH24MISS')
                         AND download_id = c_get_costed_items_rec.ID
                         AND process_flag = 'RA';

                  WWT_UPLOAD_GENERIC.LOG (
                     3,
                        TO_CHAR (SQL%ROWCOUNT)
                     || ' dup rows deleted from wwt_dell_cfi_commit_build');

                  --------------- Get all demAND AND on-hAND ---------------
                  get_demand (c_get_costed_items_rec,
                              v_old_dmd,
                              l_slc_location);
                  WWT_UPLOAD_GENERIC.LOG (0,
                                          'demAND : ' || TO_CHAR (v_old_dmd));
                  get_onhand (c_get_costed_items_rec, v_onhand);
                  WWT_UPLOAD_GENERIC.LOG (0,
                                          'onhAND : ' || TO_CHAR (v_onhand));

                  --------------- We have nothing to commit ---------------
                  IF NVL (v_onhand, 0) - NVL (v_old_dmd, 0) <= 0
                  THEN
                     WWT_UPLOAD_GENERIC.LOG (0, 'nothing to commit');

                     v_commit_flag := 'N';
                     v_complete_flag := 'Y';
                     v_comments :=
                        v_comments || ' ' || 'Nothing left to commit';
                     v_adj_qty := 0;
                     v_supplier_qty := 0;

                     WWT_UPLOAD_GENERIC.LOG (3,
                                             'Calling insert_build_row...');
                     insert_build_row (
                        c_get_costed_items_rec,
                        v_commit_flag,
                        v_comments,
                        v_process_flag,
                        v_supplier_qty,
                        l_my_file,
                        NULL,
                        0,
                        NULL,
                        (NVL (v_onhand, 0) - NVL (v_old_dmd, 0)));

                     WWT_UPLOAD_GENERIC.LOG (0, 'Inserted build row');

                     WWT_UPLOAD_GENERIC.LOG (3,
                                             'Calling delete_commit_stg...');
                     delete_commit_stg (c_get_costed_items_rec);
                     WWT_UPLOAD_GENERIC.LOG (0, 'Deleted staging row');

                     --------------- Get Phantom parts to write to table ---------------
                     WWT_UPLOAD_GENERIC.LOG (0, 'Calling non costed LOOP');

                    <<NONCOSTED_ITEMS_LOOP_1>>
                     FOR c_get_noncosted_items_rec
                        IN c_get_noncosted_items (c_get_costed_items_rec,
                                                  l_slc_location)
                     LOOP
                        WWT_UPLOAD_GENERIC.LOG (
                           3,
                              'Starting c_get_noncosted_items loop for item id '
                           || TO_CHAR (c_get_noncosted_items_rec.item_id)
                           || ' and commit build id '
                           || NVL (c_get_noncosted_items_rec.id, 'NULL'));

                        v_comment_save := v_comments;

                        IF (    NVL (c_get_noncosted_items_rec.quantity, 0) =
                                   0
                            AND INSTR (v_comments,
                                       'Phantom has only costed component') =
                                   0)
                        THEN
                           v_comments :=
                                 v_comments
                              || '; Phantom has only costed component';
                        END IF;

                        IF c_get_noncosted_items_rec.ID IS NULL
                        THEN
                           --d.knott 08-OCT-02:leading spaces are critical FOR the commmit_confirm process after this,
                           --                  if you change the 0's you need to modify the commit confirm package body
                           c_get_noncosted_items_rec.ID :=
                                 '0000000+'
                              || SUBSTR (
                                    c_get_costed_items_rec.ID,
                                      INSTR (c_get_costed_items_rec.ID, '+')
                                    + 1,
                                      INSTR (c_get_costed_items_rec.ID, '-')
                                    - 9)
                              || '-PO+0000|0000-VID';

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Set ID = ' || c_get_noncosted_items_rec.ID);
                        END IF;

                        WWT_UPLOAD_GENERIC.LOG (
                           3,
                           'Calling insert_build_row...');
                        insert_build_row (c_get_noncosted_items_rec,
                                          v_commit_flag,
                                          v_comments,
                                          v_process_flag,
                                          v_supplier_qty,
                                          l_my_file,
                                          NULL,
                                          0,
                                          NULL,
                                          0);

                        WWT_UPLOAD_GENERIC.LOG (3, 'Inserted build row');

                        WWT_UPLOAD_GENERIC.LOG (
                           3,
                           'Calling delete_commit_stg...');
                        delete_commit_stg (c_get_noncosted_items_rec);
                        WWT_UPLOAD_GENERIC.LOG (3, 'Deleted staging row');
                        v_comments := v_comment_save;
                     END LOOP NONCOSTED_ITEMS_LOOP_1;

                     WWT_UPLOAD_GENERIC.LOG (0, 'non costed LOOP done');
                  --------------- We can commit something ---------------
                  ELSE                                 -- onhand - old_dmd > 0
                     WWT_UPLOAD_GENERIC.LOG (0, 'Inventory available...');
                     v_cum_oh_qty := 0;
                     v_rmng_qty := NVL (c_get_costed_items_rec.quantity, 0);
                     v_complete_flag := 'N';

                    --------------- LOOP here to get supplier on hand ---------------
                    <<SUPP_XREF_LOOP>>
                     FOR c_get_supplier_xref_rec
                        IN c_get_supplier_xref (c_get_costed_items_rec)
                     LOOP
                        WWT_UPLOAD_GENERIC.LOG (
                           3,
                              'Starting get_supplier_xref loop for supplier sku '
                           || c_get_supplier_xref_rec.supplier_sku);
                        WWT_UPLOAD_GENERIC.LOG (
                           0,
                           'getting sku supply....supplier xref');
                        WWT_UPLOAD_GENERIC.LOG (
                           0,
                              'sku oh :'
                           || TO_CHAR (
                                 NVL (c_get_supplier_xref_rec.sku_oh_qty, 0)));

                        v_cum_oh_qty :=
                             v_cum_oh_qty
                           + NVL (c_get_supplier_xref_rec.sku_oh_qty, 0);
                        v_supplier_sku := c_get_supplier_xref_rec.supplier_sku;
                        v_fix_mult_sku := c_get_supplier_xref_rec.supplier_sku;
                        v_fix_mult_suppl := c_get_supplier_xref_rec.supplier;
                        v_fix_mult_org_id := c_get_supplier_xref_rec.org_id;

                        WWT_UPLOAD_GENERIC.LOG (
                           0,
                              'Sku : '
                           || v_supplier_sku
                           || ' cum oh :'
                           || TO_CHAR (v_cum_oh_qty));

                        IF   NVL (v_onhand, 0)
                           - NVL (v_old_dmd, 0)
                           - NVL (c_get_costed_items_rec.quantity, 0) < 0
                        THEN
                           v_adj_qty := NVL (v_onhand, 0) - NVL (v_old_dmd, 0);
                        ELSE
                           v_adj_qty :=
                              NVL (c_get_costed_items_rec.quantity, 0);
                        END IF;

                        --MS v_adj_qty IS lesser of available after old demAND  or this demand
                        WWT_UPLOAD_GENERIC.LOG (3,
                                                'Calling get_sku_demand...');
                        get_sku_demand (c_get_supplier_xref_rec, v_sku_dmd);
                        WWT_UPLOAD_GENERIC.LOG (3, 'Calling get_demand...');
                        get_demand (c_get_costed_items_rec,
                                    v_old_dmd,
                                    l_slc_location);                     --new
                        WWT_UPLOAD_GENERIC.LOG (
                           0,
                              'sku demand: '
                           || TO_CHAR (v_sku_dmd)
                           || ' demAND : '
                           || TO_CHAR (v_old_dmd));

                        IF    (NVL (v_cum_oh_qty, 0) <= NVL (v_old_dmd, 0))
                           OR (NVL (v_sku_dmd, 0) >
                                  NVL (c_get_supplier_xref_rec.sku_oh_qty, 0))
                        THEN
                           WWT_UPLOAD_GENERIC.LOG (
                              0,
                              'not enough...go to next record');
                        ELSIF (      NVL (v_cum_oh_qty, 0)
                                   - NVL (v_old_dmd, 0)
                                   - NVL (v_rmng_qty, 0) >= 0
                               AND v_complete_flag = 'N')
                        THEN
                           --enough matl to satisfy Dell request
                           WWT_UPLOAD_GENERIC.LOG (
                              0,
                              'enough material...process order');
                           v_commit_flag := 'Y';

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling get_fixed_lot_multiplier...');
                           get_fixed_lot_multiple (
                              c_get_supplier_xref_rec.supplier_sku_id,
                              c_get_supplier_xref_rec.org_id,
                              v_fixed_lot_multiple);

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling insert_build_row...');
                           insert_build_row (
                              c_get_costed_items_rec,
                              v_commit_flag,
                              v_comments,
                              v_process_flag,
                              v_rmng_qty,
                              l_my_file,
                              NULL,
                              v_fixed_lot_multiple,
                              v_supplier_sku,
                              (v_cum_oh_qty - NVL (v_old_dmd, 0) - v_rmng_qty));

                           WWT_UPLOAD_GENERIC.LOG (3, 'Inserted build row');

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling delete_commit_stg...');
                           delete_commit_stg (c_get_costed_items_rec);
                           WWT_UPLOAD_GENERIC.LOG (3, 'Deleted staging row');

                           WWT_UPLOAD_GENERIC.LOG (
                              0,
                              'insert build AND delete stg done..starting non costed LOOP');

                          <<NONCOSTED_ITEMS_LOOP_2>>
                           FOR c_get_noncosted_items_rec
                              IN c_get_noncosted_items (
                                    c_get_costed_items_rec,
                                    l_slc_location)
                           LOOP
                              WWT_UPLOAD_GENERIC.LOG (
                                 3,
                                    'Starting c_get_noncosted_items loop for item id '
                                 || TO_CHAR (
                                       c_get_noncosted_items_rec.item_id)
                                 || ' and commit build id '
                                 || NVL (c_get_noncosted_items_rec.id,
                                         'NULL'));

                              v_comment_save := v_comments;

                              IF c_get_noncosted_items_rec.quantity IS NULL
                              THEN
                                 IF (    v_comments IS NOT NULL
                                     AND INSTR (v_comments,
                                                'Missing Phantom Component') =
                                            0)
                                 THEN
                                    v_comments :=
                                          v_comments
                                       || '; Missing Phantom Component';
                                 ELSE
                                    v_comments := 'Missing Phantom Component';
                                 END IF;
                              ELSE
                                 WWT_UPLOAD_GENERIC.LOG (
                                    3,
                                    'Calling get_fixed_lot_multiplier...');
                                 get_fixed_lot_multiple (
                                    c_get_supplier_xref_rec.supplier_sku_id,
                                    c_get_supplier_xref_rec.org_id,
                                    v_fixed_lot_multiple);
                              END IF;

                              v_supplier_sku := NULL;
                              v_comment_save := v_comments;

                              IF c_get_noncosted_items_rec.ID IS NULL
                              THEN
                                 -- d.knott 08-OCT-02: leading spaces are critical FOR the commmit_confirm process
                                 -- after this, if you change the 0's you need to modify commit confirm package body

                                 c_get_noncosted_items_rec.ID :=
                                       '0000000+'
                                    || SUBSTR (
                                          c_get_costed_items_rec.ID,
                                            INSTR (c_get_costed_items_rec.ID,
                                                   '+')
                                          + 1,
                                            INSTR (c_get_costed_items_rec.ID,
                                                   '-')
                                          - 9)
                                    || '-PO+0000|0000-VID';

                                 WWT_UPLOAD_GENERIC.LOG (
                                    3,
                                       'Set ID = '
                                    || c_get_noncosted_items_rec.ID);
                              END IF;

                              WWT_UPLOAD_GENERIC.LOG (
                                 3,
                                 'Calling insert_build_row...');
                              insert_build_row (
                                 c_get_noncosted_items_rec,
                                 v_commit_flag,
                                 v_comments,
                                 v_process_flag,
                                 c_get_costed_items_rec.quantity,
                                 l_my_file,
                                 NULL,
                                 v_fixed_lot_multiple,
                                 v_supplier_sku,
                                 0);

                              WWT_UPLOAD_GENERIC.LOG (3,
                                                      'Inserted build row');

                              WWT_UPLOAD_GENERIC.LOG (
                                 3,
                                 'Calling delete_commit_stg...');
                              delete_commit_stg (c_get_noncosted_items_rec);
                              WWT_UPLOAD_GENERIC.LOG (3,
                                                      'Deleted staging row');

                              v_comments := v_comment_save;
                           END LOOP NONCOSTED_ITEMS_LOOP_2;

                           v_complete_flag := 'Y';
                           WWT_UPLOAD_GENERIC.LOG (0,
                                                   'end of non costed LOOP');
                        ELSIF (      NVL (v_cum_oh_qty, 0)
                                   - NVL (v_old_dmd, 0)
                                   - NVL (v_rmng_qty, 0) < 0
                               AND NVL (v_cum_oh_qty, 0) > NVL (v_old_dmd, 0)
                               AND v_complete_flag = 'N')
                        THEN
                           --still need more on-hAND qty
                           WWT_UPLOAD_GENERIC.LOG (
                              0,
                              'not enough material...commiting partial');
                           WWT_UPLOAD_GENERIC.LOG (
                              0,
                                 'cum oh : '
                              || TO_CHAR (NVL (v_cum_oh_qty, 0))
                              || ' dmd : '
                              || TO_CHAR (NVL (v_old_dmd, 0))
                              || ' rmng qty : '
                              || TO_CHAR (NVL (v_rmng_qty, 0)));

                           v_commit_flag := 'Y';
                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling insert_build_row...');
                           insert_build_row (
                              c_get_costed_items_rec,
                              v_commit_flag,
                              v_comments,
                              v_process_flag,
                              (c_get_supplier_xref_rec.sku_oh_qty - v_sku_dmd),
                              l_my_file,
                              NULL,
                              v_fixed_lot_multiple,
                              v_supplier_sku,
                              0);

                           WWT_UPLOAD_GENERIC.LOG (3, 'Inserted build row');

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling delete_commit_stg...');
                           delete_commit_stg (c_get_costed_items_rec); -- scally added 10-24-2002
                           WWT_UPLOAD_GENERIC.LOG (3, 'Deleted staging row');

                           --v_rmng_qty := v_rmng_qty - c_get_supplier_xref_rec.sku_oh_qty;
                           v_rmng_qty :=
                                NVL (v_rmng_qty, 0)
                              - (  NVL (c_get_supplier_xref_rec.sku_oh_qty,
                                        0)
                                 - NVL (v_sku_dmd, 0));

                           WWT_UPLOAD_GENERIC.LOG (0,
                                                   'insert AND delete done');
                        END IF;                -- cum_oh_qty and old_dmd logic
                     END LOOP SUPP_XREF_LOOP; --FOR c_get_supplier_xref_rec  "inner loop"

                     -- WWT_UPLOAD_GENERIC.LOG(0, 'end of costed LOOP');
                     WWT_UPLOAD_GENERIC.LOG (0, 'end of supplier_xref LOOP');

                     --------------- Determine if entire Dell part NUMBER was satisfied FROM on-hAND skus ---------------
                     WWT_UPLOAD_GENERIC.LOG (
                        0,
                        'check if entire order was processed');

                     IF v_complete_flag = 'N'
                     THEN
                       <<NONCOSTED_ITEMS_LOOP_3>>
                        FOR c_get_noncosted_items_rec
                           IN c_get_noncosted_items (c_get_costed_items_rec,
                                                     l_slc_location)
                        LOOP
                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                                 'Starting c_get_noncosted_items loop for item id '
                              || TO_CHAR (c_get_noncosted_items_rec.item_id)
                              || ' and commit build id '
                              || NVL (c_get_noncosted_items_rec.id, 'NULL'));

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling get_fixed_lot_multiplier...');
                           get_fixed_lot_multiple (
                              c_get_noncosted_items_rec.supplier_sku_id,
                              c_get_noncosted_items_rec.org_id,
                              v_fixed_lot_multiple);

                           v_supplier_sku := NULL;
                           v_comment_save := v_comments;

                           IF c_get_noncosted_items_rec.quantity IS NULL
                           THEN
                              IF v_comments IS NOT NULL
                              THEN
                                 v_comments :=
                                       v_comments
                                    || '; Missing Non-Costed Component';
                              ELSE
                                 v_comments := 'Missing Non-Costed Component';
                              END IF;
                           END IF;

                           IF c_get_noncosted_items_rec.ID IS NULL
                           THEN
                              -- d.knott 08-OCT-02: the leading spaces are critical FOR the commmit_confirm process
                              -- after this, if you change the 0's you need to modify the commit confirm package body
                              c_get_noncosted_items_rec.ID :=
                                    '0000000+'
                                 || SUBSTR (
                                       c_get_costed_items_rec.ID,
                                         INSTR (c_get_costed_items_rec.ID,
                                                '+')
                                       + 1,
                                         INSTR (c_get_costed_items_rec.ID,
                                                '-')
                                       - 9)
                                 || '-PO+0000|0000-VID';

                              WWT_UPLOAD_GENERIC.LOG (
                                 3,
                                 'Set ID = ' || c_get_noncosted_items_rec.ID);
                           END IF;

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling insert_build_row...');
                           insert_build_row (
                              c_get_noncosted_items_rec,
                              v_commit_flag,
                              v_comments,
                              v_process_flag,
                              (c_get_costed_items_rec.quantity - v_rmng_qty),
                              l_my_file,
                              NULL,
                              v_fixed_lot_multiple,
                              v_supplier_sku,
                              0);

                           WWT_UPLOAD_GENERIC.LOG (3, 'Inserted build row');

                           WWT_UPLOAD_GENERIC.LOG (
                              3,
                              'Calling delete_commit_stg...');
                           delete_commit_stg (c_get_noncosted_items_rec);
                           WWT_UPLOAD_GENERIC.LOG (3, 'Deleted staging row');

                           v_comments := v_comment_save;
                        END LOOP NONCOSTED_ITEMS_LOOP_3; -- c_get_noncosted_items loop
                     END IF;                            -- v_complete_flag = N

                     WWT_UPLOAD_GENERIC.LOG (0, 'done checking');
                  END IF;                                 -- on_hand - old_dmd
               END;
            END LOOP COSTED_ITEMS_LOOP;             -- c_get_costed_items loop

            WWT_UPLOAD_GENERIC.LOG (0, 'starting remaining items LOOP');

           <<REMAINING_ITEMS_LOOP>>
            FOR c_get_remaining_items_rec
               IN c_get_remaining_items (l_slc_location)
            LOOP
               WWT_UPLOAD_GENERIC.LOG (
                  3,
                     'Starting c_get_remaining_items loop for item id '
                  || TO_CHAR (c_get_remaining_items_rec.item_id)
                  || ' and commit build id '
                  || NVL (c_get_remaining_items_rec.id, 'NULL'));

               v_fixed_lot_multiple := NULL;
               v_supplier_sku := NULL;
               v_comments := 'Missing Costed Component';

               WWT_UPLOAD_GENERIC.LOG (3, 'Calling insert_build_row...');
               insert_build_row (c_get_remaining_items_rec,
                                 v_commit_flag,
                                 v_comments,
                                 v_process_flag,
                                 0,
                                 l_my_file,
                                 0,
                                 v_fixed_lot_multiple,
                                 v_supplier_sku,
                                 0);

               WWT_UPLOAD_GENERIC.LOG (3, 'Inserted build row');

               WWT_UPLOAD_GENERIC.LOG (3, 'Calling delete_commit_stg...');
               delete_commit_stg (c_get_remaining_items_rec);
               WWT_UPLOAD_GENERIC.LOG (3, 'Deleted staging row');
            END LOOP REMAINING_ITEMS_LOOP;       -- c_get_remaining_items loop

            IF UTL_FILE.IS_OPEN (l_my_file)
            THEN
               -- Close the file
               UTL_FILE.FCLOSE_ALL;
               WWT_UPLOAD_GENERIC.LOG (
                  0,
                  'done with remaining items....ending program');
            END IF;
         END;
      END IF;                                          -- end of if for v_flag

      DBMS_APPLICATION_INFO.set_module (NULL, NULL);
      WWT_UPLOAD_GENERIC.LOG (3, 'END wwt_dell_cfi_commit_analysis.main');
   EXCEPTION
      WHEN OTHERS
      THEN
         x_errbuff := 'ERROR: ' || SQLERRM;
         x_retcode := 2;
         DBMS_APPLICATION_INFO.set_module (NULL, NULL);
   END main;
END Wwt_Dell_Cfi_Commit_Analysis;
/