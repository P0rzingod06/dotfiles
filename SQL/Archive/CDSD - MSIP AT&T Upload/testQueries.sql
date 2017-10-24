select * from apps.WWT_MSIP_ITEM_INVENTORY_V
where 1=1
--and revision = 1
--and mfg_part_number = 'CISCO2821'
--and project = 'MISPLUS'
--and msip_id = 1142
--and virtual_onhand = 0
and last_update_date > sysdate - 20
--order by revision desc
order by revision desc

select * from apps.wwt_msip_item_inventory
where 1=1
--and revision IN (259)
--and msip_id = 58
and creation_Date > sysdate - 10
order by last_update_date desc

select * from apps.wwt_msip_planning_item 
where 1=1

select * from apps.mtl_system_items_b 
where 1=1
and segment2 = 'ASR1001'

alter table partner_admin.wwt_msip_item_inventory
add (RESERVE_QUANTITY NUMBER)

select * from (select * from wwt_frolic_status_log
where 1=1
and source_name = 'MSIP RESERVED QUANTITY'
order by creation_date desc)
where rownum = 1

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_EML_DIST'
and attribute1 = 231

select * from (SELECT MSIP_ID, REVISION
FROM apps.wwt_msip_item_inventory_v
WHERE hardware_model = 'XDCPVD16'
AND mfg_part_number = 'PVDM2-16='
AND project = 'EVPN'
ORDER BY revision DESC)
where 1=1
and rownum = 1

select distinct attribute11 from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
--amd attribute1 = 231

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
           wmii.min_level_quantity,
           wmii.max_level_quantity,
           wmii.inventory_quantity + wmii.outstanding_quantity - wmii.reserve_quantity virtual_onhand,
           CASE
              WHEN ( (wmii.inventory_quantity + wmii.outstanding_quantity) <
                       wmii.min_level_quantity)
              THEN
                 (  wmii.max_level_quantity
                  - wmii.inventory_quantity
                  - wmii.outstanding_quantity)
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
                
select user_name 
into l_ldap_user_id
from fnd_user
where 1=1
and user_id = l_user_id;

select * from wwt_user_security.wwt_user
where 1=1
--and ldap_user_id = 'gassertm'
and wwt_user_id = 10855

select inventory_id
into l_last_inventory_id
from apps.wwt_msip_item_inventory
where 1=1
and rownum = 1
order by inventory_id desc

select * from apps.wwt_msip_item_inventory
where last_update_date > sysdate - 180
and msip_id = 402
and revision = 1242
order by last_update_date desc

apps.wwt_upload_msip_utilities

select apps.wwt_msip_item_inventory%ROWTYPE from dual

   SELECT mii2.inventory_id
         ,mii2.msip_id
         ,mii2.outstanding_quantity
         ,mii2.revision
     FROM wwt_msip_item_inventory mii2
        , (SELECT mii.msip_id msip_id
                 ,MAX(mii.revision) revision
             FROM wwt_msip_planning_item mpi
                 ,wwt_msip_item_inventory mii
            WHERE mii.msip_id = mpi.msip_id
              AND mii.msip_id = 402
              AND mpi.warehouse = 'NCR'
              AND TRUNC(mii.creation_date) = TRUNC(SYSDATE)
           GROUP BY mii.msip_id) max_revision
   WHERE mii2.msip_id = max_revision.msip_id
     AND mii2.revision = max_revision.revision

SELECT *
FROM wwt_msip_item_inventory
WHERE inventory_id = 278632

SELECT *
     FROM wwt_msip_min_max_planning
    WHERE msip_id = 402
      AND TRUNC(start_effective_date) <= TRUNC(SYSDATE)
      AND TRUNC(NVL(end_effective_date, SYSDATE+1)) >= TRUNC(SYSDATE);