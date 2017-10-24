select count(*), creation_date from apps.wwt_so_update_stg
group by creation_Date
--where sales_order_num = 5927037
order by creation_Date desc

select * from apps.wwt_so_update_stg

select * from apps.wwt_frolic_status_log
where 1=1
and creation_Date > sysdate - 10
and source_name IN ('SALES ORDER UPDATE', 'SO Update')
order by creation_date desc

select * from apps.wwt_upload_generic_log
where 1=1
and batch_id = 709553
order by ID desc

select * from apps.wwt_po_outbound_lines where outbound_header_id = 6036486

select * from apps.wwt_po_outbound_headers where outbound_header_id = 6036486

select * from apps.oe_order_headers ooha, apps.oe_order_lines oola
where 1=1 
--and order_number = '5940342'
--and ooha.cust_po_number = '8500337392'
--and oola.USER_ITEM_DESCRIPTION = 'Cisco One-Port Clear-Channel T3/E3 Service Module - For Wide Area Network - 1 x T3/E3 WAN'
and ooha.header_id = oola.header_id
and oola.creation_date > sysdate - 1

WWT_PO_OUTBOUND_EXTRACT

select * from apps.PO_HEADERS_ALL
where 1=1
and creation_date > sysdate - 2
and comments = 'SO# 5940342, PO# 8500337392, Verizon Credit Inc.'

select * from apps.po_lines_all
where 1=1
and po_header_id IN (2929721,
2929723,
2929724,
2929725)

select *  from apps.wwt_orig_order_headers_v ooha, apps.wwt_orig_order_lines oola
where 1=1
and oola.attribute6 = 'TB0320'
and ooha.header_id = oola.header_id
and ooha.customer_po_number = '8500337392'
--and creation_Date > sysdate - 20

select oola.attribute10, oola.attribute6, oola.header_id from apps.wwt_stg_order_headers_v ooha, apps.wwt_stg_order_lines oola
where 1=1
--and oola.attribute6 = 'TB0320'
and ooha.header_id = oola.header_id
and ooha.customer_po_number = '8500337392'
--and creation_Date > sysdate - 20

select * from apps.po_lines_all
where 1=1
and po_line_id = 10247165

select * from dba_objects
where 1=1
and object_name = '%ascade%'