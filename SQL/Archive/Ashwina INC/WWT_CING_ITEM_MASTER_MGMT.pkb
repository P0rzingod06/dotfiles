CREATE OR REPLACE PACKAGE BODY APPS.wwt_cing_item_master_mgmt
IS
   --
   --
   --CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_cing_item_master_mgmt.plb,v $, $Revision: 1.9 $, $Author: rays $, $Date: 2011/09/29 19:25:14 $
   --
   --
   -- Purpose: Briefly explain the functionality of the package body
   --
   -- MODIFICATION HISTORY
   -- Person      CVS Version  Date         Comments
   -- ---------   -----------  ----------  ------------------------------------------
   -- moebesc                  07-jan-05   needed to remove supporting material from package body
   -- moebesc                  02/25/2005  find and replace on org 791 to 547 for livermore, and enabled item import for livermore
   -- moebesc                  03/29/2005  modified MFG lookup from ORG 547 addition
   -- moebesc                  12-apr-2005  find and replace on org 547 to 868 for livermore, BSA created new ORG asr #91118266
   -- moebesc                  18-may-2005 changed serial control from receipt to SO issue
   -- rolfesj                  17-jun-2005 ASR 91119416 - add field ITEM_STATUS (attribute4 on the item master interface table)
   -- moebesc                  25-jul-2005 removed GATEWAY changes.  changed receiving routing from 3 to 1, direct to two step.
   -- moebesc                  28-jul-2005 inventory balance query will now show items with mtl transaction with zero balance up to 7 days after
   -- moebesc                  15-aug-2005 addition to record row count for inventory file to remove user setup issues with items
   -- moebesc                  19-aug-2005 inventorybalance count for file done with pl/sql table
   -- moebesc                  29-aug-2005  91120730 - new cats inventory file , new inbound category from cingular
   -- moebesc                  08-nov-2005 91121940 - new item template for model parts to submit to item interface
   -- moebesc                  26-jan-2006 91123726 - stripped out old file build process for FTP since webMethods now handles in 6.1
   -- khuranah                 07-Mar-2006  Initial Creation 1.1
   -- khuranah                 21-Mar-2006  1.2 (Added the Function get_item_template_id in package to return the template_id on the basis of template_name
   -- rolfesj                  01-Feb-2007 ASR 91127975 - added ltrim, rtrim to format of description in builditemmasterrec
   -- morganc                  11-OCT-2007 INC10023 - Modified builditemmasterrec procedure, added a REPLACE around the item description to
   --                                      replace a semi-colon with a comma.
   --
   --Niranjan Shah             27-Mar-2008 Modified per ASR 91129976 - INC29106 - Item Tech data needs to be added to item interface from ATT.
   --                                      Added column ITEM_TECH to Table WWT_CING_ITEM_MASTER_ORIGINAL, cingular_master_items datarep Upload Center objects modified.
   --                                      Modified PROCEDURE processItems to take ITEM_TECH column data to inv.mtl_system_items.attribute3 column.
   --                                      Added PROCEDURE UPDATE_ITEM_MASTER_INTERFACE.  Moved to APPS from PARTNER_ADMIN Schema.
   -- hansend          1.4     24-MAR-2009 CHG11989 - Modified builditemmasterrec procedure. Changed hard-coded value 'NO ORGS' to a lookup
   -- hansend          1.5     01-JUN-2009 CHG12612 - Accidental commit in CVS
   -- hansend          1.6     10-JUN-2009 CHG12612 - Modified code to use new item creation process
   -- krishnac         1.7     CHG12612 for NSD.
   --                          1. Changed Cursor organization_id_cur  for fetching Organization Ids
   --                          2. Procedure getinventoryitemdetails Added Parameter isegment4, oitemtype to return the item_type and
   --                             include segment4 in the where
   --                          3. Procedure populate_api_tbl removed hardcoding for attribute15
   --                          4. Procedure insertitemmasterrec - Cleared the local object
   --                          5. Procedure builditemmasterrec - Removed Code that is no longer necessary
   --                                                - Added New assignments to oitemmasterrec
   --                          6. Procedure itemexistsandvalid - Added Parameters isegment4, oitemtype
   --                                                  modified call to getinventoryitemdetails
   --                          7. Procedure processitems
   --                             - Added New Variables l_wwt_item_tab_temp. l_msib_rec, l_msi_item_type
   --                             - Modified Call to itemexistsandvalid
   --                             - Added check to prevent Item Type change from Model to Standard
   --                             - Added Default template id in case of Errors while determining template to apply
   --                             - Removed Code that is no longer ncessary
   --krishnac        1.8      23-JUN-2010 CHG16489
   --                            While updating items, due to changes in apps.wwt_item_api_pkg
   --                            to handle concurrency, all 4 item segments are required to contain
   --                            values to enable lock generation.
   -- rays           1.9      31-AUG-2011 CHG20193  Changed l_serialcontrolledcode assignment in processitems from 6 to 5
   --                                           to reflect change for WMS to control items as receipt (control code 5)
   --
   --====================================================================================================================================================================

   --
   -- Cursor to get the orgids for explosion
   --
   CURSOR organization_id_cur ( p_msi_orgs IN VARCHAR2 )
   IS
        SELECT   TO_NUMBER (attribute2) organization_id
        FROM     apps.wwt_lookups_active_v
        WHERE    1 = 1
        AND      attribute1 = p_msi_orgs
        AND      lookup_type = 'WWT_ORG_DESTINATION_DETAILS'
        ORDER BY  organization_id;

   /********************************/
   /* RETURN CODE = SUCCESS := 0;  */
   /* RETURN CODE = WARNING := 1;  */
   /* RETURN CODE = ERROR   := 2;  */
   /********************************/
   --------------------------------------------------------------------------------
   FUNCTION get_item_template_id (
      p_template_name            IN       VARCHAR2
   )
      RETURN NUMBER
   IS
                                                                                 /*
      -----------------------------------------------------------------------------
      | Function Name:   get_item_template_id                                     |
      | Return Type:     NUMBER                                                   |
      |                                                                           |
      | Description:  This function will return the template id on basis of       |
      |               template name.                                              |
      |                                                                           |
      -----------------------------------------------------------------------------
                                                                                 */
      l_cing_template_id            NUMBER;
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    'p_template_name              : '
                                                        || p_template_name, p_level => 1);

      SELECT template_id
      INTO   l_cing_template_id
      FROM   apps.mtl_item_templates
      WHERE  template_name = p_template_name;

      apps.wwt_runtime_utilities.show_program_stack ('return 1');
      RETURN l_cing_template_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
         RETURN -1;
   END get_item_template_id;

   --------------------------------------------------------------------------------
   PROCEDURE update_item_master_interface (
      icingularitemdatarec       IN       items%ROWTYPE
     ,iprocessflag               IN OUT   VARCHAR2
     ,iprocessmessage            IN OUT   VARCHAR2
     ,oreturncode                OUT      PLS_INTEGER
   )
   IS
      ---This procedure added per INC 29106 ASR 91129976
      l_itemcount                   PLS_INTEGER;
      l_itemcount1                  PLS_INTEGER;
      l_processmessage              VARCHAR2 (100) := 'MTL_SYSTEM_ITEMS_INTERFACE.ATTRIBUTE3 WAS UPDATED FOR THIS ITEM';
   BEGIN
      IF iprocessflag = 'R'
      THEN   ---101
         /*
             Valid values for iprocessflag are:  'P' = Processed; 'R' = Rejected ; 'E' = Error
             This procedure needs to be processed if iprocessflag = 'R' i.e. there is possibility that
             the master_item already exists in the mtl_system_items or  mtl_system_items_interface tables.
             If 'P' = Processed i.e. a new item record created or if  'E' = Error i.e. some Oracle or data error,
             this procedure does not have to be processed.
         */
         apps.wwt_runtime_utilities.show_program_stack ('begin');
         apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' iprocessflag '
                                                           || iprocessflag
                                                           || ' iprocessmessage '
                                                           || iprocessmessage, p_level => 1);
         DBMS_OUTPUT.put_line (   'Starting Update rec for customer part #: '
                               || icingularitemdatarec.customer_part_number
                               || '  for  attribute3 change');

         --Check Interface Table First
         SELECT COUNT (*)
         INTO   l_itemcount
         FROM   apps.mtl_system_items_interface msi
         WHERE  1 = 1
         AND    msi.segment4 = 'CINGULAR'
         AND    msi.segment2 = icingularitemdatarec.item_number
         AND    msi.attribute8 = icingularitemdatarec.customer_part_number
         AND    msi.segment3 = 'ACTUAL'
         AND    msi.attribute3 != icingularitemdatarec.item_tech
         AND    icingularitemdatarec.item_tech IS NOT NULL;

         IF l_itemcount > 0
         THEN   ---102
            UPDATE apps.mtl_system_items_interface msi
               SET msi.attribute3 = icingularitemdatarec.item_tech
             WHERE 1 = 1
            AND    msi.segment4 = 'CINGULAR'
            AND    msi.segment2 = icingularitemdatarec.item_number
            AND    msi.attribute8 = icingularitemdatarec.customer_part_number
            AND    msi.segment3 = 'ACTUAL'
            AND    msi.attribute3 != icingularitemdatarec.item_tech
            AND    icingularitemdatarec.item_tech IS NOT NULL;

            iprocessmessage            := l_processmessage;
            DBMS_OUTPUT.put_line (   'Updating rec for customer part #: '
                                  || icingularitemdatarec.customer_part_number
                                  || '  for  attribute3 change');

            UPDATE partner_admin.wwt_cing_item_master_original wcim
               SET wcim.process_flag = 'P'
                  ,wcim.MESSAGE = iprocessmessage
                  ,wcim.last_update_date = SYSDATE
                  ,wcim.last_updated_by = 'Upload Center'
             WHERE 1 = 1
            AND    wcim.item_number = icingularitemdatarec.item_number
            AND    wcim.customer_part_number = icingularitemdatarec.customer_part_number
            AND    wcim.interface_transaction_id != icingularitemdatarec.interface_transaction_id
            AND    wcim.item_tech != icingularitemdatarec.item_tech;
         END IF;
      ---IF l_itemcount > 0 THEN                                               ---102
      END IF;

      ---IF iprocessflag = 'R' THEN                                              ---101
      oreturncode                := 0;
      apps.wwt_runtime_utilities.show_program_stack ('end');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' iprocessflag '
                                                        || iprocessflag
                                                        || ' iprocessmessage '
                                                        || iprocessmessage, p_level => 1);
   EXCEPTION
      WHEN OTHERS
      THEN
         oreturncode                := 2;
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END update_item_master_interface;   ---END UPDATE_ITEM_MASTER_INTERFACE

   --------------------------------------------------------------------------------

   --------------------------------------------------------------------------------
   PROCEDURE getorganizationid (
      iorgcode                   IN       apps.mtl_parameters.organization_code%TYPE
     ,x_org_id                   OUT      NUMBER
   )
   IS
                                                                              /*
   -----------------------------------------------------------------------------
   | Procedure Name:  getorganizationid                                        |
   |                                                                           |
   | Description:Finds the Organization Id on basis of Organization code.      |
   |                                                                           |
   -----------------------------------------------------------------------------
                                                                              */
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    'iorgcode              : '
                                                        || iorgcode, p_level => 1);

      SELECT organization_id
      INTO   x_org_id
      FROM   apps.mtl_parameters
      WHERE  organization_code = iorgcode;

      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN OTHERS
      THEN
         x_org_id                   := -999;
         --will write record but error on item_interface
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END getorganizationid;

   -----------------------------------------------------------------------------------------------------------
   ---04012008
   PROCEDURE getinventoryitemdetails (
      iitemnumber                IN OUT   partner_admin.wwt_cing_item_master_original.item_number%TYPE
     ,icustomerpartnumber        IN       partner_admin.wwt_cing_item_master_original.customer_part_number%TYPE
     ,imanufacturer              IN       partner_admin.wwt_cing_item_master_original.manufacturer%TYPE
     ,isegment4                  IN       mtl_system_items_b.segment4%TYPE
     ,iorgid                     IN       NUMBER
     ,oitemexists                OUT      BOOLEAN
     ,omanufacturerid            OUT      apps.mtl_system_items.segment1%TYPE
     ,oinventoryitemid           OUT      NUMBER
     ,ocontinueflag              OUT      VARCHAR2
     ,oprocessflag               OUT      VARCHAR2
     ,oprocessmessage            OUT      VARCHAR2
     ,oreturncode                OUT      NUMBER
     ,oitemtype                  OUT      VARCHAR2
   )
   IS
                                                                                 /*
      -----------------------------------------------------------------------------
      | Procedure Name:  getinventoryitemdetails                                  |
      |                                                                           |
      | Description: This procedure will give the details of the inventory items. |
      |                                                                           |
      -----------------------------------------------------------------------------
                                                                                */
      l_itemcount                   NUMBER;
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    'iitemnumber :'
                                                        || iitemnumber
                                                        || 'icustomerpartnumber'
                                                        || icustomerpartnumber
                                                        || 'imanufacturer'
                                                        || imanufacturer
                                                        || 'iorgid'
                                                        || iorgid
                                       ,p_level      => 1);

      BEGIN
        dbms_output.put_line( ' Start getinventoryitemdetails for segment4 = '|| isegment4 ||
                              ' organization_id = '|| iorgid || ' attribute8 = '||icustomerpartnumber
                            );
         SELECT inventory_item_id
               ,segment1
               ,segment2
               ,item_type
         INTO   oinventoryitemid
               ,omanufacturerid
               ,iitemnumber
               ,oitemtype
         FROM   apps.mtl_system_items_b
         WHERE  segment4        = isegment4
         AND    organization_id = iorgid
         AND    attribute8      = icustomerpartnumber
         AND    segment3        = 'ACTUAL';

         oprocessflag               := 'P';
         oprocessmessage            := 'Item Exists.Update Required';
         oreturncode                := 0;
         oitemexists                := TRUE;
         ocontinueflag              := 'Y';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            oprocessflag               := 'P';
            oprocessmessage            := 'Create Item';
            oreturncode                := 0;
            oitemexists                := FALSE;
            ocontinueflag              := 'Y';
         WHEN TOO_MANY_ROWS
         THEN
            oprocessflag               := 'E';
            oprocessmessage            := 'Duplicate Item';
            oreturncode                := 2;
            oitemexists                := TRUE;
            ocontinueflag              := 'N';
         WHEN OTHERS
         THEN
            oprocessflag               := 'E';
            oprocessmessage            := SQLERRM;
            oreturncode                := 2;
            oitemexists                := FALSE;
            ocontinueflag              := 'N';
        dbms_output.put_line( 'Exception Occured');
      END;   --Second Check MTL Item Master

      apps.wwt_runtime_utilities.show_program_stack ('end');
   END getinventoryitemdetails;

   --------------------------------------------------------------------------------
   PROCEDURE updateitemstagingrec (
      icingularitemdatarec       IN       items%ROWTYPE
     ,iprocessflag               IN       VARCHAR2
     ,iprocessmessage            IN       VARCHAR2
     ,oreturncode                OUT      NUMBER
   )
   IS
                                                                              /*
   -----------------------------------------------------------------------------
   | Procedure Name:  updateitemstagingrec                                     |
   |                                                                           |
   | Description: Updated the  wwt_cing_item_master_original table on basis of |
   |              interface_transaction_id.                                    |
   |                                                                           |
   |                                                                           |
   -----------------------------------------------------------------------------
                                                                              */
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' iprocessflag '
                                                        || iprocessflag
                                                        || ' iprocessmessage '
                                                        || iprocessmessage, p_level => 1);

      UPDATE partner_admin.wwt_cing_item_master_original
         SET process_flag = iprocessflag
            ,MESSAGE = iprocessmessage
       WHERE interface_transaction_id = icingularitemdatarec.interface_transaction_id;

      oreturncode                := 0;
      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN OTHERS
      THEN
         oreturncode                := 2;
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END updateitemstagingrec;

   --------------------------------------------------------------------------------
      /*******************************************************************************
      ** Procedure     : populate_api_tbl                                          **                                                                           **
      ** Description   : Populate  global table of Type wwt_item_tab_type          **
      **                                                                           **
      *******************************************************************************
                                                                                   */
   PROCEDURE populate_api_tbl (
      p_organization_id          IN       NUMBER DEFAULT NULL
     ,p_msib_rec                 IN       apps.mtl_system_items_b%ROWTYPE
     ,p_transaction_type         IN       VARCHAR2
     ,p_template_id              IN       NUMBER
     ,p_manufacturer_id          IN       NUMBER
     ,p_serial_controlled_flag   IN       VARCHAR2
     ,x_item_table               OUT      wwt_item_tab_type
   )
   IS
      l_organization_id             NUMBER;
      l_item_table                  wwt_item_tab_type := wwt_item_tab_type ();
      --
      -- Who Columns
      --
      l_last_update_login           NUMBER;
      l_created_by                  NUMBER := fnd_global.user_id;
      l_creation_date               DATE := SYSDATE;
      l_last_updated_by             NUMBER := fnd_global.user_id;
      l_last_update_date            DATE := SYSDATE;
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' POPULATE API '
                                                        || ' p_organization_id '
                                                        || p_organization_id
                                                        || ' p_transaction_type '
                                                        || p_transaction_type
                                                        || ' p_template_id '
                                                        || p_template_id
                                                        || ' p_manufacturer_id '
                                                        || p_manufacturer_id
                                                        || ' p_msib_rec.inventory_item_id '
                                                        || p_msib_rec.inventory_item_id
                                                        || ' p_serial_controlled_flag '
                                                        || p_serial_controlled_flag
                                                        || ' p_msib_rec.segment5 '
                                                        || p_msib_rec.segment5
                                       ,p_level      => 1);
      DBMS_OUTPUT.put_line (   'Populating API '
                            || ' Serial Controlled Flag '
                            || p_serial_controlled_flag
                            || 'p_msib_rec.inventory_item_id'
                            || p_msib_rec.inventory_item_id
                            || 'p_template_id'
                            || p_template_id
                            );
      l_item_table.EXTEND;
      l_item_table (l_item_table.COUNT) :=
         wwt_item_api_obj (p_transaction_type   -- transaction_type
                          ,NULL   -- return_status
                          ,NULL   -- language_code
                          ,NULL   -- copy_inventory_item_id
                          ,p_template_id
                          ,NULL   -- template_name
                          ,p_msib_rec.inventory_item_id
                          ,NULL   -- item_number
                          ,p_manufacturer_id
                          ,p_msib_rec.segment2
                          ,p_msib_rec.segment3
                          ,p_msib_rec.segment4
                          ,p_msib_rec.segment5
                          ,p_msib_rec.segment6
                          ,p_msib_rec.segment7
                          ,p_msib_rec.segment8
                          ,p_msib_rec.segment9
                          ,p_msib_rec.segment10
                          ,p_msib_rec.segment11
                          ,p_msib_rec.segment12
                          ,p_msib_rec.segment13
                          ,p_msib_rec.segment14
                          ,p_msib_rec.segment15
                          ,p_msib_rec.segment16
                          ,p_msib_rec.segment17
                          ,p_msib_rec.segment18
                          ,p_msib_rec.segment19
                          ,p_msib_rec.segment20
                          ,p_msib_rec.summary_flag
                          ,p_msib_rec.enabled_flag
                          ,p_msib_rec.start_date_active
                          ,p_msib_rec.end_date_active
                          ,p_msib_rec.organization_id
                          ,NULL   -- organization_code
                          ,p_msib_rec.item_catalog_group_id
                          ,p_msib_rec.catalog_status_flag
                          ,p_msib_rec.lifecycle_id
                          ,p_msib_rec.current_phase_id
                          -- main attributes
         ,                 p_msib_rec.description
                          ,NULL   -- long_description
                          ,p_msib_rec.primary_uom_code
                          ,p_msib_rec.allowed_units_lookup_code
                          ,p_msib_rec.inventory_item_status_code
                          ,p_msib_rec.dual_uom_control
                          ,p_msib_rec.secondary_uom_code
                          ,p_msib_rec.dual_uom_deviation_high
                          ,p_msib_rec.dual_uom_deviation_low
                          ,p_msib_rec.item_type
                          -- inventory
         ,                 p_msib_rec.inventory_item_flag
                          ,p_msib_rec.stock_enabled_flag
                          ,p_msib_rec.mtl_transactions_enabled_flag
                          ,p_msib_rec.revision_qty_control_code
                          ,p_msib_rec.lot_control_code
                          ,p_msib_rec.auto_lot_alpha_prefix
                          ,p_msib_rec.start_auto_lot_number
                          ,p_msib_rec.serial_number_control_code
                          ,p_msib_rec.auto_serial_alpha_prefix
                          ,p_msib_rec.start_auto_serial_number
                          ,p_msib_rec.shelf_life_code
                          ,p_msib_rec.shelf_life_days
                          ,p_msib_rec.restrict_subinventories_code
                          ,p_msib_rec.location_control_code
                          ,p_msib_rec.restrict_locators_code
                          ,p_msib_rec.reservable_type
                          ,p_msib_rec.cycle_count_enabled_flag
                          ,p_msib_rec.negative_measurement_error
                          ,p_msib_rec.positive_measurement_error
                          ,p_msib_rec.check_shortages_flag
                          ,p_msib_rec.lot_status_enabled
                          ,p_msib_rec.default_lot_status_id
                          ,p_msib_rec.serial_status_enabled
                          ,p_msib_rec.default_serial_status_id
                          ,p_msib_rec.lot_split_enabled
                          ,p_msib_rec.lot_merge_enabled
                          ,p_msib_rec.lot_translate_enabled
                          ,p_msib_rec.lot_substitution_enabled
                          ,p_msib_rec.bulk_picked_flag
                          -- bills of material
         ,                 p_msib_rec.bom_item_type
                          ,p_msib_rec.bom_enabled_flag
                          ,p_msib_rec.base_item_id
                          ,p_msib_rec.eng_item_flag
                          ,p_msib_rec.engineering_item_id
                          ,p_msib_rec.engineering_ecn_code
                          ,p_msib_rec.engineering_date
                          ,p_msib_rec.effectivity_control
                          ,p_msib_rec.config_model_type
                          ,p_msib_rec.product_family_item_id
                          ,p_msib_rec.auto_created_config_flag
                          -- costing
         ,                 p_msib_rec.costing_enabled_flag
                          ,p_msib_rec.inventory_asset_flag
                          ,p_msib_rec.cost_of_sales_account
                          ,p_msib_rec.default_include_in_rollup_flag
                          ,p_msib_rec.std_lot_size
                          -- enterprise asset management
         ,                 p_msib_rec.eam_item_type
                          ,p_msib_rec.eam_activity_type_code
                          ,p_msib_rec.eam_activity_cause_code
                          ,p_msib_rec.eam_activity_source_code
                          ,p_msib_rec.eam_act_shutdown_status
                          ,p_msib_rec.eam_act_notification_flag
                          -- purchasing
         ,                 p_msib_rec.purchasing_item_flag
                          ,p_msib_rec.purchasing_enabled_flag
                          ,p_msib_rec.buyer_id
                          ,p_msib_rec.must_use_approved_vendor_flag
                          ,p_msib_rec.purchasing_tax_code
                          ,p_msib_rec.taxable_flag
                          ,p_msib_rec.receive_close_tolerance
                          ,p_msib_rec.allow_item_desc_update_flag
                          ,p_msib_rec.inspection_required_flag
                          ,p_msib_rec.receipt_required_flag
                          ,p_msib_rec.market_price
                          ,p_msib_rec.un_number_id
                          ,p_msib_rec.hazard_class_id
                          ,p_msib_rec.rfq_required_flag
                          ,p_msib_rec.list_price_per_unit
                          ,p_msib_rec.price_tolerance_percent
                          ,p_msib_rec.asset_category_id
                          ,p_msib_rec.rounding_factor
                          ,p_msib_rec.unit_of_issue
                          ,p_msib_rec.outside_operation_flag
                          ,p_msib_rec.outside_operation_uom_type
                          ,p_msib_rec.invoice_close_tolerance
                          ,p_msib_rec.encumbrance_account
                          ,p_msib_rec.expense_account
                          ,p_msib_rec.qty_rcv_exception_code
                          ,p_msib_rec.receiving_routing_id
                          ,p_msib_rec.qty_rcv_tolerance
                          ,p_msib_rec.enforce_ship_to_location_code
                          ,p_msib_rec.allow_substitute_receipts_flag
                          ,p_msib_rec.allow_unordered_receipts_flag
                          ,p_msib_rec.allow_express_delivery_flag
                          ,p_msib_rec.days_early_receipt_allowed
                          ,p_msib_rec.days_late_receipt_allowed
                          ,p_msib_rec.receipt_days_exception_code
                          -- physical
         ,                 p_msib_rec.weight_uom_code
                          ,p_msib_rec.unit_weight
                          ,p_msib_rec.volume_uom_code
                          ,p_msib_rec.unit_volume
                          ,p_msib_rec.container_item_flag
                          ,p_msib_rec.vehicle_item_flag
                          ,p_msib_rec.maximum_load_weight
                          ,p_msib_rec.minimum_fill_percent
                          ,p_msib_rec.internal_volume
                          ,p_msib_rec.container_type_code
                          ,p_msib_rec.collateral_flag
                          ,p_msib_rec.event_flag
                          ,p_msib_rec.equipment_type
                          ,p_msib_rec.electronic_flag
                          ,p_msib_rec.downloadable_flag
                          ,p_msib_rec.indivisible_flag
                          ,p_msib_rec.dimension_uom_code
                          ,p_msib_rec.unit_length
                          ,p_msib_rec.unit_width
                          ,p_msib_rec.unit_height
                          --planing
         ,                 p_msib_rec.inventory_planning_code
                          ,p_msib_rec.planner_code
                          ,p_msib_rec.planning_make_buy_code
                          ,p_msib_rec.min_minmax_quantity
                          ,p_msib_rec.max_minmax_quantity
                          ,p_msib_rec.safety_stock_bucket_days
                          ,p_msib_rec.carrying_cost
                          ,p_msib_rec.order_cost
                          ,p_msib_rec.mrp_safety_stock_percent
                          ,p_msib_rec.mrp_safety_stock_code
                          ,p_msib_rec.fixed_order_quantity
                          ,p_msib_rec.fixed_days_supply
                          ,p_msib_rec.minimum_order_quantity
                          ,p_msib_rec.maximum_order_quantity
                          ,p_msib_rec.fixed_lot_multiplier
                          ,p_msib_rec.source_type
                          ,p_msib_rec.source_organization_id
                          ,p_msib_rec.source_subinventory
                          ,p_msib_rec.mrp_planning_code
                          ,p_msib_rec.ato_forecast_control
                          ,p_msib_rec.planning_exception_set
                          ,p_msib_rec.shrinkage_rate
                          ,p_msib_rec.end_assembly_pegging_flag
                          ,p_msib_rec.rounding_control_type
                          ,p_msib_rec.planned_inv_point_flag
                          ,p_msib_rec.create_supply_flag
                          ,p_msib_rec.acceptable_early_days
                          ,p_msib_rec.mrp_calculate_atp_flag
                          ,p_msib_rec.auto_reduce_mps
                          ,p_msib_rec.repetitive_planning_flag
                          ,p_msib_rec.overrun_percentage
                          ,p_msib_rec.acceptable_rate_decrease
                          ,p_msib_rec.acceptable_rate_increase
                          ,p_msib_rec.planning_time_fence_code
                          ,p_msib_rec.planning_time_fence_days
                          ,p_msib_rec.demand_time_fence_code
                          ,p_msib_rec.demand_time_fence_days
                          ,p_msib_rec.release_time_fence_code
                          ,p_msib_rec.release_time_fence_days
                          ,p_msib_rec.substitution_window_code
                          ,p_msib_rec.substitution_window_days
                          -- lead times
         ,                 p_msib_rec.preprocessing_lead_time
                          ,p_msib_rec.full_lead_time
                          ,p_msib_rec.postprocessing_lead_time
                          ,p_msib_rec.fixed_lead_time
                          ,p_msib_rec.variable_lead_time
                          ,p_msib_rec.cum_manufacturing_lead_time
                          ,p_msib_rec.cumulative_total_lead_time
                          ,p_msib_rec.lead_time_lot_size
                          -- wip
         ,                 p_msib_rec.build_in_wip_flag
                          ,p_msib_rec.wip_supply_type
                          ,p_msib_rec.wip_supply_subinventory
                          ,p_msib_rec.wip_supply_locator_id
                          ,p_msib_rec.overcompletion_tolerance_type
                          ,p_msib_rec.overcompletion_tolerance_value
                          ,p_msib_rec.inventory_carry_penalty
                          ,p_msib_rec.operation_slack_penalty
                          -- order management
         ,                 p_msib_rec.customer_order_flag
                          ,p_msib_rec.customer_order_enabled_flag
                          ,p_msib_rec.internal_order_flag
                          ,p_msib_rec.internal_order_enabled_flag
                          ,p_msib_rec.shippable_item_flag
                          ,p_msib_rec.so_transactions_flag
                          ,p_msib_rec.picking_rule_id
                          ,p_msib_rec.pick_components_flag
                          ,p_msib_rec.replenish_to_order_flag
                          ,p_msib_rec.atp_flag
                          ,p_msib_rec.atp_components_flag
                          ,p_msib_rec.atp_rule_id
                          ,p_msib_rec.ship_model_complete_flag
                          ,p_msib_rec.default_shipping_org
                          ,p_msib_rec.default_so_source_type
                          ,p_msib_rec.returnable_flag
                          ,p_msib_rec.return_inspection_requirement
                          ,p_msib_rec.over_shipment_tolerance
                          ,p_msib_rec.under_shipment_tolerance
                          ,p_msib_rec.over_return_tolerance
                          ,p_msib_rec.under_return_tolerance
                          ,p_msib_rec.financing_allowed_flag
                          ,p_msib_rec.vol_discount_exempt_flag
                          ,p_msib_rec.coupon_exempt_flag
                          ,p_msib_rec.invoiceable_item_flag
                          ,p_msib_rec.invoice_enabled_flag
                          ,p_msib_rec.accounting_rule_id
                          ,p_msib_rec.invoicing_rule_id
                          ,p_msib_rec.tax_code
                          ,p_msib_rec.sales_account
                          ,p_msib_rec.payment_terms_id
                          -- service
         ,                 p_msib_rec.contract_item_type_code
                          ,p_msib_rec.service_duration_period_code
                          ,p_msib_rec.service_duration
                          ,p_msib_rec.coverage_schedule_id
                          ,p_msib_rec.subscription_depend_flag
                          ,p_msib_rec.serv_importance_level
                          ,p_msib_rec.serv_req_enabled_code
                          ,p_msib_rec.comms_activation_reqd_flag
                          ,p_msib_rec.serviceable_product_flag
                          ,p_msib_rec.material_billable_flag
                          ,p_msib_rec.serv_billing_enabled_flag
                          ,p_msib_rec.defect_tracking_on_flag
                          ,p_msib_rec.recovered_part_disp_code
                          ,p_msib_rec.comms_nl_trackable_flag
                          ,p_msib_rec.asset_creation_code
                          ,p_msib_rec.ib_item_instance_class
                          ,p_msib_rec.service_starting_delay
                          -- web option
         ,                 p_msib_rec.web_status
                          ,p_msib_rec.orderable_on_web_flag
                          ,p_msib_rec.back_orderable_flag
                          ,p_msib_rec.minimum_license_quantity
                          -- start:  26 new attributes
         ,                 p_msib_rec.tracking_quantity_ind
                          ,p_msib_rec.ont_pricing_qty_source
                          ,p_msib_rec.secondary_default_ind
                          ,NULL   --option_specific_sourced
                          ,p_msib_rec.vmi_minimum_units
                          ,p_msib_rec.vmi_minimum_days
                          ,p_msib_rec.vmi_maximum_units
                          ,p_msib_rec.vmi_maximum_days
                          ,p_msib_rec.vmi_fixed_order_quantity
                          ,p_msib_rec.so_authorization_flag
                          ,p_msib_rec.consigned_flag
                          ,p_msib_rec.asn_autoexpire_flag
                          ,p_msib_rec.vmi_forecast_type
                          ,p_msib_rec.forecast_horizon
                          ,p_msib_rec.exclude_from_budget_flag
                          ,p_msib_rec.days_tgt_inv_supply
                          ,p_msib_rec.days_tgt_inv_window
                          ,p_msib_rec.days_max_inv_supply
                          ,p_msib_rec.days_max_inv_window
                          ,p_msib_rec.drp_planned_flag
                          ,p_msib_rec.critical_component_flag
                          ,p_msib_rec.continous_transfer
                          ,p_msib_rec.convergence
                          ,p_msib_rec.divergence
                          ,p_msib_rec.config_orgs
                          ,p_msib_rec.config_match
                          -- End  : 26 new attributes
                          -- Descriptive flex
         ,                 p_msib_rec.attribute_category
                          ,p_msib_rec.attribute1
                          ,p_msib_rec.attribute2
                          ,p_msib_rec.attribute3
                          ,p_msib_rec.attribute4
                          ,p_msib_rec.attribute5
                          ,p_msib_rec.attribute6
                          ,p_msib_rec.attribute7
                          ,p_msib_rec.attribute8
                          ,p_msib_rec.attribute9
                          ,p_msib_rec.attribute10
                          ,p_msib_rec.attribute11
                          ,p_msib_rec.attribute12
                          ,p_msib_rec.attribute13
                          ,p_msib_rec.attribute14
                          ,p_msib_rec.attribute15   -- Taken from lookups CHG12612
                          -- Global Descriptive flex
         ,                 p_msib_rec.global_attribute_category
                          ,p_msib_rec.global_attribute1
                          ,p_msib_rec.global_attribute2
                          ,p_msib_rec.global_attribute3
                          ,p_msib_rec.global_attribute4
                          ,p_msib_rec.global_attribute5
                          ,p_msib_rec.global_attribute6
                          ,p_msib_rec.global_attribute7
                          ,p_msib_rec.global_attribute8
                          ,p_msib_rec.global_attribute9
                          ,p_msib_rec.global_attribute10
                          -- Who
         ,                 NULL   -- Object_Version_Number
                          ,l_creation_date
                          ,l_created_by
                          ,l_last_update_date
                          ,l_last_updated_by
                          ,NULL   -- Last_Update_Login
                          -- Main Driver to lookup WWT_ITEM_CRE
         ,                 'ATT'   --wwt_item_creation_source
                          ,NULL   --wwt_transaction_type
                          -- Additional Columns for use in pre
         ,                 p_serial_controlled_flag   --wwt_Attribute1
                          ,NULL   --wwt_Attribute2
                          ,NULL   --wwt_Attribute3
                          ,NULL   --wwt_Attribute4
                          ,NULL   --wwt_Attribute5
                          ,NULL   --wwt_Attribute6
                          ,NULL   --wwt_Attribute7
                          ,NULL   --wwt_Attribute8
                          ,NULL   --wwt_Attribute9
                          ,NULL   --wwt_Attribute10
                          ,NULL   --wwt_Attribute11
                          ,NULL   --wwt_Attribute12
                          ,NULL   --wwt_Attribute13
                          ,NULL   --wwt_Attribute14
                          ,NULL   --wwt_Attribute15
                          ,NULL   --wwt_Attribute16
                          ,NULL   --wwt_Attribute17
                          ,NULL   --wwt_Attribute18
                          ,NULL   --wwt_Attribute19
                          ,NULL   --wwt_Attribute20
                          ,NULL   --wwt_Attribute21
                          ,NULL   --wwt_Attribute22
                          ,NULL   --wwt_Attribute23
                          ,NULL   --wwt_Attribute24
                          ,NULL   --wwt_Attribute25
                          ,NULL   --wwt_Attribute26
                          ,NULL   --wwt_Attribute27
                          ,NULL   --wwt_Attribute28
                          ,NULL   --wwt_Attribute29
                          ,NULL   --wwt_Attribute30
                          ,NULL   --wwt_Attribute31
                          ,NULL   --wwt_Attribute32
                          ,NULL   --wwt_Attribute33
                          ,NULL   --wwt_Attribute34
                          ,NULL   --wwt_Attribute35
                          ,NULL   --wwt_Attribute36
                          ,NULL   --wwt_Attribute37
                          ,NULL   --wwt_Attribute38
                          ,NULL   --wwt_Attribute39
                          ,NULL   --wwt_Attribute40
                          ,NULL   --wwt_Attribute41
                          ,NULL   --wwt_Attribute42
                          ,NULL   --wwt_Attribute43
                          ,NULL   --wwt_Attribute44
                          ,NULL   --wwt_Attribute45
                          ,NULL   --wwt_Attribute46
                          ,NULL   --wwt_Attribute47
                          ,NULL   --wwt_Attribute48
                          ,NULL   --wwt_Attribute49
                          ,NULL   --wwt_Attribute50
                          ,NULL   --wwt_Attribute51
                          ,NULL   --wwt_Attribute52
                          ,NULL   --wwt_Attribute53
                          ,NULL   --wwt_Attribute54
                          ,NULL   --wwt_Attribute55
                          ,NULL   --wwt_Attribute56
                          ,NULL   --wwt_Attribute57
                          ,NULL   --wwt_Attribute58
                          ,NULL   --wwt_Attribute59
                          ,NULL   --wwt_Attribute60
                          ,NULL   --wwt_Attribute61
                          ,NULL   --wwt_Attribute62
                          ,NULL   --wwt_Attribute63
                          ,NULL   --wwt_Attribute64
                          ,NULL   --wwt_Attribute65
                          ,NULL   --wwt_Attribute66
                          ,NULL   --wwt_Attribute67
                          ,NULL   --wwt_Attribute68
                          ,NULL   --wwt_Attribute69
                          ,NULL   --wwt_Attribute70
                          ,NULL   --wwt_Attribute71
                          ,NULL   --wwt_Attribute72
                          ,NULL   --wwt_Attribute73
                          ,NULL   --wwt_Attribute74
                          ,NULL   --wwt_Attribute75
                          ,NULL   --wwt_Attribute76
                          ,NULL   --wwt_Attribute77
                          ,NULL   --wwt_Attribute78
                          ,NULL   --wwt_Attribute79
                          ,NULL   --wwt_Attribute80
                          ,NULL   --wwt_Attribute81
                          ,NULL   --wwt_Attribute82
                          ,NULL   --wwt_Attribute83
                          ,NULL   --wwt_Attribute84
                          ,NULL   --wwt_Attribute85
                          ,NULL   --wwt_Attribute86
                          ,NULL   --wwt_Attribute87
                          ,NULL   --wwt_Attribute88
                          ,NULL   --wwt_Attribute89
                          ,NULL   --wwt_Attribute90
                          ,NULL   --wwt_Attribute91
                          ,NULL   --wwt_Attribute92
                          ,NULL   --wwt_Attribute93
                          ,NULL   --wwt_Attribute94
                          ,NULL   --wwt_Attribute95
                          ,NULL   --wwt_Attribute96
                          ,NULL   --wwt_Attribute97
                          ,NULL   --wwt_Attribute98
                          ,NULL   --wwt_Attribute99
                          ,NULL   --wwt_Attribute100
                          ,0   -- object_index
                          ,0   -- item_api_tbl_index
                          ,NULL   -- call_item_api
                          ,NULL   -- pre_process_code
                          ,NULL   -- pre_process_status
                          ,NULL   -- post_process_code
                          ,NULL   -- post_process_status
                          ,NULL   -- item_status_message
                          ,NULL   -- prevent Item Api Call
                          ,NULL   -- process_record
                          );
      x_item_table               := l_item_table;
      apps.wwt_runtime_utilities.show_program_stack ('end');
   END populate_api_tbl;

   --------------------------------------------------------------------------------
   PROCEDURE insertitemmasterrec (
      iitemmasterrec             IN       apps.mtl_system_items_b%ROWTYPE
     ,itransactiontype           IN       VARCHAR2
     ,itemplateid                IN       NUMBER
     ,iinterfaceprocessflag      IN       NUMBER
     ,imanufacturerid            IN       VARCHAR2
     ,isetprocessid              IN       NUMBER
     ,iserial_controlled_flag    IN       VARCHAR2   -- Reference CHG12612
     ,oprocessflag               OUT      VARCHAR2
     ,oprocessmessage            OUT      VARCHAR2
     ,oreturncode                OUT      NUMBER
   )
   IS
      l_organization_id             NUMBER;
      l_error_code                  VARCHAR2 (100);
      l_message_list                error_handler.error_tbl_type;
      l_item_table                  wwt_item_tab_type := wwt_item_tab_type ();
                                                                              /*
   -----------------------------------------------------------------------------
   | Procedure Name:  insertitemmasterrec                                      |
   |                                                                           |
   | Description:Insert data in to table mtl_system_items_interface.           |
   -----------------------------------------------------------------------------
                                                                              */
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
--      apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' itransactiontype '
--                                                        || itransactiontype
--                                                        || ' itemplateid '
--                                                        || itemplateid
--                                                        || 'iinterfaceprocessflag'
--                                                        || iinterfaceprocessflag
--                                                        || 'imanufacturerid'
--                                                        || imanufacturerid
--                                                        || 'isetprocessid'
--                                                        || isetprocessid
--                                       ,p_level      => 1);\
                                       
        wwt_upload_generic.LOG (
         0,  ' itransactiontype '
                                                        || itransactiontype
                                                        || ' itemplateid '
                                                        || itemplateid
                                                        || 'iinterfaceprocessflag'
                                                        || iinterfaceprocessflag
                                                        || 'imanufacturerid'
                                                        || imanufacturerid
                                                        || 'isetprocessid'
                                                        || isetprocessid);
      -- Reference CHG12612
      populate_api_tbl (p_organization_id             => iitemmasterrec.organization_id
                       ,p_msib_rec                    => iitemmasterrec
                       ,p_transaction_type            => itransactiontype
                       ,p_template_id                 => itemplateid
                       ,p_manufacturer_id             => imanufacturerid
                       ,p_serial_controlled_flag      => iserial_controlled_flag
                       ,x_item_table                  => l_item_table
                       );
      -- Reference CHG12612
      apps.wwt_item_api_pkg.process_items (x_item_tbl             => l_item_table
                                          ,x_error_code           => l_error_code
                                          ,x_message_list         => l_message_list
                                          ,p_clear_intf_tbls      => 'Y'
                                          );
      --
      -- CHG12612 : Clear The local  object
      --
      l_item_table.DELETE;
      oprocessflag               := 'P';
      oprocessmessage            := 'Item Record Successfully Inserted';
      oreturncode                := 0;
      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN OTHERS
      THEN
         oprocessflag               := 'E';
         oprocessmessage            := SQLERRM;
         oreturncode                := 2;
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END insertitemmasterrec;

   --------------------------------------------------------------------------------
   PROCEDURE builditemmasterrec (
      icingularitemdatarec       IN       items%ROWTYPE
     ,iorgid                     IN       NUMBER
     ,imanufacturerid            IN       VARCHAR2
     ,oitemmasterrec             OUT      apps.mtl_system_items%ROWTYPE
     ,oprocessflag               OUT      VARCHAR2
     ,oprocessmessage            OUT      VARCHAR2
     ,oreturncode                OUT      NUMBER
   )
   IS
                                                                                 /*
      -----------------------------------------------------------------------------
      | Procedure Name:  builditemmasterrec                                       |
      |                                                                           |
      | Description: Create the item master record.                               |
      |                                                                           |
      |                                                                           |
      |                                                                           |
      -----------------------------------------------------------------------------
                                                                                 */
      l_serialcontrolledcode        NUMBER;
      l_itemtype                    VARCHAR2 (25);
   BEGIN
      DBMS_OUTPUT.put_line (   '  Build Item Master Rec  '
                            || '  iorgid '
                            || iorgid
                            || '  icingularitemdatarec.item_number  '
                            || icingularitemdatarec.item_number
                            || '  imanufacturerid  '
                            || imanufacturerid
                            || '  icingularitemdatarec.description  '
                            || REPLACE (LTRIM (RTRIM (icingularitemdatarec.description))
                                       ,';'
                                       ,','
                                       )
                            || '  l_itemtype  '
                            || l_itemtype
                            || '  oitemmasterrec.attribute15 '
                            || oitemmasterrec.attribute15
                            || '  icingularitemdatarec.list_price '
                            || icingularitemdatarec.list_price
                            || '  icingularitemdatarec.customer_part_number '
                            || icingularitemdatarec.customer_part_number
                            || '  l_serialcontrolledcode  '
                            || l_serialcontrolledcode);


      oitemmasterrec.attribute15      := icingularitemdatarec.msi_attribute15; -- CHG12612
      oitemmasterrec.organization_id := iorgid;
      oitemmasterrec.segment2    := icingularitemdatarec.item_number;
      oitemmasterrec.segment1    := imanufacturerid;
      oitemmasterrec.segment3    := 'ACTUAL';
      oitemmasterrec.segment4    := icingularitemdatarec.segment4; --  CHG12612
      oitemmasterrec.description := REPLACE (LTRIM (RTRIM (icingularitemdatarec.description))
                                            ,';'
                                            ,','
                                            );
      oitemmasterrec.item_type   := icingularitemdatarec.item_type; -- CHG12612
      oitemmasterrec.attribute1  := 'HW';
      --      oitemmasterrec.attribute15 := 'NO ORGS'; -- CHG11989
      oitemmasterrec.market_price := icingularitemdatarec.list_price;
      oitemmasterrec.attribute8  := icingularitemdatarec.customer_part_number;
      oitemmasterrec.full_lead_time := NULL;
      oitemmasterrec.primary_unit_of_measure := NULL;
      oitemmasterrec.primary_uom_code := INITCAP (icingularitemdatarec.primary_unit_of_measure);
      --Decode what is sent;
      oitemmasterrec.serial_number_control_code := l_serialcontrolledcode;
      oitemmasterrec.receiving_routing_id := 1;
      oitemmasterrec.attribute3  := icingularitemdatarec.item_tech;
      ---03252008 Added per INC 29106 ASR 91129976
      oitemmasterrec.attribute4  := icingularitemdatarec.item_status;
      oitemmasterrec.attribute5  := icingularitemdatarec.external_download_flag;
      oitemmasterrec.attribute6  := icingularitemdatarec.expenditure_type;
      oitemmasterrec.attribute9  := NULL;   --dimensions;
      oitemmasterrec.attribute12 := NULL;   --pallet_count;
      --Child Orgs 25
      oprocessflag               := 'P';
      oprocessmessage            := 'Item Record Successfully Built';
      oreturncode                := 0;
      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN OTHERS
      THEN
         oprocessflag               := 'E';
         oprocessmessage            := SQLERRM;
         oreturncode                := 2;
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END builditemmasterrec;

   --------------------------------------------------------------------------------
   PROCEDURE getmanufacturerid (
      imanufacturer              IN       partner_admin.wwt_cing_item_master_original.manufacturer%TYPE
     ,omanufacturerid            OUT      VARCHAR2
     ,oprocessflag               OUT      VARCHAR2
     ,oprocessmessage            OUT      VARCHAR2
     ,oreturncode                OUT      NUMBER
   )
   IS
                                                                                 /*
      -----------------------------------------------------------------------------
      | Procedure Name:  getmanufacturerid                                        |
      |                                                                           |
      | Description: This procedure will give the manufacturer id on basis of     |
      |              manufacturer.                                                |
      -----------------------------------------------------------------------------
                                                                                 */
      l_manufacturer                VARCHAR2 (200);
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    'imanufacturer              : '
                                                        || imanufacturer, p_level => 1);
      l_manufacturer             := UPPER (LTRIM (RTRIM (imanufacturer)));
      omanufacturerid            := 0;

      --See if manufacturer item exists
      SELECT m.manufacturer_id
      INTO   omanufacturerid
      FROM   repos_admin.manufacturer_mapping@repos.world mm
            ,repos_admin.manufacturer@repos.world m
      WHERE  m.manufacturer_id = mm.manufacturer_id
      AND    mm.manufacturer = l_manufacturer
      AND    mm.manufacturer_id <> -1;

      oprocessflag               := 'P';
      oprocessmessage            := 'Manufacturer Exists';
      oreturncode                := 0;
      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         oreturncode                :=
             repos_admin.store_load_procedures.map_manufacturer@repos.world (l_manufacturer
                                                                            ,omanufacturerid
                                                                            ,'Cingular ePL'
                                                                            );
         omanufacturerid            := 0;
         oprocessflag               := 'R';
         oprocessmessage            := 'Manufacturer Does Not Exist';
         oreturncode                := 2;
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END getmanufacturerid;

   --------------------------------------------------------------------------------
   PROCEDURE itemexistsandvalid (
      iitemnumber                IN OUT   partner_admin.wwt_cing_item_master_original.item_number%TYPE
     ,icustomerpartnumber        IN       partner_admin.wwt_cing_item_master_original.customer_part_number%TYPE
     ,imanufacturer              IN       partner_admin.wwt_cing_item_master_original.manufacturer%TYPE
     ,isegment4                  IN       mtl_system_items_b.segment4%TYPE     -- CHG12612
     ,iorgid                     IN       NUMBER
     ,oitemexists                OUT      BOOLEAN
     ,otransactiontype           OUT      VARCHAR2
     ,omanufacturerid            OUT      VARCHAR2
     ,oinventoryitemid           OUT      NUMBER
     ,ocontinueflag              OUT      VARCHAR2
     ,oprocessflag               OUT      VARCHAR2
     ,oprocessmessage            OUT      VARCHAR2
     ,oreturncode                OUT      NUMBER
     ,oitemtype                  OUT      VARCHAR2                             -- CHG12612
   )
   IS
                                                                                 /*
      -----------------------------------------------------------------------------
      | Procedure Name:  itemexistsandvalid                                       |
      |                                                                           |
      | Description:This procedure will check for existemce of items and          |
      |             manufacturers.                                                |
      -----------------------------------------------------------------------------
                                                                                 */
      l_itemcount                   NUMBER := 0;
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    'iitemnumber              : '
                                                        || iitemnumber
                                                        || ' icustomerpartnumber '
                                                        || icustomerpartnumber
                                                        || ' imanufacturer '
                                                        || imanufacturer
                                                        || 'iorgid'
                                                        || iorgid
                                       ,p_level      => 1);

      IF iitemnumber IS NULL
      THEN
         oprocessflag               := 'E';
         oprocessmessage            := 'Item Number is null';
         oreturncode                := 2;
         ocontinueflag              := 'N';
         apps.wwt_runtime_utilities.show_program_stack ('return 1');
         RETURN;
      END IF;
      dbms_output.put_line ( 'Before Calling getinventoryitemdetails');
      getinventoryitemdetails (iitemnumber
                              ,icustomerpartnumber
                              ,imanufacturer
                              ,isegment4            -- CHG12612
                              ,iorgid
                              ,oitemexists
                              ,omanufacturerid
                              ,oinventoryitemid
                              ,ocontinueflag
                              ,oprocessflag
                              ,oprocessmessage
                              ,oreturncode
                              ,oitemtype           -- CHG12612
                              );

      dbms_output.put_line ( 'After Calling getinventoryitemdetails');
      apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' iitemnumber '
                                                        || iitemnumber
                                                        || ' omanufacturerid '
                                                        || omanufacturerid
                                                        || ' oinventoryitemid '
                                                        || oinventoryitemid
                                                        || 'ocontinueflag'
                                                        || ocontinueflag
                                                        || 'oprocessflag'
                                                        || oprocessflag
                                                        || 'oprocessmessage'
                                                        || oprocessmessage
                                                        || 'oreturncode'
                                                        || oreturncode
                                       ,p_level      => 2);

      IF     oitemexists = FALSE
         AND oreturncode = 0
      THEN
         getmanufacturerid (imanufacturer
                           ,omanufacturerid
                           ,oprocessflag
                           ,oprocessmessage
                           ,oreturncode
                           );
         apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' omanufacturerid '
                                                           || omanufacturerid
                                                           || 'oprocessflag'
                                                           || oprocessflag
                                                           || 'oprocessmessage'
                                                           || oprocessmessage
                                                           || 'oreturncode'
                                                           || oreturncode
                                          ,p_level      => 2);

         IF oreturncode = 0
         THEN
            otransactiontype           := 'CREATE';
            apps.wwt_runtime_utilities.show_program_stack ('return 2');
            RETURN;
         ELSE
            oitemexists                := FALSE;
            oreturncode                := 2;
            oprocessmessage            := 'Manufacturer Does not Exist';
            ocontinueflag              := 'N';
            apps.wwt_runtime_utilities.show_program_stack ('return 3');
            RETURN;
         END IF;
      ELSE
         otransactiontype           := 'UPDATE';
         apps.wwt_runtime_utilities.show_program_stack ('return 4');
         RETURN;
      END IF;   --End of IF     oitemexists = FALSE

      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN OTHERS
      THEN
         oprocessflag               := 'E';
         oprocessmessage            := SQLERRM;
         oreturncode                := 2;
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END itemexistsandvalid;

   --------------------------------------------------------------------------------
   PROCEDURE processitems
   IS
                                                                                 /*
      -----------------------------------------------------------------------------
      | Procedure Name:  processitems                                             |
      |                                                                           |
      | Description: This procedure finally processes the items and calls the      |
      |              procedure to insert into mtl_system_items_interface.         |
      |                                                                           |
      |                                                                           |
      |                                                                           |
      -----------------------------------------------------------------------------
                                                                                 */
      l_orgcount                    NUMBER := 3;
      l_orgloopcount                NUMBER := 0;
      l_processflag                 partner_admin.wwt_cing_item_master_original.process_flag%TYPE;
      l_processmessage              partner_admin.wwt_cing_item_master_original.MESSAGE%TYPE;
      l_returncode                  NUMBER := 0;
      l_itemmasterrec               apps.mtl_system_items%ROWTYPE;
      l_orgid                       apps.mtl_system_items.organization_id%TYPE;
      l_templateid                  NUMBER;
      l_itemexists                  BOOLEAN := FALSE;
      l_transactiontype             VARCHAR2 (100);
      l_manufacturerid              VARCHAR2 (10);
      l_interfaceprocessflag        NUMBER := 1;
      l_setprocessid                NUMBER := 1;
      l_createcount                 NUMBER := 0;
      l_updatecount                 NUMBER := 0;
      l_continueflag                VARCHAR2 (1);
      l_inventoryitemid             apps.mtl_system_items.inventory_item_id%TYPE;
      --
      -- New Variables
      --
      l_wwt_item_tab1               wwt_item_tab_type := wwt_item_tab_type (); -- CHG12612
      l_wwt_item_tab_temp           wwt_item_tab_type := wwt_item_tab_type ();
      l_template_name               VARCHAR2 (240);
      l_itemtype                    VARCHAR2 (25);
      l_error_code                  VARCHAR2 (1000);
      l_error_message               VARCHAR2 (4000);
      l_mesg_list                   error_handler.error_tbl_type;
      l_serialcontrolledcode        NUMBER;
      l_msib_rec                    apps.mtl_system_items_b%ROWTYPE;          -- CHG12612
      l_msi_item_type               mtl_system_items_b.ITEM_TYPE%TYPE;        -- CHG12612
   BEGIN
      apps.wwt_runtime_utilities.show_program_stack ('begin');
      apps.wwt_runtime_utilities.DEBUG (p_text       => 'items Values:', p_level => 2);

      FOR items_rec IN items
      LOOP
      
      wwt_upload_generic.LOG (
         0,
            '  item_status   - ' || items_rec.item_status
                                                           || '  item_number   - '
                                                           || items_rec.item_number
                                                           || '  manufacturer   - '
                                                           || items_rec.manufacturer
                                                           || '  description   - '
                                                           || items_rec.description
                                                           || '  serial_controlled_flag   - '
                                                           || items_rec.serial_controlled_flag
                                                           || '  item_type   - '
                                                           || items_rec.item_type
                                                           || '  list_price   - '
                                                           || items_rec.list_price
                                                           || '  customer_part_number   - '
                                                           || items_rec.customer_part_number
                                                           || '  primary_unit_of_measure   - '
                                                           || items_rec.primary_unit_of_measure
                                                           || '  external_download_flag   - '
                                                           || items_rec.external_download_flag
                                                           || '  expenditure_type   - '
                                                           || items_rec.expenditure_type
                                                           || '  bom_item_type   - '
                                                           || items_rec.bom_item_type
                                                           || '  cing_last_update_date   - '
                                                           || items_rec.cing_last_update_date
                                                           || '  created_by   - '
                                                           || items_rec.created_by
                                                           || '  creation_date   - '
                                                           || items_rec.creation_date
                                                           || '  last_update_date   - '
                                                           || items_rec.last_update_date
                                                           || '  last_updated_by   - '
                                                           || items_rec.last_updated_by
                                                           || '  process_flag   - '
                                                           || items_rec.process_flag
                                                           || '  MESSAGE   - '
                                                           || items_rec.MESSAGE
                                                           || '  interface_transaction_id   - '
                                                           || items_rec.interface_transaction_id
                                                           || '  tbuy_interface_error_id   - '
                                                           || items_rec.tbuy_interface_error_id);
                                                           
