select wpoh.* 
from apps.wwt_po_outbound_headers wpoh 
,apps.wwt_po_outbound_lines wpol 
,apps.wwt_po_outbound_shipments wpos 
where wpoh.outbound_header_id = wpol.outbound_header_id 
--and wpoh.outbound_header_id = wpos.outbound_header_id --not necessary, but you should know it's there 
and wpol.outbound_line_id = wpos.outbound_line_id 
and wpol.vendor_product_num like '%AIR-ANT2422DB-R%'
and wpoh.po_number = '10450201'
;
UPDATE APPS.WWT_PO_OUTBOUND_HEADERS POH
SET POH.STATUS = 'PROCESSING_' || ?
WHERE POH.STATUS = 'UNPROCESSED'
AND POH.TP_LOCATION_CODE = ?
AND POH.COMMUNICATION_METHOD = ?
;