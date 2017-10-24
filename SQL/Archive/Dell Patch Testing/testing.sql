select * from apps.wwt_lookups
where 1=1
and lookup_type = 'WWT_FLAT_FILE_CLEANSING'
and attribute1 LIKE '%DGH%'
--and attribute10 LIKE '%compal%'

select * from WWT_DGH_PULLREQ_STG
where 1=1
order by creation_date desc

select * from wwt_dgh_line
order by creation_date desc

select * from wwt_frolic_status_log
order by creation_date desc

select * from wwt_upload_generic_log
where 1=1
and batch_id = 680332
--order by creation_Date desc

select  * from WWT_DGH_COMMIT_OUTBOUND
where 1=1
--and commit_id IN (400272,400359)
--and commit_id IN (396131)
--and mrp_site = 'WISCHE'
--and partner_id = 'COMPAL' 
order by creation_Date desc

select * from wwt_dgh_commit_outbound
where 1=1
--and partner_id = 'SIRTRON'
--and batch_id = 20121024082835912
and process_status = 'UNPROCESSED'
--and batch_id NOT IN (20141030075203477,20141030061702328,20121121071704714)

update wwt_dgh_commit_outbound
set process_status = 'UNPROCESSED'
where 1=1
and commit_id IN (400272,400359)

wwt_dgh_outbound_852_onhand

select * from apps.wwt_dgh_sites_v

