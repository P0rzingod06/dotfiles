wwt_upload_generic

select osexec('/bin/date') from dual

wwt_dell_cfi_commit_analysis

select attribute1, attribute2
FROM apps.wwt_lookups_active_v
where lookup_type = 'DSH_UTL_FILE_RETRIES';

select * from apps.wwt_frolic_status_log
where 1=1
and creation_date > sysdate - 25
and source_name = 'DELL CFI REQUEST - NASHVILLE'
order by creation_date desc
;

apps.wwt_dell_cfi_commit_analysis;

SELECT username, osuser
FROM   gv$session
WHERE  module = 'WWT_DELL_CFI_COMMIT_ANALYSIS'

APPS.WWT_WM_UTILITIES

select * from wwt_dell_cfi_commit_build

wwt_upload_generic

select * from apps.wwt_upload_generic_log
where 1=1
and batch_id = 709344
--and source_id = 68
--and message LIKE '%Woo%'
and creation_date > sysdate - 1
order by id desc

APPS.WWT_UPLOAD_DSH_UTILITY

WWT_DELL_COMMIT_STG

APPS.WWT_UPLOAD_DSH_UTILITY;

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
and attribute1 = 68
;
select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_MAPPING'
and attribute1 = 68
;
 SELECT attribute14
         FROM   wwt_lookups_active_v
         WHERE  lookup_type IN  ('WWT_DLP_INV_ORG_XREF',  'WWT_DELL_INV_ORG_XREF')
--         AND    LOWER(attribute9) = LOWER(g_facility)
--         AND    ROWNUM = 1;

SELECT username, osuser
                 FROM gv$session
                WHERE module = 'WWT_DELL_CFI_COMMIT_ANALYSIS'

SELECT *
  FROM V$PARAMETER
  WHERE NAME = 'utl_file_dir'
  
  select * from all_directories
  where directory_name like '%CFI%'
  
  wwt_sda.upload_pkg
  
  APPS.WWT_WM_UTILITIES.CALL_WM_SERVICE(P_SERVICE_NAME => '',
                                             P_PARM1 =>  'ls -l /ftpdata/WWTHCDEV.dell_cfi_request/nashville/outbox/201503261352.txt',
                                             P_PARM2 =>  NULL,
                                             P_PARM3 =>  NULL,
                                             P_PARM4 =>  NULL,
                                             P_PARM5 =>  NULL,
                                             P_PARM6 =>  NULL,
                                             P_PARM7 =>  NULL,
                                             P_PARM8 =>  NULL,
                                             P_PARM9 =>  NULL,
                                             P_PARM10 => NULL,
                                             X_STATUS => l_status,
                                             X_STATUS_MESSAGE => l_status_message,
                                             X_HTTP_RESPONSE  => l_http_response);
                                             
select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_WM_SERVICE_PARMS'
and attribute1 = 'wwtpub.unix:shRunCommand'
