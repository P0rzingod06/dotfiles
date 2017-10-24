CREATE OR REPLACE PACKAGE BODY APPS.WWT_DGH_ECO_ALLOC_PROCESSOR

-- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_dgh_eco_alloc_processor.plb,v $, $Revision: 1.21 $, $Author: lawtons $, $Date: 2014/02/05 16:38:07 $

AS

   /*

   *******************************************************************************************

   *Package Name        :  WWT_DGH_ECO_ALLOC_PROCESSOR

   *Description         :  Used to process the ECO and Allocations for a specific hub

   *******************************************************************************************

   * Developer    Date               Vers   CHG       Description

   **********************************************************************************************

   * ericksot       24-MAY-2012  1.1      CHG22194 Creation

   * ericksot       07-JUNE-2012  1.2     CHG22194 Changing ASN queries to make them more efficent.

   * ericksot       19-JUNE-2012  1.3     CHG22629  Making a change to the price list query to make it 

                                                                       base itself by default on the request_date. Also 

                                                                       changing the error

    * ericksot       02-JULY-2012  1.4     CHG22629 Adding in PROMISE_DATE_OFFSET

    * ericksot        11-JULY-2012 1.6     CHG22629 Excluding Short Review from an updated promise date and also adding in Planner Code                                                              

   * ericksot        11-JULY-2012 1.7     CHG22629  Modifying so short review can't have a plan exception of Warning  

   * desantim	     18-JULY-2012 1.8	  CHG22754	Removed Commit Outbound Errors along with the other line errors and added new log procedure that will be modified shortly

   * ericksot      02-Aug-2012 1.9       CHG22943  Adding extra logging for eco paramters and also removing split for dispute communication since zero commit logic will now handle this.

   * ericksot      23-Aug-2012 1.10      CHG23115  Adding in Functionality for ECO Audit and also excluding partial  ASN's from ASN Timeout logic

   * ericksot      09-Oct-2012 1.12      ?  	   Adding in changes for GCFI

   * ericksot       29-Jan-2013 1.13     CHG24788        Added in change to fix a bug where the line are not getting updated properly.

   * ericksot       12-Mar-2013 1.15     ?        Fix to make for the line update change.

   * ericksot       19-Mar-2013 1.18   CHG25323 Fixing the fix line so its bullet proof.

   *ericksot        07-May-2013 1.20   CHG25971 Update line_fix to base the inventory_item_id off of the dell_part_number and the mtl_system_items_b table so that we always get the correct inventory_item_id

   *lawtons         05-FEB-2014 1.21    CHG29233    Add filter for zone and site id with MRP site
   
   *dupontb         25-NOV-2014 1.22    CHG33460 Re-wrote the line_fix procedure to locate any STG record in error and mark them as DNP (do not process) and missing line data. Then update ORIG/GHUB line data
                                                                                 and then update ORIG header to UNPROCESS for reprocess.  
   **********************************************************************************************

   */

   

   -- Global Variables

   g_user_id           APPS.WWT_DGH_HUB.CREATED_BY%TYPE := -1;

   g_ldap_user         APPS.WWT_DGH_HUB.LDAP_CREATED_BY%TYPE :='SYSTEM';

   

   TYPE AVAILABLE_INV_TABTYPE  IS TABLE OF NUMBER INDEX BY VARCHAR2(4000);

   

   TYPE LINE_ALLOC_TYPE IS RECORD(LINE_ID APPS.WWT_DGH_LINE.line_id%TYPE, CUST_PART_NUMBER APPS.WWT_DGH_LINE.cust_part_number%TYPE, 

   ORDER_QTY APPS.WWT_DGH_LINE.order_qty%TYPE, REQUESTED_DATE APPS.WWT_DGH_LINE.requested_date%TYPE, MRP_SITE_ID APPS.WWT_DGH_HEADER.mrp_site_id%TYPE, 

   MRP_SITE APPS.WWT_DGH_HEADER.mrp_site%TYPE, HUB_ID APPS.WWT_DGH_HUB.hub_id%TYPE,ITEM_CROSS_REF_NAME VARCHAR2(4000), 

   STATUS_NAME APPS.WWT_DGH_STATUS.Status_Name%TYPE, DELIVER_TO_CODE APPS.WWT_DGH_LINE.DELIVER_TO_CODE%TYPE,

   PART_REV_RESTRICT_FLAG APPS.WWT_DGH_SITES_V.PART_REV_RESTRICT_FLAG%TYPE, PARENT_LINE_ID APPS.WWT_DGH_LINE.parent_line_id%TYPE);

   

   TYPE LINE_ALLOC_TABTYPE IS TABLE OF LINE_ALLOC_TYPE;

   

   /*

   *****************************************************************************************

   Procedure name: LOG

   Description: Write to the application log table and the fnd_file for concurrent request logging

   *****************************************************************************************

   */

   PROCEDURE LOG( P_MESSAGE IN VARCHAR2 ) IS

   BEGIN

       fnd_file.put_line (fnd_file.LOG, P_MESSAGE);

   END LOG;



   /*

   *****************************************************************************************

   Function name: GET_PLANNER

   Description: return the planner given the inventory_item_id, organization_id, mrp_site_id, and zone_type

   *****************************************************************************************

   */

   FUNCTION GET_PLANNER(P_INVENTORY_ITEM_ID NUMBER, P_ORGANIZATION_ID NUMBER, P_MRP_SITE_ID NUMBER, P_ZONE_TYPE VARCHAR2)

   RETURN VARCHAR2 IS

   l_planner   APPS.WWT_DGH_LINE.PLANNER_CODE%TYPE;



BEGIN

   BEGIN

      IF P_ZONE_TYPE  = 'BE'

      THEN

          SELECT nvl(msi1.planner_code, msi2.planner_code)

          INTO l_planner       

          FROM inv.mtl_system_items_b msi1, 

          inv.mtl_system_items_b msi2

          WHERE msi1.inventory_item_id = P_INVENTORY_ITEM_ID

          AND msi1.organization_id = P_ORGANIZATION_ID

          AND msi2.inventory_item_id = msi1.inventory_item_id

          AND msi2.organization_id = 101;

       ELSE

          SELECT wlav.attribute2

             INTO l_planner

             FROM apps.wwt_dsh_gcfi_customer_item wdgci,

                  apps.wwt_dsh_gcfi_item_region_xref wdgirx,

                  apps.wwt_dsh_gcfi_rva_odm_item_xref wdgroix,

                  apps.wwt_lookups_active_v wlav

            WHERE wdgci.erp_inventory_item_id = P_INVENTORY_ITEM_ID

              AND wdgci.customer_item_id = wdgirx.customer_item_id

              AND wdgirx.region_part_xref_id = wdgroix.region_part_xref_id

              AND wdgroix.mrp_site_id = P_MRP_SITE_ID

              AND TO_CHAR(wdgroix.dsh_planner_id) = wlav.attribute1

              AND wlav.lookup_type = 'GCFI_PLANNER_CODE'

              AND rownum = 1;

       END IF;

   EXCEPTION

   WHEN OTHERS THEN

      l_planner := '';

   END;

   RETURN l_planner;

