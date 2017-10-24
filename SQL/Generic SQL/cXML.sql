SELECT * FROM apps.wwt_lookups_active_v wcst
WHERE 1=1 
AND wcst.lookup_type = 'WWT_CXML_SUPPLIER_TRANSACTION '--WWT_CXML_ENTERPRISE_NETWORK_ACCOUNT--WWT_CXML_PARTNER_ENVIRONMENT--WWT_CXML_SUPPLIER_TRANSACTION
;
SELECT * FROM apps.wwt_punchin_info
where 1=1
--and description like '%Cricket%'
;