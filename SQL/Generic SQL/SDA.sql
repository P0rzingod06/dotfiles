select * 
from wwt_sda.order_event_log oel, 
wwt_sda.order_header oh
where 1=1
--and creation_Date > sysdate - 10
and oel.event_type = 'Comment'
and oel.order_id = oh.order_id
and oh.program_id = 321
--and order_comment_id = 109815
order by creation_date desc
;
select * from apps.order_comment
where 1=1
--and order_comment_id = 112291
and comment_value like '%Test JK%'
order by creation_date desc
;
select * from apps.order_header
where 1=1
and order_id = 112374
;
select * from wwt_sda.program
where 1=1
and program_id = 321
;
select * from apps.wwt_lookups_active_v
where 1=1
and lookup_type = 'SDA_ALERT_NOTIFICATIONS'
and attribute4 like '%Verizon%'
;
SELECT wlav.attribute26,   -- email_distribution
               wlav.attribute6,    -- send_to_cm_flag
               wlav.attribute7,    -- cm_subscriber_flag
               wlav.attribute8,    -- order_subscriber_flag
               wlav.attribute9,    -- bom_submitter_flag
               DECODE(wlav.attribute1,'Comment','Y','N'),   -- is_comment_flag
               oh.order_id,
               oel.order_comment_id,
               oel.wwt_created_by,
               oel.event,
               oel.event_type,
               wlav.attribute13,    -- send_to_warehouse_mgrs
               wlav.attribute14     -- send_to_logistics_mgrs
          FROM wwt_sda.order_event_log oel,
               wwt_sda.order_header oh,
               wwt_sda.program p,
               apps.wwt_lookups_active_v wlav
         WHERE oel.order_event_log_id = 3421800
           AND oel.order_id = oh.order_id
           AND wlav.lookup_type = 'SDA_ALERT_NOTIFICATIONS'
           AND oel.event_type = wlav.attribute1
           AND NVL(oel.event,'E') = NVL(wlav.attribute2, NVL(oel.event,'E'))
           AND oh.program_id = p.program_id
           AND p.program_name = wlav.attribute4
;