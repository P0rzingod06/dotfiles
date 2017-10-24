wwt_upload_so_update

apps.WWT_UPLOAD_ATP_DATE

WWT_UTIL_SO_LINE

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_UPLOAD_GENERIC_EML_DIST'
and attribute1 = 219

brenda.dupont@wwt.com, sam.lawton@wwt.com,yiyun.yang@wwt.com,wong.wang@wwt.com,michael.gassert@wwt.com,Yeshwant.Mahambare@wwt.com, Sudhan.Sairam@wwt.com

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_FF_TEMPLATE'
and attribute1 LIKE '%SO U%'
--and attribute2 LIKE 

select * from PARTNER_ADMIN.WWT_SO_UPDATE_STG
where 1=1
--AND sales_order_num = 5684602
--and rownum = 1
--order by last_update_date desc
--group by sales_order_num

attribute84

select TRUNC(MIN(oola.request_date))
from apps.wwt_oe_order_headers_all_v ooha, apps.oe_order_lines_all oola
where 1=1
and OOHA.ORDER_NUMBER = 5684602
and oola.header_id = ooha.header_id;

SELECT wshd.header_id, NVL(TRUNC(TO_DATE(wshd.attribute84)), null)
FROM apps.wwt_oe_order_headers_all_v ooha,
APPS.WWT_SO_HEADERS_DFF_V wshd
WHERE     1 = 1
AND ooha.order_number = 5684602
AND ooha.header_id = wshd.header_id

select * from wwt_so_headers_dff
where 1=1
--and creation_date > sysdate - 1
and header_id IN (13268369,
13451082,
13451094,
13457393,
13448208)

update wwt_so_headers_dff
where 1=1
and 

select distinct wshd.*
from apps.oe_order_headers_all ooha,
wwt_so_headers_dff wshd
where 1=1
and ooha.order_number = 5626902

select distinct oola.ship_from_org_id,mp.calendar_code, oola.salesrep_id, ooha.header_id,ooha.*
from apps.oe_order_headers_all ooha
,apps.oe_order_lines_all oola
,apps.mtl_parameters mp
,apps.wwt_so_update_stg wsus
where ooha.header_id = oola.header_id
--and wsus.sales_order_num = 5684602
and wsus.sales_order_num IN(5626902,
5684602,
5685485,
5685463,
5687571)
and wsus.sales_order_num = ooha.order_number
and mp.organization_id = oola.ship_from_org_id

select * from wwt_orig_order_headers
where 1=1
and order_number = 5626902
--and booked_date LIKE '%10/9/2014%'
and creation_Date > sysdate - 500

update oe_order_lines_all
set salesrep_id = 100003175
where 1=1
--and line_id = 31457727
and header_id = 13448208

select * from oe_order_headers_all
where 1=1
--and line_id = 31457727
and header_id = 13448208

select * from wwt_lookups
where 1=1
and lookup_type = 'WWT_MICROSOFT_SALES_CHANNELS'
--and attribute2 = 100003166

select * from apps.wwt_so_update_stg
where 1=1
--and sales_order_num = 5684602
order by last_update_date desc

3689

select * from bom_cal_week_start_dates
where 1=1

select mrp_calendar.next_work_day(101,1,TO_DATE('11/22/14','MM/DD/YY')) from dual

select sysdate from dual

select * from mtl_parameters

select * from wwt_lookups_active_v
where 1=1
and lookup_type = 'WWT_OXBOW_SOURCING_RULES'
--and attribute4 LIKE '%MSFT%'
--and attribute12 IS NOT NULL

select  distinct wl.attribute12 
         from apps.wwt_lookups wl,
         apps.oe_order_headers_all ooha,
         APPS.HZ_CUST_ACCT_SITES_ALL HCASA,
APPS.HZ_PARTY_SITES HPS ,  
APPS.HZ_LOCATIONS HL,
APPS.HZ_CUST_SITE_USES_ALL HCSUA,
apps.hz_partIes HP ,
apps.hz_cust_accounts hca,
apps.wwt_so_update_stg wsus
where 1=1
AND HCSUA.CUST_ACCT_SITE_ID = HCASA.CUST_ACCT_SITE_ID 
AND HCASA.PARTY_SITE_ID = HPS.PARTY_SITE_ID 
AND HPS.LOCATION_ID = HL.LOCATION_ID
and hp.party_id = hps.party_id 
and hp.party_id = hca.party_id 
AND    HCSUA.site_use_code =  'SHIP_TO'
          and wl.lookup_type = 'WWT_OXBOW_SOURCING_RULES' 
              and wl.attribute2 = hl.country
              AND wsus.sales_order_num = 5684602
              and wl.attribute12 is not null 
              and hcsua.site_use_id = ooha.ship_to_org_id 
              AND wsus.sales_order_num = ooha.order_number

select TO_DATE ('22-NOV-14', 'DD-MON-YY') from dual

select TO_NUMBER('10') from dual

brenda.dupont@wwt.com, sam.lawton@wwt.com,yiyun.yang@wwt.com,wong.wang@wwt.com,michael.gassert@wwt.com

select * from apps.wwt_so_update_stg
where 1=1
--and so_id = 275024
--and sales_order_num = 5684602
order by last_update_date desc

select * from apps.wwt_frolic_status_log
where 1=1
and creation_Date > sysdate - 10
and source_name IN ('SALES ORDER UPDATE', 'SO Update')
order by creation_date desc

select * from apps.wwt_upload_generic_log
where 1=1
and batch_id = 682819
order by id desc

SELECT wshd.header_id,
wshd.attribute84
--NVL (TO_DATE (wshd.attribute84, 'DD-MON-RRRR'), null)
FROM apps.wwt_oe_order_headers_all_v ooha,
APPS.WWT_SO_HEADERS_DFF_V wshd
WHERE     1 = 1
AND ooha.order_number = 5705417
AND ooha.header_id = wshd.header_id

SELECT wshd.header_id,
NVL (TO_DATE (wshd.attribute84, 'YYYY/MM/DD HH24:MI:SS'),null)
FROM apps.oe_order_headers_all ooha,
APPS.WWT_SO_HEADERS_DFF wshd
WHERE     1 = 1
AND ooha.order_number = 5674501
AND ooha.header_id = wshd.header_id

WWT_SO_HEADER_DFF_UTILS.populate_wwt_so_header_dff(x_errcode,x_retcode, p_header_id, p_attribute84)

SELECT COUNT (*)
        FROM apps.wwt_lookups_active_v
       WHERE     1 = 1
             AND lookup_type = 'WWT_MICROSOFT_SALES_CHANNELS'
             AND attribute2 = 100003175
             
             SELECT DISTINCT mp.organization_id, ooha.salesrep_id
           FROM apps.oe_order_headers_all ooha,
                apps.oe_order_lines_all oola,
                apps.mtl_parameters mp
          WHERE     ooha.header_id = oola.header_id
                AND ooha.order_number = 5705554 
                AND mp.organization_id = oola.ship_from_org_id
                AND ROWNUM = 1;
