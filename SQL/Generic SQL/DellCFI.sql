select * from apps.wwt_dsh_gcfi_scp_arch
where 1=1
and creation_Date > sysdate - 10
and item_number = 'GR390'
order by creation_Date desc
;
select * from apps.WWT_DSH_GCFI_PLAN_ORDERS_OB
where 1=1
--and creation_Date > sysdate - 10
order by creation_Date desc
;
select part_number,onhand_quantity,creation_date 
from apps.WWT_INVENTORY_ADVICE_OUTBOUND 
where 1=1
--and part_number in ('GR390') 
and creation_date > sysdate - 2 
order by creation_date desc
;
WWT_DSH_GCFI_EXTRACT_846
;