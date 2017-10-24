/**Find Partners **/

SELECT DISTINCT attribute4 partnerID, attribute5
FROM apps.wwt_lookups_active_v wl
WHERE wl.lookup_type = 'WWT_ASN_OUTBOUND_EXTRACT'
AND attribute5 = 'PO CREATE'

/**Find ASNs **/

UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_' || ? 
     , last_update_date = SYSDATE
     , last_updated_by = ? 
WHERE process_status = 'UNPROCESSED'
 AND communication_method = ?
 AND partner_id = ? 
 
select * from apps.wwt_asn_outbound_shipments where partner_id = 'DOE HI' order by last_update_date DESC

select shipment_id, communication_method, partner_id from apps.wwt_asn_outbound_shipments where communication_method = 'PO CREATE' --and shipment_id IN (4678161, 4706664, 4705205, 4683169)

select * from apps.wwt_asn_outbound_shipments where shipment_id IN (4678161, 4706664, 4705205, 4683169)

update apps.wwt_asn_outbound_shipments set process_status = 'UNPROCESSED' where partner_id = 'DOE HI' and shipment_id IN (4678161, 4706664, 4705205, 4683169)

/** Summed Lines **/

select sum(quantity_shipped),
       unit_selling_price,
       shipped_uom,
       inventory_item_segment1,
       inventory_item_segment2,
       inventory_item_segment3,
       item_description,
       order_line_num
from apps.wwt_asn_outbound_items
where shipment_id = ?
group by order_line_num,
       unit_selling_price,
       shipped_uom,
       inventory_item_segment1,
       inventory_item_segment2,
       inventory_item_segment3,
       item_description
order by order_line_num

select * from dba_objects where object_name LIKE 'WWT_ASN_OUTBOUND%' and object_type = 'TABLE'

/** update process **/
UPDATE apps.wwt_asn_outbound_shipments
SET process_status = ?
   ,process_message = ?
   ,last_update_date = SYSDATE
   ,last_updated_by = ? 
WHERE process_status = ? 
  AND communication_method = ?
  AND partner_id = ? 
