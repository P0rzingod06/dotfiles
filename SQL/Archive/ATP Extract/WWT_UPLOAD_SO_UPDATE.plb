/* Formatted on 5/5/2015 10:51:34 AM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.WWT_UPLOAD_SO_UPDATE
IS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_upload_so_update.plb,v $, $Revision: 1.5 $, $Author: gassertm $, $Date: 2015/01/28 19:16:56 $
   /**************************************************************************************************

      NAME:       APPS.WWT_UPLOAD_SO_UPDATE

      PURPOSE:   To process Sales Order updates from the file dropped.

      REVISIONS:
      Ver        Date           Author           Description
      ---------  ------------  ---------------  ------------------------------------
      1.1        15-MAY-2014    dupontb         Created this package for STRY0286178/CHG30803
      1.2        30-JUL-2014    lawtons         Added ability to process PROMISE_DATE
      1.3        28-JAN-2015    gassertm        Added function to check if order is a MSFT order.  If it is,
                                                add corresponding number of days to ship_Date and promise_date.
                                                STRY0146183/CHG32403.
      1.4       28-JAN-2015     gassertm        Missing comments.
      1.5       28-JAN-2015     gassertm        Change all schema owners to APPS.
      1.6       02-FEB-2015    gassertm        Added ROWNUM = 1 to salesrep_id query, so that it does not error
                                                when it return multiple rows.
      1.7       23-APR-2015   gassertm       Added function GET_MIN_SHIP_DATE.  Modified CALCULATE_SHIP_DATE to
                                                                 take into account request date and latest delivery date.  Then added logic
                                                                 to properly update arrival date.
   ***************************************************************************************************/

   /***************************************** GLOBAL VARIABLES **************************************/

   /************************************************************************************************
   ** Procedue Name  : UPDATE_FROLIC_LOG_RECIPIENT
   ** Description         : Retrieves userid for use in table updates and the email address for update of log recipients
   ************************************************************************************************/
   PROCEDURE UPDATE_FROLIC_LOG_RECIPIENT (x_retcode          OUT VARCHAR2,
                                          x_errbuff          OUT VARCHAR2,
                                          x_orig_file_name   OUT VARCHAR2,
                                          x_user_id          OUT NUMBER)
   IS
      l_email_address   APPS.FND_USER.email_address%TYPE;
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
           FROM APPS.FND_USER
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
                  'Unknown error when querying table APPS.FND_USER using user_id : '
               || x_user_id);
            x_retcode := 2;
            x_errbuff :=
               (   'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.UPDATE_FROLIC_LOG_RECIPIENT when querying table APPS.FND_USER using user_id = : '
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
   PROCEDURE LOAD_EXTERNAL_DATA (x_retcode              OUT VARCHAR2,
                                 x_errbuff           IN OUT VARCHAR2,
                                 x_file_id              OUT NUMBER,
                                 x_ship_date         IN OUT DATE,
                                 x_promise_date      IN OUT DATE,
                                 x_sales_order_num   IN OUT NUMBER,
                                 p_orig_file_name    IN     VARCHAR2,
                                 p_user_id           IN     NUMBER)
   IS
   BEGIN
      x_retcode := 0;

      SELECT APPS.WWT_SO_UPDATE_STG_S.NEXTVAL INTO x_file_id FROM DUAL;

      --      Insert external table data into the WWT_SO_UPDATE_STG table

      INSERT INTO APPS.wwt_so_update_stg
           VALUES (x_file_id                                           --SO_ID
                            ,
                   x_sales_order_num                         --SALES_ORDER_NUM
                                    ,
                   x_ship_date                                     --SHIP_DATE
                              ,
                   'U'                             -- STATUS (U = unprocessed)
                      ,
                   NULL                                           -- ERROR_MSG
                       ,
                   SYSDATE                                    -- CREATION_DATE
                          ,
                   p_user_id                                     -- CREATED_BY
                            ,
                   SYSDATE                                 -- LAST_UPDATE_DATE
                          ,
                   p_user_id                                -- LAST_UPDATED_BY
                            ,
                   x_promise_date                               --PROMISE_DATE
                                 );
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
    ** Function Name  : GET_WORK_DATE
    ** Description    : Gets work date that is p_work_days away from p_start_date for the given org_id.
    ************************************************************************************************/

   FUNCTION GET_WORK_DATE (p_org_id            IN NUMBER,
                           p_start_date        IN DATE,
                           p_work_days_added   IN NUMBER)
      RETURN DATE
   IS
      l_curr_work_date   DATE := TO_DATE (p_start_date, 'DD-MON-YY');
      l_prev_work_date   DATE;
      l_final_date       DATE;
   BEGIN
      wwt_runtime_utilities.DEBUG (0, '****** org_id = ' || p_org_id);
      wwt_runtime_utilities.DEBUG (0, '****** start_date = ' || p_start_date);
      wwt_runtime_utilities.DEBUG (
         0,
         '****** work_days_added = ' || p_work_days_added);

      FOR l_counter IN 1 .. p_work_days_added
      LOOP
         --Assign previous workdate to current work date because we are retrieving the
         --next work date.
         l_prev_work_date := l_curr_work_date;

         l_curr_work_date :=
            mrp_calendar.next_work_day (p_org_id, 1, l_prev_work_date);

         --If input date is day before a holiday/weekend, function will return the same date instead of the following work day.
         --So we need to check if the returned work day is equal to the input date.  If so, add one day to the input date so the function
         -- will then properly return next work day(if input date is holiday/weekend, function will return next work day).
         IF l_curr_work_date = l_prev_work_date
         THEN
            l_curr_work_date :=
               mrp_calendar.next_work_day (p_org_id, 1, l_prev_work_date + 1);
         END IF;
      END LOOP;

      l_final_date := l_curr_work_date;

      RETURN l_final_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            2,
            'ERROR in GET_WORK_DATE: ' || SUBSTR (SQLERRM, 1, 200));
   END get_work_date;

   /************************************************************************************************
    ** Function Name  : GET_MIN_SHIP_DATE
    ** Description    : Take in sales order number and retrieve minimum ship date from given file.
    ************************************************************************************************/
   PROCEDURE GET_MIN_SHIP_DATE (p_sales_order_num    IN     NUMBER,
                                x_min_request_date      OUT DATE,
                                x_retcode               OUT VARCHAR2,
                                x_errbuff               OUT VARCHAR2)
   IS
   BEGIN
      --initialize recode
      x_retcode := 0;

      WWT_UPLOAD_GENERIC.LOG (
         0,
         '******p_sales_order_num = ' || p_sales_order_num);

      -- order dates for sales order number and take first date which will be the minimum date.
      SELECT TRUNC (MIN (oola.request_date))
        INTO x_min_request_date
        FROM apps.oe_order_headers_all ooha, apps.oe_order_lines_all oola
       WHERE     1 = 1
             AND OOHA.ORDER_NUMBER = p_sales_order_num
             AND oola.header_id = ooha.header_id;

      WWT_UPLOAD_GENERIC.LOG (
         0,
         '****** x_min_request_date = ' || x_min_request_date);
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            2,
               'ERROR in WWT_UPLOAD_SO_UPDATE.GET_MIN_SHIP_DATE: '
            || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
               'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.GET_MIN_SHIP_DATE: '
            || SUBSTR (SQLERRM, 1, 200);
   END;

   /************************************************************************************************
    ** Function Name  : CALCULATE_SHIP_DATE
    ** Description    : Calculate minimum ship date and retrieve latest delivery request date.  If dates are equal,
    **                        then make no changes.  If LDR > schedule, then update schedule date to LDR.
    **                        IF schedule_date > LDR, then update latest delivery date.
    ************************************************************************************************/
   PROCEDURE CALCULATE_SHIP_DATE (p_sales_order_num   IN     NUMBER,
                                  x_ship_date         IN OUT DATE,
                                  x_retcode           IN OUT NUMBER,
                                  x_errbuff           IN OUT VARCHAR2)
   IS
      l_min_ship_date                  DATE;
      l_latest_delivery_request_date   DATE;
      l_so_header_id                   NUMBER;
   BEGIN
      GET_MIN_SHIP_DATE (p_sales_order_num,
                         l_min_ship_date,
                         x_retcode,
                         x_errbuff);

      WWT_UPLOAD_GENERIC.LOG (0,
                              '******l_min_ship_date = ' || l_min_ship_date);

      BEGIN
         --if latest_delivery_request_date is null, then update to minimum request date from file.
         SELECT wshd.header_id,
                NVL (TO_DATE (wshd.attribute84, 'YYYY/MM/DD HH24:MI:SS'),
                     x_ship_date)
           INTO l_so_header_id, l_latest_delivery_request_date
           FROM apps.oe_order_headers_all ooha, APPS.WWT_SO_HEADERS_DFF wshd
          WHERE     1 = 1
                AND ooha.order_number = p_sales_order_num
                AND ooha.header_id = wshd.header_id;

         WWT_UPLOAD_GENERIC.LOG (
            0,
               '******l_latest_delivery_request_date = '
            || l_latest_delivery_request_date);
      EXCEPTION
         WHEN OTHERS
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               2,
                  'ERROR selecting latest_delivery_request_date in wwt_upload_so_update.calculate_request_date'
               || SUBSTR (SQLERRM, 1, 200));

            x_retcode := 2;
            x_errbuff := SUBSTR (SQLERRM, 1, 200);
      END;

      WWT_UPLOAD_GENERIC.LOG (0, '******x_ship_date = ' || x_ship_date);

      IF l_latest_delivery_request_date <> l_min_ship_date
      THEN
         -- Compare  to minimum request_date to lates delivery request date and handle appropriately.
         -- If two dates are equal, don't do anything.
         IF l_latest_delivery_request_date < x_ship_date
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               0,
               '******LDR < calc_ship_date.  Updating LDR to calc_ship_date.');

            WWT_SO_HEADER_DFF_UTILS.populate_wwt_so_header_dff (
               x_errbuf        => x_errbuff,
               x_retcode       => x_retcode,
               p_header_id     => l_so_header_id,
               p_attribute84   => TO_CHAR (x_ship_date,
                                           'YYYY/MM/DD HH24:MI:SS'));
         ---if ship_date is less than minimum request date then update min request date
         ELSIF x_ship_date < l_latest_delivery_request_date
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               0,
               '******calc_ship_date < LDR.  Updating calc_ship_date to LDR.');

            x_ship_date := l_latest_delivery_request_date;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            2,
               'ERROR in WWT_UPLOAD_SO_UPDATE.calculate_request_date: '
            || SUBSTR (SQLERRM, 1, 200));

         x_retcode := 2;
         x_errbuff := SUBSTR (SQLERRM, 1, 200);
   END;


   PROCEDURE UPDATE_MSFT_DATES (x_ship_date          IN OUT DATE,
                                x_promise_date       IN OUT DATE,
                                p_min_request_date   IN     DATE,
                                p_sales_order_num    IN     NUMBER,
                                x_retcode               OUT VARCHAR2,
                                x_errbuff               OUT VARCHAR2,
                                p_file_id            IN     NUMBER,
                                p_user_id            IN     NUMBER)
   IS
      l_org_id        NUMBER;
      l_salesrep_id   NUMBER;
      l_msft_order    NUMBER;
      l_days_added    VARCHAR2 (25);
   BEGIN
      x_retcode := 0;

      WWT_UPLOAD_GENERIC.LOG (
         0,
         '****** l_sales_order_num = ' || p_sales_order_num);
      WWT_UPLOAD_GENERIC.LOG (0, '****** l_ship_date = ' || x_ship_date);
      WWT_UPLOAD_GENERIC.LOG (0,
                              '****** l_promise_date = ' || x_promise_date);

      BEGIN
         SELECT DISTINCT mp.organization_id, ooha.salesrep_id
           INTO l_org_id, l_salesrep_id
           FROM apps.oe_order_headers_all ooha,
                apps.oe_order_lines_all oola,
                apps.mtl_parameters mp
          WHERE     ooha.header_id = oola.header_id
                AND ooha.order_number = p_sales_order_num
                AND mp.organization_id = oola.ship_from_org_id
                AND ROWNUM = 1;

         WWT_UPLOAD_GENERIC.LOG (0, '****** l_calendar_code = ' || l_org_id);
         WWT_UPLOAD_GENERIC.LOG (0,
                                 '****** l_salesrep_id = ' || l_salesrep_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               2,
                  'Unable to retrieve an org_id, organization_code, and salesrep_id for file_id : '
               || p_file_id);

            x_retcode := 2;
            x_errbuff := 'Error retrieving organization information';
         WHEN OTHERS
         THEN
            WWT_UPLOAD_GENERIC.LOG (
               2,
                  'ERROR in WWT_UPLOAD_SO_UPDATE.update_msft_date: '
               || SUBSTR (SQLERRM, 1, 200));
            x_retcode := 2;
            x_errbuff :=
                  'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.update_msft_date during organization information query: '
               || SUBSTR (SQLERRM, 1, 200);
      END;

      --Check to see if this is a Microsoft order.  If it is, then continue procedure.  Else we are done.
      --Returns 1 if it is a msft order, 0 if it isn't.
      SELECT COUNT (*)
        INTO l_msft_order
        FROM apps.wwt_lookups_active_v
       WHERE     1 = 1
             AND lookup_type = 'WWT_MICROSOFT_SALES_CHANNELS'
             AND attribute2 = l_salesrep_id;

      WWT_UPLOAD_GENERIC.LOG (0, '****** l_msft_order = ' || l_msft_order);

      --If this is not a microsoft order, then we don't need to do anything.
      IF l_msft_order = 1
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            0,
            '******Processing Microsoft order : ' || p_sales_order_num);

         BEGIN
            --Select number of days to add to promise_date and shipping_date according
            -- to lookup.
            SELECT DISTINCT wl.attribute12
              INTO l_days_added
              FROM apps.wwt_lookups wl,
                   apps.oe_order_headers_all ooha,
                   APPS.HZ_CUST_ACCT_SITES_ALL HCASA,
                   APPS.HZ_PARTY_SITES HPS,
                   APPS.HZ_LOCATIONS HL,
                   APPS.HZ_CUST_SITE_USES_ALL HCSUA,
                   apps.hz_partIes HP,
                   apps.hz_cust_accounts hca
             WHERE     1 = 1
                   AND HCSUA.CUST_ACCT_SITE_ID = HCASA.CUST_ACCT_SITE_ID
                   AND HCASA.PARTY_SITE_ID = HPS.PARTY_SITE_ID
                   AND HPS.LOCATION_ID = HL.LOCATION_ID
                   AND hp.party_id = hps.party_id
                   AND hp.party_id = hca.party_id
                   AND HCSUA.site_use_code = 'SHIP_TO'
                   AND wl.lookup_type = 'WWT_OXBOW_SOURCING_RULES'
                   AND wl.attribute2 = hl.country
                   AND wl.attribute12 IS NOT NULL
                   AND hcsua.site_use_id = ooha.ship_to_org_id
                   AND ooha.order_number = p_sales_order_num;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               --when null set to 0 days
               WWT_UPLOAD_GENERIC.LOG (
                  0,
                     '******No days added because no match found in lookup for sales order: '
                  || p_sales_order_num);

               l_days_added := 0;
            WHEN OTHERS
            THEN
               WWT_UPLOAD_GENERIC.LOG (
                  2,
                     'ERROR in WWT_UPLOAD_SO_UPDATE.update_msft_date: '
                  || SUBSTR (SQLERRM, 1, 200));
               x_retcode := 2;
               x_errbuff :=
                     'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.update_msft_date during days added query: '
                  || SUBSTR (SQLERRM, 1, 200);
         END;

         WWT_UPLOAD_GENERIC.LOG (0, '******l_days_added: ' || l_days_added);

         IF l_days_added > 0
         THEN
            x_ship_date :=
               GET_WORK_DATE (l_org_id,
                              x_ship_date,
                              TO_NUMBER (l_days_added));

            WWT_UPLOAD_GENERIC.LOG (
               0,
               '******updated g_ship_date: ' || x_ship_date);

            x_promise_date :=
               GET_WORK_DATE (l_org_id,
                              x_promise_date,
                              TO_NUMBER (l_days_added));

            WWT_UPLOAD_GENERIC.LOG (
               0,
               '******updated g_promise_date: ' || x_promise_date);
         END IF;

         --Compare request date and latest delivery request date. Then handle appropriately.
         CALCULATE_SHIP_DATE (p_sales_order_num,
                              x_ship_date,
                              x_retcode,
                              x_errbuff);
      ELSE
         WWT_UPLOAD_GENERIC.LOG (
            0,
               '******This order is not a Microsoft order: '
            || p_sales_order_num);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         WWT_UPLOAD_GENERIC.LOG (
            2,
               'ERROR in WWT_UPLOAD_SO_UPDATE.UPDATE_MSFT_DATES: '
            || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
               'UNKNOWN ERROR encountered during WWT_UPLOAD_SO_UPDATE.UPDATE_MSFT_DATES: '
            || SUBSTR (SQLERRM, 1, 200);
   END;

   /************************************************************************************************
   ** Procedue Name  : process_upload_file
   ** Description         : Uploads the SO data into a custom table PARTNER_ADMIN.WWT_SO_UPDATE_STG. This is called from GUC source 219
   ************************************************************************************************/
   PROCEDURE process_upload_file (x_retcode   OUT VARCHAR2,
                                  x_errbuff   OUT VARCHAR2)
   IS
      CURSOR l_so_update_ext_cur
      IS
         SELECT * FROM wwt_so_update_ext;

      l_user_id            APPS.FND_USER.user_id%TYPE;
      l_user_name          APPS.FND_USER.user_name%TYPE;
      l_file_id            NUMBER;
      l_orig_file_name     VARCHAR2 (100);
      l_sales_order_num    NUMBER;
      l_ship_date          VARCHAR2 (50);
      l_promise_date       VARCHAR2 (50);
      l_min_request_date   VARCHAR2 (50);
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

      FOR l_so_update_ext_rec IN l_so_update_ext_cur
      LOOP
         BEGIN
            l_sales_order_num := l_so_update_ext_rec.SALES_ORDER_NUM;
            l_ship_date :=
               TO_DATE (l_so_update_ext_rec.SHIP_DATE, 'MM/DD/YYYY');
            l_promise_date :=
               TO_DATE (l_so_update_ext_rec.PROMISE_DATE, 'MM/DD/YYYY');

            IF x_retcode < 2
            THEN
               WWT_UPLOAD_GENERIC.LOG (0,
                                       '****** processing UPDATE_MSFT_DATES');
               UPDATE_MSFT_DATES (l_ship_date,
                                  l_promise_date,
                                  l_min_request_date,
                                  l_sales_order_num,
                                  x_retcode,
                                  x_errbuff,
                                  l_file_id,
                                  l_user_id);
            END IF;

            IF x_retcode < 2
            THEN
               WWT_UPLOAD_GENERIC.LOG (
                  0,
                  '****** processing LOAD_EXTERNAL_DATA');
               LOAD_EXTERNAL_DATA (x_retcode,
                                   x_errbuff,
                                   l_file_id,
                                   l_ship_date,
                                   l_promise_date,
                                   l_sales_order_num,
                                   l_orig_file_name,
                                   l_user_id);
            END IF;

            IF x_retcode < 2
            THEN
               WWT_UPLOAD_GENERIC.LOG (
                  0,
                  '****** processing VALIDATE_UPLOAD_DATA');
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
         END;
      END LOOP;
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