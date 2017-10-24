select * from apps.WWT_DGH_PULLREQ_STG where cust_pull_request = 'ZD15002240' order by batch_id,cust_pull_request_line

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
--and attribute10 like '%compal%' 

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_FLAT_FILE_CLEANSING'

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_EDI_FTP_INBOUND'
--and attribute1 = 'Compal 940'