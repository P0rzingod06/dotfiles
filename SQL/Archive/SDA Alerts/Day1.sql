select order_event_log_id, order_id, event_type, action_message, event, creation_date from wwt_sda.order_event_log
where action_status IS NOT NULL
and action_status <> 'DONE'
and action_status <> 'IGNORE'
and action_status <> 'NO ACTION'
and action_status NOT LIKE 'PROCESSING_%'
and creation_date > sysdate - 100

select * from wwt_sda.order_event_log
where action_status IS NOT NULL
and action_status <> 'DONE'
and action_status <> 'IGNORE'
and action_status <> 'NO ACTION'
and action_status NOT LIKE 'PROCESSING_%'

select * from wwt_sda.order_event_log

select distinct action_status from wwt_sda.order_event_log

select * from wwt_process_exec_status
where process_name LIKE '%SDA%'

insert into LAST_RUN_TIME
values ( 1471, 'SDAsendFailedReports', 'SDA failed alerts notification', 0, '6/15/2014 9:00:00 AM', 'N', 3984, '6/15/2014 9:00:00 AM', 3984, '6/15/2014 9:00:00 AM', NULL, NULL, NULL, NULL)

select LAST_RUN_TIME from wwt_process_exec_status
where process_name = ?

select * from wwt_sda.order_event_log
where last_update_date > to_Date('01/15/2014 9:00:00', 'MM-DD-YYYY HH:MI:SS')
and action_status IS NOT NULL
and action_status <> 'DONE'
and action_status <> 'IGNORE'
and action_status <> 'NO ACTION'
and action_status NOT LIKE 'PROCESSING_%'

update wwt_process_exec_status
set last_run_time = to_Date('03/15/2014 9:00:00', 'MM/DD/YYYY hh:mi:ss')
,exec_count = 0
where process_id = 1478