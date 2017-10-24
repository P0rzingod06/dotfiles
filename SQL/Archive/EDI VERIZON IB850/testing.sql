select * from oe_order_headers_all
where 1=1
and order_number = 5704503 
--and CUST_PO_NUMBER = '8609575042'
--and orig_sys_document_ref LIKE '%beth%'

select header_id, creation_Date, wwt_attribute49, status from apps.wwt_orig_order_headers_v
where 1=1
--and creation_Date > sysdate - 5
--and customer_po_number LIKE ('%8609575042%')
--, '8609617322', '8609766068', '8609687592', '8609797156')
and salesrep = 'Verizon(GTE)-Fujitsu'
and source = 'EDI'
and last_update_date > sysdate - 5
--and rownum = 5
order by creation_date desc

select * from wwt_orig_order_lines
where 1=1
and header_id IN (16430257,
16430255,
16430254)

select header_id, creation_Date, wwt_attribute49 from apps.wwt_stg_order_headers_v
where 1=1
and orig_header_id IN (16371141,
16371140,
16371139,
16371138,
16371134,
16372120,
16371132)
order by creation_date desc