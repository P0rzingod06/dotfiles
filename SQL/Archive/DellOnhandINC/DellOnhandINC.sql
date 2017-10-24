select m.mfg_item_number, v.customer_item_number, a.alloc_13_wk, a.creation_date
from apps.wwt_dsh_gcfi_cust_items_flat_v v,
apps.wwt_dsh_gcfi_mfg_item m, 
apps.wwt_dsh_gcfi_item_alloc a,
(select mfg_item_id from apps.wwt_dsh_gcfi_cust_items_flat_v where customer_item_number in ('22MCC', '80RHP', '972G7', 'T0YYG', 'N0N8R')) v1
where 1=1 
and m.mfg_item_id = v.mfg_item_id
and a.customer_item_id = v.customer_item_id
and a.region_id = 1 --DAO
and a.mfg_item_id = v.mfg_item_id
and v.mfg_item_id = v1.mfg_item_id
;
select *
from apps.wwt_inventory_advice_outbound
where 1=1
and part_number in ('T0YYG',
'M1X8W',
'3P401',
'N0N8R',
'MPPPF',
'80RHP',
'DYFG0',
'9GT2R',
'70JX4',
'YT59K',
'NP5F6',
'22MCC',
'26CC4')
order by creation_date desc , part_number
;
select * from dba_objects
where 1=1
and object_name LIKE '%GCFI%'
and object_type = 'PACKAGE BODY'
;
WWT_DSH_GCFI_EXTRACT_846
;