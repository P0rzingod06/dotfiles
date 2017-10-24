select * from apps.wwt_frolic_status_log
where 1=1
and source_name IN ('EHI ASSET INFORMATION','EHI Asset Information')
order by creation_date desc

select * from apps.wwt_upload_generic_log
where 1=1
and batch_id = 682160

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_SOURCE'
and attribute1 = 97

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_WORKFLOW'
and attribute1 = 97

select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_FLAT_FILE_CLEANSING'
and attribute1 = 'EHI Asset Information'

APPS.WWT_UPDATE_EHI_ASSET_INFO

WWT_SO_HEADER_DFF_UTILS

wwt_om_cascade_values_to_lines

WWT_SO_HEADER_DFF_UTILS.populate_wwt_so_header_dff(x_errbuff, x_retcode, p_header_id, p_attribute84)