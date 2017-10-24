update wwt_sda.order_event_log
set action_status = 'IGNORE'
where 1=1
and action_status IS NULL
and event_type <> 'SIOP Upload'
and event_type <> 'Open Order Upload'