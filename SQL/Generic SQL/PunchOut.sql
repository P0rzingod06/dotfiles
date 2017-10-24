WWT_PUNCHOUT_API
;
select * from apps.wwt_punchin_info
where 1=1
--and description LIKE '%AT&T%'
--and customer_name = 'Charter Communications'
and credential_id = 'AN01000049696'
order by punchin_id desc
;
SELECT erp.punchthrough_flag,erp.punchthrough_username,erp.punchthrough_password
,erp.punchthrough_from_cred_id
,repos.system_user_id
,repos.system_password
FROM apps.wwt_punchin_info erp,
repos_admin.wwt_partner_punchout_settings@repos repos
WHERE erp.credential_id = 'AN01000002779-T'
AND   erp.partner_system_id = repos.partner_system_id (+)
;