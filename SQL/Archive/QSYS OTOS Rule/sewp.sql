select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
--and attribute10 LIKE '%Sub%'



select * from wwt_frolic_status_log
where 1=1
--and creation_date > sysdate - 10
and file_location LIKE '%sewp%'
order by creation_date desc

select * from repos_admin.wwt_nasa_sewp
order by creation_date desc

select * from REPOS_ADMIN.WWT_NASA_SEWP_FILES
order by creation_date desc

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_FLAT_FILE_CLEANSING'
and attribute2 LIKE '%Su%'

wwt_nasa_sewp_import

G_EMAIL_LIST VARCHAR2(25) := 'NASA_SEWP_PARTS_LOAD';

select contract_customer_price from repos_Admin.order_line_item

DW_ETL.FREIGHT_ANALYSIS_V