--         apps.wwt_runtime_utilities.DEBUG (p_text       =>    '  item_status   - '
--                                                           || items_rec.item_status
--                                                           || '  item_number   - '
--                                                           || items_rec.item_number
--                                                           || '  manufacturer   - '
--                                                           || items_rec.manufacturer
--                                                           || '  description   - '
--                                                           || items_rec.description
--                                                           || '  serial_controlled_flag   - '
--                                                           || items_rec.serial_controlled_flag
--                                                           || '  item_type   - '
--                                                           || items_rec.item_type
--                                                           || '  list_price   - '
--                                                           || items_rec.list_price
--                                                           || '  customer_part_number   - '
--                                                           || items_rec.customer_part_number
--                                                           || '  primary_unit_of_measure   - '
--                                                           || items_rec.primary_unit_of_measure
--                                                           || '  external_download_flag   - '
--                                                           || items_rec.external_download_flag
--                                                           || '  expenditure_type   - '
--                                                           || items_rec.expenditure_type
--                                                           || '  bom_item_type   - '
--                                                           || items_rec.bom_item_type
--                                                           || '  cing_last_update_date   - '
--                                                           || items_rec.cing_last_update_date
--                                                           || '  created_by   - '
--                                                           || items_rec.created_by
--                                                           || '  creation_date   - '
--                                                           || items_rec.creation_date
--                                                           || '  last_update_date   - '
--                                                           || items_rec.last_update_date
--                                                           || '  last_updated_by   - '
--                                                           || items_rec.last_updated_by
--                                                           || '  process_flag   - '
--                                                           || items_rec.process_flag
--                                                           || '  MESSAGE   - '
--                                                           || items_rec.MESSAGE
--                                                           || '  interface_transaction_id   - '
--                                                           || items_rec.interface_transaction_id
--                                                           || '  tbuy_interface_error_id   - '
--                                                           || items_rec.tbuy_interface_error_id
--                                          ,p_level      => 2);
         l_orgloopcount             := 0;
         l_transactiontype          := NULL;
         l_template_name            := NULL;
         l_templateid               := NULL;
         --
         -- Check if item already exists.
         --
         itemexistsandvalid (items_rec.item_number
                            ,items_rec.customer_part_number
                            ,items_rec.manufacturer
                            ,items_rec.segment4   -- CHG12612
                            ,101
                            ,l_itemexists
                            ,l_transactiontype
                            ,l_manufacturerid
                            ,l_inventoryitemid
                            ,l_continueflag
                            ,l_processflag
                            ,l_processmessage
                            ,l_returncode
                            ,l_msi_item_type      -- CHG12612
                            );

        -- Start of changes for CHG12612

         IF l_itemexists = FALSE
         THEN
