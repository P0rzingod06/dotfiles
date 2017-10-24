SELECT *
FROM partner_admin.wwt_orig_order_headers wooh, 
partner_admin.wwt_orig_order_lines wool, 
partner_admin.wwt_orig_order_lines_dff woold 
WHERE 1 = 1 
AND wooh.creation_date >= TRUNC (SYSDATE) - 9 
AND wool.header_id = wooh.header_id 
AND woold.line_id = wool.line_id 
AND customer_po_number = 'SEWP' 
ORDER BY woold.line_dff_id

update wwt_orig_order_headers
set status = 'UNPROCESSED'
where 1 = 1 
and header_id = 16413203

AND customer_po_number = 'SEWP' 

SELECT *
FROM partner_admin.wwt_stg_order_headers wooh, 
partner_admin.wwt_stg_order_lines wool, 
partner_admin.wwt_stg_order_lines_dff woold,
wwt_stg_order_headers_dff wsohd
WHERE 1 = 1 
AND wooh.creation_date >= TRUNC (SYSDATE) - 9
AND wool.header_id = wooh.header_id 
AND woold.line_id = wool.line_id 
AND wsohd.header_id = wooh.header_id
AND wooh.customer_po_number = 'SEWP' 
ORDER BY woold.line_dff_id

select * from wwt_stg_order_headers_dff
where 1=1
and creation_date > sysdate - 2

