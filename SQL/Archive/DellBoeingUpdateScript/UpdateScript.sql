Update apps.WWT_DELL_BOEING_POO_LOG WDBPL
Set PO_SENT_FLAG = 'N'
where 1=1
and PO_SENT_FLAG = 'E'
and creation_date >= TO_DATE('15-NOV-15 03:09:17','DD-MON-YY hh:mi:ss')
/