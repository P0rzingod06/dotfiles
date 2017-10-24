select * from apps.WWT_PO_TRANSACTIONS_LOG
where 1=1
--and creation_Date > sysdate - 1
and po_number IN ('2719001',
'2524351',
'2339131',
'2332952',
'2807040')
;
select * from apps.wwt_po_outbound_headers
where 1=1
--and creation_Date > sysdate - 1
and po_number IN ('2719001',
'2524351',
'2339131',
'2332952',
'2807040',
'2494159')
--and COMMUNICATION_METHOD = 'EDI'
;
select * from apps.wwt_poack_outbound_headers
where 1=1
--and creation_Date > sysdate - 1
and purchase_order_number IN ('0004804112')
;--SO# 5978044, PO# 0004804112, UPMC University of Pittsburgh
WWT_PO_OUTBOUND_EXTRACT
;
select segment1,xml_send_date,TYPE_LOOKUP_CODE,APPROVED_FLAG,USER_HOLD_FLAG,CANCEL_FLAG,creation_Date,last_updated_by,created_by
from apps.po_headers_all
where 1=1
--and creation_Date > sysdate - 1
and segment1 IN ('2719001',
'2524351',
'2339131',
'2332952',
'2807040',
'2494159')
--and XML_SEND_DATE > TO_DATE('14-NOV-15 00:00:00','DD-MON-YY HH24:mi:ss')
--and XML_SEND_DATE < TO_DATE('15-NOV-15 14:10:00','DD-MON-YY HH24:mi:ss')
order by xml_send_date
;
select * from apps.fnd_user
where 1=1
and user_id = 0
;