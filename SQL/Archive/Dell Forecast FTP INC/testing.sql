select * from apps.wwt_upload_generic_log
where 1=1
and batch_id = 681737
and creation_date > sysdate - 3
order by creation_date desc

select * from apps.wwt_frolic_status_log
where 1=1
and creation_date > sysdate - 3
order by creation_date desc

WWT_DELL_FORECAST_STG

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_MAPPING'
and attribute1 = 62

select * from apps.wwt_dell_forecast_stg
where 1=1
--and part_number = '016KN'
--and 

WWT_DELL_FORECAST_EXT_TABLE
