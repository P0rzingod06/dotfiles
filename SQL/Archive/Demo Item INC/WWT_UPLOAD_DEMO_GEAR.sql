CREATE OR REPLACE PACKAGE BODY APPS.WWT_UPLOAD_DEMO_GEAR IS

-- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_upload_demo_gear.plb,v $, $Revision: 1.1 $, $Author: dupontb $, $Date: 2011/09/30 03:35:23 $
/*******************************************************************************

   NAME:       APPS.WWT_UPLOAD_DEMO_GEAR

   PURPOSE:   To load Item files from Demo Gear GUC.

   REVISIONS:
   Ver        Date         CHG#       Author       Description
   ---------  -----------  ---------  -----------  ------------------------------------
   1.1        16-SEP-2011  CHG20107   dupontb      Created this package
********************************************************************************/
    --Added for session fixes due to global variables and webmethods cached JDBC pools
    PRAGMA SERIALLY_REUSABLE;

    -- Cursor defined --
    CURSOR g_item_data_cur  (cp_segment4 IN VARCHAR2,
                           cp_org_id   IN NUMBER)
      IS

        SELECT wdgie.*,
--
               (select max (msib.inventory_item_id)
                 from  mtl_system_items_b msib
                where 1=1
                  AND msib.organization_id = cp_org_id
                  AND msib.segment2 = wdgie.manufacturer_part_number
                  AND msib.segment4 = cp_segment4) inventory_item_id,
--
               (SELECT ffvt.description mfg_name
                  FROM fnd_flex_values_vl ffvt,
                       fnd_flex_value_sets ffvs,
                       fnd_flex_values_vl ffv
                 WHERE     1 = 1
                       AND ffv.flex_value_id = ffvt.flex_value_id
                       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                       AND ffvs.flex_value_set_name = 'Manufacturer'
                       AND wdgie.manufacturer = ffv.flex_value) mfg_name
