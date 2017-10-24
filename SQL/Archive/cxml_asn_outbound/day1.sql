WWT_ASN_OUTBOUND_EXTRACT

select * from apps.wwt_asn_outbound_shipments

SELECT APPS.WWT_ASN_OUT_HEADER_BATCH_S.NEXTVAL BATCHID
          , pd.partner_id PARTNERID
FROM 
    (SELECT DISTINCT partner_id
       FROM apps.wwt_asn_outbound_shipments
      WHERE process_status = 'UNPROCESSED'
        AND communication_method = 'cXML') pd
        
UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_cXML_ASN'
    , last_update_date = SYSDATE
    , last_updated_by = ?
WHERE process_status = 'UNPROCESSED'
AND communication_method = 'cXML'

UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_' || ?
     , last_update_date = SYSDATE
     , last_updated_by = ?
WHERE process_status = 'PROCESSING_cXML_ASN'
 AND communication_method = 'cXML'
 AND partner_id = ?
 
 
 UPDATE apps.wwt_asn_outbound_shipments
SET process_status = ?
    , process_message = ?
    , last_update_date = SYSDATE
    , last_updated_by = ?
WHERE shipment_id = ?

UPDATE apps.wwt_asn_outbound_shipments
SET process_status = 'PROCESSING_cXML_ASN'
    , last_update_date = SYSDATE
    , last_updated_by = ?
WHERE process_status = 'UNPROCESSED'
AND communication_method = 'cXML'

select distinct process_status from apps.wwt_asn_outbound_shipments
where communication_method = 'cXML'
--where process_status = 'UNPROCESSED'
--ORDER by last_update_date DESC

update apps.wwt_asn_outbound_shipments
set process_status = 'UNPROCESSED',
process_message = NULL
where shipment_id = 90750 OR shipment_id = 90823 OR shipment_id = 90832 OR shipment_id = 90849

select * from apps.wwt_asn_outbound_shipments
where shipment_id = 90750 OR shipment_id = 90823 OR shipment_id = 90832 OR shipment_id = 90849

select distinct partner_id from apps.wwt_asn_outbound_shipments

update apps.wwt_asn_outbound_shipments
set partner_id = 'AN01000049696'
where shipment_id = 90750

select * from apps.wwt_asn_outbound_shipments
where communication_method = 'cXML'
AND process_status = 'PROCESSED'
AND partner_id = 'AN01000049696'

