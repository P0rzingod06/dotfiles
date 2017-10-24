UPDATE APPS.WWT_PO_OUTBOUND_HEADERS POH
SET POH.STATUS = 'PROCESSING_'
WHERE POH.STATUS = 'UNPROCESSED'
AND POH.TP_LOCATION_CODE = 'DellBoeing_PO_Outbound'
AND POH.COMMUNICATION_METHOD = 'XML'

select * from APPS.WWT_PO_OUTBOUND_HEADERS POH
where POH.STATUS = 'UNPROCESSED'
AND POH.TP_LOCATION_CODE = 'DellBoeing_PO_Outbound'
AND POH.COMMUNICATION_METHOD = 'XML'

select * from APPS.WWT_PO_OUTBOUND_HEADERS
where status = 'UNPROCESSED'

update APPS.WWT_PO_OUTBOUND_HEADERS
set status = 'UNPROCESSED'
where outbound_header_id = 5846993 OR outbound_header_id = 5846992 OR outbound_header_id = 5840523

WWT_PO_TRANSACTIONS_LOG

select * from apps.wwt_po_outbound_headers
where outbound_header_id = 5846993 OR outbound_header_id = 5846992 OR outbound_header_id = 5840523

select * from apps.wwt_po_outbound_headers
where TP_LOCATION_CODE = 'DellBoeing_PO_Outbound'
AND COMMUNICATION_METHOD = 'XML'
AND status = 'UNPROCESSED'