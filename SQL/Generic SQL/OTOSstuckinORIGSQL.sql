SELECT OH.HEADER_ID, PG.NAME, PG.PROCESS_GROUP_ID, OH.CUSTOMER_PO_NUMBER, OH.HEADER_ID, OH.CREATION_DATE, OH.LAST_UPDATE_DATE, OH.LAST_UPDATED_BY, OH.STATUS, OH.STATUS_MESSAGE, OH.BATCH_ID,  COUNT(OL.LINE_ID) LINE_COUNT
FROM APPS.wwt_orig_order_headers_v OH,
APPS.WWT_ORIG_ORDER_LINES OL,
APPS.WWT_OM_PROCESS_GROUPS PG
WHERE 1=1
--and oh.status in ('ERROR - NO PROCESSING GROUPS DEFINED') 
AND OH.STATUS in  ('IN PROCESS', 'IN QUEUE') --this status is pulled from the ORIG email alert  --'ERROR'
--AND OH.STATUS != 'PROCESSED'
--AND PG.NAME = 'Boeing-SMARTnet'
AND OH.CREATION_DATE >= SYSDATE - 90
AND OH.HEADER_ID = OL.HEADER_ID
--and pg.name LIKE '%AT&T-Ariba%'
--and OH.STATUS_MESSAGE like ('%The contract number is not valid%')
AND OH.HEADER_ID in (17272217)
--and OH.CUSTOMER_PO_NUMBER in ('DOJotos')
--and OH.process_group_id = 244
AND OH.PROCESS_GROUP_ID = PG.PROCESS_GROUP_ID (+)
GROUP BY PG.NAME, PG.PROCESS_GROUP_ID,OH.CUSTOMER_PO_NUMBER, OH.HEADER_ID, OH.LAST_UPDATE_DATE, OH.STATUS, OH.STATUS_MESSAGE, OH.BATCH_ID, OH.CREATION_DATE, OH.LAST_UPDATED_BY
--ORDER BY OH.HEADER_ID, oh.creation_date DESC
ORDER BY oh.creation_date DESC
;--PROCESSED--Successfully Processed - Rules Applied
--actual Oracle Alert Sql for ORIG Orders
--SELECT status
--      ,name
--      ,l_count
--      ,max_header_id
--      ,wwt_get_env
---- INTO   &status
----       ,&pg_name
----       ,&order_count
----       ,&max_header_id
----       ,&env
--FROM   (SELECT   /*+ index(wooh WWT_ORIG_ORDER_HEADERS_N2) */
--                 wooh.status
--                ,wopg.NAME
--                ,COUNT (wooh.header_id) l_count
--                ,MAX (wooh.header_id) max_header_id
--        FROM     apps.wwt_om_process_groups wopg
--                ,apps.wwt_orig_order_headers_v wooh
--                , (SELECT   /*+ index(wool2) */
--                            wooh2.header_id
--                           ,DECODE (SIGN (MAX (wooh2.last_update_date) - MAX (wool2.last_update_date))
--                                   ,-1, MAX (wool2.last_update_date)
--                                   ,MAX (wooh2.last_update_date)
--                                   ) last_update_date
--                   FROM     apps.wwt_orig_order_headers_v wooh2
--                           ,apps.wwt_orig_order_lines wool2
--                   WHERE    wooh2.header_id = wool2.header_id
--                   AND      wooh2.creation_date > SYSDATE - 7
--                   GROUP BY wooh2.header_id) a
--        WHERE    1 = 1
--        AND      wooh.process_group_id = wopg.process_group_id
--        AND      wooh.header_id = a.header_id(+)
--        AND      (SYSDATE - (25 / 1440)) > NVL (a.last_update_date, wooh.last_update_date)
--        AND      wooh.status IN
--                     ('UNPROCESSED'
--                     ,'IN PROCESS'
--                     ,'IN QUEUE'
--                     ,'PENDING - DEFINING PROCESS GROUP'
--                     ,'IN PROCESS - DEFINING PROCESS GROUP'
--                     ,NULL
--                     )
--        AND      wooh.process_group_id IS NOT NULL
--        AND      NOT EXISTS (SELECT attribute1
--                             FROM   apps.wwt_lookups
--                             WHERE  lookup_type = 'WWT_COP_24X7_ALERT'
--                             AND    wooh.process_group_id = attribute1)
--        GROUP BY wooh.status
--                ,wopg.NAME
--        UNION
--        SELECT   /*+ index(wooh WWT_ORIG_ORDER_HEADERS_N2) */
--                 wooh.status
--                ,wopg.NAME
--                ,COUNT (wooh.header_id) l_count
--                ,MAX (wooh.header_id) max_header_id
--        FROM     apps.wwt_om_process_groups wopg
--                ,apps.wwt_orig_order_headers_v wooh
--                , (SELECT   /*+ index(wool2) */
--                            wooh2.header_id
--                           ,DECODE (SIGN (MAX (wooh2.last_update_date) - MAX (wool2.last_update_date))
--                                   ,-1, MAX (wool2.last_update_date)
--                                   ,MAX (wooh2.last_update_date)
--                                   ) last_update_date
--                   FROM     apps.wwt_orig_order_headers_v wooh2
--                           ,apps.wwt_orig_order_lines wool2
--                   WHERE    wooh2.header_id = wool2.header_id
--                   AND      wooh2.creation_date > SYSDATE - 7
--                   GROUP BY wooh2.header_id) a
--        WHERE    1 = 1
--        AND      wooh.process_group_id = wopg.process_group_id(+)
--        AND      wooh.header_id = a.header_id(+)
--        AND      (SYSDATE - (25 / 1440)) > NVL (a.last_update_date, wooh.last_update_date)
--        AND      wooh.status IN
--                          ('ERROR - CONFLICT DEFINING PROCESS GROUP', 'ERROR - NO PROCESSING GROUPS DEFINED')
--        GROUP BY wooh.status
--                ,wopg.NAME
--        ORDER BY 1
--                ,2)