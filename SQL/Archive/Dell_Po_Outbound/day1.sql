SELECT *
FROM APPS.WWT_PO_OUTBOUND_HEADERS
WHERE TP_LOCATION_CODE = 'Dell_PO_Outbound'
AND COMMUNICATION_METHOD = 'XML'
AND (outbound_header_id = 41 OR outbound_header_id = 42)
AND STATUS = 'UNPROCESSED'

update wwt_po_outbound_headers set status = 'UNPROCESSED' where outbound_header_id = 41 OR outbound_header_id = 42
select outbound_header_id, po_attribute9, status from wwt_po_outbound_headers where outbound_header_id = 41 OR outbound_header_id = 42
update wwt_po_outbound_headers set po_attribute9 = 100003085 where outbound_header_id = 41
update wwt_po_outbound_headers set po_attribute9 = 2245 where outbound_header_id = 41


apps.WWT_WM_ARCHIVE
apps.PARTNER_ADMIN.WWT_PO_TRANSACTIONS_LOG
apps.WWT_WM_ADMIN.WWT_WM_ARCHIVE

WWT_PO_TRANSACTIONS_LOG

select * from PARTNER_ADMIN.WWT_PO_OUTBOUND_SHIPMENTS where outbound_line_id = 42
select * from APPS.WWT_PO_DELL_SHIPMENTS_V where outbound_shipment_id = 42
update APPS.WWT_PO_DELL_SHIPMENTS_V set outbound_shipment_id = 42 where outbound_shipment_id = 243626

apps.WWT_WM_ADMIN.WWT_WM_ARCHIVE
WWT_PO_TRANSACTIONS_LOG

select * from PARTNER_ADMIN.WWT_PO_OUTBOUND_LINES where outbound_header_id = 41
select distinct pol_attribute6 from partner_admin.wwt_po_outbound_lines where pol_attribute6 LIKE '%**%'
update PARTNER_ADMIN.WWT_PO_OUTBOUND_LINES set pol_attribute6 = '**', item_description = 'Q: QD360902983 745 SCOTT' where outbound_header_id = 41
select distinct item_description from PARTNER_ADMIN.WWT_PO_OUTBOUND_LINES where item_description LIKE 'Q:%'

SELECT ATTRIBUTE2 AUTH_USERNAME,
    ATTRIBUTE3 AUTH_PASSWORD,
    ATTRIBUTE4 PHONE,
    ATTRIBUTE5 CUSTOMER_SHORT_NAME,
    ATTRIBUTE6 GOVT_RATING,
    ATTRIBUTE7 SOURCE,
    attribute1,
    attribute10
FROM APPS.WWT_LOOKUPS
WHERE LOOKUP_TYPE = 'WWT_PO_OUTBOUND_DELL'
AND attribute7 = 'MSFT'
AND ATTRIBUTE1 = 2245
AND ATTRIBUTE10 = ?

select * from wwt_lookups where lookup_type = 'WWT_PO_OUTBOUND_DELL'