END; 



   /*

   *****************************************************************************************

   Procedure name: ALLOCATION_LOCK

   Description:  Used to lock a hub during the allocation process

   *****************************************************************************************

   */

   PROCEDURE ALLOCATION_LOCK(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE, P_ACTION IN VARCHAR2) 

   IS

   PRAGMA AUTONOMOUS_TRANSACTION;

   L_ALLOCATION_RUNNING_FLAG VARCHAR2(1) := 'N';

   

   BEGIN

   IF P_ACTION = 'LOCK'

   THEN

    log( 'LOCKING HUB: ' || P_HUB_ID);   

     L_ALLOCATION_RUNNING_FLAG := 'Y';

   ELSE

    log('UNLOCKING HUB: ' || P_HUB_ID);    

    L_ALLOCATION_RUNNING_FLAG := 'N';

   END IF;

   

   UPDATE APPS.WWT_DGH_HUB SET ALLOCATION_RUNNING_FLAG = L_ALLOCATION_RUNNING_FLAG, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE WHERE HUB_ID = P_HUB_ID;

   COMMIT;

   

   END ALLOCATION_LOCK;

   

   

   /*

   ****************************************************************************************

   Procedure Name: Line_Fix

   Description: This fixes an issue that sometimes happens with a database locking issue where lines don't get updated properly

   ****************************************************************************************

   */

   PROCEDURE LINE_FIX(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE)

   IS
      
   CURSOR dgh_stg_header_cur IS
      SELECT distinct(wsoh.header_id) stg_header_id,
             wooh.header_id orig_header_id,
             wsoh.creation_date,
             SYSDATE last_update_date,
             fnd_global.user_id last_updated_by
      FROM apps.wwt_om_process_groups wopg,
             apps.wwt_stg_order_headers_v wsoh,
             apps.wwt_stg_order_lines wsol,
             apps.wwt_orig_order_headers_v wooh,
             apps.wwt_orig_order_lines wool
       WHERE     1 = 1
             AND wsoh.status = 'ERROR'
             AND wopg.name IN APPS.wwt_util_constants.get_value ('OTOS_PG_NAMES', 'DSH_CONSTANTS', 'DGH_GHUB_ORDER_RESET') 
             AND wsoh.process_group_id = wopg.process_group_id
             AND wsol.header_id = wsoh.header_id
             AND wsol.orig_line_id = wool.line_id
             AND wooh.header_id = wsoh.orig_header_id
             AND wool.header_id = wooh.header_id
             AND wool.inventory_item_id IS NULL;


      CURSOR dgh_stg_line_cur (cp_stg_header_id IN NUMBER) IS
        SELECT /*+ ordered */
                         wsoh.org_id,
                         wool.line_id orig_line_id,
                         msib.inventory_item_id,
                         msib.segment1,
                         msib.segment2,
                         msib.segment3,
                         msib.segment4,
                         msib.description,
                         qlht.name,
                         wdhz.organization_id,
                         wdhz.zone_type,
                         wdhz.hub_id,
                         wdl.line_id ghub_line_id,
                         wlav_ghub_locs.lookup_id deliver_to_code_id,
                         hoi.org_information3 operating_unit,
                         qll.list_line_id price_list_line_id,
                         wdal.dell_part_number,
                         wdco.commit_qty,
                         wds.status_id,
                         wdal.ship_qty,
                         wdhz.hub_zone_id
                  FROM apps.wwt_stg_order_headers wsoh,
                       apps.wwt_orig_order_headers wooh,
                       apps.wwt_orig_order_lines wool,
                       apps.wwt_dgh_asn_line wdal,
                       apps.wwt_dgh_line wdl,
                       apps.wwt_dgh_header wdh,
                       apps.wwt_lookups_active_v wlav_ghub_locs,
                       apps.wwt_lookups_active_v wlav_mrp_sites,
                       apps.mtl_cross_references mcr,
                       apps.mtl_system_items_b msib,
                       apps.wwt_lookups_active_v wlav_partner,
                       apps.wwt_dgh_commit_outbound wdco,
                       apps.wwt_dgh_hub_zone wdhz,
                       apps.wwt_dgh_hub_zone_mrp_site wdhzms,
                       apps.qp_pricing_attributes qpa,
                       apps.qp_list_lines qll,
                       apps.qp_list_headers_tl qlht,
                       apps.wwt_dgh_status wds,
                       apps.hr_organization_information hoi
                 WHERE     1 = 1
                       AND wsoh.header_id = cp_stg_header_id
                       AND wooh.header_id = wsoh.orig_header_id
                       AND wool.header_id = wsoh.orig_header_id
                       AND wdal.line_id = apps.wwt_util_datatypes_pkg.wwt_to_number (wool.wwt_attribute1)
                       AND wdal.asn_number = wsoh.attribute5
                       AND wdal.process_status = 'PROCESSED'  --ignore failed ASN's
                       AND wdl.line_id = wdal.line_id
                       AND wdh.header_id = wdl.header_id
                       AND wlav_ghub_locs.lookup_type = 'WWT_DSH_GH_SITE_MAP'
                       AND wlav_mrp_sites.lookup_type = 'GCFI_MRP_SITE_MASTER'
                       AND wlav_ghub_locs.attribute1 = wlav_mrp_sites.attribute2
                       AND wlav_mrp_sites.attribute1
                              || '_'
                              || wlav_ghub_locs.attribute3
                              || '_'
                              || wlav_ghub_locs.attribute4
                              || DECODE (wlav_ghub_locs.attribute5,
                                         NULL, NULL,
                                         '_' || wlav_ghub_locs.attribute5) = wdal.deliver_to_code
                       AND wlav_mrp_sites.attribute2 = TO_CHAR (wdh.mrp_site_id)
                       AND wlav_mrp_sites.attribute1 = wdh.mrp_site
                       AND mcr.cross_reference_type = wlav_mrp_sites.attribute13 --odm cross reference type
                       AND mcr.cross_reference = wdal.odm_part_number
                       AND msib.inventory_item_id = mcr.inventory_item_id
                       AND msib.organization_id = 101
                       AND msib.segment1 = '11921'
                       AND msib.segment2 = wdal.dell_part_number||''
                       AND msib.segment3 = 'ACTUAL'
                       AND msib.segment4 = 'N/A'
                       AND wdco.commit_id = wdal.wwt_pulling_sequence
                       AND wlav_partner.lookup_type = 'WWT_DGH_WAREHOUSE_PARTNERS'
                       AND wlav_partner.attribute1 = TO_CHAR (wdh.hub_id)
                       AND wdco.partner_id = wlav_partner.attribute2
                       AND wdhz.hub_id = wdh.hub_id
                       AND wdhz.zone_type =                             --to get hub_zone_type
                              (CASE
                                  WHEN (SELECT customer_item_id
                                          FROM apps.wwt_dsh_gcfi_customer_item
                                         WHERE     erp_inventory_item_id =
                                                      msib.inventory_item_id
                                               AND ROWNUM = 1)
                                          IS NOT NULL
                                  THEN
                                     'CFI'
                                  WHEN (SELECT wdps.inventory_item_id
                                          FROM apps.wwt_dell_part_substring wdps
                                         WHERE     wdps.inventory_item_id =
                                                      msib.inventory_item_id
                                               AND ROWNUM = 1)
                                          IS NOT NULL
                                  THEN
                                     'BE'
                                  ELSE
                                     '***Unknown***'
                               END)
                       AND wdhz.subinventory = wdco.subinventory --to confirm correct hub_zone_id
                       AND wdhzms.mrp_site_id = wdh.mrp_site_id
                       AND wdhzms.hub_zone_id = wdhz.hub_zone_id
                       AND qpa.product_attribute_context = 'ITEM'
                       AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
                       AND qpa.product_attr_value = TO_CHAR (msib.inventory_item_id)
                       AND qpa.list_header_id = wdhzms.price_list_header_id --to return correct price list line
                       AND qll.list_line_id = qpa.list_line_id
                       AND qlht.list_header_id = qpa.list_header_id
                       AND qlht.language = 'US'
                       AND TRUNC (
                              apps.wwt_dgh_utilities.to_mrp_tz (wdh.mrp_site,
                                                                wdl.requested_date)) BETWEEN TRUNC (
                                                                                                NVL (
                                                                                                   qll.start_date_active,
                                                                                                   apps.wwt_dgh_utilities.to_mrp_tz (
                                                                                                      wdh.mrp_site,
                                                                                                      wdl.requested_date)))
                                                                                         AND TRUNC (
                                                                                                NVL (
                                                                                                   qll.end_date_active,
                                                                                                   apps.wwt_dgh_utilities.to_mrp_tz (
                                                                                                      wdh.mrp_site,
                                                                                                      wdl.requested_date)))
                       AND wds.status_name = 'Closed'
                       AND wds.status_type = 'LINE'
                       AND wds.hub_id = wdh.hub_id
                       AND hoi.organization_id = wdhz.organization_id
                       AND hoi.org_information_context = 'Accounting Information';
       
   BEGIN
  
           FOR dgh_stg_header_rec in dgh_stg_header_cur               --Begin header cursor loop
           LOOP
                       
            log('Updating ORIG Header ID: '||dgh_stg_header_rec.orig_header_id);
            log('Updating STG Header ID: '||dgh_stg_header_rec.stg_header_id);
            
            -- set each FAILED OCU COP Stage header record
             update partner_admin.wwt_stg_order_headers wsoh
                set status                   = 'DNP',
                    status_message           = substr('Null GHUB item_id issue - setting to cancelled'||status_message,1,4000),
                    last_update_date         = sysdate,
                    last_updated_by          = dgh_stg_header_rec.last_updated_by  
              where wsoh.header_id = dgh_stg_header_rec.stg_header_id;
            
            
            
            -- set each FAILED OCU COP Orig header record to UNPROCESSED
             UPDATE partner_admin.wwt_orig_order_headers wooh
                SET status                   = 'UNPROCESSED', 
                    status_message           = NULL,
                    last_update_date         = SYSDATE,
                    last_updated_by          = dgh_stg_header_rec.last_updated_by,  
                    batch_id                 = NULL
              WHERE wooh.header_id = dgh_stg_header_rec.orig_header_id;         
            
            
              FOR dgh_stg_line_rec in dgh_stg_line_cur (dgh_stg_header_rec.stg_header_id) --Begin line cursor loop
               LOOP
                 -- set all the NULL COP Orig line columns to valid values
                 UPDATE partner_admin.wwt_orig_order_lines
                    SET inventory_item_id        = dgh_stg_line_rec.inventory_item_id, --msib.inventory_item_id,
                        inventory_item_segment_1 = dgh_stg_line_rec.segment1,          --msib.segment1,
                        inventory_item_segment_2 = dgh_stg_line_rec.segment2,          --msib.segment2,
                        inventory_item_segment_3 = dgh_stg_line_rec.segment3,          --msib.segment3,
                        inventory_item_segment_4 = dgh_stg_line_rec.segment4,          --msib.segment4,
                        user_item_description    = dgh_stg_line_rec.description,       --msib.description,
                        price_list               = dgh_stg_line_rec.name,              --qlh.name,
                        ship_from_org_id         = dgh_stg_line_rec.organization_id,   --wdhz.organization_id,
                        wwt_attribute2           = dgh_stg_line_rec.zone_type,         --wdhz.zone_type,
