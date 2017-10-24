WWT_APPLICATION_LOGGER.put

select * from dba_objects
where 1=1
and object_name LIKE '%LOGGER%'

select distinct application_name from wwt_application_log
where creation_Date > sysdate - 1

select * from wwt_application_log
where 1=1
--and creation_date > sysdate - 1
and module_name IN ('WWT_DSH_GCFI_EXTRACT_846', 'DSH Inbound Supplier Onhand')
order by creation_date desc

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_DSH_846_EXTRACT_CONSTS'

select * from wwt_frolic_status_log
where 1=1
and creation_date > sysdate - 1
order by creation_date desc

SELECT batch_id,
MAX (creation_date) creation_date,
MAX (last_update_date) last_update_date,
COUNT (*),
SUM (onhand_quantity) oh
FROM apps.WWT_INVENTORY_ADVICE_OUTBOUND
WHERE     partner_id = '656064441SUP'
AND creation_date BETWEEN TO_DATE ('20-APR-2014 23:00',
'DD-MON-YYYY HH24:MI')
AND TO_DATE ('29-APR-2016 03:00',
'DD-MON-YYYY HH24:MI')
--         AND batch_id IN (270010,270945,271141,273200,273452,273589,273637,273841,273928,274094)
GROUP BY batch_id
ORDER BY 2 desc

select batch_id, creation_date, last_update_date from apps.WWT_INVENTORY_ADVICE_OUTBOUND
where 1=1
and creation_date > sysdate - 1
group by batch_id, creation_Date, last_update_date
order by 2 desc

select count(*) from partner_admin.WWT_DSH_SUPPLIER_ONHAND_QTY
where 1=1
and creation_date < to_date('01-APR-2015');