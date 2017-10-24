select * 
from DBA_SCHEDULER_WINDOWS
where 1=1
--and last_update_date > sysdate - 10
;
select * 
from ALL_SCHEDULER_RUNNING_JOBS
where 1=1
--and last_update_date > sysdate - 10
;
select *
from ALL_SCHEDULER_JOBS
where 1=1
--and last_update_date > sysdate - 10
and job_name LIKE '%urge%'
--and start_date IS NOT NULL
;
select * 
from ALL_SCHEDULER_JOB_LOG
where 1=1
--and last_update_date > sysdate - 10
order by log_date desc
;
select * 
from ALL_SCHEDULER_JOB_RUN_DETAILS
where 1=1
--and last_update_date > sysdate - 10
order by log_date desc
;
select * 
from ALL_SCHEDULER_JOB_CLASSES
where 1=1
--and last_update_date > sysdate - 10
--order by log_date desc
;