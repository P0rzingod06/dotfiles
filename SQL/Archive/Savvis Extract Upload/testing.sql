SELECT *
FROM APPS.WWT_LOOKUPS_ACTIVE_V
WHERE LOOKUP_TYPE = 'WWT_WM_RECEIVE_EMAIL'
--and attribute2 = '%EWO Extract%'
;
select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_FLAT_FILE_CLEANSING'
and attribute2 LIKE '%Savvis%';
;
select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_FF_TEMPLATE'
--and attribute1 = '%Order%'
and attribute1 = 'Order Inbound'

select *from wwt_lookups
where 1=1
and lookup_type = 'WWT_DATA_TRANSLATIONS'
and attribute1 = 'Savvis Header'

WWT_WM_EMAILS
;
select * from apps.wwt_wm_email_attachments
where 1=1
--and status = 'PROCESSED'
order by creation_date desc
;
select * from APPS.WWT_WM_EMAIL_HEADERS
where 1=1
--and email_to LIKE '%dev%'
order by creation_date desc
;
select * from apps.wwt_frolic_status_log
where 1=1
and creation_date > sysdate - 5
--and source_name = 'Savvis EWO'
--and source_name LIKE '%SAVIS%'
order by creation_date desc

select * from wwt_upload_generic_log
where 1=1
and batch_id = 681840

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
and attribute1 = 2

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_WORKFLOW'
and attribute1 = 2

select * from apps.wwt_orig_order_headers_v
where 1=1
and creation_Date > sysdate - 10
and source = 'Generic COP Upload'
order by creation_date desc

select * from wwt_orig_order_lines
where 1=1
and creation_Date > sysdate - .5
and header_id IN (16415251, 16415250)
order by creation_date desc
;
select * from APPS.WWT_WM_EMAIL_HEADERS
where 1=1
--and email_to LIKE '%dev%'
and creation_date > sysdate - 3
order by creation_date desc
;
--Then you can check here to see if it went successfully into Caper

select * from apps.wwt_frolic_status_log
where 1=1
and creation_date > sysdate - 1
--and source_name = 'Savvis EWO'
order by creation_date desc
;
--For the COP Generic Upload Frolic part
select * from apps.wwt_frolic_status_log
where 1=1
and creation_date > sysdate - 1
--and source_name = 'COP GENERIC UPLOAD'
order by creation_date desc