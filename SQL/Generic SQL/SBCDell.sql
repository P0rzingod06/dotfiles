select * from apps.wwt_partner_trx_headers
where 1=1
and creation_Date > sysdate - 100
and header_id = 559331
--and vendor_order_number LIKE '%P01285403%'
;--559331
select * from wwt_stg_order_headers
where 1=1
and header_id = 559330
;