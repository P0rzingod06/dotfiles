WWT_UPLOAD_GENERIC
;
select * from apps.wwt_frolic_status_log
where 1=1
and creation_Date > sysdate - 10
--and source_name LIKE '%GCFI%'
and source_name IN (
'DSH GCFI ODM BACKLOG'
--'MICROSOFT EU INVENTORY UPLOAD'
--'MICROSOFT NETWORK FORECAST'
)
--and status LIKE '%ERROR%'
--and status <> 'SUCCESS'
--and file_owner <> 'nfsnobody'
and lower(file_location) LIKE '%fcj%'
--and log_id = 352667
order by creation_Date desc
;
select * from apps.wwt_upload_generic_log
where 1=1
--and batch_id = 734047
order by ID desc
;
update apps.wwt_upload_generic_log
set status='ERROR',message='Manually set Stuck Record to Error',last_update_date=sysdate,last_updated_by=55386
where 1=1
and file_location = '/ftpdata/WWTHCDEV.so_update/Test_1006_2.csv'
;
select * from apps.fnd_user
where 1=1
and user_name LIKE '%GASSERT%'
;
select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'--WWT_UPLOAD_GENERIC_EML_DIST--WWT_UPLOAD_GENERIC_WORKFLOW--WWT_UPLOAD_GENERIC_EXTERNAL_TABLE_SETUP
--and upper(attribute2) LIKE '%CATALOG - INGRAM%'                             --WWT_UPLOAD_GENERIC_EXTERNAL_TABLE_COLUMNS--WWT_UPLOAD_GENERIC_SOURCE--WWT_UPLOAD_GENERIC_MAPPING
--and lower(attribute10) LIKE '%compal%'
--and attribute13 IN ('boeing','cingular','cop-generic')
--and attribute1 IN (155)
and attribute12 like '%gcfi%'
order by attribute1 desc
;
select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_FLAT_FILE_CLEANSING'--WWT_FF_TEMPLATE,WWT_DATA_TRANSLATIONS,WWT_DATA_TRANSFORMATIONS--WWT_FLAT_FILE_CLEANSING
and lower(attribute1) LIKE '%compal%'
;
SELECT *
from wwt_cisco_dis_accelerator
;
wwt_rep_on_demand_cataload_dbl;WWT_BOEING_MSRRAD_DII_IMPORT;wwt_msip_reserve_file_pkg;WWT_CISCO_DIS_ACCELERATOR_PKG;wwt_catalog_etl.product_load_ingram
;