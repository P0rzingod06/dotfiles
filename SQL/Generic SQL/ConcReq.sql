/* Formatted on 5/8/2015 9:27:55 AM (QP5 v5.256.13226.35510) */
  SELECT request_id,
         program,
         argument_text,
         (CASE
             WHEN     actual_start_date IS NOT NULL
                  AND actual_completion_date IS NOT NULL
             THEN
                'COMPLETED'
             ELSE
                'In-Process'
          END)
            status,
         TO_CHAR (actual_start_date, 'DD-MON-YYYY HH24:MI:SS') start_date,
         TO_CHAR (actual_completion_date, 'DD-MON-YYYY HH24:MI:SS') end_date,
         (CASE
             WHEN actual_completion_date IS NULL
             THEN
                TRUNC (MOD ( (SYSDATE - actual_start_date) * 24, 60))
             ELSE
                TRUNC (
                   MOD ( (actual_completion_date - actual_start_date) * 24, 60))
          END)
/* Formatted on 5/8/2015 9:29:03 AM (QP5 v5.256.13226.35510) */
            hours_to_execute,
(CASE
             WHEN actual_completion_date IS NULL
             THEN
                TRUNC (MOD ( (SYSDATE - actual_start_date) * 24 * 60, 60))
             ELSE
                TRUNC (
                   MOD (
                      (actual_completion_date - actual_start_date) * 24 * 60,
                      60))
          END)
            minutes_to_execute,
         (CASE
             WHEN actual_completion_date IS NULL
             THEN
                TRUNC (MOD ( (SYSDATE - actual_start_date) * 24 * 60 * 60, 60))
             ELSE
                TRUNC (
                   MOD (
                        (actual_completion_date - actual_start_date)
                      * 24
                      * 60
                      * 60,
                      60))
          END)
            seconds_to_execute
    FROM apps.fnd_conc_req_summary_v
   WHERE 1 = 1 
--  AND program LIKE '%WWT%SO%' 
--  AND actual_start_date LIKE '07-MAY-2015%'
         AND actual_start_date > TO_DATE('07-MAY-2015 13:00:00','DD-MON-YYYY HH24:MI:SS') AND actual_start_date < TO_DATE('07-MAY-2105 14:00:00','DD-MON-YYYY HH24:MI:SS') --You can only check back a week at a time, anything further back from that will not be returned from this view
         AND program = 'WWT SO Update'
--AND actual_start_date > sysdate - 10
ORDER BY actual_start_date DESC;

select program, program_short_name, user_concurrent_program_name, actual_start_date,  argument_text from apps.fnd_conc_req_summary_v
where 1=1
--AND actual_start_date > TO_DATE('07-MAY-2015 13:00:00','DD-MON-YYYY HH24:MI:SS') AND actual_start_date < TO_DATE('07-MAY-2105 14:00:00','DD-MON-YYYY HH24:MI:SS') --You can only check back a week at a time, anything further back from that will not be returned from this view
and actual_start_date < sysdate - .86
order by actual_start_date desc
