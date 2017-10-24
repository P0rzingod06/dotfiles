  SELECT /*+ ORDERED USE_NL(OOHA WSHD JRS WMP OOLA WSLD WLAV) */
  ooh.header_id,
  ooh.order_number,
  NVL (ooh.order_date_type_code, 'SHIP') date_type_code,
  ool.line_id,
  ool.line_number line_num,
  ool.schedule_ship_date,
  ool.schedule_arrival_date,
  ool.promise_date,
  NVL (ool.arrival_set_id, ool.ship_set_id) set_id,
  ool.attribute13 material_designator,
  wsld.attribute63 lab_processing_reqd_flag,
--  Determines if there are any WDD records in a status other than Backordered or Ready to Release
  NVL ((SELECT DECODE (COUNT (1), 0, 'Y', 'N')
      FROM   apps.wsh_delivery_details wdd
      WHERE  wdd.released_status NOT IN ('B', 'R')
      AND    wdd.source_line_id = ool.line_id)
  , 'Y'
  ) valid_wdd_status_flag,
--  Determines if there are any WDD Included Item records in a status other than Backordered or Ready to Release
  NVL ((SELECT DECODE (COUNT (1), 0, 'Y', 'N')
      FROM   apps.wsh_delivery_details wdd,
             apps.oe_order_lines_all oolai
      WHERE  wdd.released_status NOT IN ('B', 'R')
      AND    oolai.line_id = wdd.source_line_id
      AND    oolai.ordered_quantity > 0
      AND    oolai.item_type_code = 'INCLUDED'
      AND    oolai.link_to_line_id = ool.line_id)
  , 'Y'
  ) valid_wdd_comp_status_flag,
  -- Determines if the Credit Check Failure hold is applied to the order header
  NVL ( (SELECT DECODE (COUNT (1), 0, 'N', 'Y')
      FROM   apps.oe_hold_definitions ohd,
             apps.oe_hold_sources_all ohsa,
             apps.oe_order_holds_all holds
      WHERE  ohd.name = 'Credit Check Failure'
      AND    ohsa.hold_id = ohd.hold_id
      AND    holds.hold_source_id = ohsa.hold_source_id
      AND    NVL (holds.released_flag, 'N') = 'N'
      AND    holds.header_id = ooh.header_id)
  , 'N'
  ) hdr_credit_check_hold_flag,
  --
  NVL ((select NVL (MP.WMS_ENABLED_FLAG, 'N') WMS_ENABLED_FLAG
     FROM apps.HZ_TIMEZONES_VL HTV,
          apps.GL_SETS_OF_BOOKS GSOB,
          apps.HR_OPERATING_UNITS HOU,
          apps.HR_ORGANIZATION_UNITS HRU_OU,
          apps.HR_ORGANIZATION_INFORMATION HOI,
          apps.MTL_PARAMETERS MP,
          apps.HR_ORGANIZATION_UNITS HRU
    WHERE 1=1
      AND HRU.ORGANIZATION_ID = ool.ship_from_org_id
      AND HRU.ORGANIZATION_ID = MP.ORGANIZATION_ID (+)
      AND HRU.ORGANIZATION_ID = HOI.ORGANIZATION_ID (+)
       AND GSOB.SET_OF_BOOKS_ID(+) = HOU.SET_OF_BOOKS_ID
       AND HOU.ORGANIZATION_ID(+) =
           APPS.WWT_UTIL_DATATYPES_PKG.WWT_TO_NUMBER(HOI.ORG_INFORMATION2)
      AND HOI.ORG_INFORMATION_CONTEXT (+)= 'Accounting Information'
      AND APPS.WWT_UTIL_DATATYPES_PKG.WWT_TO_NUMBER (HOI.ORG_INFORMATION3) = HRU_OU.ORGANIZATION_ID (+)
      AND MP.TIMEZONE_ID = HTV.TIMEZONE_ID (+)),
  'N')
  whs_wms_enabled_flag
  FROM  
  apps.wwt_oe_order_headers_all_v ooh,                        --CHG30803
  apps.wwt_so_headers_dff wshd,
  apps.jtf_rs_salesreps jrs,
  apps.wwt_metric_programs wmp,
  apps.oe_order_lines_all ool,                          --CHG30803
  apps.wwt_so_lines_dff wsld,
  apps.wwt_lookups_active_v wlav
  WHERE  1 = 1
  AND    wlav.attribute2 IN
  ('STOCK', 'OE_TO_PO', 'DROP_SHIP', 'RETURN') --May need to be lookup-driven in the future based on field being updated
  AND    wlav.lookup_type = 'WWT_OM_LINE_FLOW_CONTROLS'
  AND    TO_CHAR (ool.line_type_id) = wlav.attribute1
  AND    ool.line_id = wsld.line_id(+)
  AND    NVL (ool.shipped_quantity, 0) = 0          --Line not shipped
  AND    ool.ordered_quantity > 0                 --Line not cancelled
  AND    NVL (ool.item_type_code, 'ZZZ') != 'INCLUDED'
  AND    ool.open_flag = 'Y'
  AND    ooh.header_id = ool.header_id
  AND    apps.wwt_util_datatypes_pkg.wwt_to_number (jrs.attribute2) = wmp.program_id
  AND    ooh.org_id = jrs.org_id
  AND    ooh.salesrep_id = jrs.salesrep_id
  AND    ooh.header_id = wshd.header_id(+)
  AND    ooh.open_flag = 'Y'
  AND    ooh.header_id IN (14707225,
14726927)
  AND    (EXISTS (SELECT 1 FROM apps.oe_sets os
    WHERE os.set_name IN (SELECT     REGEXP_SUBSTR (null, '[^,]+', 1, LEVEL) ship_set
                          FROM       DUAL
                          CONNECT BY REGEXP_SUBSTR (null, '[^,]+', 1, LEVEL) IS NOT NULL)
    AND os.header_id IN (14707225,
14726927)
    AND os.set_id = NVL (ool.arrival_set_id, ool.ship_set_id))
  OR null IS NULL
  )
  ORDER BY NVL (ooh.order_date_type_code, 'SHIP'),
  ooh.order_number,
  NVL (ool.arrival_set_id, ool.ship_set_id),
  ool.line_number
; --it looks like schedule date passed in same as date already there.  No update necessary.  So throw error? /* VALIDATION #4 Check if dates passed is same as current date*/ cascade values to lines
  
  select DECODE (UPPER (wnd.waybill),
'MULTI', NVL (wdd.attribute11, wdd.tracking_number),
NVL (wdd.attribute11, wdd.tracking_number))
"ASN_VALUES/REF[1]:REF02",
NVL (wnd.attribute2, wnd.ship_method_code) "ASN_VALUES/TD5[1]:TD503"
from apps.wwt_wwt_oe_order_headers_all_v oha,apps.oe_order_lines_all ola,apps.wsh_delivery_details wdd, 
apps.wsh_delivery_assignments wda,apps.wsh_new_deliveries wnd
where 1=1
and oha.order_number = %Order[0]/SALES_ORDER_NUM%
and oha.header_id = ola.header_id
and wdd.source_line_id = ola.line_id
and wdd.delivery_detail_id = wda.delivery_detail_id
and wda.delivery_id = wnd.delivery_id
  
  key_bank_outbound_procs;
  
select distinct header_id from apps.wwt_oe_order_headers_all_v
where 1=1
and order_number IN (6073053,6067119)
;