select * from wwt_frolic_status_log
where 1=1
--and creation_date > sysdate - 1
and source_name = 'DEMO GEAR ITEM UPLOAD'
order by creation_Date desc

select * from wwt_upload_generic_log
where 1=1
and batch_Id = 683135
order by id desc

WEBCOMM2-UWL-RTU

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
and attribute10 LIKE '%demo%'

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_WORKFLOW'
--and attribute10 LIKE '%demo%'
and attribute1 = 124

APPS.WWT_UPLOAD_DEMO_GEAR.PROCESS_ITEMS

SELECT ffvt.description mfg_name
                  FROM fnd_flex_values_vl ffvt,
                       fnd_flex_value_sets ffvs,
                       fnd_flex_values_vl ffv
                 WHERE     1 = 1
                       AND ffv.flex_value_id = ffvt.flex_value_id
                       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
                       AND ffvs.flex_value_set_name = 'Manufacturer'
                       AND '101' = ffv.flex_value
                       
select max (msib.inventory_item_id)
                 from  mtl_system_items_b msib
                where 1=1
                  AND msib.organization_id = '101'
                  AND msib.segment2 = 'NEW-UWL-STD'
                  AND msib.segment4 = 'DEMO'
                  
SELECT attribute1,
           attribute2,
           attribute3,
           attribute4
      FROM wwt_lookups_active_v
      WHERE lookup_type = 'WWT_DEMO_GEAR_ITEM_CREATION'