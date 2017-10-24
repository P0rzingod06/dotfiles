select * from WWT_NOTIFY.NOTIFY_TEMPLATES
where 1=1
and name IN ('sales-order-creation-email','quote-export-email','request-for-quote-email','quote-creation-in-pivot-failure-email')
order by last_updated_timestamp desc
;
select * from WWT_NOTIFY.NOTIFICATION_RECORD
;
SELECT *
FROM wwt_notify.notification_record
WHERE 1=1
--AND notification_record_id IN (270100,270099,270123)
AND template_id IN (41)
order by last_update_date desc
;