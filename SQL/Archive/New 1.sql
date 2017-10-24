select * from wwt_orig_order_headers
where 1=1
and creation_Date  > sysdate - 6
and source <> 'QSYS_3'
and status = 'ERROR - NO PROCESSING GROUPS DEFINED'
order by creation_date desc