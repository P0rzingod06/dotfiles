select * from wwt_orig_order_headers_dff
where 1=1
and header_id = 16159171

select * from wwt_orig_order_headers
where 1=1
and SALESREP = 'AT&T - Ariba'
and SOURCE = 'POI_TO_COP'
and creation_date > sysdate - 50
--and header_id = 16159171

select wooh.status, NVL(wooh.end_customer_name, 'N/A'),  woohd.attribute99
from wwt_orig_order_headers_v wooh,
wwt_orig_order_headers_dff woohd
where 1=1
and wooh.header_id = 16164162
and woohd.header_id = wooh.header_id

update wwt_orig_order_headers
set status = 'UNPROCESSED', end_customer_name = NULL
where 1=1
and header_id = 16164519

update wwt_stg_order_headers
set end_customer_name = 
where 1=1
and header_id in (20177738, 20316227,20316228)

select distinct end_customer_name from wwt_orig_order_headers
where 1=1
and header_id = 16164162

--check for email sent
SELECT wooh.header_id,
    CASE
        WHEN WOOLD.ATTRIBUTE29 LIKE 'TELCO%' THEN 'N'
        WHEN WOOLD.ATTRIBUTE29 IS NULL THEN 'N'
        ELSE 'Y'
    END, wooh.end_customer_name,  woohd.attribute99
FROM APPS.WWT_ORIG_ORDER_HEADERS WOOH, 
wwt_orig_order_headers_dff woohd,
APPS.WWT_ORIG_ORDER_LINES WOOL, 
APPS.WWT_ORIG_ORDER_LINES_DFF WOOLD 
WHERE 1=1 
AND WOOH.HEADER_ID = WOOL.HEADER_ID 
and wooh.header_id = woohd.header_id
AND WOOL.LINE_ID = WOOLD.LINE_ID
and wooh.salesrep = 'AT&T - Ariba'
and wooh.source = 'POI_TO_COP'
and wooh.creation_date > sysdate - 50
--and woohd.attribute99 LIKE '%TRI
--and wooh.end_customer_name IS NOT NULL
--AND WOOH.HEADER_ID IN ( 16160804, 16161807,
--16162820,
--16162823,
--16162832,
--16161936,
--16163806,
--16163202)

select distinct 'TEST'
from apps.wwt_orig_order_headers wooh
where 1=1