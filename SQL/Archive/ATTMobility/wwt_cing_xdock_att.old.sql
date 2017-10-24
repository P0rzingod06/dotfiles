/* Formatted on 11/3/2014 11:13:13 AM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.Wwt_Cing_Xdock_Attr_Load
IS
   --
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_cing_xdock_attr_load.plb,v $, $Revision: 1.10 $, $Author: dupontb $, $Date: 2011/07/19 15:45:39 $
   /*
   PURPOSE :
           Load Xdock attribute data

    MODIFICATION HISTORY
    Person      Date        CHG#       Ver   Comments
    ---------   ------      --------   ----  ----------------------------------------------------
    knoblaub    08-14-06                      Gave Birth
    knoblaub    09-07-06                      File format changes
    knoblaub    11-16-06                      Added columns
    dupontb     05-SEP-2008                   Made modifications for GUC processing
    dupontb     05-NOV-2008                   Made changes to the SELECT INTO for update
    dupontb     11-MAY-2011 CHG18892   1.10   Added a new procedue to lookup email/alert dist list
   ***********************************************************************************************/

                                                                             /*
*******************************************************************************
*******************************************************************************
**Procedue Name       : UPDATE_ALERT_DISTRIBUTION_LIST                       **
**Description         : Proc will update an email dist list based on the     **
**                      filename from the upload. If no_data_found is        **
**                      then we will use a default dist list. We will use    **
**                      the frolic log table.                                **
*******************************************************************************
*******************************************************************************
                                                                             */
   PROCEDURE update_alert_distribution_list
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_update_dist_list   VARCHAR2 (250);
      l_orig_file_name     VARCHAR2 (100);
      l_orig_file_owner    VARCHAR2 (100);
      l_log_id             NUMBER;
   BEGIN
      l_orig_file_name := wwt_upload_generic.g_tokens ('ORIGINAL_FILE_NAME');
      l_orig_file_owner := wwt_upload_generic.g_tokens ('FILE_OWNER');
      WWT_UPLOAD_GENERIC.LOG (2, 'ORIGINAL_FILE_NAME: ' || l_orig_file_name);
      WWT_UPLOAD_GENERIC.LOG (2, 'FILE_OWNER: ' || l_orig_file_owner);

      -- Creating Email DL based on orig filename from upload
      BEGIN
         WWT_UPLOAD_GENERIC.LOG (2, 'before distribution list update');

         UPDATE wwt_frolic_status_log
            SET email_user = l_orig_file_owner
          WHERE     1 = 1
                AND source_name = 'CINGULAR XDOCK'
                AND SUBSTR (file_location, 25) = l_orig_file_name
                AND status = 'PROCESSING';

         COMMIT;

         WWT_UPLOAD_GENERIC.LOG (
            1,
               'after distribution list update. dist list = '
            || l_orig_file_owner);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               2,
               'In NO DATA FOUND, no need to do anything. We will just use the DL in from GUC');
      END;
   END update_alert_distribution_list;

   /*--------------------------------------------------------------------------------
          Procedure Name: main

          Description:This Proc will insert data into wwt_cing_xdock_attr or
                      update the existing data.

     --------------------------------------------------------------------------------*/
   PROCEDURE main (x_errbuff       OUT VARCHAR2,
                   x_retcode       OUT VARCHAR2,
                   p_filename   IN     VARCHAR2)
   IS
      l_table_rec   wwt_cing_xdock_attr%ROWTYPE;

      CURSOR c_load_data
      IS
         SELECT callout_line,
                tbuy_so,
                att_item,
                callout,
                project_number,
                partial_qty_on_hand,
                market_reported_qty_on_hand,
                specific_reason_not_deployed,
                residual_material_on_hand,
                planned_deployment_date,
                actual_deployment_date,
                qty_for_reloc_by_inv_plan,
                submit_rma,
                comments
           FROM wwt_cing_xdock_attr_ext;
   BEGIN
      x_retcode := 0;
      x_errbuff := NULL;

      /* Added this new procedure so it will take the email address stored on
         frolic log table in column fileOwner and overwrite the GUC email on
         the frolic log table email_user */
      update_alert_distribution_list ();


      FOR i IN c_load_data
      LOOP
         BEGIN
            INSERT INTO wwt_cing_xdock_attr (ID,
                                             tbuy_so,
                                             manu_no,
                                             ceq_no,
                                             callout_line_number,
                                             partial_qty_on_hand,
                                             market_reported_qty_on_hand,
                                             specific_reason_not_deployed,
                                             planned_deployment_date,
                                             actual_deployment_date,
                                             qty_used_for_reallocation_ip,
                                             submit_rma,
                                             comments,
                                             residual_material_onhand,
                                             attribute1,
                                             attribute2,
                                             attribute3,
                                             attribute4,
                                             attribute5,
                                             attribute6,
                                             attribute7,
                                             attribute8,
                                             attribute9,
                                             attribute10,
                                             filename,
                                             creation_date,
                                             created_by,
                                             last_update_date,
                                             last_updated_by)
                    VALUES (
                              wwt_cing_xdock_attr_s1.NEXTVAL,
                              i.tbuy_so,
                              i.callout,
                              i.att_item,
                              i.callout_line,
                              DECODE (i.partial_qty_on_hand,
                                      -9999999, NULL,
                                      i.partial_qty_on_hand),
                              DECODE (i.market_reported_qty_on_hand,
                                      -9999999, NULL,
                                      i.market_reported_qty_on_hand),
                              DECODE (i.specific_reason_not_deployed,
                                      'NULL', NULL,
                                      i.specific_reason_not_deployed),
                              DECODE (
                                 i.planned_deployment_date,
                                 TO_DATE ('01-JAN-1900', 'DD-MON-YYYY'), NULL,
                                 i.planned_deployment_date),
                              DECODE (
                                 i.actual_deployment_date,
                                 TO_DATE ('01-JAN-1900', 'DD-MON-YYYY'), NULL,
                                 i.actual_deployment_date),
                              DECODE (i.qty_for_reloc_by_inv_plan,
                                      -9999999, NULL,
                                      i.qty_for_reloc_by_inv_plan),
                              DECODE (i.submit_rma,
                                      'NULL', NULL,
                                      i.submit_rma),
                              DECODE (i.comments, 'NULL', NULL, i.comments),
                              DECODE (i.residual_material_on_hand,
                                      'NULL', NULL,
                                      i.residual_material_on_hand),
                              DECODE (i.project_number,
                                      'NULL', NULL,
                                      i.project_number),
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              p_filename,
                              SYSDATE,
                              -1,
                              SYSDATE,
                              -1);
         EXCEPTION
            --Data already exisits, archive data before updating
            WHEN DUP_VAL_ON_INDEX
            THEN
               l_table_rec := NULL;

               SELECT *
                 INTO l_table_rec
                 FROM wwt_cing_xdock_attr
                WHERE     tbuy_so = i.tbuy_so
                      AND manu_no = i.callout
                      AND ceq_no = i.att_item
                      AND NVL (callout_line_number, 'NULL') =
                             NVL (i.callout_line, 'NULL');

               -- Trigger apps.wwt_cing_xdock_attr_bru handling archive logic on UPDATE
               UPDATE wwt_cing_xdock_attr
                  SET filename = p_filename,
                      last_update_date = SYSDATE,
                      last_updated_by = -1,
                      partial_qty_on_hand =
                         DECODE (i.partial_qty_on_hand,
                                 NULL, partial_qty_on_hand,
                                 -9999999, NULL,
                                 i.partial_qty_on_hand),
                      market_reported_qty_on_hand =
                         DECODE (i.market_reported_qty_on_hand,
                                 NULL, market_reported_qty_on_hand,
                                 -9999999, NULL,
                                 i.market_reported_qty_on_hand),
                      specific_reason_not_deployed =
                         DECODE (i.specific_reason_not_deployed,
                                 NULL, specific_reason_not_deployed,
                                 'NULL', NULL,
                                 i.specific_reason_not_deployed),
                      planned_deployment_date =
                         DECODE (
                            i.planned_deployment_date,
                            NULL, planned_deployment_date,
                            TO_DATE ('01-JAN-1900', 'DD-MON-YYYY'), NULL,
                            i.planned_deployment_date),
                      actual_deployment_date =
                         DECODE (
                            i.actual_deployment_date,
                            NULL, actual_deployment_date,
                            TO_DATE ('01-JAN-1900', 'DD-MON-YYYY'), NULL,
                            i.actual_deployment_date),
                      qty_used_for_reallocation_ip =
                         DECODE (i.qty_for_reloc_by_inv_plan,
                                 NULL, i.qty_for_reloc_by_inv_plan,
                                 -9999999, NULL,
                                 i.qty_for_reloc_by_inv_plan),
                      submit_rma =
                         DECODE (i.submit_rma,
                                 NULL, submit_rma,
                                 'NULL', NULL,
                                 i.submit_rma),
                      comments =
                         DECODE (i.comments,
                                 NULL, comments,
                                 'NULL', NULL,
                                 i.comments),
                      residual_material_onhand =
                         DECODE (i.residual_material_on_hand,
                                 NULL, i.residual_material_on_hand,
                                 'NULL', NULL,
                                 i.residual_material_on_hand),
                      attribute1 =
                         DECODE (i.project_number,
                                 NULL, i.project_number,
                                 'NULL', NULL,
                                 i.project_number),
                      attribute2 = attribute2,
                      attribute3 = attribute3,
                      attribute4 = attribute4,
                      attribute5 = attribute5,
                      attribute6 = attribute6,
                      attribute7 = attribute7,
                      attribute8 = attribute8,
                      attribute9 = attribute9,
                      attribute10 = attribute10
                WHERE ID = l_table_rec.ID;
            WHEN OTHERS
            THEN
               wwt_upload_generic.LOG (
                  3,
                     'DATA INSERT Error: '
                  || TO_CHAR (SQLCODE)
                  || ': '
                  || SQLERRM);
               x_retcode := 2;
               x_errbuff := 'Exit out of Loop. Encountered Error';
               EXIT;
         END;
      END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuff :=
            ('DATA Error: ' || TO_CHAR (SQLCODE) || ': ' || SQLERRM);
   END main;
END Wwt_Cing_Xdock_Attr_Load;
/
