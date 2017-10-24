SELECT ph.po_header_id, ph.vendor_site_id, ph.org_id, trm.name, pvs.vendor_site_code
FROM APPS.PO_HEADERS_ALL ph, APPS.AP_TERMS_TL trm, APPS.PO_VENDOR_SITES_ALL pvs
WHERE 
ph.vendor_id = ?
AND ph.segment1 = ?
AND ph.vendor_site_id = pvs.vendor_site_id (+)
AND ph.terms_id = trm.term_id (+)
AND trm.language = USERENV('LANG')
ORDER BY ph.po_header_id desc

select * from APPS.PO_HEADERS_ALL
where vendor_id = 49 
order by segment1 DESC

select * from apps.po_headers_all
where segment1 = 10373566

select * from apps.po_headers_all
where po_header_id = 2697140

select * from apps.po_headers_all
where segment1 LIKE '1037208%'

SELECT ph.po_header_id, ph.vendor_site_id, ph.org_id, trm.name, pvs.vendor_site_code
FROM APPS.PO_HEADERS_ALL ph, APPS.AP_TERMS_TL trm, APPS.PO_VENDOR_SITES_ALL pvs
WHERE 
ph.vendor_id = ?
AND ph.segment1 = ?
AND ph.vendor_site_id = pvs.vendor_site_id (+)
AND ph.terms_id = trm.term_id (+)
AND trm.language = USERENV('LANG')
ORDER BY ph.po_header_id desc

SELECT APPS.WWT_PO_OUTBOUND_HEADER_BATCH_S.nextval BATCH_ID FROM DUAL

Select count(Freight_Id) as rowCount
FROM APPS.WWT_INBOUND_FREIGHT_COST
WHERE VENDOR_PO = 53977574
AND Ship_Set_Number = 14
AND VENDOR_TRACKING_NUMBER = 8590871

select * from wwt_inbound_freight_cost

select * from WWT_INBOUND_FREIGHT_COST order by last_update_date DESC