--           DBMS_OUTPUT.put_line (   ' itemexistsandvalid '
--                                    || ' Item DOES NOT  Exist'
--                                    || ' Item #: '
--                                    || items_rec.item_number
--                                    || ' Org: '
--                                    || l_orgid
--                                    || ' Continue: '
--                                    || l_continueflag
--                                  );
                                  
                                  wwt_upload_generic.LOG (
         0,' itemexistsandvalid '
                                    || ' Item DOES NOT  Exist'
                                    || ' Item #: '
                                    || items_rec.item_number
                                    || ' Org: '
                                    || l_orgid
                                    || ' Continue: '
                                    || l_continueflag);
         ELSE
          DBMS_OUTPUT.put_line (   ' itemexistsandvalid '
                                    || ' Item Exists'
                                    || ' Item #: '
                                    || items_rec.item_number
                                    || ' Org: '
                                    || l_orgid
                                    || ' Continue: '
                                    || l_continueflag
                                  );
                                  
                                  wwt_upload_generic.LOG (
         0,' itemexistsandvalid '
                                    || ' Item Exists'
                                    || ' Item #: '
                                    || items_rec.item_number
                                    || ' Org: '
                                    || l_orgid
                                    || ' Continue: '
                                    || l_continueflag);
         END IF;
         apps.wwt_runtime_utilities.DEBUG (p_text       =>    'otransactiontype              : '
                                                           || l_transactiontype
                                                           || ' omanufacturerid '
                                                           || l_manufacturerid
                                                           || ' oinventoryitemid '
                                                           || l_inventoryitemid
                                                           || 'ocontinueflag'
                                                           || l_continueflag
                                                           || 'oprocessflag'
                                                           || l_processflag
                                                           || 'oprocessmessage'
                                                           || l_processmessage
                                                           || 'oreturncode'
                                                           || l_returncode
                                          ,p_level      => 2);
         --
         -- If Bom Item Type is MODEL get the template id for
         -- Cingular PTO KIT
         --
         IF NVL (UPPER (items_rec.bom_item_type), 'STANDARD') = 'MODEL'
         THEN
             l_templateid               := get_item_template_id ('Cingular PTO KIT');
         END IF;

         IF l_itemexists = FALSE   -- Item Does Not Exist
         THEN
            l_transactiontype          := 'CREATE';
            l_createcount              :=   l_createcount + 1;
            l_orgid := 101;

            IF l_continueflag = 'Y'
            THEN
               IF NVL (UPPER (items_rec.bom_item_type), 'STANDARD') = 'MODEL'
               THEN
                    --
                    -- Assign template_id which is defaulted in the lookup
                    -- WWT_ATT_ITEM_TEMPLATES ( attribute3)
                   l_templateid               := items_rec.template_id ;
               END IF;

               builditemmasterrec (items_rec
                                  ,l_orgid
                                  ,l_manufacturerid
                                  ,l_itemmasterrec
                                  ,l_processflag
                                  ,l_processmessage
                                  ,l_returncode
                                  );
               apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' oprocessflag '
                                                                 || l_processflag
                                                                 || ' oprocessmessage '
                                                                 || l_processmessage
                                                                 || 'oreturncode'
                                                                 || l_returncode
                                                ,p_level      => 2);
               DBMS_OUTPUT.put_line (   'Inserting rec for customer part #: '
                                        || l_itemmasterrec.attribute8
                                        || ' Org id: '
                                        || l_itemmasterrec.organization_id
                                      );
               --
               -- Proceed to process items
               --
               insertitemmasterrec (l_itemmasterrec
                                   ,l_transactiontype
                                   ,l_templateid
                                   ,l_interfaceprocessflag
                                   ,l_manufacturerid
                                   ,l_setprocessid
                                   ,items_rec.serial_controlled_flag
                                   ,l_processflag
                                   ,l_processmessage
                                   ,l_returncode
                                   );
               --
               --
               --
               apps.wwt_runtime_utilities.DEBUG (p_text       =>    ' oprocessflag '
                                                                 || l_processflag
                                                                 || ' oprocessmessage '
                                                                 || l_processmessage
                                                                 || 'oreturncode'
                                                                 || l_returncode
                                                ,p_level      => 2);
            ELSE
               DBMS_OUTPUT.put_line (   'Error on Item: '
                                     || items_rec.item_number
                                     || ' : '
                                     || l_processmessage);
            END IF;   -- End of IF l_continueflag = 'Y'
         END IF;   -- End of IF l_itemexists = FALSE

         IF l_itemexists = TRUE   -- Item Does Exist
         THEN
          --
          -- Check prevent item_type change from MODEL to anything else
          --
          dbms_output.put_line( 'l_msi_item_type :' || l_msi_item_type || ' items_rec.bom_item_type :' || items_rec.bom_item_type);
          IF UPPER(l_msi_item_type) = 'PTO KIT' and UPPER(items_rec.bom_item_type) <> 'MODEL' then
              l_continueflag := 'N';
              l_processmessage := 'Item TYpe Violation( Model TO Standard )';
              l_processflag    := 'E';
          ELSE
            l_transactiontype          := 'UPDATE';
            l_updatecount              :=   l_updatecount + 1;
          END IF;


            IF l_continueflag = 'Y'
            THEN
               FOR organization_id_rec IN organization_id_cur ( p_msi_orgs =>  items_rec.msi_attribute15)
               LOOP
                  apps.wwt_runtime_utilities.DEBUG( p_text       =>   'Updating rec for customer part #: '
                                                                      || items_rec.customer_part_number
                                                                      || ' Org id: '  || organization_id_rec.organization_id
                                                                      || 'l_inventoryitemid ' || l_inventoryitemid
                                                  ,p_level       => 2
                                                  );
                  --
                  -- Set item type and template id
                  --
                  IF items_rec.template_id IS NOT NULL THEN
                    l_templateid               := items_rec.template_id;
                  ELSE
                      BEGIN

                         SELECT attribute3
                         INTO   l_templateid
                         FROM   apps.wwt_lookups
                         WHERE  1 = 1
                         AND    lookup_type = 'WWT_ORG_DESTINATION_DETAILS'
                         AND    attribute1 = items_rec.msi_attribute15
                         AND    attribute2 = organization_id_rec.organization_id;

                         EXCEPTION
                         WHEN OTHERS THEN
                              l_templateid := 350;
                      END;
                  END IF;

                  --
                  -- Set serial control Flag based on the combination of lookup value
                  -- and passed in value
                  --
                  IF items_rec.serial_controlled_flag = 'Y' and items_rec.wwt_serial_control_flag = 'Y' THEN
                     l_serialcontrolledcode     := 5;
                  ELSE
                     l_serialcontrolledcode     := 1;
                  END IF;

                  l_itemtype                                                         := items_rec.item_type;
                  -- Reference CHG12612
                  l_msib_rec.inventory_item_id                                       := l_inventoryitemid;
                  l_msib_rec.organization_id                                         := organization_id_rec.organization_id;
                  l_msib_rec.segment1                                                := l_manufacturerid;
                  l_msib_rec.segment2                                                := items_rec.item_number;
                  --
                  -- Start CHG16489
                  -- All 4 segments are required for generating the lock
                  -- Segment3 is hardcoded to ACTUAL for this CING Program.
                  l_msib_rec.segment3                                                := 'ACTUAL';
                  l_msib_rec.segment4                                                := items_rec.segment4;
                  --
                  -- End CHG16489
                  -- 4 segments are required for generating the lock
                  --
                  l_msib_rec.item_type                                               := l_itemtype;
                  l_msib_rec.attribute8                                              := items_rec.customer_part_number;
                  l_msib_rec.primary_uom_code                                        := INITCAP (items_rec.primary_unit_of_measure);
                  l_msib_rec.serial_number_control_code                              := l_serialcontrolledcode;
                  l_msib_rec.attribute3                                              := items_rec.item_tech;
                  l_msib_rec.attribute4                                              := items_rec.item_status;
                  l_msib_rec.attribute5                                              := items_rec.external_download_flag;
                  l_msib_rec.attribute6                                              := items_rec.expenditure_type;

                  populate_api_tbl (p_organization_id             => organization_id_rec.organization_id
                                   ,p_msib_rec                    => l_msib_rec
                                   ,p_transaction_type            => l_transactiontype
                                   ,p_template_id                 => l_templateid
                                   ,p_manufacturer_id             => l_manufacturerid
                                   ,p_serial_controlled_flag      => items_rec.serial_controlled_flag
                                   ,x_item_table                  => l_wwt_item_tab_temp
                                   );
                 l_wwt_item_tab1.EXTEND;
                 l_wwt_item_tab1(l_wwt_item_tab1.COUNT) := l_wwt_item_tab_temp(l_wwt_item_tab_temp.count);
                  --
                  -- set all other values as required by the program
                  --
                  l_wwt_item_tab1 (l_wwt_item_tab1.COUNT).wwt_item_creation_source  := 'ATT';
                  l_wwt_item_tab1 (l_wwt_item_tab1.COUNT).market_price              := items_rec.list_price;
                  l_wwt_item_tab1 (l_wwt_item_tab1.COUNT).description               := REPLACE (LTRIM (RTRIM (items_rec.description))
                                                                                               ,';'
                                                                                               ,','
                                                                                              );
                  apps.wwt_runtime_utilities.DEBUG (p_text       =>    'apps.wwt_item_api_pkg.process_items     : '
                                                                    || ' l_error_code '
                                                                    || l_error_code
                                                   ,p_level      => 2
                                                  );
               END LOOP organization_id_rec;
               --
               -- Call item Api once after exploding org Records
               --
               apps.wwt_item_api_pkg.process_items (x_item_tbl          => l_wwt_item_tab1
                                                   ,x_error_code        => l_error_code
                                                   ,x_message_list      => l_mesg_list
                                                   );
               FOR i IN 1 .. l_mesg_list.COUNT
                LOOP
                     IF ( lengthb (l_mesg_list (i).MESSAGE_TEXT) + lengthb (l_processmessage) )> 1000 THEN
                        EXIT;
                     END IF;
                     l_processmessage := l_processmessage || l_mesg_list (i).MESSAGE_TEXT;
                     l_processflag    := l_error_code;
                END LOOP;   -- End of FOR i IN 1 .. l_mesg_list.COUNT
                --
                -- This delete will prevent update submissions of previously
                -- processed records
                --
                l_wwt_item_tab1.DELETE;
                l_wwt_item_tab_temp.DELETE;
            ELSE
               DBMS_OUTPUT.put_line (   'Error on Item: '
                                     || items_rec.item_number
                                     || ' : '
                                     || l_processmessage);
            END IF;   -- End of IF l_continueflag = 'Y'
         END IF;   -- End of IF l_itemexists = TRUE
         updateitemstagingrec (items_rec
                              ,l_processflag
                              ,l_processmessage
                              ,l_returncode
                              );
         apps.wwt_runtime_utilities.DEBUG ( p_text  => 'oreturncode' || l_returncode
                                           ,p_level => 2
                                          );
      END LOOP items_rec;

      DBMS_OUTPUT.put_line (   'Items Created: '
                            || l_createcount);
      DBMS_OUTPUT.put_line (   'Items Updated: '
                            || l_updatecount);
      apps.wwt_runtime_utilities.show_program_stack ('end');
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line (   'FATAL ERROR: Pkg WWT_CING_ITEM_MASTER_MGMT.processItems '
                               || 'Error Message: '
                               || SQLERRM);
         apps.wwt_runtime_utilities.show_program_stack ('exception 1');
         apps.wwt_runtime_utilities.flush_message_stack;
   END processitems;
END wwt_cing_item_master_mgmt;
/