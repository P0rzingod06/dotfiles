select * from APPS.WWT_PURCHASE_ORDER_ACK
where 1=1
--and header_id = 16000250
and date_of_creation > sysdate - 100
order by date_of_creation
;
select * from APPS.wwt_poack_outbound_headers
where 1=1
and trading_partner_id = '114315195HUBCCC'
--and creation_date > sysdate - 10
order by creation_date desc
;
WWT_PO_ACK_OB_EXTRACT
;
apps.wwt_orcp_inv_processor_wms
;