--
          FROM wwt_demo_gear_item_ext wdgie;



    TYPE g_item_data_tab_type IS TABLE OF g_item_data_cur%ROWTYPE INDEX BY BINARY_INTEGER;
    g_item_data_tab    g_item_data_tab_type;

  /*------------------------------------------------------------------------------
     Purpose: Find inventory_id based on part_number from upload file and
              compare to segment2 in mtl_system_items_b.
  --------------------------------------------------------------------------------*/
    FUNCTION get_inventory_item_id ( p_manufacturer IN VARCHAR2,
                                     p_part_number  IN VARCHAR2,
                                     p_segment3     IN VARCHAR2,
                                     p_segment4     IN VARCHAR2,
                                     p_org_id       IN NUMBER)

    RETURN NUMBER

    IS
        -- Local variables
        l_inventory_item_id   mtl_system_items_b.inventory_item_id%TYPE;

    BEGIN

        wwt_upload_generic.LOG(2, 'BEGIN get_inventory_item_id procedure.');

        IF p_part_number IS NOT NULL THEN

           SELECT msib.inventory_item_id
             INTO l_inventory_item_id
             FROM mtl_system_items_b msib
            WHERE 1=1
              AND msib.segment1 = p_manufacturer
              AND msib.segment3 = p_segment3
              AND msib.segment4 = p_segment4
              AND msib.organization_id = p_org_id
              AND msib.segment2 = p_part_number;

       ELSE
         l_inventory_item_id := NULL;
       END IF;

           wwt_upload_generic.LOG(1, 'l_inventory_item_id: '||l_inventory_item_id);
           RETURN  l_inventory_item_id;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN
         RETURN NULL;

       WHEN OTHERS THEN
         raise_application_error(-20013, 'Fatal Error in function get_inventory_item_id; Model Number: '||p_part_number||
                                         '; Error => '||SQLERRM);

    END get_inventory_item_id;

  /*------------------------------------------------------------------------------
     Purpose: Build API table object (apps.wwt_item_api_object) that will be used
              by an API pkg that will load msi table.
              API pkg called: apps.wwt_item_api_pkg
  --------------------------------------------------------------------------------*/
    PROCEDURE build_api_object_tbl (     p_item_rec            IN g_item_data_cur%ROWTYPE
                                        ,p_organization_id     IN NUMBER
                                        ,p_transaction_type    IN VARCHAR2
                                        ,p_segment4            IN VARCHAR2
                                        ,p_user_id             IN VARCHAR2
                                        ,x_item_table         OUT wwt_item_tab_type)
    IS
       -- Local variables
       l_item_table    wwt_item_tab_type := wwt_item_tab_type ();

      BEGIN

         wwt_upload_generic.LOG(2, 'BEGIN build_api_object_tbl');

          l_item_table.EXTEND;
          l_item_table (l_item_table.COUNT) :=
             wwt_item_api_obj (p_transaction_type   -- transaction_type
                              ,NULL   -- return_status
                              ,NULL   -- language_code
                              ,NULL   -- copy_inventory_item_id
                              ,NULL   --p_template_id
                              ,NULL   -- template_name
                              ,NULL   --inventory_item_id
                              ,NULL   -- item_number
                              ,p_item_rec.manufacturer --segment1
                              ,p_item_rec.manufacturer_part_number --segment2
                              ,p_item_rec.cost_segment --segment3
                              ,p_segment4 --segment4
                              ,NULL -- segment5
                              ,NULL -- segment6
                              ,NULL -- segment7
                              ,NULL -- segment8
                              ,NULL -- segment9
                              ,NULL -- segment10
                              ,NULL -- segment11
                              ,NULL -- segment12
                              ,NULL -- segment13
                              ,NULL -- segment14
                              ,NULL -- segment15
                              ,NULL -- segment16
                              ,NULL -- segment17
                              ,NULL -- segment18
                              ,NULL -- segment19
                              ,NULL -- segment20
                              ,NULL -- summary_flag
                              ,NULL -- enabled_flag
                              ,NULL -- start_date_active
                              ,NULL -- end_date_active
                              ,p_organization_id
                              ,NULL   -- organization_code
                              ,NULL   -- item_catalog_group_id
                              ,NULL   -- catalog_status_flag
                              ,NULL   -- lifecycle_id
                              ,NULL   -- current_phase_id
                              -- main attributes --
                              ,p_item_rec.description --description
                              ,NULL   --long_description
                              ,'Ea'   --primary_uom_code
                              ,NULL   --allowed_units_lookup_code
                              ,NULL   --inventory_item_status_code
                              ,NULL   --dual_uom_control
                              ,NULL   --secondary_uom_code
                              ,NULL   --dual_uom_deviation_high
                              ,NULL   --dual_uom_deviation_low
                              ,NULL   --item_type
                              -- inventory --
                              ,NULL --inventory_item_flag
                              ,NULL --stock_enabled_flag
                              ,NULL --mtl_transactions_enabled_flag
                              ,NULL --revision_qty_control_code
                              ,NULL --lot_control_code
                              ,NULL --auto_lot_alpha_prefix
                              ,NULL --start_auto_lot_number
                              ,p_item_rec.serial_control --serial_number_control_code
                              ,NULL --auto_serial_alpha_prefix
                              ,NULL --start_auto_serial_number
                              ,NULL --shelf_life_code
                              ,NULL --shelf_life_days
                              ,NULL --restrict_subinventories_code
                              ,NULL --location_control_code
                              ,NULL --restrict_locators_code
                              ,NULL --reservable_type
                              ,NULL --cycle_count_enabled_flag
                              ,NULL --negative_measurement_error
                              ,NULL --positive_measurement_error
                              ,NULL --check_shortages_flag
                              ,NULL --lot_status_enabled
                              ,NULL --default_lot_status_id
                              ,NULL --serial_status_enabled
                              ,NULL --default_serial_status_id
                              ,NULL --lot_split_enabled
                              ,NULL --lot_merge_enabled
                              ,NULL --lot_translate_enabled
                              ,NULL --lot_substitution_enabled
                              ,NULL --bulk_picked_flag
                              -- bills of material --
                              ,NULL --bom_item_type
                              ,NULL --bom_enabled_flag
                              ,NULL --base_item_id
                              ,NULL --eng_item_flag
                              ,NULL --engineering_item_id
                              ,NULL --engineering_ecn_code
                              ,NULL --engineering_date
                              ,NULL --effectivity_control
                              ,NULL --config_model_type
                              ,NULL --product_family_item_id
                              ,NULL --auto_created_config_flag
                              -- costing --
                              ,NULL --costing_enabled_flag
                              ,NULL --inventory_asset_flag
                              ,NULL --cost_of_sales_account
                              ,NULL --default_include_in_rollup_flag
                              ,NULL --std_lot_size
                              -- enterprise asset management --
                              ,NULL --eam_item_type
                              ,NULL --eam_activity_type_code
                              ,NULL --eam_activity_cause_code
                              ,NULL --eam_activity_source_code
                              ,NULL --eam_act_shutdown_status
                              ,NULL --eam_act_notification_flag
                              -- purchasing --
                              ,NULL --purchasing_item_flag
                              ,NULL --purchasing_enabled_flag
                              ,NULL --buyer_id
                              ,NULL --must_use_approved_vendor_flag
                              ,NULL --purchasing_tax_code
                              ,NULL --taxable_flag
                              ,NULL --receive_close_tolerance
                              ,NULL --allow_item_desc_update_flag
                              ,NULL --inspection_required_flag
                              ,NULL --receipt_required_flag
                              ,p_item_rec.market_price --market_price
                              ,NULL --un_number_id
                              ,NULL --hazard_class_id
                              ,NULL --rfq_required_flag
                              ,p_item_rec.list_price --list_price_per_unit
                              ,NULL --price_tolerance_percent
                              ,NULL --asset_category_id
                              ,NULL --rounding_factor
                              ,NULL --unit_of_issue
                              ,NULL --outside_operation_flag
                              ,NULL --outside_operation_uom_type
                              ,NULL --invoice_close_tolerance
                              ,NULL --encumbrance_account
                              ,NULL --expense_account
                              ,NULL --qty_rcv_exception_code
                              ,NULL --receiving_routing_id
                              ,NULL --qty_rcv_tolerance
                              ,NULL --enforce_ship_to_location_code
                              ,NULL --allow_substitute_receipts_flag
                              ,NULL --allow_unordered_receipts_flag
                              ,NULL --allow_express_delivery_flag
                              ,NULL --days_early_receipt_allowed
                              ,NULL --days_late_receipt_allowed
                              ,NULL --receipt_days_exception_code
                              -- physical --
                              ,NULL --weight_uom_code
                              ,NULL --unit_weight
                              ,NULL --volume_uom_code
                              ,NULL --unit_volume
                              ,NULL --container_item_flag
                              ,NULL --vehicle_item_flag
                              ,NULL --maximum_load_weight
                              ,NULL --minimum_fill_percent
                              ,NULL --internal_volume
                              ,NULL --container_type_code
                              ,NULL --collateral_flag
                              ,NULL --event_flag
                              ,NULL --equipment_type
                              ,NULL --electronic_flag
                              ,NULL --downloadable_flag
                              ,NULL --indivisible_flag
                              ,NULL --dimension_uom_code
                              ,NULL --unit_length
                              ,NULL --unit_width
                              ,NULL --unit_height
                              --planing --
                              ,NULL --inventory_planning_code
                              ,NULL --planner_code
                              ,NULL --planning_make_buy_code
                              ,NULL --min_minmax_quantity
                              ,NULL --max_minmax_quantity
                              ,NULL --safety_stock_bucket_days
                              ,NULL --carrying_cost
                              ,NULL --order_cost
                              ,NULL --mrp_safety_stock_percent
                              ,NULL --mrp_safety_stock_code
                              ,NULL --fixed_order_quantity
                              ,NULL --fixed_days_supply
                              ,NULL --minimum_order_quantity
                              ,NULL --maximum_order_quantity
                              ,NULL --fixed_lot_multiplier
                              ,NULL --source_type
                              ,NULL --source_organization_id
                              ,NULL --source_subinventory
                              ,NULL --mrp_planning_code
                              ,NULL --ato_forecast_control
                              ,NULL --planning_exception_set
                              ,NULL --shrinkage_rate
                              ,NULL --end_assembly_pegging_flag
                              ,NULL --rounding_control_type
                              ,NULL --planned_inv_point_flag
                              ,NULL --create_supply_flag
                              ,NULL --acceptable_early_days
                              ,NULL --mrp_calculate_atp_flag
                              ,NULL --auto_reduce_mps
                              ,NULL --repetitive_planning_flag
                              ,NULL --overrun_percentage
                              ,NULL --acceptable_rate_decrease
                              ,NULL --acceptable_rate_increase
                              ,NULL --planning_time_fence_code
                              ,NULL --planning_time_fence_days
                              ,NULL --demand_time_fence_code
                              ,NULL --demand_time_fence_days
                              ,NULL --release_time_fence_code
                              ,NULL --release_time_fence_days
                              ,NULL --substitution_window_code
                              ,NULL --substitution_window_days
                              -- lead times --
                              ,NULL --preprocessing_lead_time
                              ,NULL --full_lead_time
                              ,NULL --postprocessing_lead_time
                              ,NULL --fixed_lead_time
                              ,NULL --variable_lead_time
                              ,NULL --cum_manufacturing_lead_time
                              ,NULL --cumulative_total_lead_time
                              ,NULL --lead_time_lot_size
                              -- wip --
                              ,NULL --build_in_wip_flag
                              ,NULL --wip_supply_type
                              ,NULL --wip_supply_subinventory
                              ,NULL --wip_supply_locator_id
                              ,NULL --overcompletion_tolerance_type
                              ,NULL --overcompletion_tolerance_value
                              ,NULL --inventory_carry_penalty
                              ,NULL --operation_slack_penalty
                              -- order management --
                              ,NULL --customer_order_flag
                              ,NULL --customer_order_enabled_flag
                              ,NULL --internal_order_flag
                              ,NULL --internal_order_enabled_flag
                              ,NULL --shippable_item_flag
                              ,NULL --so_transactions_flag
                              ,NULL --picking_rule_id
                              ,NULL --pick_components_flag
                              ,NULL --replenish_to_order_flag
                              ,NULL --atp_flag
                              ,NULL --atp_components_flag
                              ,NULL --atp_rule_id
                              ,NULL --ship_model_complete_flag
                              ,NULL --default_shipping_org
                              ,NULL --default_so_source_type
                              ,NULL --returnable_flag
                              ,NULL --return_inspection_requirement
                              ,NULL --over_shipment_tolerance
                              ,NULL --under_shipment_tolerance
                              ,NULL --over_return_tolerance
                              ,NULL --under_return_tolerance
                              ,NULL --financing_allowed_flag
                              ,NULL --vol_discount_exempt_flag
                              ,NULL --coupon_exempt_flag
                              ,NULL --invoiceable_item_flag
                              ,NULL --invoice_enabled_flag
                              ,NULL --accounting_rule_id
                              ,NULL --invoicing_rule_id
                              ,NULL --tax_code
                              ,NULL --sales_account
                              ,NULL --payment_terms_id
                              -- service --
                              ,NULL --contract_item_type_code
                              ,NULL --service_duration_period_code
                              ,NULL --service_duration
                              ,NULL --coverage_schedule_id
                              ,NULL --subscription_depend_flag
                              ,NULL --serv_importance_level
                              ,NULL --serv_req_enabled_code
                              ,NULL --comms_activation_reqd_flag
                              ,NULL --serviceable_product_flag
                              ,NULL --material_billable_flag
                              ,NULL --serv_billing_enabled_flag
                              ,NULL --defect_tracking_on_flag
                              ,NULL --recovered_part_disp_code
                              ,NULL --comms_nl_trackable_flag
                              ,NULL --asset_creation_code
                              ,NULL --ib_item_instance_class
                              ,NULL --service_starting_delay
                              -- web option --
                              ,NULL --web_status
                              ,NULL --orderable_on_web_flag
                              ,NULL --back_orderable_flag
                              ,NULL --minimum_license_quantity
                              -- start:  26 new attributes --
                              ,NULL --tracking_quantity_ind
                              ,NULL --ont_pricing_qty_source
                              ,NULL --secondary_default_ind
                              ,NULL --option_specific_sourced
                              ,NULL --vmi_minimum_units
                              ,NULL --vmi_minimum_days
                              ,NULL --vmi_maximum_units
                              ,NULL --vmi_maximum_days
                              ,NULL --vmi_fixed_order_quantity
                              ,NULL --so_authorization_flag
                              ,NULL --consigned_flag
                              ,NULL --asn_autoexpire_flag
                              ,NULL --vmi_forecast_type
                              ,NULL --forecast_horizon
                              ,NULL --exclude_from_budget_flag
                              ,NULL --days_tgt_inv_supply
                              ,NULL --days_tgt_inv_window
                              ,NULL --days_max_inv_supply
                              ,NULL --days_max_inv_window
                              ,NULL --drp_planned_flag
                              ,NULL --critical_component_flag
                              ,NULL --continous_transfer
                              ,NULL --convergence
                              ,NULL --divergence
                              ,NULL --config_orgs
                              ,NULL --config_match
                              -- End  : 26 new attributes --
                              -- Descriptive flex --
                              ,NULL --attribute_category
                              ,'HW' --attribute1
                              ,NULL --attribute2
                              ,NULL --attribute3
                              ,NULL --attribute4
                              ,NULL --attribute5
                              ,NULL --attribute6
                              ,NULL --attribute7
                              ,p_item_rec.attribute8 --attribute8
                              ,NULL --attribute9
                              ,NULL --attribute10
                              ,NULL --attribute11
                              ,NULL --attribute12
                              ,NULL --attribute13
                              ,NULL --attribute14
                              ,'WWT_6'   --attribute15
                              -- Global Descriptive flex --
                              ,NULL --global_attribute_category
                              ,NULL --global_attribute1
                              ,NULL --global_attribute2
                              ,NULL --global_attribute3
                              ,NULL --global_attribute4
                              ,NULL --global_attribute5
                              ,NULL --global_attribute6
                              ,NULL --global_attribute7
                              ,NULL --global_attribute8
                              ,NULL --global_attribute9
                              ,NULL --global_attribute10
                              -- Who --
                              ,NULL   -- Object_Version_Number
                              ,SYSDATE
                              ,p_user_id
                              ,SYSDATE
                              ,p_user_id
                              ,NULL   -- Last_Update_Login
                              -- Main Driver to lookup WWT_ITEM_CREATION_PROCESSING
                              ,'DEMO'   --wwt_item_creation_source
                              ,NULL   --wwt_transaction_type
                              -- Additional Columns for use in pre
                              ,NULL --,p_item_rec.consumable_indicator   --wwt_Attribute1
                              ,NULL --,p_item_rec.manufacturer_item   --wwt_Attribute2
                              ,NULL   --wwt_Attribute3
                              ,NULL   --wwt_Attribute4
                              ,'DEMO Gear Item Upload'   --wwt_Attribute5
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
                              ,0      -- object_index
                              ,0      -- item_api_tbl_index
                              ,NULL   -- call_item_api
                              ,NULL   -- pre_process_code
                              ,NULL   -- pre_process_status
                              ,NULL   -- post_process_code
                              ,NULL   -- post_process_status
                              ,NULL   -- item_status_message
                              ,NULL   -- prevent Item Api Call
                              ,NULL   -- process_record
                              );
          x_item_table  := l_item_table;

      EXCEPTION
         WHEN others THEN
            raise_application_error(-20013, 'Fatal Error in procedure build_api_object_tbl Error => '
                                        ||SQLERRM);

      END build_api_object_tbl;

  /*------------------------------------------------------------------------------
     Purpose: Process items from JPMC. This is called from GUC upload
              JPMC ITEM MASTER (source id 54).
  --------------------------------------------------------------------------------*/
  PROCEDURE process_items (  p_user_name  IN   VARCHAR2
                            ,x_retcode   OUT   NUMBER
                            ,x_errbuff   OUT   VARCHAR2)
  IS

    -- Local variables
    l_item_table     wwt_item_tab_type := wwt_item_tab_type ();
    l_valid_manufacturer VARCHAR2 (100);
    l_item_exist         VARCHAR2(1);
    l_organization_id    NUMBER;
    l_template_name   VARCHAR2(10);
    l_segment4           VARCHAR2(10);
    l_transaction_type   VARCHAR2(30);
    l_user_id            NUMBER;
    l_errors             NUMBER;
    l_inventory_item_id  NUMBER;
    l_error_code         VARCHAR2 (100);
    l_message_list       error_handler.error_tbl_type;
    item_errors          EXCEPTION;
    PRAGMA exception_init(item_errors, -24381);


  BEGIN

    wwt_upload_generic.LOG(2, 'BEGIN process_items');


    --Grab hard coded values from lookup: WWT_DEMO_GEAR_ITEM_CREATION
    SELECT attribute1,
           attribute2,
           attribute3,
           attribute4
      INTO l_segment4,
           l_template_name,
           l_organization_id,
           l_transaction_type
      FROM wwt_lookups_active_v
      WHERE lookup_type = 'WWT_DEMO_GEAR_ITEM_CREATION';

    x_retcode := 0;

    --Passing in user name to get user_id from function
    l_user_id := WWT_UTIL_GET_USER_ID.GET_RUNTIME_USER_ID (p_user_name);

    --Following block opens the cursor, collects cursor data into and closes the cursor
    OPEN g_item_data_cur  (l_segment4,  l_organization_id);

        FETCH g_item_data_cur
        BULK COLLECT
        INTO g_item_data_tab;

    CLOSE g_item_data_cur;

    FOR item_rec IN 1..g_item_data_tab.COUNT LOOP

      BEGIN /* process each item */

           --Convert Serial Control Flag to a numeric
           IF g_item_data_tab(item_rec).serial_control = 'Y' THEN
              g_item_data_tab(item_rec).serial_control := 5;
           ELSE
              g_item_data_tab(item_rec).serial_control := 1;
           END IF;

           --Validate manufacturer id is good
        IF g_item_data_tab(item_rec).mfg_name IS NOT NULL THEN

               --Check point to see if item exists
               IF (g_item_data_tab(item_rec).inventory_item_id) IS NULL THEN

                   --Call API table object
                   build_api_object_tbl (  p_item_rec         => g_item_data_tab(item_rec)
                                          ,p_organization_id  => l_organization_id
                                          ,p_transaction_type => l_transaction_type
                                          ,p_segment4         => l_segment4
                                          ,p_user_id          => l_user_id
                                          ,x_item_table       => l_item_table);

                    wwt_upload_generic.LOG(0, 'inventory_item_id: ' || g_item_data_tab(item_rec).inventory_item_id || ' l_org_id: ' || l_organization_id || ' manufacturer part number: '|| g_item_data_tab(item_rec).MANUFACTURER_PART_NUMBER || 'attribute8: ' || g_item_data_tab(item_rec).attribute8);

                   --Call API to load msi table
                   wwt_item_api_pkg.process_items ( x_item_tbl     => l_item_table
                                                        ,x_error_code   => l_error_code
                                                        ,x_message_list => l_message_list);

                   -- Evaluate status returned from the API to update x_retcode so it's returned to the upload
                   IF l_message_list.EXISTS(1) THEN

                        x_retcode := 1;
                        x_errbuff := l_message_list(1).message_text;
                        wwt_upload_generic.LOG(1, x_errbuff);

                   ELSE

                        x_retcode := 0;
                        wwt_upload_generic.LOG(1, 'Item '|| g_item_data_tab(item_rec).manufacturer_part_number || ' created successfully.');

                   END IF;

               ELSE

                   x_retcode := 1;
                   wwt_upload_generic.LOG(1, 'Duplicate item '|| g_item_data_tab(item_rec).manufacturer_part_number ||' found in segment2 on table apps.mtl_system_items_b');

               END IF;

        ELSE
             x_retcode := 1;
             wwt_upload_generic.LOG(1,'Manufacturer id is not populate:   '|| g_item_data_tab(item_rec).manufacturer);
        END IF;

      EXCEPTION /* process each item */
         WHEN OTHERS THEN
            x_retcode := 1;
            wwt_upload_generic.LOG(1,'ERROR: ' || SUBSTRB(SQLERRM, 1, 2000));
      END;

      -- Only grab inv item id and insert into cross reference when we have return code of 0
      IF NVL(x_retcode, 0) = 0 THEN

         /* Need to call function to grab inventory_item_id because when the cursor is executed the item does not exist.
            We have to wait for the process_item API is called before we will have inverntory item id which is needed for cross references insert */
          l_inventory_item_id := get_inventory_item_id (g_item_data_tab(item_rec).manufacturer,
                                                        g_item_data_tab(item_rec).manufacturer_part_number,
                                                        g_item_data_tab(item_rec).cost_segment,
                                                        l_segment4,
                                                        l_organization_id);

          --Call insert for cross references
          INSERT INTO mtl_cross_references (
            inventory_item_id,
            cross_reference_type,
            cross_reference,
            last_update_date,
            last_updated_by,
            creation_date,
            created_by,
            last_update_login,
            org_independent_flag)
        VALUES (
            l_inventory_item_id,
            'Receiving', -- Static always Receiving
            g_item_data_tab(item_rec).manufacturer_part_number, -- Supplier Part Number
            sysdate,
            l_user_id,
            sysdate,
            l_user_id,
            NULL,
            'Y');

      END IF;

    END LOOP item_rec;

    IF NVL(x_retcode, 0) > 0 THEN

         wwt_upload_generic.LOG(1, 'Errors occurred during the Item Process; '||
                                   'please refer to upload log for more details.');

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
         x_retcode := 2;
         x_errbuff := 'Error: '||SQLERRM ||' in Procedure: process_items.';

  END process_items;

END WWT_UPLOAD_DEMO_GEAR;
/