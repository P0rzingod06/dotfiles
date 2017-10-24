select * from apps.wwt_frolic_status_log
where 1=1
and source_name LIKE '%CINGULAR_XDOCK%'
order by creation_date desc

select * from wwt_upload_generic_log
where 1=1
and batch_id = 680120

select ID, planned_deployment_date, actual_deployment_date, submit_rma, filename, last_update_date from wwt_cing_xdock_attr
where 1=1
and last_update_Date IS NOT NULL
order by last_update_date desc

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_DATA_TRANSFORMATIONS'
--and attribute1 = 'ATT CrossDock'
and attribute27 LIKE '%eplac%'

update wwt_lookups
set attribute27 = 'import java.text.*;
import java.util.regex.*;
String inputDate = %PLANNED_DEPLOYMENT_DATE%;
SimpleDateFormat newFormat = new SimpleDateFormat("dd-MMM-yyyy");
SimpleDateFormat oldFormat;
if  (inputDate != null && !inputDate.equals("")) {
    if(inputDate == "-"){
        inputDate = "";
    }
    if (Pattern.matches("\\d{1,2}/\\d{1,2}/\\d{4}", inputDate)) {
        oldFormat= new SimpleDateFormat("MM/dd/yyyy");
    }
    else if (Pattern.matches("\\d{1,2}-[a-zA-Z]*-\\d{2}", inputDate)) {
        oldFormat= new SimpleDateFormat("dd-MMM-yy");
    }
    else {
        oldFormat = new SimpleDateFormat("dd-MMM-yyyy");
    }
    Date oldDate = oldFormat.parse(inputDate);
    return newFormat.format(oldDate);
}'
where 1=1
--and lookup_type = 'WWT_DATA_TRANSFORMATIONS'
--and attribute1 = 'ATT CrossDock'
and lookup_id = 279509

select * from wwt_lookups
where 1=1
--and lookup_type = 'WWT_DATA_TRANSFORMATIONS'
--and attribute1 = 'ATT CrossDock'
and lookup_id = 279509

select case when %ACTUAL_DEPLOYMENT_DATE%='-' then NULL
            else %ACTUAL_DEPLOYMENT_DATE% end QUERY_RESULT
from dual

select * from apps.wwt_application_log
where 1=1
and application_name LIKE '%Caper%'
and module_name LIKE '%ATT%'
order by creation_date desc

select DECODE('-',
                       'N', 'NULL',
                       'No','NULL',
                       'NO','NULL',
             '-',null,
                       null,null,
                       'Y','Yes',
                       'YES','Yes',
                            'Yes') from dual
                            
select case when '-' = '-' then null
            when '-' = null then null end
            from dual
            
            SELECT NVL(%ATT_ITEM%,'skipLine') query_result FROM dual
            
            SELECT NVL(%ATT_ITEM%,'skipLine') query_result FROM dual
            
select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_DATA_TRANSFORMATIONS'
and attribute1 = 'ATT CrossDock'

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_DATA_TRANSLATIONS'
and attribute1 = 'ATT CrossDock'
and attribute2 = 'ATT ITEM'