--                        wwt_attribute3           = dgh_stg_line_rec.hub_id,            --wdhz.hub_id,
                        wwt_attribute3           = dgh_stg_line_rec.hub_zone_id,            --wdhz.hub_id,
                        last_update_date         = SYSDATE,
                        last_updated_by          = dgh_stg_header_rec.last_updated_by    
                  WHERE line_id = dgh_stg_line_rec.orig_line_id; 
                
                
                -- set all the NULL GHUB line columns to valid values
                 UPDATE partner_admin.wwt_dgh_line wdl
                    SET deliver_to_code_id       = dgh_stg_line_rec.deliver_to_code_id, --wdsv.deliver_to_code_id,
                        inventory_item_id        = dgh_stg_line_rec.inventory_item_id,  --msib.inventory_item_id,
                        organization_id          = dgh_stg_line_rec.organization_id,    --wdhz.organization_id,
                        operating_unit_id        = dgh_stg_line_rec.org_id,             --wsoh.org_id,
                        price_list_line_id       = dgh_stg_line_rec.price_list_line_id, --qll.list_line_id,
                        wwt_part_number          = dgh_stg_line_rec.dell_part_number,   --wdal.dell_part_number,
                        allocated_qty            = dgh_stg_line_rec.commit_qty,         --wdco.commit_qty,
                        status_id                = dgh_stg_line_rec.status_id,          --wds.status_id,
                        asn_qty                  = dgh_stg_line_rec.ship_qty,           --wdal.ship_qty,
                        hub_zone_id              = dgh_stg_line_rec.hub_zone_id,        --wdhz.hub_zone_id,
                        last_update_date         = SYSDATE,
                        last_updated_by          = dgh_stg_header_rec.last_updated_by     
                  WHERE wdl.line_id = dgh_stg_line_rec.ghub_line_id;
                  
                  --record event in milestone table
                  INSERT INTO apps.wwt_dgh_milestone_audit 
                  (
                       milestone_audit_id,
                       line_id,
                       milestone,
                       milestone_date,
                       created_by,
                       creation_date,
                       last_updated_by,
                       last_update_date,
                       ldap_created_by
                   )
                   VALUES 
                   (
                       apps.wwt_dgh_milestone_audit_s.NEXTVAL,
                       dgh_stg_line_rec.ghub_line_id,
                       'GHUB Null Item Error',
                       SYSDATE,
                       dgh_stg_header_rec.last_updated_by,
                       SYSDATE,
                       dgh_stg_header_rec.last_updated_by,
                       SYSDATE,
                       dgh_stg_header_rec.last_updated_by
                    );
                  
              END LOOP; --End line cursor loop             

           END LOOP;  --End header cursor loop

   EXCEPTION

   WHEN OTHERS THEN

      log('Error running line fix for hub ' || P_HUB_ID || ' error message: ' || SQLERRM);

   END LINE_FIX;   

   

        /*

   *****************************************************************************************

   Procedure name: PROCESS_ASN_UPDATES

   Description:  This is used to Process any material transactions associated with asn updates and update the line status a 

   *****************************************************************************************

   */

   PROCEDURE PROCESS_ASN_UPDATES(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE)

   IS

   

   BEGIN

 

    log('adding ASN QTY for: ' || P_HUB_ID);   

    UPDATE apps.wwt_dgh_line l SET ASN_QTY = 

    NVL((SELECT SUM (-1 * mmt.transaction_quantity) quantity_shipped

    FROM apps.oe_order_lines_all oola,

         apps.mtl_material_transactions mmt,

         apps.wwt_dgh_line wdl

    WHERE     1 = 1

         AND mmt.transaction_action_id IN (1, 27)

         AND mmt.transaction_type_id IN (15, 33)

         AND oola.line_id = mmt.trx_source_line_id

         AND oola.orig_sys_line_ref = TO_CHAR (wdl.line_id)

         AND mmt.organization_id = wdl.organization_id

         AND wdl.line_id = l.LINE_ID 

         GROUP BY wdl.line_id), 0)

         ,LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

    WHERE

    l.STATUS_ID in (SELECT wds.STATUS_ID

                FROM apps.wwt_dgh_status wds

                WHERE

                wds.auto_close_check_flag = 'Y'

                AND wds.hub_id = P_HUB_ID);



     log('writing milestone system closed for : ' || P_HUB_ID);   

     INSERT INTO APPS.WWT_DGH_MILESTONE_AUDIT

     (

        MILESTONE_AUDIT_ID

        ,LINE_ID

         ,MILESTONE

         ,MILESTONE_DATE

         ,CREATED_BY

         ,CREATION_DATE

         ,LAST_UPDATED_BY

         ,LAST_UPDATE_DATE

         ,LDAP_CREATED_BY

         ,LDAP_LAST_UPDATED_BY

    )

    (SELECT APPS.WWT_DGH_MILESTONE_AUDIT_S.nextval,

    l.LINE_ID,

    'System Close Date',

    SYSDATE,

    g_user_id,

    SYSDATE,

    g_user_id,

    SYSDATE,

    g_ldap_user,

    g_ldap_user

    FROM apps.wwt_dgh_line l 

    WHERE 

    l.STATUS_ID in (SELECT wds.STATUS_ID

                FROM apps.wwt_dgh_status wds

                WHERE

                wds.auto_close_check_flag = 'Y'

                AND wds.hub_id = P_HUB_ID)

    AND l.ASN_QTY >=  l.ALLOCATED_QTY);

    

     log('Updating Partial ASN and Closed for : ' || P_HUB_ID);                       

    UPDATE apps.wwt_dgh_line l set status_id = CASE 

    WHEN ASN_QTY >=  ALLOCATED_QTY

    THEN (SELECT STATUS_ID FROM APPS.WWT_DGH_STATUS where STATUS_TYPE = 'LINE' AND STATUS_NAME = 'Closed' and hub_id = P_HUB_ID)

    ELSE (SELECT STATUS_ID FROM APPS.WWT_DGH_STATUS where STATUS_TYPE = 'LINE' AND STATUS_NAME = 'Partial ASN' and hub_id = P_HUB_ID)

    END

    ,LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

    WHERE  l.STATUS_ID in (SELECT wds.STATUS_ID

                FROM apps.wwt_dgh_status wds

                WHERE

                wds.auto_close_check_flag = 'Y'

                AND wds.hub_id = P_HUB_ID)

                AND (ASN_QTY > 0  OR l.ORDER_QTY = 0);



     log('Set the ASN Timeouts for : ' || P_HUB_ID);                       

    UPDATE apps.wwt_dgh_line l set status_id = (SELECT STATUS_ID FROM APPS.WWT_DGH_STATUS where STATUS_TYPE = 'LINE' AND STATUS_NAME = 'ASN Timeout' and hub_id = P_HUB_ID)

    ,LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

    WHERE  l.STATUS_ID in (SELECT wds.STATUS_ID

                FROM apps.wwt_dgh_status wds

                WHERE

                wds.auto_close_check_flag = 'Y'

                AND STATUS_NAME not in ('Partial ASN', 'ASN Timeout' )

                AND wds.hub_id = P_HUB_ID)

                AND (SELECT  (SYSDATE - MAX(co.creation_date)) * 24 * 60

                        FROM WWT_DGH_SITES_V ds,

                        WWT_DGH_COMMIT_OUTBOUND co

                        WHERE ds.MRP_SITE = co.MRP_SITE

                        AND ds.logistics_partner = co.PARTNER_ID

                        AND co.line_id = l.line_id) 

                        >= 

                        (SELECT ASN_TIMEOUT

                        FROM APPS.WWT_DGH_HUB

                        WHERE HUB_ID = P_HUB_ID);

                        

     log('LINE FIX for : ' || P_HUB_ID);  

    --Fix lines with bad 

    LINE_FIX(P_HUB_ID);

    log('LINE FIX Ended');  



   END PROCESS_ASN_UPDATES;   

   

   

     /*

   *****************************************************************************************

   Procedure name: CLEANUP_VALIDATE_LINES

   Description:  Used to clean up the validate lines so that they have clean allocations

   *****************************************************************************************

   */

   PROCEDURE CLEANUP_VALIDATE_LINES(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE)

   IS

   

   BEGIN

  

   UPDATE APPS.WWT_DGH_LINE 

   SET ALLOCATED_QTY = 0, INVENTORY_ITEM_ID = NULL, ORGANIZATION_ID = NULL, 

   OPERATING_UNIT_ID = NULL, WWT_PART_NUMBER = NULL, PLAN_EXCEPTION = NULL, 

   PRICE_LIST_LINE_ID = NULL, DELIVER_TO_CODE_ID = NULL,  HUB_ZONE_ID = NULL,

   LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE 

   WHERE LINE_ID IN (

   SELECT l.LINE_ID

   FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s

   WHERE l.header_id = h.header_id and l.status_id = s.status_id and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID

   );

   

   UPDATE APPS.WWT_DGH_LINE 

   SET PROMISE_DATE = NULL,  

   LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE 

   WHERE LINE_ID IN (

   SELECT l.LINE_ID

   FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s

   WHERE l.header_id = h.header_id and l.status_id = s.status_id and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID and s.status_name != 'Short Review'

   );

   

   --Also Close out all old ERRORS and WARNING Generated in this application

   DELETE APPS.WWT_DGH_LINE_ERROR

    WHERE ERROR_CODE_ID IN

    (SELECT ec.ERROR_CODE_ID

    FROM APPS.WWT_DGH_ERROR_CODE ec

    WHERE ec.HUB_ID = P_HUB_ID

    AND ec.ERROR_CODE IN ('Missing Lead Time' ,'Missing Price List' ,'Address Failure' ,'No Inventory Item Found' ,'Cross Reference Missing'

    ,'General ECO Fatal Error' ,'Using Max Rev.' ,'ODM Part Mismatch' ,'Base Part Change', 'Commit Outbound Error'))

    AND LINE_ID IN 

    (

       SELECT l.LINE_ID

       FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s

       WHERE l.header_id = h.header_id and l.status_id = s.status_id and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID

     );

     

     --Delete All non-essential ECO Audit Records

     DELETE 

     FROM APPS.WWT_DGH_ECO_LINE_AUDIT ea

     WHERE 

        ea.LINE_ID IN 

        (

           SELECT l.LINE_ID

           FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s

           WHERE l.header_id = h.header_id and l.status_id = s.status_id and s.cleanup_audit_flag = 'Y' and h.hub_id = P_HUB_ID

         )

         AND REQUEST_START_TIME NOT IN 

         (

           SELECT MAX(ea2.REQUEST_START_TIME)

           FROM APPS.WWT_DGH_ECO_LINE_AUDIT ea2

           WHERE ea2.LINE_ID = ea.LINE_ID

         );

 

   END CLEANUP_VALIDATE_LINES;   

   

    /*

   *****************************************************************************************

   Procedure name: GET_HUB_AVAILABLE

   Description:  Gets the Available inventory for the hub

   *****************************************************************************************

   */

   PROCEDURE GET_HUB_AVAILABLE(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE,  X_AVAILABLE_TAB OUT AVAILABLE_INV_TABTYPE)

   IS

   

   CURSOR AVAIL_CUR

   IS

   SELECT

   HUB_ZONE_ID,

   INVENTORY_ITEM_ID,

   NVL(ON_HAND, 0) AS ONHAND,

   NVL(HUB_RESERVED, 0) AS HUBRESERVED

   FROM APPS.WWT_DGH_AVAILABLE_INVENTORY_V

   WHERE HUB_ID = P_HUB_ID;

   

   L_AVAIL_REC AVAIL_CUR%ROWTYPE;

     

   BEGIN

    OPEN AVAIL_CUR;

    LOOP

        FETCH AVAIL_CUR INTO L_AVAIL_REC;

        EXIT WHEN AVAIL_CUR%NOTFOUND;

         log('Item: ' || L_AVAIL_REC.INVENTORY_ITEM_ID || ' Has OnHand : ' || L_AVAIL_REC.ONHAND || ' and Has Hub Reserved : ' || L_AVAIL_REC.HUBRESERVED);         

        X_AVAILABLE_TAB(L_AVAIL_REC.HUB_ZONE_ID || '_' || L_AVAIL_REC.INVENTORY_ITEM_ID) :=(L_AVAIL_REC.ONHAND - L_AVAIL_REC.HUBRESERVED);      



    END LOOP;       

 

   END GET_HUB_AVAILABLE;   



    /*

   *****************************************************************************************

   Procedure name: GET_LINE_QUERY

   Description:  Builds the line query given the hubzones order by.

   *****************************************************************************************

   */   

    PROCEDURE GET_LINE_QUERY(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE, X_LINE_QUERY OUT VARCHAR2)

    IS

    L_ORDER_BY VARCHAR2(200);

    BEGIN

    SELECT ALLOCATION_ORDER_BY

    INTO L_ORDER_BY

    FROM APPS.WWT_DGH_HUB h

    WHERE h.hub_id = P_HUB_ID;

    

   X_LINE_QUERY := 'SELECT l.LINE_ID, l.CUST_PART_NUMBER, l.ORDER_QTY, l.REQUESTED_DATE, h.MRP_SITE_ID, h.MRP_SITE, h.HUB_ID,

   max(ds.ITEM_CROSS_REF_NAME) as ITEM_CROSS_REF_NAME, s.status_name, l.DELIVER_TO_CODE, max(ds.PART_REV_RESTRICT_FLAG) as PART_REV_RESTRICT_FLAG, l.PARENT_LINE_ID

   FROM APPS.WWT_DGH_LINE l, 

   APPS.WWT_DGH_HEADER h, 

   APPS.WWT_DGH_STATUS s,

   APPS.WWT_DGH_SITES_V ds

   WHERE l.header_id = h.header_id

   AND h.MRP_SITE_ID = ds.MRP_SITE_ID

   AND l.status_id = s.status_id 

   AND s.validate_flag = ''Y'' 

   AND h.hub_id = ' || P_HUB_ID || '

   GROUP BY l.LINE_ID, l.CUST_PART_NUMBER, l.ORDER_QTY, l.REQUESTED_DATE, h.MRP_SITE_ID, h.MRP_SITE, h.HUB_ID,

   s.status_name, l.DELIVER_TO_CODE, l.PARENT_LINE_ID, l.CREATION_DATE

   ORDER BY ' || L_ORDER_BY;

   

   log('Hub Line Query: ' || X_LINE_QUERY);

      

   END GET_LINE_QUERY;



    /*

   *****************************************************************************************

   Procedure name: GENERATE_ECO_WARNINGS

   Description:  Used to generate the eco warnings when we select an eco item

   *****************************************************************************************

   */   

    PROCEDURE GENERATE_ECO_WARNINGS(

      P_LINE IN LINE_ALLOC_TYPE,

      P_ERROR_CODES IN VARCHAR2,

      X_ERROR IN OUT  BOOLEAN, 

      X_DISPUTE IN OUT  BOOLEAN 

    )

    IS 

        L_ERROR_CODE_TBL wwt_string_to_table_type;

        L_ERROR_DISPUTE_FLAG VARCHAR2(1);

        L_ERROR_TYPE VARCHAR2(50);

    BEGIN

         

         IF P_ERROR_CODES IS NOT NULL

            THEN

                L_ERROR_CODE_TBL := apps.wwt_utilities.wwt_string_to_table_fun(P_ERROR_CODES, ',');

                

                 FOR i in 1..L_ERROR_CODE_TBL.count

                 LOOP

                 

                    SELECT DISPUTE_FLAG, ERROR_TYPE INTO L_ERROR_DISPUTE_FLAG, L_ERROR_TYPE FROM APPS.WWT_DGH_ERROR_CODE 

                    WHERE HUB_ID = (SELECT h.HUB_ID FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h WHERE h.header_id = l.header_id and l.line_id = P_LINE.LINE_ID)

                    AND ERROR_CODE = L_ERROR_CODE_TBL(i);

                    

                    IF P_LINE.PART_REV_RESTRICT_FLAG = 'N' AND L_ERROR_CODE_TBL(i) = 'ODM Part Mismatch'

                    THEN

                        log('Since this is not a part restricted MRP Site but the Error is a dispute error we do not want to log it');

                        CONTINUE;

                    END IF; 

                    

                    IF (P_LINE.PART_REV_RESTRICT_FLAG = 'Y' AND L_ERROR_DISPUTE_FLAG = 'Y') OR  L_ERROR_CODE_TBL(i) = 'Base Part Change'

                    THEN

                        log('PART_REV_RESTRICT_FLAG set to yes and this ECO had a warning or Base Part Change error so mark it in dispute and exit');

                        --This line is disputed. Generate the error, mark the dispute flag and quit.

                        X_DISPUTE := TRUE;

                    END IF;

                

                    log('Warning associated with ALLOCATED ECO PART.  Warning Code: ' || L_ERROR_CODE_TBL(i));

                    APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR(L_ERROR_CODE_TBL(i), P_LINE.LINE_ID, NULL, g_user_id, g_ldap_user);

                    

                    IF L_ERROR_DISPUTE_FLAG = 'Y'

                    THEN

                        log('Since this is a dispute error we have already marked it in dispute and we do not need to add the error logic to it');

                        CONTINUE;

                    END IF;

                    

                    IF UPPER(L_ERROR_TYPE) = 'ERROR'

                    THEN

                        log('ECO had ERROR');

                        --This line is disputed. Generate the error, mark the dispute flag and quit.

                        X_ERROR := TRUE;

                    END IF;

               END LOOP; 

                

            END IF;



    END GENERATE_ECO_WARNINGS;



    /*

   *****************************************************************************************

   Procedure name: GET_ITEM_AND_ALLOCATION

   Description:  This maps the items given the line and the eco part list it will return 

   *****************************************************************************************

   */     

    PROCEDURE GET_ITEM_AND_ALLOCATION(

    P_LINE IN LINE_ALLOC_TYPE,

    P_HUB_ZONE IN APPS.WWT_DGH_HUB_ZONE%ROWTYPE, 

    P_ECO_PARTS IN apps.wwt_dgh_eco_util_pkg.dgh_eco_lines_tab_type, 

    X_AVAILABLE_TAB IN OUT AVAILABLE_INV_TABTYPE,

    X_INVENTORY_ITEM_ID OUT APPS.WWT_DGH_LINE.Inventory_Item_id%TYPE, 

    X_ALLOCATED_AMOUNT OUT APPS.WWT_DGH_LINE.ALLOCATED_QTY%TYPE, 

    X_ERROR IN OUT  BOOLEAN, 

    X_DISPUTE OUT  BOOLEAN)

    IS

        L_CALCULATED_QTY NUMBER;

        L_CHECK_CALC_QTY NUMBER;

        L_TEST_AVAIL NUMBER;

        L_PROMISE_DATE_OFFSET NUMBER;

    BEGIN

    

     X_ALLOCATED_AMOUNT := 0;

     X_DISPUTE := FALSE;

     

     --Dividing by 1440 for minutes in a Day.

     SELECT PROMISE_DATE_OFFSET/1440 INTO L_PROMISE_DATE_OFFSET FROM APPS.WWT_DGH_HUB WHERE HUB_ID = P_LINE.HUB_ID;

     

     log('ECO PARTS COUNT: ' || P_ECO_PARTS.count);

    

     FOR i in 1..P_ECO_PARTS.count

     LOOP

     

         --Check if we had it in the available list if not add it the available.

         BEGIN

          L_TEST_AVAIL := X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id);

          

         EXCEPTION

          WHEN NO_DATA_FOUND

             THEN

                X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id) := 0;

         END;    

     

        log('ECO PART '|| i ||' INVENTORY ITEM ID: ' || P_ECO_PARTS(i).inventory_item_id);

        

        IF X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id) > 0

        THEN

            log('AVAILABLE INVENTORY FOUND.  AMOUNT AVAIL: ' || X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id));



            X_INVENTORY_ITEM_ID := P_ECO_PARTS(i).inventory_item_id;

            

            UPDATE APPS.WWT_DGH_LINE 

            SET INVENTORY_ITEM_ID = X_INVENTORY_ITEM_ID, 

            ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID,

            OPERATING_UNIT_ID = (SELECT OPERATING_UNIT from apps.wwt_dell_org_lookup_v WHERE ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID ),

            WWT_PART_NUMBER = (SELECT segment2  FROM APPS.MTL_SYSTEM_ITEMS_B ms WHERE ms.ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID AND ms.INVENTORY_ITEM_ID = X_INVENTORY_ITEM_ID),

            PLANNER_CODE = GET_PLANNER(X_INVENTORY_ITEM_ID, P_HUB_ZONE.ORGANIZATION_ID, P_LINE.MRP_SITE_ID, P_HUB_ZONE.ZONE_TYPE),

            LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

            WHERE LINE_ID = P_LINE.LINE_ID;

        

            --Generate Warnings

             log('CALL GENERATE_ECO_WARNINGS for error code: ' || P_ECO_PARTS(i).ERROR_CODE);

            GENERATE_ECO_WARNINGS

            (

              P_LINE,  

              P_ECO_PARTS(i).ERROR_CODE,

              X_ERROR, 

              X_DISPUTE 

            );

            

             IF X_ERROR OR X_DISPUTE

             THEN

                 IF UPPER(P_LINE.STATUS_NAME) = 'OPEN'

                        THEN

                            APPS.WWT_DGH_UTILITIES.REGISTER_MILESTONE ( P_LINE.LINE_ID, 'ECO Failure', SYSDATE, g_user_id, g_ldap_user );

                 END IF;

                 log('There was an error or a dispute so exit allocation loop');

                 EXIT;

             END IF; 

            

            --Calculated Qty

            L_CALCULATED_QTY := CEIL(P_LINE.ORDER_QTY/P_ECO_PARTS(i).box_quantity) * P_ECO_PARTS(i).box_quantity;

            

            log('Given the Box QTY in the ECO where is the CALC QTY '|| L_CALCULATED_QTY);

            --Check if we have enough inventory to order the full calculated QTY

            L_CHECK_CALC_QTY := X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id) - L_CALCULATED_QTY;

   

            IF L_CHECK_CALC_QTY >= 0

            THEN

                log('We have enough available inventory for the calc qty so use it');

                --If we have enough order the calc qty

                X_ALLOCATED_AMOUNT := L_CALCULATED_QTY;          

            ELSE

                log('We do not have enough available inventory for the calc qty so use everything we have');

                --If not order the rest of the inventory and we might have to split if it does not fulfill the entire ORDER_QTY

                X_ALLOCATED_AMOUNT := X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id);

            END IF;

            

            log('Update the Promise date to now for this line');

            IF P_LINE.STATUS_NAME != 'Short Review' THEN

                --Can't set allocated amount or reduce available yet until we find out if we have a prices list and an address

                UPDATE APPS.WWT_DGH_LINE SET PROMISE_DATE = SYSDATE + L_PROMISE_DATE_OFFSET, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE  WHERE LINE_ID = P_LINE.LINE_ID;

            END IF;

            

            --END LOOP

            EXIT;

        END IF;            

           

        

        --Check if we found any inventory since this will be the last step in the loop...if not then we need to assign the last inventory_inventory_item_id in the loop and set the promise date based on the promise date

        IF i = P_ECO_PARTS.count AND X_INVENTORY_ITEM_ID IS NULL

        THEN

            log('We could not find an eco part with available inventory so use the last inventory item id: '|| P_ECO_PARTS(i).inventory_item_id);

            X_INVENTORY_ITEM_ID := P_ECO_PARTS(i).inventory_item_id;

            

            log('Set the promise date using the following lead time: ' || P_ECO_PARTS(i).LEAD_TIME);

            UPDATE APPS.WWT_DGH_LINE 

            SET INVENTORY_ITEM_ID = X_INVENTORY_ITEM_ID, 

            ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID,

            OPERATING_UNIT_ID = (SELECT OPERATING_UNIT from apps.wwt_dell_org_lookup_v WHERE ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID ), 

            WWT_PART_NUMBER = (SELECT segment2  FROM APPS.MTL_SYSTEM_ITEMS_B ms WHERE ms.ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID AND ms.INVENTORY_ITEM_ID = X_INVENTORY_ITEM_ID),

            PLANNER_CODE = GET_PLANNER(X_INVENTORY_ITEM_ID, P_HUB_ZONE.ORGANIZATION_ID, P_LINE.MRP_SITE_ID, P_HUB_ZONE.ZONE_TYPE),

            PROMISE_DATE = CASE WHEN P_LINE.STATUS_NAME = 'Short Review' THEN PROMISE_DATE WHEN P_ECO_PARTS(i).LEAD_TIME IS NULL THEN NULL ELSE SYSDATE + P_ECO_PARTS(i).LEAD_TIME END 

            , LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

            WHERE LINE_ID = P_LINE.LINE_ID;

            

            IF P_ECO_PARTS(i).LEAD_TIME IS NULL

            THEN

                APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('Missing Lead Time', P_LINE.LINE_ID, NULL, g_user_id, g_ldap_user);

                log('Missing lead time so set error to true');

                X_ERROR := TRUE;

            END IF;

            

            --Generate Warnings

             log('CALL GENERATE_ECO_WARNINGS for error code: ' || P_ECO_PARTS(i).ERROR_CODE);

            GENERATE_ECO_WARNINGS

            (

              P_LINE,  

              P_ECO_PARTS(i).ERROR_CODE,

              X_ERROR, 

              X_DISPUTE 

            );

            

             IF X_ERROR OR X_DISPUTE

             THEN

                 IF UPPER(P_LINE.STATUS_NAME) = 'OPEN'

                        THEN

                            APPS.WWT_DGH_UTILITIES.REGISTER_MILESTONE ( P_LINE.LINE_ID, 'ECO Failure', SYSDATE, g_user_id, g_ldap_user );

                 END IF;

                 log('There was an error or a dispute so exit allocation loop');

                 EXIT;

             END IF;

        

         END IF;            

     END LOOP;

        

    END GET_ITEM_AND_ALLOCATION;



    /*

   *****************************************************************************************

   Procedure name: GET_PRICE_LIST_FOR_LINE

   Description:  Gets the price list for the line.  Even if there is no allocation we will try to 

   determine the price list so we can feed back an error with the price list if there is one.  If there is an error we will set the 

   allocation amount to 0, Log the error and the milestone if the line is open.

   *****************************************************************************************

   */  

   PROCEDURE GET_PRICE_LIST_FOR_LINE(

   P_LINE_ID IN APPS.WWT_DGH_LINE.Line_id%TYPE, 

   P_LINE_STATUS IN APPS.WWT_DGH_STATUS.STATUS_NAME%TYPE, 

   X_ALLOCATED_AMOUNT IN OUT APPS.WWT_DGH_LINE.ALLOCATED_QTY%TYPE, 

   X_ERROR IN OUT BOOLEAN)

   IS

    L_PRICE_LIST_ID NUMBER;

   BEGIN

   

    SELECT qll.list_line_id

    INTO L_PRICE_LIST_ID

     FROM apps. qp_list_lines qll,

          apps.qp_list_headers qlh,

          apps.qp_pricing_attributes qpa,

          apps.wwt_dgh_header h,

          apps.wwt_dgh_line l,

          APPS.WWT_DGH_HUB_ZONE_MRP_SITE hzm

    WHERE     hzm.mrp_site_id = h.mrp_site_id

          AND hzm.hub_zone_id = l.hub_zone_id

          AND hzm.PRICE_LIST_HEADER_ID = qlh.list_header_id

          AND qlh.list_header_id = qll.list_header_id

          AND qll.list_line_id = qpa.list_line_id

          AND l.header_id = h.header_id

          AND l.line_id = P_LINE_ID

          AND qpa.product_attr_value = TO_CHAR(l.inventory_item_id)

          AND qpa.product_attribute_context = 'ITEM'

          AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'

          AND TRUNC (wwt_dgh_utilities.to_mrp_tz(h.MRP_SITE, l.requested_date)) BETWEEN TRUNC (

          NVL (qll.start_date_active, wwt_dgh_utilities.to_mrp_tz(h.MRP_SITE, l.requested_date)))

          AND TRUNC (NVL (qll.end_date_active, wwt_dgh_utilities.to_mrp_tz(h.MRP_SITE, l.requested_date)));

          

          log('Price List Found ' || L_PRICE_LIST_ID);  

          UPDATE apps.wwt_dgh_line l SET PRICE_LIST_LINE_ID = L_PRICE_LIST_ID, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE WHERE line_id = P_LINE_ID;

       

   EXCEPTION

      WHEN NO_DATA_FOUND

      THEN 

      X_ERROR := TRUE;

      X_ALLOCATED_AMOUNT := 0;

      log('Price List  Not Found ');

      APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('Missing Price List',P_LINE_ID, NULL, g_user_id, g_ldap_user);

      IF UPPER(P_LINE_STATUS) = 'OPEN'

      THEN

        APPS.WWT_DGH_UTILITIES.REGISTER_MILESTONE ( P_LINE_ID, 'Price List Missing', SYSDATE, g_user_id, g_ldap_user );

      END IF;

   END ;



    /*

   *****************************************************************************************

   Procedure name: GET_DELIVERY_ADDRESS

   Description:  Gets the delivery address for the line.  Even if there is no allocation we will try to 

   determine the address so we can feed back an error with the price list if there is one.  If there is an error we will set the 

   allocation amount to 0, Log the error, and the milestone if the line is open.

   *****************************************************************************************

   */     

  PROCEDURE GET_DELIVERY_ADDRESS(

  P_LINE_ID IN APPS.WWT_DGH_LINE.LINE_id%TYPE, 

  P_LINE_STATUS IN APPS.WWT_DGH_STATUS.STATUS_NAME%TYPE, 

  P_MRP_SITE_ID IN APPS.WWT_DGH_HEADER.MRP_SITE_id%TYPE, 

  P_DELIVER_TO_CODE IN APPS.WWT_DGH_LINE.DELIVER_TO_CODE%TYPE, 

  X_ALLOCATED_AMOUNT IN OUT APPS.WWT_DGH_LINE.ALLOCATED_QTY%TYPE, 

  X_ERROR IN OUT BOOLEAN) 

   IS

    L_DELIVER_TO_CODE_ID NUMBER;

   BEGIN

   

    SELECT ds.DELIVER_TO_CODE_ID

    INTO L_DELIVER_TO_CODE_ID

    FROM APPS.WWT_DGH_SITES_V ds

    WHERE ds.mrp_site_id = P_MRP_SITE_ID

    AND ds.DELIVER_TO_CODE = P_DELIVER_TO_CODE;

    

    log('Deliver to Code Found ' || L_DELIVER_TO_CODE_ID);      

    UPDATE apps.wwt_dgh_line l SET DELIVER_TO_CODE_ID = L_DELIVER_TO_CODE_ID, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE WHERE line_id = P_LINE_ID;

       

   EXCEPTION

      WHEN NO_DATA_FOUND

      THEN

      X_ERROR := TRUE; 

      X_ALLOCATED_AMOUNT := 0;

      log('Deliver to Code Not Found');      

      APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('Address Failure',P_LINE_ID, NULL, g_user_id, g_ldap_user);

      IF UPPER(P_LINE_STATUS) = 'OPEN'

      THEN

        APPS.WWT_DGH_UTILITIES.REGISTER_MILESTONE ( P_LINE_ID, 'Address Failure', SYSDATE, g_user_id, g_ldap_user );

      END IF;

   END GET_DELIVERY_ADDRESS;



    /*

   ************************************************************************************************

   Procedure name: DETERMINE_SPLIT_LINE

   Description:  This procedure is used to determine if the line needs to be split and if so perform the appropriate action on the split line.

   ************************************************************************************************

   */

   PROCEDURE DETERMINE_SPLIT_LINE(

   P_LINE IN LINE_ALLOC_TYPE,

   P_ALLOCATED_AMOUNT IN APPS.WWT_DGH_LINE.ALLOCATED_QTY%TYPE, 

   P_ERROR IN BOOLEAN,

   P_DISPUTE IN BOOLEAN, 

   X_NEED_ALOC_SPLIT OUT BOOLEAN, 

   X_SPLIT_ALLOC_LINE OUT LINE_ALLOC_TYPE)

   IS

   L_SPLIT_LINE APPS.WWT_DGH_LINE%ROWTYPE;

   L_SPLIT_REVIEW_STATUS_ID APPS.WWT_DGH_STATUS.STATUS_ID%TYPE;

   L_OPEN_REVIEW_STATUS_ID APPS.WWT_DGH_STATUS.STATUS_ID%TYPE;

   L_CHILD_COUNT NUMBER := 0;

   BEGIN

   

   X_NEED_ALOC_SPLIT :=FALSE;

   

   SELECT * INTO L_SPLIT_LINE FROM APPS.WWT_DGH_LINE where line_id = P_LINE.LINE_ID;

   

   L_SPLIT_LINE.PARENT_LINE_ID := P_LINE.LINE_ID;

   L_SPLIT_LINE.ALLOCATED_QTY := 0;

   

   SELECT STATUS_ID

   INTO L_SPLIT_REVIEW_STATUS_ID

   FROM APPS.WWT_DGH_STATUS

   WHERE STATUS_TYPE = 'LINE'

   AND UPPER(STATUS_NAME) = 'SPLIT REVIEW'

   AND HUB_ID = (SELECT HUB_ID FROM APPS.WWT_DGH_HEADER hd, APPS.WWT_DGH_LINE l WHERE l.header_id = hd.header_id AND l.line_id = P_LINE.LINE_ID);

   

   SELECT STATUS_ID

   INTO L_OPEN_REVIEW_STATUS_ID

   FROM APPS.WWT_DGH_STATUS

   WHERE STATUS_TYPE = 'LINE'

   AND UPPER(STATUS_NAME) = 'OPEN REVIEW'

   AND HUB_ID = (SELECT HUB_ID FROM APPS.WWT_DGH_HEADER hd, APPS.WWT_DGH_LINE l WHERE l.header_id = hd.header_id AND l.line_id = P_LINE.LINE_ID);

   

   IF P_ERROR = FALSE

   THEN

        log('No Error so lets see if we need to split');

        IF P_ALLOCATED_AMOUNT = 0

        THEN

            log('The allocated amount was 0 so either we are in dispute or we could find nothing to allocate so we do not need to split this line. ');  

        ELSIF  P_ALLOCATED_AMOUNT < P_LINE.ORDER_QTY

        THEN

             log('The Allocated amount could not satisfy the ordered qty and it was not 0.  So we need to split the line in order to satisfy the rest.');

             L_SPLIT_LINE.LINE_ID := APPS.WWT_DGH_LINE_S.nextval;

             L_SPLIT_LINE.ORDER_QTY := P_LINE.ORDER_QTY - P_ALLOCATED_AMOUNT;

             L_SPLIT_LINE.STATUS_ID := L_SPLIT_REVIEW_STATUS_ID;

             

             INSERT INTO APPS.WWT_DGH_LINE VALUES L_SPLIT_LINE;

             log('New Split Line id: ' || L_SPLIT_LINE.LINE_ID );

             

             UPDATE APPS.WWT_DGH_LINE SET ORDER_QTY = P_ALLOCATED_AMOUNT, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE WHERE LINE_ID = P_LINE.LINE_ID; 

             log('Update Order Qty of parent to allocated amount : ' || P_ALLOCATED_AMOUNT );

             

             X_SPLIT_ALLOC_LINE := P_LINE;

             X_SPLIT_ALLOC_LINE.LINE_ID := L_SPLIT_LINE.LINE_ID;

             X_SPLIT_ALLOC_LINE.ORDER_QTY := L_SPLIT_LINE.ORDER_QTY;

             X_SPLIT_ALLOC_LINE.STATUS_NAME := 'Split Review';

             X_SPLIT_ALLOC_LINE.PARENT_LINE_ID := L_SPLIT_LINE.LINE_ID;

             X_NEED_ALOC_SPLIT := TRUE;             

        END IF;

    END IF;

    

    IF UPPER(P_LINE.STATUS_NAME) = 'OPEN'

    THEN

        log('Since this was in Open status move it to Open Review');

        UPDATE APPS.WWT_DGH_LINE SET STATUS_ID = L_OPEN_REVIEW_STATUS_ID, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE WHERE LINE_ID = P_LINE.LINE_ID;

    END IF;

    

   END  DETERMINE_SPLIT_LINE;



    /*

   *****************************************************************************************

   Procedure name: ALLOCATE_PART

   Description:  This process actually runs the allocation for the line

   *****************************************************************************************

   */

   PROCEDURE ALLOCATE_PART(

   P_LINE IN LINE_ALLOC_TYPE,

   P_HUB_ZONE IN APPS.WWT_DGH_HUB_ZONE%ROWTYPE, 

   P_ECO_PARTS IN apps.wwt_dgh_eco_util_pkg.dgh_eco_lines_tab_type, 

   X_AVAILABLE_TAB IN OUT AVAILABLE_INV_TABTYPE,

   X_ERROR IN OUT BOOLEAN)

   IS

    L_ALLOCATED_AMOUNT APPS.WWT_DGH_LINE.ALLOCATED_QTY%TYPE := 0;

    L_INVENTORY_ITEM_ID APPS.WWT_DGH_LINE.INVENTORY_ITEM_ID%TYPE;

    L_DISPUTE BOOLEAN := FALSE;

    L_NEED_ALOC_SPLIT BOOLEAN := FALSE;

    L_SPLIT_LINE LINE_ALLOC_TYPE;

   BEGIN

        log('Call GET_ITEM_AND_ALLOCATION');

        GET_ITEM_AND_ALLOCATION(P_LINE, P_HUB_ZONE, P_ECO_PARTS, X_AVAILABLE_TAB, L_INVENTORY_ITEM_ID, L_ALLOCATED_AMOUNT, X_ERROR, L_DISPUTE);

        

        IF L_INVENTORY_ITEM_ID IS NOT NULL

        THEN

           log('Calling Get Price List');

          GET_PRICE_LIST_FOR_LINE(P_LINE.LINE_ID, P_LINE.STATUS_NAME, L_ALLOCATED_AMOUNT, X_ERROR);

        ELSE

            log('There was no inventory Item Id found so we are creating an error for that');

          --???? NOT Sure that this will ever happen

          APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('No Inventory Item Found',P_LINE.LINE_ID, null, g_user_id, g_ldap_user);

        END IF;

        

      log('Call Get Delivery Addresses');

      GET_DELIVERY_ADDRESS(P_LINE.LINE_ID, P_LINE.STATUS_NAME, P_LINE.MRP_SITE_ID, P_LINE.DELIVER_TO_CODE, L_ALLOCATED_AMOUNT, X_ERROR);

      

      --For logging purposes

      IF X_ERROR

      THEN

         log('Line in Error Status');

      END IF;

      

      --For logging purposes

      IF L_DISPUTE

      THEN

         log('Line in Dispute Status');

      END IF;

      

      --Finally set the allocated amount...this could have been reduced to 0 if there was an error with Price List or DELIVERY ADDRESS

      IF L_INVENTORY_ITEM_ID IS NOT NULL

      THEN

         log('Actually make the allocation If there was an error then the allocation will be 0. Alloc amount: ' || L_ALLOCATED_AMOUNT);

         X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || L_INVENTORY_ITEM_ID) := X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || L_INVENTORY_ITEM_ID) - L_ALLOCATED_AMOUNT;

        UPDATE APPS.WWT_DGH_LINE SET ALLOCATED_QTY = L_ALLOCATED_AMOUNT, LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE WHERE LINE_ID = P_LINE.LINE_ID;

        

        log('Available inventory for item: ' || L_INVENTORY_ITEM_ID || ' after alloc subtracted is: ' || X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || L_INVENTORY_ITEM_ID));

      END IF;

      

      log('Call DETERMINE SPLIT LINE');

      DETERMINE_SPLIT_LINE(P_LINE, L_ALLOCATED_AMOUNT, X_ERROR, L_DISPUTE, L_NEED_ALOC_SPLIT, L_SPLIT_LINE);

      

      --If we need to allocate the split recursivly call this function

      IF L_NEED_ALOC_SPLIT

      THEN

        log('SPLIT LINE Allocation was needed so recalling ALLOCATE_PART for line_id: ' || L_SPLIT_LINE.line_id);

        ALLOCATE_PART(L_SPLIT_LINE, P_HUB_ZONE, P_ECO_PARTS, X_AVAILABLE_TAB, X_ERROR);

      END IF;

      

   END ALLOCATE_PART;



    /*

   *****************************************************************************************

   Procedure name: CREATE_ECO_AUDIT

   Description:  This process is used to generate the ECO Audit Records for each line.

   *****************************************************************************************

   */

    PROCEDURE CREATE_ECO_AUDIT(

        P_LINE IN LINE_ALLOC_TYPE, 

        P_HUB_ZONE IN APPS.WWT_DGH_HUB_ZONE%ROWTYPE,

        P_ECO_PARTS IN apps.wwt_dgh_eco_util_pkg.dgh_eco_lines_tab_type, 

        X_AVAILABLE_TAB IN OUT AVAILABLE_INV_TABTYPE

    )

    IS

        L_AVAIL NUMBER;

        L_CONC_REQUEST_ID NUMBER;

        L_CONC_START_TIME DATE;

        L_ORDER NUMBER := 0;

        

        L_ECO_AUDIT_REC APPS.WWT_DGH_ECO_LINE_AUDIT%ROWTYPE;

    BEGIN

    log('Begin CREATE_ECO_AUDIT');

    

     L_CONC_REQUEST_ID := fnd_global.conc_request_id;

     

     log('Conc Id: ' || L_CONC_REQUEST_ID);

     

     BEGIN

         SELECT fcr.actual_start_date

         INTO L_CONC_START_TIME

         FROM apps.FND_CONCURRENT_REQUESTS fcr

         WHERE fcr.request_id = L_CONC_REQUEST_ID;

     EXCEPTION

          WHEN NO_DATA_FOUND

             THEN

                L_CONC_START_TIME := SYSDATE;

     END;

         

     log('Conc Start Time: ' || L_CONC_START_TIME);

     

     FOR i in 1..P_ECO_PARTS.count

     LOOP

     

         --Check if we had it in the available list if not add it the available.

         BEGIN

         log('Top of Loop ');

          L_AVAIL := X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id);

          

         EXCEPTION

          WHEN NO_DATA_FOUND

             THEN

                X_AVAILABLE_TAB(P_HUB_ZONE.HUB_ZONE_ID || '_' || P_ECO_PARTS(i).inventory_item_id) := 0;

                 L_AVAIL := 0;

         END;

         L_ORDER := L_ORDER + 1;

         

         SELECT segment2

         INTO L_ECO_AUDIT_REC.PART_NUMBER  

         FROM APPS.MTL_SYSTEM_ITEMS_B ms 

         WHERE ms.ORGANIZATION_ID = P_HUB_ZONE.ORGANIZATION_ID AND ms.INVENTORY_ITEM_ID = P_ECO_PARTS(i).inventory_item_id;

         

         log('Part Num: ' || L_ECO_AUDIT_REC.PART_NUMBER);

         

         L_ECO_AUDIT_REC.ECO_AUDIT_ID  :=  APPS.WWT_DGH_ECO_LINE_AUDIT_S.nextval;

         L_ECO_AUDIT_REC.CONC_REQUEST_ID := L_CONC_REQUEST_ID;

         L_ECO_AUDIT_REC.REQUEST_START_TIME := L_CONC_START_TIME;

         L_ECO_AUDIT_REC.LINE_ID := P_LINE.LINE_ID;

         L_ECO_AUDIT_REC.ECO_ORDER := L_ORDER;

         L_ECO_AUDIT_REC.AVAILABLE_QTY  := L_AVAIL;

         L_ECO_AUDIT_REC.INVENTORY_ITEM_ID := P_ECO_PARTS(i).inventory_item_id;

         

         L_ECO_AUDIT_REC.SCHEDULED_EFFECTIVE_DATE := P_ECO_PARTS(i).SCHEDULE_EFFECTIVE_DATE;

         L_ECO_AUDIT_REC.GRACE_DAYS                          := P_ECO_PARTS(i).GRACE_DAYS;

         L_ECO_AUDIT_REC.ECO_STATUS                         := P_ECO_PARTS(i).ECO_STATUS;

         L_ECO_AUDIT_REC.PRIORITY                               := P_ECO_PARTS(i).PRIORITY;

         L_ECO_AUDIT_REC.BASE_PART                            := P_ECO_PARTS(i).BASE_PART;

         L_ECO_AUDIT_REC.ALL_PART_REVS                     := P_ECO_PARTS(i).ALL_PART_REVS;

         L_ECO_AUDIT_REC.XREF_PART_REVS                   := P_ECO_PARTS(i).XREF_PART_REVS;

         

         L_ECO_AUDIT_REC.CREATED_BY   :=  g_user_id;

         L_ECO_AUDIT_REC.CREATION_DATE := SYSDATE;

         L_ECO_AUDIT_REC.LAST_UPDATED_BY  := g_user_id;

         L_ECO_AUDIT_REC.LAST_UPDATE_DATE := SYSDATE;

         L_ECO_AUDIT_REC.LDAP_CREATED_BY := g_ldap_user;

         L_ECO_AUDIT_REC.LDAP_LAST_UPDATED_BY  := g_ldap_user;

            

         

         INSERT INTO APPS.WWT_DGH_ECO_LINE_AUDIT VALUES L_ECO_AUDIT_REC;

         

      log('End of Loop ');

      END LOOP;

    

    log('End CREATE_ECO_AUDIT');

    END CREATE_ECO_AUDIT;



    /*

   *****************************************************************************************

   Procedure name: DETERMINE_LINE_ZONE_AND_PARTS

   Description:  This process determines a lines hubzone and then from that what parts are available.

   *****************************************************************************************

   */

   PROCEDURE DETERMINE_LINE_ZONE_AND_PARTS(

   P_HUB_ID IN APPS.WWT_DGH_HUB.HUB_ID%TYPE,  

   X_AVAILABLE_TAB IN OUT AVAILABLE_INV_TABTYPE,

   P_LINE IN LINE_ALLOC_TYPE, 

   X_ERROR IN OUT BOOLEAN,

   X_ECO_PARTS OUT apps.wwt_dgh_eco_util_pkg.dgh_eco_lines_tab_type,

   X_HUB_ZONE OUT APPS.WWT_DGH_HUB_ZONE%ROWTYPE

   )

   IS

     L_RETCODE NUMBER;

     L_ERRBUFF VARCHAR2(4000);

     L_CROSS_REFERENCE_ITEM NUMBER;

     L_BASE_PART_ITEM VARCHAR2(4000);

     L_IS_CFI NUMBER;

      

   BEGIN

        log('get_item_cross_ref parameter P_XREF_TYPE: ' || P_LINE.ITEM_CROSS_REF_NAME);

        log('get_item_cross_ref paramater P_CUST_PART: ' || P_LINE.CUST_PART_NUMBER);

                

        L_CROSS_REFERENCE_ITEM := APPS.WWT_DSH_COMMON_UTILITIES.GET_ITEM_CROSS_REFERENCE ( P_LINE.ITEM_CROSS_REF_NAME, 0, P_LINE.CUST_PART_NUMBER); 

        

        log('Cross Reference Item Returned: ' || L_CROSS_REFERENCE_ITEM);

        

        IF L_CROSS_REFERENCE_ITEM IS NULL

        THEN

             log('No Cross Reference Item so report error');

             APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR ('Cross Reference Missing',P_LINE.line_id, NULL, g_user_id, g_ldap_user);

             X_ERROR := TRUE;

         ELSE

            log('Cross Reference Item Returned so lets get base part');

            L_BASE_PART_ITEM := apps.wwt_dgh_eco_util_pkg.get_base_part (L_CROSS_REFERENCE_ITEM);

           

           SELECT

             CASE WHEN 

            (SELECT customer_item_id

            FROM APPS.WWT_DSH_GCFI_CUSTOMER_ITEM

            WHERE erp_inventory_item_id = L_CROSS_REFERENCE_ITEM AND rownum = 1) IS NULL 

            THEN 

                0 

            ELSE 

                1

            END

            INTO L_IS_CFI

           FROM DUAL;

            

            log('Base Part Item Returned: ' || L_BASE_PART_ITEM);

            IF L_BASE_PART_ITEM IS NULL AND L_IS_CFI = 0

            THEN

             log('Unknown hubzone');

             APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR ('Cross Reference Missing',P_LINE.line_id, 'Not a CFI or a BE part', g_user_id, g_ldap_user);

             X_ERROR := TRUE;

                

            ELSIF L_IS_CFI = 1

            THEN

                log('No Base Part Item so assume CFI');

                BEGIN

                    SELECT * 

                    INTO X_HUB_ZONE

                    FROM 

                    APPS.WWT_DGH_HUB_ZONE WDHZ

                    WHERE HUB_ID = P_HUB_ID

                    AND ZONE_TYPE = 'CFI'

                    AND ENABLED_FLAG = 'Y'
                    
                    AND EXISTS (SELECT 1
                                FROM APPS.WWT_DGH_HUB_ZONE_MRP_SITE WDHZMS
                                WHERE WDHZMS.HUB_ZONE_ID = WDHZ.HUB_ZONE_ID
                                AND WDHZMS.MRP_SITE_ID = P_LINE.MRP_SITE_ID)

                    AND ROWNUM = 1;

                   

                    X_ECO_PARTS(1).inventory_item_id := L_CROSS_REFERENCE_ITEM;

                   Select NVL(fixed_lot_multiplier,1),segment2

                   INTO  X_ECO_PARTS(1).box_quantity, X_ECO_PARTS(1).base_part 

                   FROM APPS.MTL_SYSTEM_ITEMS 

                   WHERE inventory_item_id = L_CROSS_REFERENCE_ITEM 

                   AND organization_id = X_HUB_ZONE.organization_id;

                   

                    SELECT wdgroix.lead_time 

                    INTO x_eco_parts(1).lead_time

                    FROM apps.wwt_dsh_gcfi_customer_item wdgci,

                        apps.wwt_dsh_gcfi_item_region_xref wdgirx,

                        apps.wwt_dsh_gcfi_rva_odm_item_xref wdgroix

                    WHERE wdgci.erp_inventory_item_id = L_CROSS_REFERENCE_ITEM

                    AND wdgci.customer_item_id = wdgirx.customer_item_id

                    AND wdgirx.region_part_xref_id = wdgroix.region_part_xref_id

                    AND wdgroix.mrp_site_id = P_LINE.MRP_SITE_ID

                    AND rownum = 1;



                  

                    UPDATE APPS.WWT_DGH_LINE set hub_zone_id = X_HUB_ZONE.hub_zone_id where line_id = P_LINE.line_id;

                    

                    log('Call Create ECO AUDIT ');

                    CREATE_ECO_AUDIT(P_LINE,X_HUB_ZONE, X_ECO_PARTS, X_AVAILABLE_TAB); 

                 EXCEPTION

                 WHEN NO_DATA_FOUND

                 THEN

                    APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('General ECO Fatal Error',P_LINE.LINE_ID, 'CFI HUBZONE not setup', g_user_id, g_ldap_user);

                    X_ERROR := TRUE;

                END;    

            ELSE

                log('Base Part Item so assume BE');

                BEGIN

                    SELECT * 

                    INTO X_HUB_ZONE

                    FROM 

                    APPS.WWT_DGH_HUB_ZONE WDHZ

                    WHERE HUB_ID = P_HUB_ID

                    AND ZONE_TYPE = 'BE'

                    AND ENABLED_FLAG = 'Y'
                    
                    AND EXISTS (SELECT 1
                                FROM APPS.WWT_DGH_HUB_ZONE_MRP_SITE WDHZMS
                                WHERE WDHZMS.HUB_ZONE_ID = WDHZ.HUB_ZONE_ID
                                AND WDHZMS.MRP_SITE_ID = P_LINE.MRP_SITE_ID)

                    AND ROWNUM = 1;

                  

                UPDATE APPS.WWT_DGH_LINE set hub_zone_id = X_HUB_ZONE.hub_zone_id where line_id = P_LINE.line_id;

                 

                 EXCEPTION

                 WHEN NO_DATA_FOUND

                 THEN

                    APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('General ECO Fatal Error',P_LINE.LINE_ID, 'BE HUBZONE not setup', g_user_id, g_ldap_user);

                    X_ERROR := TRUE;

                END;



                log('Get ECO for line id: ' || P_LINE.line_id);

                log('eco paramater P_XREF_TYPE: ' || P_LINE.ITEM_CROSS_REF_NAME);

                log('eco paramater P_CUST_PART: ' || P_LINE.CUST_PART_NUMBER);

                log('eco paramater P_CUTIN_DATE: ' || TRUNC(wwt_dgh_utilities.to_mrp_tz(P_LINE.MRP_SITE, SYSDATE)));

                log('eco paramater P_HUB_ZONE_ID: ' || X_HUB_ZONE.HUB_ZONE_ID);

                

                apps.wwt_dgh_eco_util_pkg.get_eco_data (

                P_LINE.ITEM_CROSS_REF_NAME,

                P_LINE.CUST_PART_NUMBER,

                TRUNC(wwt_dgh_utilities.to_mrp_tz(P_LINE.MRP_SITE, SYSDATE)),

                X_HUB_ZONE.HUB_ZONE_ID,

                X_ECO_PARTS,

                L_RETCODE,

                L_ERRBUFF);

                

                IF L_RETCODE = 2

                THEN

                    log('Line ECO Fatally Errored with : ' || L_ERRBUFF);

                    IF L_ERRBUFF LIKE 'Cannot find cross reference %'

                    THEN

                         APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('Cross Reference Missing',P_LINE.line_id, L_ERRBUFF, g_user_id, g_ldap_user);

                         IF UPPER(P_LINE.STATUS_NAME) = 'OPEN'

                         THEN

                            APPS.WWT_DGH_UTILITIES.REGISTER_MILESTONE (P_LINE.line_id, 'Cross Reference Missing', SYSDATE, g_user_id, g_ldap_user );

                         END IF;

                    ELSE

                         APPS.WWT_DGH_UTILITIES.REGISTER_LINE_ERROR('General ECO Fatal Error',P_LINE.LINE_ID, L_ERRBUFF, g_user_id, g_ldap_user);

                    END IF;

                    X_ERROR := TRUE;

                ELSE

                    log('Call Create ECO AUDIT ');

                    CREATE_ECO_AUDIT(P_LINE,X_HUB_ZONE, X_ECO_PARTS, X_AVAILABLE_TAB);

                END IF;

          END IF;

       END IF;

   END DETERMINE_LINE_ZONE_AND_PARTS;



    /*

   *****************************************************************************************

   Procedure name: PROCESS_LINES

   Description:  This processes the lines that need to be validated

   *****************************************************************************************

   */

   PROCEDURE PROCESS_LINES(

   P_HUB_ID IN APPS.WWT_DGH_HUB.HUB_ID%TYPE,  

   X_AVAILABLE_TAB IN OUT AVAILABLE_INV_TABTYPE)

   IS

   

   L_LINE_QUERY VARCHAR2(4000);

   L_LINES LINE_ALLOC_TABTYPE;

   L_ECO_PARTS apps.wwt_dgh_eco_util_pkg.dgh_eco_lines_tab_type;

   L_ERROR BOOLEAN;

   L_HUBZONE APPS.WWT_DGH_HUB_ZONE%ROWTYPE;

   

   BEGIN

    log('Get Line Query');

    GET_LINE_QUERY(P_HUB_ID, L_LINE_QUERY);

   

    EXECUTE IMMEDIATE L_LINE_QUERY BULK COLLECT INTO L_LINES;

   

   log('# of Hub Lines to process: ' || L_LINES.count);

   

    FOR i in 1..L_LINES.count

    LOOP

        L_ECO_PARTS.delete;

        L_ERROR := FALSE;

        

        log('Determine HubZone and Possible Part List');

        DETERMINE_LINE_ZONE_AND_PARTS(P_HUB_ID, X_AVAILABLE_TAB, L_LINES(i), L_ERROR, L_ECO_PARTS, L_HUBZONE);

         

        log('Call Allocate Part for line');

        ALLOCATE_PART(L_LINES(i), L_HUBZONE, L_ECO_PARTS, X_AVAILABLE_TAB, L_ERROR);

   END LOOP;

  

   END PROCESS_LINES;

   

        /*

   *****************************************************************************************

   Procedure name: GENERATE_PLAN_EXCEPTIONS

   Description:  Used to generate the plan exceptions for the Hub

   *****************************************************************************************

   */

   PROCEDURE GENERATE_PLAN_EXCEPTIONS(P_HUB_ID IN APPS.WWT_DGH_HUB.hub_id%TYPE)

   IS

   

   BEGIN

  

   log('Call out errored lines in plan exception');

   UPDATE APPS.WWT_DGH_LINE 

   SET PLAN_EXCEPTION = (Select ATTRIBUTE2 FROM APPS.WWT_LOOKUPS_ACTIVE_V where lookup_type = 'WWT_DGH_PLAN_EXCEPTION' AND ATTRIBUTE1 = 'ERROR')

   , LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

   WHERE PLAN_EXCEPTION IS NULL 

   AND LINE_ID IN (

   SELECT l.LINE_ID

   FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s, APPS.WWT_DGH_LINE_ERROR le, APPS.WWT_DGH_ERROR_CODE ec

   WHERE l.header_id = h.header_id and l.status_id = s.status_id and le.line_id = l.line_id and le.error_code_id = ec.error_code_id 

   and le.status = 'Open' and ec.error_type = 'Error' and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID

   );

   

   log('Call out warning lines in plan exception');

   UPDATE APPS.WWT_DGH_LINE 

   SET PLAN_EXCEPTION = (Select ATTRIBUTE2 FROM APPS.WWT_LOOKUPS_ACTIVE_V where lookup_type = 'WWT_DGH_PLAN_EXCEPTION' AND ATTRIBUTE1 = 'WARNING') 

   , LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

   WHERE PLAN_EXCEPTION IS NULL 

   AND LINE_ID IN (

   SELECT l.LINE_ID

   FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s, APPS.WWT_DGH_LINE_ERROR le, APPS.WWT_DGH_ERROR_CODE ec

   WHERE l.header_id = h.header_id and l.status_id = s.status_id and le.line_id = l.line_id and le.error_code_id = ec.error_code_id 

   and le.status = 'Open' and ec.error_type = 'Warning' and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID and STATUS_NAME != 'Short Review'

   );



   log('Call out everything that is short');

   UPDATE APPS.WWT_DGH_LINE 

   SET PLAN_EXCEPTION = (Select ATTRIBUTE2 FROM APPS.WWT_LOOKUPS_ACTIVE_V where lookup_type = 'WWT_DGH_PLAN_EXCEPTION' AND ATTRIBUTE1 = 'SHORT') 

   , LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

   WHERE PLAN_EXCEPTION IS NULL 

   AND ALLOCATED_QTY < ORDER_QTY

   AND LINE_ID IN (

   SELECT l.LINE_ID

   FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s

   WHERE l.header_id = h.header_id and l.status_id = s.status_id and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID

   );



   log('Call out everything that is ready to commit in plan exception');

   UPDATE APPS.WWT_DGH_LINE 

   SET PLAN_EXCEPTION = (Select ATTRIBUTE2 FROM APPS.WWT_LOOKUPS_ACTIVE_V where lookup_type = 'WWT_DGH_PLAN_EXCEPTION' AND ATTRIBUTE1 = 'READY')

   , LAST_UPDATED_BY = g_user_id, LDAP_LAST_UPDATED_BY = g_ldap_user, LAST_UPDATE_DATE = SYSDATE

   WHERE PLAN_EXCEPTION IS NULL 

   AND LINE_ID IN (

   SELECT l.LINE_ID

   FROM APPS.WWT_DGH_LINE l, APPS.WWT_DGH_HEADER h, APPS.WWT_DGH_STATUS s

   WHERE l.header_id = h.header_id and l.status_id = s.status_id and s.validate_flag = 'Y' and h.hub_id = P_HUB_ID

   );

 

   END GENERATE_PLAN_EXCEPTIONS;   

   

   

     /*

   *****************************************************************************************

   Procedure name: RUN_PROCESSOR

   Description:  Used to start the ECO AND ALLOC PROCESSOR

   *****************************************************************************************

   */

   PROCEDURE RUN_PROCESSOR(

                               X_ERRBUFF          OUT VARCHAR2,

                               X_RETCODE          OUT NUMBER,

                               P_HUB_ID          IN APPS.WWT_DGH_HUB.HUB_ID%TYPE)

   IS

   L_AVAILABLE_TAB AVAILABLE_INV_TABTYPE;

   

   BEGIN

    x_retcode  := 0;

    log('Begin ECO AND ALLOCATION PROCESS');

       

    log('Lock Hub For allcation.  Hub Id: ' || P_HUB_ID);   

    ALLOCATION_LOCK(P_HUB_ID, 'LOCK');

    

    log('Call PROCESS_ASN_UPDATES for hub Id: ' || P_HUB_ID);

    PROCESS_ASN_UPDATES(P_HUB_ID);

    

    log('Clean Validate Lines');   

    CLEANUP_VALIDATE_LINES(P_HUB_ID);

    

    log('Call Get Hub Available');   

    GET_HUB_AVAILABLE(P_HUB_ID, L_AVAILABLE_TAB);

         

    log('Call Process Lines');

    PROCESS_LINES(P_HUB_ID, L_AVAILABLE_TAB);

  

    log('Call Generate Plan Exceptions');

    GENERATE_PLAN_EXCEPTIONS(P_HUB_ID);

  

  --If we decide on AUTO Committing lines this logic would go here.

    

    ALLOCATION_LOCK(P_HUB_ID, 'UNLOCK');

    log('Successfully End ECO AND ALLOCATION PROCESS');

    COMMIT;

   EXCEPTION

      WHEN OTHERS

      THEN 

         x_errbuff := 'ERROR: ' || SQLERRM;

         x_retcode := 2;

         log('Fatal Error Occured');

         log(x_errbuff);

         ROLLBACK;

         ALLOCATION_LOCK(P_HUB_ID, 'UNLOCK');

    END RUN_PROCESSOR;

                                   

END WWT_DGH_ECO_ALLOC_PROCESSOR;
/