/* Formatted on 11/7/2014 3:04:52 PM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.wwt_intl_delivery_update_pkg
AS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_intl_delivery_update_pkg.plb,v $, $Revision: 1.1 $, $Author: gassertm $, $Date: 2014/10/03 10:04:14 $
                                                                             /*
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Package Name        : WWT_INTL_DELIVERY_UPDATE_PKG                         --
--Description         : This package is called by the international delivery --
--                      update file upload.              .                   --
--===========================================================================--
-- Developer   Ver   Date        RFC       Description                       --
--===========================================================================--
-- Gassertm    1.1  10/03/2014  CHG33211  Creation                           --
-------------------------------------------------------------------------------
                                                                             *

 /*
*****************************************************************************************

   Function name: GET_VALID_DATE

   Description: Return true if date P_DATE uses the format P_DATE_FORMAT, false otherwise.

 *****************************************************************************************
 */

   FUNCTION GET_VALID_DATE (P_DATE IN VARCHAR2, P_DATE_FORMAT IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_valid_date   BOOLEAN;
      l_temp_date    DATE;
   BEGIN
      BEGIN
         l_temp_date := TO_DATE (P_DATE, P_DATE_FORMAT);
         l_valid_date := TRUE;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_valid_date := FALSE;
      END;

      RETURN l_valid_date;
   END;

                                                                             /*
*******************************************************************************
*******************************************************************************
**Procedure Name      : MAIN                                                 **
**Description         : Retrieve file from intl_delivery_update ftp folder-  **
**                      guc source id 227. Update or insert record in        **
**                      wwt_wsh_new_deliveries_dff table depending on        **
**                      values in upload.                                    **
*******************************************************************************
*******************************************************************************
                                                                             */

   PROCEDURE MAIN (x_retcode       OUT NUMBER,
                   x_errbuff       OUT VARCHAR2,
                   p_filename   IN     VARCHAR2,
                   p_username   IN     VARCHAR2)
   IS
      CURSOR INTL_DELIVERY_EXT_CUR
      IS
         SELECT * FROM WWT_INTL_DELIVERY_UPDATE_EXT;

      l_user_id                     NUMBER;
      l_delivery_number             NUMBER;
      l_dest_country_arrival_date   VARCHAR2 (100);
      l_customs_clearance_date      VARCHAR2 (100);
      l_final_dest_arrival_date     VARCHAR (100);
      l_delivery_num_count          NUMBER;
      --Valid date format input into table.
      l_table_date_format           VARCHAR2 (8) := 'YYYYMMDD';
      --Valid date format input into csv file.
      l_input_date_format           VARCHAR2 (11) := 'DD-MON-YYYY';
   BEGIN
      -- initialize to 0 - no error.
      x_retcode := 0;

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
      FOR INTL_DELIVERY_EXT_REC IN INTL_DELIVERY_EXT_CUR
      LOOP
         BEGIN
            l_delivery_number := INTL_DELIVERY_EXT_REC.DELIVERY_NUMBER;
            l_dest_country_arrival_date :=
               INTL_DELIVERY_EXT_REC.INTL_DEST_COUNTRY_ARRIVAL_DATE;
            l_customs_clearance_date :=
               INTL_DELIVERY_EXT_REC.INTL_CUSTOMS_CLEARANCE_DATE;
            l_final_dest_arrival_date :=
               INTL_DELIVERY_EXT_REC.INTL_FINAL_DEST_ARRIVAL_DATE;

            --Make sure dates are valid and row is not empty.
            IF l_delivery_number IS NOT NULL
            THEN
               wwt_upload_generic.LOG (
                  0,
                     'New record found for delivery number '
                  || l_delivery_number);

               IF     GET_VALID_DATE (l_dest_country_arrival_date,
                                      l_input_date_format)
                  AND GET_VALID_DATE (l_customs_clearance_date,
                                      l_input_date_format)
                  AND GET_VALID_DATE (l_final_dest_arrival_date,
                                      l_input_date_format)
               THEN
                  -- If delivery number already exists, then just update row.
                  SELECT COUNT (SOURCE_KEY_ID_1)
                    INTO l_delivery_num_count
                    FROM WWT_WSH_NEW_DELIVERIES_DFF
                   WHERE l_delivery_number IN (SELECT SOURCE_KEY_ID_1
                                                 FROM WWT_WSH_NEW_DELIVERIES_DFF);

                  IF l_delivery_num_count > 0
                  THEN
                     wwt_upload_generic.LOG (
                        0,
                           'Delivery number found in table.  Updating delivery '
                        || l_delivery_number
                        || '.');

                     UPDATE WWT_WSH_NEW_DELIVERIES_DFF
                        SET ATTRIBUTE1 =
                               TO_CHAR (
                                  TO_DATE (l_dest_country_arrival_date),
                                  l_table_date_format),
                            ATTRIBUTE2 =
                               TO_CHAR (TO_DATE (l_customs_clearance_date),
                                        l_table_date_format),
                            ATTRIBUTE3 =
                               TO_CHAR (TO_DATE (l_final_dest_arrival_date),
                                        l_table_date_format),
                            ATTRIBUTE4 =
                               INTL_DELIVERY_EXT_REC.INTL_FINAL_DEST_CARRIER,
                            ATTRIBUTE5 =
                               INTL_DELIVERY_EXT_REC.INTL_FINAL_DEST_TRACKING_NUM,
                            LAST_UPDATED_BY = l_user_id,
                            LAST_UPDATE_DATE = SYSDATE
                      WHERE SOURCE_KEY_ID_1 = l_delivery_number;

                     wwt_upload_generic.LOG (
                        0,
                           'Record Update Successful for Delivery Number '
                        || l_delivery_number);
                  ELSE
                     --Delivery number does not exist in table so insert it.
                     wwt_upload_generic.LOG (
                        0,
                           'Inserting delivery number '
                        || l_delivery_number
                        || ' into table.');



                     INSERT
                       INTO WWT_WSH_NEW_DELIVERIES_DFF (SOURCE_KEY_ID_1,
                                                        SOURCE_KEY_ID_2,
                                                        SOURCE_KEY_ID_3,
                                                        SOURCE_KEY_ID_4,
                                                        ATTRIBUTE1,
                                                        ATTRIBUTE2,
                                                        ATTRIBUTE3,
                                                        ATTRIBUTE4,
                                                        ATTRIBUTE5,
                                                        CREATED_BY,
                                                        CREATION_DATE,
                                                        LAST_UPDATED_BY,
                                                        LAST_UPDATE_DATE)
                        VALUES (
                                  TO_NUMBER (l_delivery_number),
                                  -1,
                                  -1,
                                  -1,
                                  TO_CHAR (
                                     TO_DATE (l_dest_country_arrival_date),
                                     l_table_date_format),
                                  TO_CHAR (
                                     TO_DATE (l_customs_clearance_date),
                                     l_table_date_format),
                                  TO_CHAR (
                                     TO_DATE (l_final_dest_arrival_date),
                                     l_table_date_format),
                                  INTL_DELIVERY_EXT_REC.INTL_FINAL_DEST_CARRIER,
                                  INTL_DELIVERY_EXT_REC.INTL_FINAL_DEST_TRACKING_NUM,
                                  l_user_id,
                                  SYSDATE,
                                  l_user_id,
                                  SYSDATE);

                     wwt_upload_generic.LOG (
                        0,
                           'Record Insertion Successful for delivery number '
                        || l_delivery_number);
                  END IF;
               ELSE
                  x_errbuff :=
                        'Invalid date as input for delivery number '
                     || l_delivery_number;
                  x_retcode := 2;
               END IF;
            ELSE
               wwt_upload_generic.LOG (0, 'End of file found');
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
END wwt_intl_delivery_update_pkg;
/