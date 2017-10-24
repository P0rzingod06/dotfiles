/** beginning select of unprocessed records **/
select * from WWT_PO_OUTBOUND_HEADERS where TP_LOCATION_CODE = 'SoftwareSpectrum_PO_Outbound' AND COMMUNICATION_METHOD = 'XML' AND status = 'UNPROCESSED'
order by last_update_date DESC

select * from wwt_po_outbound_headers where outbound_header_id = 5839897

update wwt_po_outbound_headers set status = 'UNPROCESSED' where outbound_header_id = 5839897

UPDATE APPS.WWT_PO_OUTBOUND_HEADERS POH
SET POH.STATUS = 'PROCESSING_' || ?
WHERE POH.STATUS = 'UNPROCESSED'
AND POH.TP_LOCATION_CODE = 'SoftwareSpectrum_PO_Outbound'
AND POH.COMMUNICATION_METHOD = 'XML'

/**Select header extension **/

SELECT BILL_TO_ACCOUNT_ID
FROM APPS.WWT_PO_SSI_HEADERS_V
WHERE OUTBOUND_HEADER_ID = 5839897

/** insert into archive **/

WWT_WM_ADMIN.WWT_WM_ARCHIVE