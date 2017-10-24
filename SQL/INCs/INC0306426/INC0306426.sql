SELECT scd.source_item_cost,pv.vendor_name
FROM apps.item_header ih,
apps.contract_header ch,
apps.source_contract_detail scd,
apps.vendor_item_detail vid,
apps.vendor v,
apps.po_vendors pv
WHERE     1 = 1
AND ch.contract_name IN ('KEY_BANK_PUBLIC_STANDARDS','KEY_BANK_NEW_BURROUGHS_STANDARDS','KEY_BANK_PRIVATE_STANDARDS')
AND ch.contract_id = scd.contract_id
AND ih.item_id = scd.item_id
AND scd.vendor_item_detail_id = vid.vendor_item_detail_id
AND vid.vendor_id = v.vendor_id
AND v.erp_vendor_id = pv.vendor_id
and scd.enabled_flag = 'Y'
AND ih.item_number = 'J6E65AA'
;
select 
scd.user_defined2 "WWT_STG_ORDER_LINES/WWT_STG_ORDER_LINES_DFF/ATTRIBUTE46"
from 
repos_admin.item_header ih, 
repos_admin.source_contract_detail scd, 
repos_admin.contract_header ch 
where 1=1 
and ch.contract_name= 'KEY_BANK'
and scd.enabled_flag = 'Y' 
AND CH.contract_id = scd.contract_id 
and ih.item_id = scd.item_id 
and DECODE(%WWT_STG_ORDER_LINES/INVENTORY_ITEM_SEGMENT_1%,null,'xyz123',ih.manufacturer_id) 
= nvl(%WWT_STG_ORDER_LINES/INVENTORY_ITEM_SEGMENT_1%,'xyz123')
and ih.item_number =  'J6E65AA'
;