/* Formatted on 1/13/2015 10:23:39 AM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.WWT_UPLOAD_SO_UPDATE
IS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_upload_so_update.plb,v $, $Revision: 1.2 $, $Author: lawtons $, $Date: 2014/08/22 19:05:54 $
   /**************************************************************************************************

      NAME:       APPS.WWT_UPLOAD_SO_UPDATE

      PURPOSE:   To process Sales Order updates from the file dropped.

      REVISIONS:
      Ver        Date           Author           Description
      ---------  ------------  ---------------  ------------------------------------
      1.2        30-JUL-2014    lawtons         Added ability to process PROMISE_DATE
      1.1        15-MAY-2014    dupontb         Created this package for STRY0286178/CHG30803
   ***************************************************************************************************/


   /************************************************************************************************
   ** Procedue Name  : UPDATE_FROLIC_LOG_RECIPIENT
   ** Description         : Retrieves userid for use in table updates and the email address for update of log recipients
   ************************************************************************************************/
   PROCEDURE UPDATE_FROLIC_LOG_RECIPIENT (x_retcode          OUT VARCHAR2,
                                          x_errbuff          OUT VARCHAR2,
                                          x_orig_file_name   OUT VARCHAR2,
                                          x_user_id          OUT NUMBER)
   IS
      l_email_address   APPLSYS.FND_USER.email_address%TYPE;
      l_file_location   VARCHAR2 (50);
      l_pid_id          NUMBER;
   BEGIN
      x_retcode := 0;

      WWT_UPLOAD_GENERIC.LOG (
         0,
         '****** FILE_OWNER = ' || wwt_upload_generic.g_tokens ('FILE_OWNER'));

      --    Get user_id from function using the FILE_OWNER token
      x_user_id :=
         wwt_util_user.get_runtime_user_id (
            wwt_upload_generic.g_tokens ('FILE_OWNER'),
            'WWT_UPLOAD');

      WWT_UPLOAD_GENERIC.LOG (0, '****** x_user_id = ' || x_user_id);

      --    get email address of the user who dropped the file, using user id returned above
      BEGIN
         SELECT email_address
           INTO l_email_address
           FROM APPLSYS.FND_USER
          WHERE 1 = 1 AND user_id = x_user_id;

         WWT_UPLOAD_GENERIC.LOG (
            0,
            '****** l_email_address = ' || l_email_address);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            WWT_UPLOAD_GENERIC.LOG (0, 'Could not find User: ' || x_user_id);
            x_retcode := 1;
            x_errbuff := 'Could not find User: ' || x_user_id;
         WHEN OTHERS
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               0,
                  'Unknown error when querying table APPLSYS.FND_USER using user_id : '
               || x_user_id);
            x_retcode := 2;
            x_errbuff :=
               (   'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.UPDATE_FROLIC_LOG_RECIPIENT when querying table APPLSYS.FND_USER using user_id = : '
                || x_user_id
                || SUBSTR (SQLERRM, 1, 150));
      END;

      --      if the user is not found above, we cannot update the log distribution list
      IF x_retcode < 1
      THEN
         BEGIN
            --              retireve file name being processed
            x_orig_file_name :=
               wwt_upload_generic.g_tokens ('ORIGINAL_FILE_NAME');
            WWT_UPLOAD_GENERIC.LOG (
               0,
               '****** x_orig_file_name = ' || x_orig_file_name);

            l_pid_id := wwt_upload_generic.g_tokens ('PID');
            WWT_UPLOAD_GENERIC.LOG (0, '****** l_pid_id = ' || l_pid_id);

            --            update the frolic log with the email address of the user who dropped the file currently being processed
            UPDATE wwt_frolic_status_log
               SET email_user = email_user || l_email_address
             WHERE     1 = 1
                   AND source_name = 'SALES ORDER UPDATE'
                   AND log_id = l_pid_id
                   AND status = 'PROCESSING';
         EXCEPTION
            WHEN OTHERS
            THEN
               WWT_UPLOAD_GENERIC.LOG (
                  2,
                  'Unable to update email_user on table wwt_frolic_status_log');
               x_retcode := 2;
               x_errbuff :=
                  (   'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.UPDATE_FROLIC_LOG_RECIPIENT when updating email_user on table wwt_frolic_status_log'
                   || SUBSTR (SQLERRM, 1, 150));
         END;
      END IF;
   END UPDATE_FROLIC_LOG_RECIPIENT;

    /************************************************************************************************
** Procedue Name  : LOAD_EXTERNAL_DATA
** Description         : Loads the raw external file into wwt_so_update_stg.  Rows in this table are saved without update,
**                            exception for the status and error message fields.
************************************************************************************************/
   PROCEDURE LOAD_EXTERNAL_DATA (x_retcode             OUT VARCHAR2,
                                 x_errbuff          IN OUT VARCHAR2,
                                 x_file_id             OUT NUMBER,
                                 p_orig_file_name   IN     VARCHAR2,
                                 p_user_id          IN     NUMBER)
   IS
   BEGIN
      x_retcode := 0;

      SELECT PARTNER_ADMIN.WWT_SO_UPDATE_STG_S.NEXTVAL
        INTO x_file_id
        FROM DUAL;

      --      Insert external table data into the WWT_SO_UPDATE_STG table
      INSERT INTO partner_admin.wwt_so_update_stg
         SELECT x_file_id                                              --SO_ID
                         ,
                sales_order_num                              --SALES_ORDER_NUM
                               ,
                TO_DATE (ship_date, 'MM/DD/YYYY')                  --SHIP_DATE
                                                 ,
                'U'                                -- STATUS (U = unprocessed)
                   ,
                NULL                                              -- ERROR_MSG
                    ,
                SYSDATE                                       -- CREATION_DATE
                       ,
                p_user_id                                        -- CREATED_BY
                         ,
                SYSDATE                                    -- LAST_UPDATE_DATE
                       ,
                p_user_id                                   -- LAST_UPDATED_BY
                         ,
                TO_DATE (promise_date, 'MM/DD/YYYY')            --PROMISE_DATE
           FROM apps.wwt_so_update_ext;
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            2,
            'ERROR in LOAD_EXTERNAL_DATA: ' || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
               x_errbuff
            || (   'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.LOAD_EXTERNAL_DATA: '
                || SUBSTR (SQLERRM, 1, 150));
   END LOAD_EXTERNAL_DATA;

    /************************************************************************************************
** Procedue Name  : VALIDATE_UPLOAD_DATA
** Description         : Validates the rows loaded from the current file and sets status accordingly.
**                            All rows are initially loaded with a status of 'U'.  If an error is found,
                               status is set to 'E' else it stays in a status of 'U' and then the API process
                               will grab all records in an unprocessed status.
************************************************************************************************/
   PROCEDURE VALIDATE_UPLOAD_DATA (p_file_id   IN     NUMBER,
                                   p_user_id   IN     NUMBER,
                                   x_retcode      OUT VARCHAR2,
                                   x_errbuff   IN OUT VARCHAR2)
   IS
   BEGIN
      x_retcode := 0;

      -- Upate error status and message for null ship date
      UPDATE apps.wwt_so_update_stg
         SET status = 'E',
             error_msg = ' - ship date is null',
             last_update_date = SYSDATE,
             last_updated_by = p_user_id
       WHERE status IN ('U', 'E') AND ship_date IS NULL AND so_id = p_file_id;
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            0,
            'ERROR in VALIDATE_UPLOAD_DATA: ' || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
               'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.VALIDATE_UPLOAD_DATA: '
            || SUBSTR (SQLERRM, 1, 200);
   END VALIDATE_UPLOAD_DATA;


   /************************************************************************************************
   ** Procedue Name  : process_upload_file
   ** Description         : Uploads the SO data into a custom table PARTNER_ADMIN.WWT_SO_UPDATE_STG. This is called from GUC source 219
   ************************************************************************************************/
   PROCEDURE process_upload_file (x_retcode   OUT VARCHAR2,
                                  x_errbuff   OUT VARCHAR2)
   IS
      l_user_id          APPLSYS.FND_USER.user_id%TYPE;
      l_user_name        APPLSYS.FND_USER.user_name%TYPE;
      l_file_id          NUMBER;
      l_orig_file_name   VARCHAR2 (100);
   BEGIN
      x_retcode := 0;
      l_orig_file_name :=
         apps.wwt_upload_generic.g_tokens ('ORIGINAL_FILE_NAME');

      WWT_UPLOAD_GENERIC.LOG (
         0,
         '----------------------------------------------------------------');
      WWT_UPLOAD_GENERIC.LOG (0, '****** Starting WWT_SO_UPDATE_UPLOAD...');

      UPDATE_FROLIC_LOG_RECIPIENT (x_retcode,
                                   x_errbuff,
                                   l_orig_file_name,
                                   l_user_id);

      IF x_retcode < 2
      THEN
         WWT_UPLOAD_GENERIC.LOG (0, '****** processing LOAD_EXTERNAL_DATA');
         LOAD_EXTERNAL_DATA (x_retcode,
                             x_errbuff,
                             l_file_id,
                             l_orig_file_name,
                             l_user_id);
      END IF;

      IF x_retcode < 2
      THEN
         WWT_UPLOAD_GENERIC.LOG (0, '****** processing VALIDATE_UPLOAD_DATA');
         VALIDATE_UPLOAD_DATA (l_file_id,
                               l_user_id,
                               x_retcode,
                               x_errbuff);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            2,
               'ERROR in WWT_UPLOAD_SO_UPDATE.process_upload_file: '
            || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
               'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.process_upload_file: '
            || SUBSTR (SQLERRM, 1, 200);
   END process_upload_file;
END WWT_UPLOAD_SO_UPDATE;
/
