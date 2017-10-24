SELECT *
FROM APPS.WWT_LOOKUPS_ACTIVE_V
WHERE LOOKUP_TYPE = 'WWT_TN_DELIVERY_ALERTS'


wwt_upload_generic

select * from wwt_frolic_Status_log
where 1=1
and creation_Date > sysdate - 1
order by creation_Date desc
                            
