/* Formatted on 12/16/2014 2:20:30 PM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW APPS.WWT_MSIP_ITEM_INVENTORY_V
(
   MSIP_ID,
   INVENTORY_ID,
   HARDWARE_MODEL,
   MFG_PART_NUMBER,
   START_EFFECTIVE_DATE,
   END_EFFECTIVE_DATE,
   WAREHOUSE,
   SERVICE_LINE,
   PROJECT,
   PRODUCT_FAMILY,
   REVISION,
   LAST_UPDATE_DATE,
   INVENTORY_QUANTITY,
   OUTSTANDING_QUANTITY,
   RESERVE_QUANTITY,
   MIN_LEVEL_QUANTITY,
   MAX_LEVEL_QUANTITY,
   VIRTUAL_ONHAND,
   SUGGESTED_QUANTITY,
   REASON_CODE,
   CREATION_DATE,
   RELEASE_TIMESTAMP,
   INVENTORY_NOTES,
   RELEASED_QUANTITY,
   SO_NUMBER,
   SO_LINE_CREATION_DATE,
   SO_LINE_ID,
   SLA_MEASURABLE,
   TRIGGER_TIMESTAMP,
   LDAP_CREATED_BY,
   NOTES,
   RELEASE_ID
)
AS
   (SELECT /*+ qb_name (wmiiv) */
          wmpi.msip_id,
           wmii.inventory_id,
           wmpi.hardware_model,
           msib.segment2 mfg_part_number,
           wmpi.start_effective_date,
           wmpi.end_effective_date,
           wmpi.warehouse,
           wmpi.service_line,
           wmpi.project,
           wmpi.product_family,
           wmii.revision,
           wmii.last_update_date,
           wmii.inventory_quantity,
           wmii.outstanding_quantity,
           NVL(wmii.reserve_quantity,0),
           wmii.min_level_quantity,
           wmii.max_level_quantity,
           CASE
              WHEN (  wmii.inventory_quantity
                    + wmii.outstanding_quantity
                    - NVL(wmii.reserve_quantity,0) < 0)
              THEN
                 0
              ELSE
                   wmii.inventory_quantity
                 + wmii.outstanding_quantity
                 - NVL(wmii.reserve_quantity,0)
           END
              virtual_onhand,
           CASE
              WHEN (    (  wmii.inventory_quantity
                         + wmii.outstanding_quantity
                         - NVL(wmii.reserve_quantity,0)) < wmii.min_level_quantity
                    AND (  wmii.inventory_quantity
                         + wmii.outstanding_quantity
                         - NVL(wmii.reserve_quantity,0)) < 0)
              THEN
                 (wmii.max_level_quantity)
              WHEN ( (  wmii.inventory_quantity
                      + wmii.outstanding_quantity
                      - NVL(wmii.reserve_quantity,0)) < wmii.min_level_quantity)
              THEN
                 (  wmii.max_level_quantity
                  + NVL(wmii.reserve_quantity,0)
                  - wmii.inventory_quantity
                  - wmii.outstanding_quantity)
              ELSE
                 0
           END
              suggested_quantity,
           wmii.reason_code,
           wmii.creation_date,
           wmii.release_timestamp,
           wmii.notes inventory_notes,
           wmr.released_quantity,
           ooha.order_number so_number,
           oola.creation_date so_line_creation_date,
           wmr.so_line_id,
           wmr.sla_measurable,
           wmr.trigger_timestamp,
           wmr.ldap_created_by,
           wmr.notes,
           wmr.release_id
      FROM apps.wwt_msip_item_inventory wmii,
           apps.wwt_msip_planning_item wmpi,
           apps.mtl_system_items_b msib,
           apps.wwt_msip_release wmr,
           apps.oe_order_headers_all ooha,
           apps.oe_order_lines_all oola
     WHERE     wmii.msip_id = wmpi.msip_id
           AND wmpi.inventory_item_id = msib.inventory_item_id
           AND msib.organization_id = 101
           AND wmii.inventory_id = wmr.inventory_id_reference(+)
           AND wmr.so_line_id = oola.line_id(+)
           AND oola.header_id = ooha.header_id(+));