select ''''||batch_id "ASNNumber",
         ''''||batch_id "WWTPullingNo",
         ''''||commit_id "WWTPullingSequence",
         ''''||cust_pull_request "ODMPullingNo",
         ''''||cust_pull_request_line "ODMPullingSequence",
         ''''||deliver_to_code "DeliveryLocation",
         ''''||hub_short_name "WhsNo",
         ''''||dell_part_number "PartNo",
         ''''||odm_part_number "ODMPartNo",
         ''''||commit_qty "POQuantity",
         ''''||commit_qty "ShippingQuantity",
         ''''||to_char(sysdate, 'MM-MON-YYYY HH:MM') "ShippingDateTime",
         ''''||odm_po_number "ODMPONo",
         ''''||odm_po_line "ODMPOLine",
         ''''||unit_selling_price "UnitSellingPrice"
         from apps.wwt_dgh_commit_outbound
         where line_id in (select line_id from apps.wwt_dgh_line where header_id in (32293))
         and partner_id = 'SIRTRON'
         and ROWNUM = 1
         
         select * from apps.wwt_dgh_commit_outbound
         
         select * from apps.wwt_dgh_asn_line where creation_date like sysdate
         
          select * from apps.WWT_ORIG_ORDER_HEADERS_v where customer_po_number = 'HAPPYPATHCB3F'
          
          customer_po_number = '20121024112758786-20121024A1'
          
select * from WWT_DGH_ASN_LINE
order by creation_date desc 

select * from wwt_orig_order_headers
where 1=1
and creation_date > sysdate - 1
order by creation_date desc

SELECT wlav.attribute4 starting_constant,
         wlav.attribute5 location_id,
         wlav.attribute6 vid,
         wlav.attribute7 vloc,
         PART,
         SUM (AVAILABLE_QTY) AVAILABLE_QTY,                        --added sum
         SUM (oh_qty) oh_qty,                                      --added sum
         SUM (dmd_qty) dmd_qty,                                    --added sum
         organization_id,
         qa_assurance_qty,
         on_hold_qty,
         currentDateTime
    FROM (select distinct wlav.attribute4,
                wlav.attribute5,
                wlav.attribute6,
                wlav.attribute7
         from apps.wwt_lookups_active_v wlav 
         where lookup_type = 'WWT_DSH_ONHAND_CONSTANTS'
         AND wlav.attribute2 = 'BRAZIL') wlav,
         (SELECT final_iv.part,
                 GREATEST ( (NVL (final_iv.oh_qty, 0) - NVL (dmd.dmd_qty, 0)),
                           0)
                    available_qty,
                 NVL (final_iv.oh_qty, 0) oh_qty,
                 NVL (dmd.dmd_qty, 0) dmd_qty,
                 final_iv.organization_id,
                 0 qa_assurance_qty,
                 0 on_hold_qty,
                 TO_CHAR (SYSDATE, 'DD-MON-YYYY HH24:MI:SS') currentDateTime
            FROM (  SELECT inventory_item_id,
                           part,
                           SUM (oh_qty) oh_qty,
                           organization_id
                      FROM (SELECT details_iv.inventory_item_id,
                                   details_iv.part,
                                   details_iv.oh_qty,
                                   details_iv.organization_id
                              FROM (  SELECT NVL (wdps.part, msib.segment2) part,
                                             oh.inventory_item_id inventory_item_id,
                                             oh.organization_id,
                                             SUM (oh.transaction_quantity) oh_qty
                                        FROM apps.mtl_onhand_quantities oh,
                                             apps.mtl_secondary_inventories s,
                                             apps.wwt_lookups_active_v wl,
                                             apps.wwt_dell_part_substring wdps,
                                             apps.mtl_system_items_b msib
                                       WHERE     oh.subinventory_code =
                                                    s.secondary_inventory_name
                                             AND oh.organization_id =
                                                    s.organization_id
                                             AND oh.inventory_item_id =
                                                    wdps.inventory_item_id(+)
                                             AND s.secondary_inventory_name =
                                                    wl.attribute1
                                             AND s.organization_id =
                                                    TO_NUMBER (wl.attribute8)
                                             AND wl.lookup_type =
                                                    'WWT_DSH_ONHAND_CONSTANTS'
                                             AND wl.attribute2 = 'BRAZIL'
                                             AND NVL (wl.attribute3, 'N') = 'Y'
                                             AND oh.inventory_item_id =
                                                    msib.inventory_item_id
                                             AND oh.organization_id =
                                                    msib.organization_id
                                    GROUP BY oh.inventory_item_id,
                                             NVL (wdps.part, msib.segment2),
                                             oh.organization_id) details_iv,
                                   (  SELECT sm.inventory_item_id
                                        FROM (SELECT wuscwm.part,
                                                     wuscwm.inventory_item_id,
                                                     curr_wk_qty,
                                                     wk1_qty,
                                                     wk2_qty,
                                                     wk3_qty,
                                                     wk4_qty
                                                FROM apps.wwt_usage_summr_cal_week_mv wuscwm,
                                                     apps.wwt_lookups_active_v wl
                                               WHERE     wuscwm.organization_id =
                                                            wl.attribute8
                                                     AND wl.attribute2 ='BRAZIL'
                                                     AND wl.lookup_type =
                                                            'WWT_DSH_ONHAND_CONSTANTS') sm
                                      HAVING (  SUM (sm.curr_wk_qty)
                                              + SUM (sm.wk1_qty)
                                              + SUM (sm.wk2_qty)
                                              + SUM (sm.wk3_qty)
                                              + SUM (sm.wk4_qty)) > 0
                                    GROUP BY sm.inventory_item_id) mv_iv
                             WHERE details_iv.inventory_item_id =
                                      mv_iv.inventory_item_id(+)
                            UNION ALL
                            SELECT mv_iv.inventory_item_id,
                                   mv_iv.part,
                                   0 oh_qty,
                                   TO_NUMBER (wl2.attribute8) organization_id
                              FROM (  SELECT NVL(wdps.part,sm.part) part, sm.inventory_item_id
                                        FROM (SELECT wuscwm.part,
                                                     wuscwm.inventory_item_id,
                                                     curr_wk_qty,
                                                     wk1_qty,
                                                     wk2_qty,
                                                     wk3_qty,
                                                     wk4_qty
                                                FROM apps.wwt_usage_summr_cal_week_mv wuscwm,
                                                     apps.wwt_lookups_active_v wl,
                                                     apps.wwt_lookups_active_v wl2
                                               WHERE     1 = 1
                                                     AND wuscwm.salesrep_id =
                                                            wl2.attribute2
                                                     AND wuscwm.organization_id =
                                                            wl.attribute8
                                                     AND wl.lookup_type =
                                                            'WWT_DSH_ONHAND_CONSTANTS'
                                                     AND wl2.lookup_type =
                                                            'WWT_DSH_BRAZIL_SALESREPS'
                                                     AND wl.attribute2 = 'BRAZIL'
                                                     AND wl2.attribute3 =
                                                            'BRAZIL') sm,
                                             apps.wwt_dell_part_substring wdps
                                       WHERE     1 = 1
                                             AND sm.inventory_item_id =
                                                    wdps.inventory_item_id(+)
                                      HAVING (  SUM (sm.curr_wk_qty)
                                              + SUM (sm.wk1_qty)
                                              + SUM (sm.wk2_qty)
                                              + SUM (sm.wk3_qty)
                                              + SUM (sm.wk4_qty)) > 0
                                    GROUP BY sm.inventory_item_id, NVL(wdps.part,sm.part)) mv_iv,
                                   apps.wwt_lookups_active_v wl2
                             WHERE     wl2.lookup_type =
                                          'WWT_DSH_ONHAND_CONSTANTS'
                                   AND wl2.attribute2 = 'BRAZIL')
                  GROUP BY inventory_item_id, part, organization_id) final_iv,
                 (  SELECT m.inventory_item_id inv_item,
                           m.organization_id org_id,
                           SUM (m.line_item_quantity) dmd_qty
                      FROM apps.wwt_mtl_demand_v m,
                           apps.oe_order_lines_all oola,
                           apps.wwt_lookups_active_v wl
                     WHERE     m.completed_quantity = 0
                           AND (m.primary_uom_quantity - m.completed_quantity) >
                                  0
                           AND m.organization_id = TO_NUMBER (wl.attribute8)
                           AND oola.line_id = m.demand_source_line
                           AND oola.subinventory = wl.attribute1
                           AND wl.lookup_type = 'WWT_DSH_ONHAND_CONSTANTS'
                           AND wl.attribute2 = 'BRAZIL'
                           AND NVL (wl.attribute3, 'N') = 'Y'
                  GROUP BY m.inventory_item_id, m.organization_id) dmd,
                 (SELECT distinct attribute9 CCC6
                    FROM apps.wwt_lookups_active_v wl
                   WHERE     wl.lookup_type = 'WWT_DSH_ONHAND_CONSTANTS'
                         AND wl.attribute2 = 'BRAZIL' --added region condition
                                                       ) feed_from
           WHERE     final_iv.inventory_item_id = dmd.inv_item(+)
                 AND final_iv.organization_id = dmd.org_id(+)
                 AND feed_from.CCC6 = 'N')
   WHERE  1=1
GROUP BY wlav.attribute4,
         wlav.attribute5,
         wlav.attribute6,
         wlav.attribute7,
         PART,
         organization_id,
         qa_assurance_qty,
         on_hold_qty,
         currentDateTime
         
SELECT to_recipients, cc_recipients, bcc_recipients
FROM applsys.alr_distribution_lists
WHERE NAME = 'DSH_ALPHA_PLANNING_DISTR'

select * from applsys.alr_distribution_lists
where 1=1
and name =  'DSH_ALPHA_PLANNING_DISTR'

update applsys.alr_distribution_lists
set to_recipients = 'chris.connell@wwt.com'
where 1=1
and name =  'DSH_ALPHA_PLANNING_DISTR'

select * from WWT_INV_LINE
where 1=1
and creation_Date > sysdate - 1
order by creation_Date desc