SELECT prof.profile_name, app_role.role_name, perm.perm_name, apl.app_name
FROM wwt_user_security.wwt_application apl,
wwt_user_security.wwt_user usr,
wwt_user_security.wwt_user_profile usr_prof,
wwt_user_security.wwt_profile prof,
wwt_user_security.wwt_profile_app_role prof_role,
wwt_user_security.wwt_app_role app_role,
wwt_user_security.wwt_app_role_perm role_perm,
wwt_user_security.wwt_app_perm perm
WHERE usr.ldap_user_id = 'hawesj'   -- user name
AND apl.app_name = 'inventory-api'  -- app name
AND apl.app_id = perm.app_id
AND usr.wwt_user_id = usr_prof.wwt_user_id
AND prof.profile_id = usr_prof.profile_id
AND prof_role.profile_id = prof.profile_id
;
