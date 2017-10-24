select * from apps.WWT_INVOICE_OUTBOUND_HEADERS
where 1=1
and invoice_number IN (1907330)
and creation_date > sysdate - 20
--and sales_order_number IS NULL
order by creation_Date desc
;
SELECT *
FROM apps.wwt_invoice_outbound_headers wioh
,apps.wwt_oe_order_headers_all_v ooha
--,apps.wwt_so_headers_dff wshd
WHERE 1=1
AND wioh.sales_order_number = ooha.order_number
AND wioh.org_id = ooha.org_id (+)
--AND ooha.header_id = wshd.header_id (+)
AND wioh.process_status = 'PROCESSING_INIT_2015120107512781'
AND wioh.partner_id = 'AN01000049696'
ORDER BY wioh.header_id desc
;
SELECT * FROM apps.fnd_user
where 1=1
and user_name = 'GASSERTM'
;
SELECT  distinct partner_id
FROM     apps.wwt_invoice_outbound_headers wioh
WHERE  process_status = 'UNPROCESSED'
AND       communication_method IN ('cXML', 'xCBL')
AND       DECODE(?, NULL, 'ABC', partner_id) = NVL(?, 'ABC')
ORDER BY partner_id
;
WWT_INVOICE_OUTBOUND_EXTRACT
;