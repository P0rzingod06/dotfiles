select reservation_id,organization_id,attribute5,last_update_date,attribute1,attribute7,demand_source_name, demand_source_type_id,last_updated_by,reservation_quantity, primary_reservation_quantity, inventory_item_id
from apps.mtl_reservations
where 1=1
and creation_Date > sysdate - 10
--and inventory_item_id IN (18216500)
--and attribute7 = 236901591
and demand_source_name IN ('QBOA-2186373.1-NSER 12151580V')
--and attribute5 = 'BOADT - C'
--and attribute5 = 'CMCST - O'
--and demand_source_name <> 'WWT_INVENTORY_CALLOUT'
--and reservation_id = 234397895
--and attribute7 = 234397895
order by last_update_date desc
;
select *
from apps.mtl_reservations
where 1=1
and reservation_id IN (236893058)
;
update apps.mtl_reservations
set primary_reservation_quantity = 
where 1=1
and reservation_id IN (236893058)
and demand_source_name = 'WWT_INVENTORY_CALLOUT'
;
update apps.mtl_reservations
set demand_source_name = 'QBOA-MIKE-NSER 00000000D',
attribute1 = NULL,
demand_source_type_id = 140
where 1=1
and attribute5 like 'BOADT - C' --Material Designator
and organization_id = 3346 --Org. 40
--and (
--attribute7 = '237871415'
--or reservation_id in (237871406)
--)
--and demand_source_type_id = 140 --MISC
and demand_source_name = 'QBOA-MIKE-NSER 00000000D'
;
select * from mtl_txn_source_types
;