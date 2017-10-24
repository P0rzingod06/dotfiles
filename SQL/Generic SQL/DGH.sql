select * from wwt_dgh_pullreq_stg
where 1=1
and creation_Date > sysdate - 1
order by creation_date desc
;