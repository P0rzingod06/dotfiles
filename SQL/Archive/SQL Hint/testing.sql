SELECT  partner_admin.wwt_special_char_removal_func(callout_number) callout_number,partner_admin.wwt_special_char_removal_func(order_id) order_id ,TO_CHAR(callout_date,'dd-mon-yyyy hh24:mi:ss') callout_date,partner_admin.wwt_special_char_removal_func(manu_userid) ordered_by_cuid ,partner_admin.wwt_special_char_removal_func(header_ship_to_location)header_ship_to_location ,partner_admin.wwt_special_char_removal_func(header_ship_to_location_type) header_ship_to_location_type,TO_CHAR(date_requested_current,'dd-mon-yyyy hh24:mi:ss') date_requested_current ,partner_admin.wwt_special_char_removal_func(warehouse_location)from_warehouse_location ,partner_admin.wwt_special_char_removal_func(network_project_number) network_project_number,partner_admin.wwt_special_char_removal_func(line_ship_to_location) line_ship_to_location,partner_admin.wwt_special_char_removal_func(line_ship_to_location_type) line_ship_to_location_type,partner_admin.wwt_special_char_removal_func(customer_part_number) customer_part_number ,partner_admin.wwt_special_char_removal_func(item_number)item_number ,partner_admin.wwt_special_char_removal_func(manufacturer) manufacturer,partner_admin.wwt_special_char_removal_func(callout_line_number) callout_line_number ,quantity,partner_admin.wwt_special_char_removal_func(cats_code) cats_code ,partner_admin.wwt_special_char_removal_func(ownership_designation_flag)ownership_designation_flag ,partner_admin.wwt_special_char_removal_func(asset_number) asset_number,partner_admin.wwt_special_char_removal_func(serial_number) serial_number ,tbuy_interface_transaction_id ,TO_CHAR(tbuy_requested_transfer_date,'dd-mon-yyyy hh24:mi:ss') tbuy_requested_transfer_date ,partner_admin.wwt_special_char_removal_func(warehouse_location_type) warehouse_location_type,partner_admin.wwt_special_char_removal_func(from_project_number) from_project_number 
FROM partner_admin.WWT_CING_SHIP_REQ_TRANSACTION CSRT 
WHERE transaction_status = 'CREATED' AND transaction_date_sent IS NULL AND process_flag = 'U'

select * from apps.WWT_CING_SHIP_REQ_TRANSACTION CSRT
where 1=1
--and creation_Date > sysdate
and transaction_status = 'CREATED'
and transaction_date_sent IS NULL
and process_flag = 'U'

SELECT /*+ INDEX (CSRT WCSRT_N3) */ 
DISTINCT TRANSACTION_BATCH_ID 
FROM PARTNER_ADMIN.WWT_CING_SHIP_REQ_TRANSACTION CSRT 
WHERE TRANSACTION_STATUS = 'CREATED' 
AND TRANSACTION_DATE_SENT IS NULL