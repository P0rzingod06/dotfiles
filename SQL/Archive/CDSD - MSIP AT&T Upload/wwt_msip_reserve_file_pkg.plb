/* Formatted on 1/12/2015 10:29:08 AM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.wwt_msip_reserve_file_pkg
AS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_msip_reserve_file_pkg.plb,v $, $Revision: 1.1 $, $Author: gassertm $, $Date: 2014/10/03 10:04:14 $
                                                                             /*
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Package Name        : WWT_MSIP_RESERVE_FILE                                --
--Description         : This package is called by msip reserve file upload   --
--===========================================================================--
-- Developer   Ver   Date        RFC       Description                       --
--===========================================================================--
-- Gassertm    1.1  11/18/2014  CHG33211  Creation                           --
-- Gassertm    1.2  01/15/2015  CHG33785  Altered change number in comments  --
--                                        and added log message in           --
--                                        GET_VALID_PROJECT                  --
-------------------------------------------------------------------------------
                                                                             */
   --Global Variables

   TYPE g_invalid_project_rectype IS RECORD (invalid_project VARCHAR2 (35));

   TYPE g_invalid_project_tabtype IS TABLE OF g_invalid_project_rectype;

   CURSOR G_INVALID_PROJECTS_CUR
   IS
      SELECT attribute1
        FROM WWT_LOOKUPS_ACTIVE_V
       WHERE 1 = 1 AND lookup_type = 'WWT_MSIP_RESERVE_INVALID_PROJECTS';

   g_invalid_project_tab   g_invalid_project_tabtype;

   /*
*****************************************************************************************

   Function name: GET_VALID_PROJECT

   Description: Return true if given project is valid, compared to invalid projects in
                WWT_MSIP_RESERVE_INVALID_PROJECTS lookup.

 *****************************************************************************************
 */

   FUNCTION GET_VALID_PROJECT (P_PROJECT IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_valid_project   BOOLEAN;
   BEGIN
      BEGIN
         --initialize to true
         l_valid_project := TRUE;

         FOR i IN 1 .. g_invalid_project_tab.COUNT
         LOOP
            IF P_PROJECT = g_invalid_project_tab (i).invalid_project
            THEN
               l_valid_project := FALSE;

               wwt_upload_generic.LOG (
                  1,
                  'Bad project name found: ' || p_project);
            END IF;
         END LOOP i;

         IF P_PROJECT IS NULL OR P_PROJECT = 'UNDEFINED'
         THEN
            l_valid_project := FALSE;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            wwt_upload_generic.LOG (
               1,
                  'ERROR while processing file - '
               || TO_CHAR (SQLCODE)
               || ' : '
               || SQLERRM
               || ' with project: '
               || P_PROJECT);

            l_valid_project := FALSE;
      END;

      RETURN l_valid_project;
   END;

   /*
  *****************************************************************************************

     Function name: GET_VALID_INPUT

     Description: Return true if given input is valid.

   *****************************************************************************************
   */

   FUNCTION GET_VALID_INPUT (P_MFG_PART_NUMBER     IN VARCHAR2,
                             P_HARDWARE_MODEL      IN VARCHAR2,
                             P_PROJECT             IN VARCHAR2,
                             P_RESERVED_QUANTITY   IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_valid_input   BOOLEAN;
   BEGIN
      BEGIN
         --initialize to true
         l_valid_input := TRUE;

         IF P_MFG_PART_NUMBER IS NULL OR P_MFG_PART_NUMBER = 'UNDEFINED'
         THEN
            l_valid_input := FALSE;
         ELSIF P_HARDWARE_MODEL IS NULL OR P_HARDWARE_MODEL = 'UNDEFINED'
         THEN
            l_valid_input := FALSE;
         ELSIF GET_VALID_PROJECT (P_PROJECT) = FALSE
         THEN
            l_valid_input := FALSE;
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            wwt_upload_generic.LOG (
               1,
                  'ERROR while processing file - '
               || TO_CHAR (SQLCODE)
               || ' : '
               || SQLERRM
               || ' in record :'
               || P_MFG_PART_NUMBER
               || ' , '
               || P_PROJECT
               || ' , '
               || P_HARDWARE_MODEL);

            l_valid_input := FALSE;
      END;

      RETURN l_valid_input;
   END;

                                                                              /*
******************************************************************************
*******************************************************************************
**Procedure Name      : MAIN                                                 **
**Description         : Retrieve file from msip_reserve_file ftp folder-     **
**                      guc source id 230. Update reserve quantity in msip   **
**                      item inventory table with quantity in uploaded file. **
**                      If record in file does not have match in table,      **
**                      throw out record.                                    **
*******************************************************************************
*******************************************************************************
                                                                             */

   PROCEDURE MAIN (x_retcode       OUT NUMBER,
                   x_errbuff       OUT VARCHAR2,
                   p_filename   IN     VARCHAR2,
                   p_username   IN     VARCHAR2)
   IS
      CURSOR MSIP_RESERVED_QUANTITY_CUR
      IS
         SELECT TRIM (mfg_part_number) mfg_part_number,
                TRIM (hardware_model) hardware_model,
                TRIM (reserved_quantity) reserved_quantity,
                TRIM (project) project
           FROM WWT_MSIP_RESERVED_QUANTITY_EXT;

      l_user_id                  NUMBER;
      l_ldap_user_id             VARCHAR (30);
      l_duplicate_record_count   NUMBER;
      l_msip_id                  NUMBER;
      l_revision                 NUMBER;
      l_temp_reserved_quantity   NUMBER;
      l_frolic_start_time        DATE;
      l_last_update_date         DATE;
      l_inventory_quantity       NUMBER;
      l_outstanding_quantity     NUMBER;
      l_min_level_quantity       NUMBER;
      l_max_level_quantity       NUMBER;
      l_reserved_quantity        NUMBER;
      l_frolic_source_name       VARCHAR (22) := 'MSIP RESERVED QUANTITY';
   BEGIN
      -- initialize to 0 - no error.
      x_retcode := 0;

      OPEN G_INVALID_PROJECTS_CUR;

      FETCH G_INVALID_PROJECTS_CUR BULK COLLECT INTO g_invalid_project_tab;

      CLOSE G_INVALID_PROJECTS_CUR;

      wwt_upload_generic.LOG (
         0,
            'PARAMETERS: filename='
         || p_filename
         || ' / username='
         || p_username);

      l_user_id :=
         wwt_util_get_user_id.GET_RUNTIME_USER_ID (UPPER (p_username));

      --If user_id is -1(anonymous), we want user id to show WWT_Upload instead.
      IF l_user_id = -1
      THEN
         l_user_id := wwt_util_get_user_id.GET_RUNTIME_USER_ID ('WWT_UPLOAD');
      END IF;

      wwt_upload_generic.LOG (
         0,
         'Retrieved ' || l_user_id || ' from ' || p_username);

      wwt_upload_generic.LOG (0, 'Beginning external table loop');

     <<EXTERNAL_TABLE_LOOP>>
      FOR MSIP_RESERVED_QUANTITY_REC IN MSIP_RESERVED_QUANTITY_CUR
      LOOP
         BEGIN
            IF MSIP_RESERVED_QUANTITY_REC.reserved_quantity >= 0
            THEN
               l_reserved_quantity :=
                  MSIP_RESERVED_QUANTITY_REC.reserved_quantity;

               IF GET_VALID_INPUT (
                     MSIP_RESERVED_QUANTITY_REC.mfg_part_number,
                     MSIP_RESERVED_QUANTITY_REC.hardware_model,
                     MSIP_RESERVED_QUANTITY_REC.project,
                     MSIP_RESERVED_QUANTITY_REC.reserved_quantity)
               THEN
                  wwt_upload_generic.LOG (
                     0,
                        'Part Number '
                     || MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                     || ' is in external loop');

                  SELECT COUNT (*)
                    INTO l_duplicate_record_count
                    FROM apps.WWT_MSIP_ITEM_INVENTORY_V
                   WHERE     hardware_model =
                                MSIP_RESERVED_QUANTITY_REC.hardware_model
                         AND mfg_part_number =
                                MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                         AND project = MSIP_RESERVED_QUANTITY_REC.project;

                  IF l_duplicate_record_count != 0
                  THEN
                     wwt_upload_generic.LOG (
                        0,
                           l_duplicate_record_count
                        || ' records found in table for following record : '
                        || MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                        || ' , '
                        || MSIP_RESERVED_QUANTITY_REC.project
                        || ' , '
                        || MSIP_RESERVED_QUANTITY_REC.hardware_model
                        || '.  Inserting record into table.');

                     --Select msip_id and revision number from view to match real table.
                     --Order by revision date in order to retrieve latest revision.
                     SELECT *
                       INTO l_msip_id, l_revision, l_last_update_date
                       FROM (  SELECT MSIP_ID, REVISION, LAST_UPDATE_DATE
                                 FROM apps.wwt_msip_item_inventory_v
                                WHERE     hardware_model =
                                             MSIP_RESERVED_QUANTITY_REC.hardware_model
                                      AND mfg_part_number =
                                             MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                                      AND project =
                                             MSIP_RESERVED_QUANTITY_REC.project
                             ORDER BY revision DESC)
                      WHERE ROWNUM = 1;

                     SELECT NVL (RESERVE_QUANTITY, 0),
                            INVENTORY_QUANTITY,
                            OUTSTANDING_QUANTITY,
                            MIN_LEVEL_QUANTITY,
                            MAX_LEVEL_QUANTITY
                       INTO l_temp_reserved_quantity,
                            l_inventory_quantity,
                            l_outstanding_quantity,
                            l_min_level_quantity,
                            l_max_level_quantity
                       FROM apps.wwt_msip_item_inventory
                      WHERE msip_id = l_msip_id AND revision = l_revision;

                     --Check if reserve_quantity is already populated.  If so it could have come from a previous file or the current file.  If it came from current file add quantities, else insert new quantity.
                     IF l_temp_reserved_quantity > 0
                     THEN
                        SELECT *
                          INTO l_frolic_start_time
                          FROM (  SELECT start_time
                                    FROM apps.wwt_frolic_status_log
                                   WHERE     1 = 1
                                         AND source_name = l_frolic_source_name
                                ORDER BY creation_date DESC)
                         WHERE ROWNUM = 1;

                        IF l_last_update_date >= l_frolic_start_time
                        THEN
                           wwt_upload_generic.LOG (
                              0,
                                 'Record with msip_id = '
                              || l_msip_id
                              || ' and revision = '
                              || l_revision
                              || ' has already been encountered in current file.  Adding to existing reserve quantity in table.');

                           l_reserved_quantity :=
                              l_reserved_quantity + l_temp_reserved_quantity;
                        END IF;
                     END IF;

                     wwt_upload_generic.LOG (
                        0,
                           'Inserting new record in table with msip_id = '
                        || l_msip_id
                        || ' and revision = '
                        || l_revision
                        || ' .');

                     INSERT
                       INTO apps.wwt_msip_item_inventory (
                               INVENTORY_ID,
                               MSIP_ID,
                               REVISION,
                               INVENTORY_QUANTITY,
                               OUTSTANDING_QUANTITY,
                               MIN_LEVEL_QUANTITY,
                               MAX_LEVEL_QUANTITY,
                               REASON_CODE,
                               CREATED_BY,
                               CREATION_DATE,
                               LAST_UPDATED_BY,
                               LAST_UPDATE_DATE,
                               REQUEST_ID,
                               LAST_UPDATE_REQUEST_ID,
                               LOGIN_ID,
                               LAST_UPDATE_LOGIN_ID,
                               LDAP_CREATED_BY,
                               LDAP_LAST_UPDATED_BY,
                               RELEASE_TIMESTAMP,
                               NOTES,
                               RESERVE_QUANTITY)
                     VALUES (partner_admin.wwt_msip_item_inventory_s.NEXTVAL,
                             l_msip_id,
                             l_revision + 1,
                             l_inventory_quantity,
                             l_outstanding_quantity,
                             l_min_level_quantity,
                             l_max_level_quantity,
                             'RESERVE_UPLOAD',
                             l_user_id,
                             SYSDATE,
                             l_user_id,
                             SYSDATE,
                             -1,
                             -1,
                             -1,
                             -1,
                             NULL,
                             NULL,
                             NULL,
                             NULL,
                             MSIP_RESERVED_QUANTITY_REC.reserved_quantity);

                     wwt_upload_generic.LOG (
                        0,
                           'Insert msip_id = '
                        || l_msip_id
                        || ' and revision = '
                        || l_revision
                        || ' was successful.');
                  ELSE
                     wwt_upload_generic.LOG (
                        1,
                           'No Data Found in MSIP table for '
                        || MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                        || ' , '
                        || MSIP_RESERVED_QUANTITY_REC.project
                        || ' , '
                        || MSIP_RESERVED_QUANTITY_REC.hardware_model
                        || '.  Throwing out record.');
                  END IF;
               ELSE
                  wwt_upload_generic.LOG (
                     1,
                        'End of file found or bad record found.  Throwing out record: '
                     || MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                     || ' , '
                     || MSIP_RESERVED_QUANTITY_REC.project
                     || ' , '
                     || MSIP_RESERVED_QUANTITY_REC.hardware_model);
               END IF;
            ELSE
               --Reserve quantity can never be less than 0.  If it is upload should fail.
               X_ERRBUFF :=
                     'Encountered negative reserve quantity with following record: '
                  || MSIP_RESERVED_QUANTITY_REC.mfg_part_number
                  || ' , '
                  || MSIP_RESERVED_QUANTITY_REC.project
                  || ' , '
                  || MSIP_RESERVED_QUANTITY_REC.hardware_model
                  || '.  This is bad and caused the upload to fail.';
               X_RETCODE := 2;
            END IF;
         END;
      END LOOP EXTERNAL_TABLE_LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_errbuff :=
               'ERROR while processing file - '
            || TO_CHAR (SQLCODE)
            || ' : '
            || SQLERRM;
         x_retcode := 2;
   END MAIN;
END wwt_msip_reserve_file_pkg;
/