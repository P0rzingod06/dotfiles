declare
l_retcode NUMBER;
l_errbuff VARCHAR2(100);

begin

apps.WWT_OM_CASCADE_VALUES_TO_LINES.mass_so_update (l_errbuff, l_retcode, 120, 53667);

end;
/

select * from dba_objects
where 1=1
and object_name LIKE '%ASCADE%'

select * from wwt_so_update_stg
order by creation_date desc