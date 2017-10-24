select * from apps.wwt_asn_outbound_shipments
where 1=1
--and order_id = 5698158
and partner_id = 'EDWARDJONESAM'
--and shipment_id IN (9252467,9252468)
--and shipment_id = 'S2579909'
and creation_date > sysdate - 150
and process_status <> 'PROCESSED'
--order by creation_date asc
;
select * from wwt_asn_outbound_orders
where 1=1
--and shipment_id IN (9244211)
--and so_header_id = 13490070
--and tracking_number = '1Z7777777777333889'
and shipment_id IN (9252467,9252468)
;
select * from wwt_asn_outbound_extensions
where 1=1
and common_table_name LIKE 'WWT_ASN_OUTBOUND_ITEMS'
and common_table_id IN (20710206,20710207)
;
select * from wwt_asn_outbound_items
where 1=1
and shipment_id IN (9252468)
;
update wwt_asn_outbound_shipments
--set quantity_shipped = 1
set process_status = 'UNPROCESSED'
where 1=1
and shipment_id IN (9252468)
;
select * from oe_order_lines_all
where 1=1
--and order_number IN (5702132,5702132)
--and header_id = 13491183
and line_id = 31581856
--and order_number = 5676506
;
update oe_order_lines_all
set last_update_date = (select sysdate from dual)
where 1=1
--and order_number = 5676506
and line_id = 31581856
;
select * from wwt_so_headers_dff
where 1=1
and header_id = 13506256
;
WWT_ASN_OUTBOUND_EXTRACT
;
select * 
from dba_objects
where 1=1
and object_name LIKE '%OE%'
and object_type = 'TABLE'
and owner = 'ONT'
;
--If order is canceled it doesn't go into asn shipment tables,  need to use query to determine if cancelled then create xml with given values.

UPDATE apps.wwt_mtl_txn_extract_detail mted
   SET mted.process_status = ? --newProcessStatus
      ,mted.process_message = ? --newProcessMessage
      ,mted.last_update_date = SYSDATE
      ,mted.last_updated_by = ? --updatedBy
 WHERE mted.process_status = ? --currentProcessStatus
   AND mted.parent_record_id IN (SELECT *
                                    FROM apps.wwt_mtl_txn_extract mte
                                   WHERE 1=1 
--                                   and mte.process_status = 'UNPROCESSED' --currentProcessStatus
                                     AND mte.partner_id = 'EDWARDJONESAM' --partnerID
                                  )
 ;                                 
select * from wwt_mtl_txn_extract_detail
where 1=1
and creation_date > sysdate - 100
;
WWT_PROCESS_EXEC_API
;
select * from APPS.WWT_PROCESS_EXEC_STATUS
order by creation_date desc
WITH lookup_vals
     AS (SELECT wlav.attribute1 edj_sold_to_org_id,
                wlav.attribute5 edj_org_id,
                wlav.attribute2 cbiz_sold_to_org_id,
                wlav.attribute4 related_org_id
           FROM apps.wwt_lookups_active_v wlav
          WHERE wlav.lookup_type = 'EDJ_SHIP_REQUEST_REPORT' AND ROWNUM = 1) --should only be one row returned
 ;         
SELECT * FROM WWT_LOOKUPS
WHERE 1=1
AND LOOKUP_TYPE = 'WWT_ASN_OUTBOUND_EXTRACT'
--AND ATTRIBUTE21 = 'Y'
;
wwt_asn_outbound_edjam
;
SELECT apps.wwt_edj_device_ship_s.NEXTVAL
FROM DUAL
;

