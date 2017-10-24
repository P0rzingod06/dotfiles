/* Formatted on 5/29/2015 9:41:47 AM (QP5 v5.256.13226.35510) */
CREATE OR REPLACE PACKAGE BODY APPS.wwt_boa_blackbox_upload_pkg
AS
   -- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_boa_blackbox_upload_pkg.plb,v $, $Revision: 1.1 $, $Author: gassertm $, $Date: 2014/10/03 10:04:14 $
                                                                             /*
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
--Package Name        : wwt_boa_blackbox_upload_pkg                                             --
--Description         : This package is called by the international delivery                    --
--                             update file upload.                                                                        --
--===========================================================================--
-- Developer   Ver   Date        RFC       Description                                                       --
--===========================================================================--
-- Gassertm    1.1  10/03/2014  CHG33211  Creation                                               --
----------------------------------------------------------------------------------------------------------------------------------------*/

   /*
     *******************************************************************************
     *******************************************************************************
     **Procedure Name      :  CREATE_BATCH_IDS                                                **
     **Description         : Creates batch IDs for serial and inventory table              **
     *******************************************************************************
     *******************************************************************************
                                                                                                                         */

   PROCEDURE CREATE_BATCH_IDS (x_retcode              IN OUT NUMBER,
                               x_errbuff              IN OUT VARCHAR2,
                               x_inventory_batch_id      OUT NUMBER,
                               x_serial_batch_id         OUT NUMBER)
   IS
   BEGIN
      SELECT APPS.WWT_BOA_SERIAL_BATCH_ID_S.NEXTVAL
        INTO x_serial_batch_id
        FROM DUAL;

      wwt_upload_generic.LOG (
         0,
         'Current Serial batch_id: ' || x_serial_batch_id);


      SELECT APPS.WWT_BOA_INVENTORY_BATCH_ID_S.NEXTVAL
        INTO x_inventory_batch_id
        FROM DUAL;

      wwt_upload_generic.LOG (
         0,
         'Current Inventory batch_id: ' || x_inventory_batch_id);
   EXCEPTION
      WHEN OTHERS
      THEN
         wwt_upload_generic.LOG (
            2,
            'Error creating batch ids: ' || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
            'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.CREATE_BATCH_IDS while creating batch ids';
   END;

   /*
     *******************************************************************************
     *******************************************************************************
     **Procedure Name      :  ARCHIVE_SERIAL                                                    **
     **Description         : Purge records from Serial table and insert into Serial     **
     **                           archive table.                                                              **
     *******************************************************************************
     *******************************************************************************
                                                                                                                         */

   PROCEDURE ARCHIVE_SERIAL (x_retcode   IN OUT NUMBER,
                             x_errbuff   IN OUT VARCHAR2)
   IS
      TYPE l_serial_table_type
         IS TABLE OF APPS.WWT_BLACKBOX_SERIAL_ARCHIVE%ROWTYPE;

      l_serial_table   l_serial_table_type;

      l_id             NUMBER;
   BEGIN
      IF x_retcode < 2
      THEN
         BEGIN
            SELECT *
              BULK COLLECT INTO l_serial_table
              FROM APPS.WWT_BOA_BLACKBOX_SERIAL;

            FORALL x IN l_serial_table.FIRST .. l_serial_table.LAST
               INSERT INTO WWT_BLACKBOX_SERIAL_ARCHIVE
                    VALUES l_serial_table (x);
         EXCEPTION
            WHEN OTHERS
            THEN
               wwt_upload_generic.LOG (
                  2,
                     'Error inserting into serial archive table: '
                  || SUBSTR (SQLERRM, 1, 200));
               x_retcode := 2;
               x_errbuff :=
                  'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.ARCHIVE_SERIAL while inserting into serial archive table';
         END;

         wwt_upload_generic.LOG (
            0,
            'Archive insert successful, deleting rows from current table');

         BEGIN
            DELETE FROM APPS.WWT_BOA_BLACKBOX_SERIAL;
         EXCEPTION
            WHEN OTHERS
            THEN
               wwt_upload_generic.LOG (
                  2,
                     'Error deleting from serial archive table: '
                  || SUBSTR (SQLERRM, 1, 200));
               x_retcode := 2;
               x_errbuff :=
                  'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.ARCHIVE_SERIAL while deleting from serial archive table';
         END;

         wwt_upload_generic.LOG (0, 'Archive delete successful.');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         wwt_upload_generic.LOG (
            2,
            'Error inserting into serial table for serial number in wwt_boa_blackbox_upload.ARCHIVE_SERIAL');
         x_retcode := 2;
         x_errbuff :=
            'Unknown Error into serial table for serial number in wwt_boa_blackbox_upload.ARCHIVE_SERIAL';
   END;

   /*
   *******************************************************************************
   *******************************************************************************
   **Procedure Name      :  INSERT_SERIAL                                                           **
   **Description         : Insert Serial data into Serial table.                                **
   *******************************************************************************
   *******************************************************************************
                                                                                                                       */

   PROCEDURE INSERT_SERIAL (x_retcode         IN OUT NUMBER,
                            x_errbuff         IN OUT VARCHAR2,
                            p_user_id         IN     VARCHAR2,
                            p_batch_id        IN     NUMBER,
                            p_item            IN     VARCHAR2,
                            p_manufacturer    IN     VARCHAR2,
                            p_description     IN     VARCHAR2,
                            p_quantity        IN     NUMBER,
                            p_serial_number   IN     VARCHAR2)
   IS
      l_id   NUMBER;
   BEGIN
      BEGIN
         SELECT APPS.WWT_BOA_BLACKBOX_SERIAL_S.NEXTVAL INTO l_id FROM DUAL;

         wwt_upload_generic.LOG (0, 'Current Serial Id: ' || l_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            wwt_upload_generic.LOG (
               2,
                  'Error selecting next value from serial sequence: '
               || SUBSTR (SQLERRM, 1, 200));
            x_retcode := 2;
            x_errbuff :=
               'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.MAIN while selecting Next Value from sequence.';
      END;

      INSERT INTO APPS.WWT_BOA_BLACKBOX_SERIAL
           VALUES (l_id,                 -- next value from inventory sequence
                   p_item,                                              --ITEM
                   NULL,                                             --ITEM_ID
                   p_manufacturer,                              --MANUFACTURER
                   p_description,                                --DESCRIPTION
                   p_quantity,                                      --QUANTITY
                   p_serial_number,                            --SERIAL_NUMBER
                   'UNPROCESSED',                                     --STATUS
                   NULL,                                      --STATUS_MESSAGE
                   NULL,                                         ---REQUEST_ID
                   p_batch_id,                                      --BATCH_ID
                   p_user_id,                                     --CREATED_BY
                   SYSDATE,                                    --CREATION_DATE
                   p_user_id,                                --LAST_UPDATED_BY
                   SYSDATE);                                --LAST_UPDATE_DATE
   EXCEPTION
      WHEN OTHERS
      THEN
         wwt_upload_generic.LOG (
            2,
               'Error inserting into serial table for serial number '
            || p_serial_number
            || ': '
            || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
            'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.INSERT_SERIAL while inserting into serial table';
   END;

   /*
   *******************************************************************************
   *******************************************************************************
   **Procedure Name      :  INSERT_INVENTORY                                                          **
   **Description         : Insert Serial data into Inventory table.                                **
   *******************************************************************************
   *******************************************************************************
                                                                                                                       */
   PROCEDURE ARCHIVE_INVENTORY (x_retcode   IN OUT NUMBER,
                                x_errbuff   IN OUT VARCHAR2)
   IS
      TYPE l_inventory_table_type
         IS TABLE OF APPS.WWT_BLACKBOX_INVENTORY_ARCHIVE%ROWTYPE;

      l_inventory_table   l_inventory_table_type;

      l_id                NUMBER;
   BEGIN
      IF x_retcode < 2
      THEN
         BEGIN
            SELECT *
              BULK COLLECT INTO l_inventory_table
              FROM APPS.WWT_BOA_BLACKBOX_INVENTORY;


            FORALL x IN l_inventory_table.FIRST .. l_inventory_table.LAST
               INSERT INTO APPS.WWT_BLACKBOX_INVENTORY_ARCHIVE
                    VALUES l_inventory_table (x);
         EXCEPTION
            WHEN OTHERS
            THEN
               wwt_upload_generic.LOG (
                  2,
                     'ERROR inserting into inventory archive table: '
                  || SUBSTR (SQLERRM, 1, 200));
               x_errbuff :=
                  'Uknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.ARCHIVE_INVENTORY while inserting into inventory archive table';
               x_retcode := 2;
         END;

         wwt_upload_generic.LOG (
            2,
            'Archive insert successful, deleting rows from current table');

         BEGIN
            DELETE FROM APPS.WWT_BOA_BLACKBOX_INVENTORY;
         EXCEPTION
            WHEN OTHERS
            THEN
               wwt_upload_generic.LOG (
                  2,
                     'Error deleting from inventory archive table: '
                  || SUBSTR (SQLERRM, 1, 200));
               x_retcode := 2;
               x_errbuff :=
                  'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.ARCHIVE_INVENTORY while deleting from inventory archive table';
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         wwt_upload_generic.LOG (
            2,
            'Error inserting into inventory archive table for inventory number in WWT_BOA_BLACKBOX_UPLOAD.ARCHIVE_SERIAL');
         x_retcode := 2;
         x_errbuff :=
            'Uknown Error into inventory table for inventory number in wwt_boa_blackbox_upload.ARCHIVE_INVENTORY';
   END;



   PROCEDURE INSERT_INVENTORY (x_retcode          IN OUT NUMBER,
                               x_errbuff          IN OUT VARCHAR2,
                               p_user_id          IN     VARCHAR2,
                               p_batch_id         IN     NUMBER,
                               p_item             IN     VARCHAR2,
                               p_manufacturer     IN     VARCHAR2,
                               p_description      IN     VARCHAR2,
                               p_quantity         IN     NUMBER,
                               p_project_number   IN     VARCHAR2 -- stored in serial number column for inventory records
                                                                 )
   IS
      l_id   NUMBER;
   BEGIN
      BEGIN
         SELECT APPS.WWT_BOA_BLACKBOX_INVENTORY_S.NEXTVAL INTO l_id FROM DUAL;

         wwt_upload_generic.LOG (0, 'Current Inventory Id: ' || l_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            wwt_upload_generic.LOG (
               2,
                  'Error selecting next value from inventory sequence: '
               || SUBSTR (SQLERRM, 1, 200));
            x_retcode := 2;
            x_errbuff :=
               'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.MAIN while selecting Next Value in sequence.  ';
      END;


      INSERT INTO APPS.WWT_BOA_BLACKBOX_INVENTORY
           VALUES (l_id,                 -- next value from inventory sequence
                   p_item,                                              --ITEM
                   NULL,                                             --ITEM_ID
                   p_manufacturer,                              --MANUFACTURER
                   p_description,                                --DESCRIPTION
                   p_quantity,                                      --QUANTITY
                   p_project_number,                          --PROJECT_NUMBER
                   NULL,                                 --SERIAL_CONTROL_FLAG
                   'UNPROCESSED',                                     --STATUS
                   NULL,                                      --STATUS_MESSAGE
                   NULL,                                         ---REQUEST_ID
                   p_batch_id,                                      --BATCH_ID
                   p_user_id,                                     --CREATED_BY
                   SYSDATE,                                    --CREATION_DATE
                   p_user_id,                                --LAST_IPDATED_BY
                   SYSDATE);                                --LAST_UPDATE_DATE
   EXCEPTION
      WHEN OTHERS
      THEN
         wwt_upload_generic.LOG (
            2,
               'Error inserting into inventory table for project number '
            || p_project_number
            || ': '
            || SUBSTR (SQLERRM, 1, 200));
         x_retcode := 2;
         x_errbuff :=
            'Unknown Error in WWT_BOA_BLACKBOX_UPLOAD_PKG.INSERT_INVENTORY while inserting into inventory table';
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
      CURSOR WWT_BOA_BLACKBOX_EXT_CUR
      IS
         SELECT * FROM WWT_BOA_BLACKBOX_EXT;

      l_user_id              NUMBER;
      l_record_type          VARCHAR2 (50);
      l_inventory_count      NUMBER;
      l_serial_count         NUMBER;
      l_inventory_batch_id   NUMBER;
      l_serial_batch_id      NUMBER;
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

      BEGIN
         SELECT COUNT (*)
           INTO l_inventory_count
           FROM APPS.WWT_BOA_BLACKBOX_INVENTORY;

         wwt_upload_generic.LOG (0,
                                 'l_inventory_count: ' || l_inventory_count);

         SELECT COUNT (*)
           INTO l_serial_count
           FROM APPS.WWT_BOA_BLACKBOX_SERIAL;

         wwt_upload_generic.LOG (0, 'l_serial_count: ' || l_serial_count);
      EXCEPTION
         WHEN OTHERS
         THEN
            wwt_upload_generic.LOG (
               0,
                  'ERROR while retrieving count from inventory/serial table:  '
               || SQLERRM);
            x_errbuff :=
                  'ERROR while retrieving count from inventory/serial table:  '
               || SQLERRM;
            x_retcode := 2;
      END;

      IF x_retcode < 2 AND l_inventory_count > 0 AND l_serial_count > 0
      THEN
         ARCHIVE_SERIAL (x_retcode, x_errbuff);
         ARCHIVE_INVENTORY (x_retcode, x_errbuff);
      END IF;

      IF x_retcode < 2
      THEN
         CREATE_BATCH_IDS (x_retcode,
                           x_errbuff,
                           l_inventory_batch_id,
                           l_serial_batch_id);
      END IF;

      wwt_upload_generic.LOG (0, 'Beginning external table loop');

     <<EXTERNAL_TABLE_LOOP>>
      FOR WWT_BOA_BLACKBOX_EXT_REC IN WWT_BOA_BLACKBOX_EXT_CUR
      LOOP
         l_record_type := WWT_BOA_BLACKBOX_EXT_REC.RECORD_TYPE;

         IF l_record_type = 'I' AND x_retcode < 2 --Record type is inventory so archive and insert into Inventory table.
         THEN
            wwt_upload_generic.LOG (0, 'Record is an Inventory Record');

            INSERT_INVENTORY (X_RETCODE,
                              X_ERRBUFF,
                              l_user_id,
                              l_inventory_batch_id,
                              WWT_BOA_BLACKBOX_EXT_REC.ITEM,
                              WWT_BOA_BLACKBOX_EXT_REC.MANUFACTURER,
                              WWT_BOA_BLACKBOX_EXT_REC.DESCRIPTION,
                              WWT_BOA_BLACKBOX_EXT_REC.QUANTITY,
                              WWT_BOA_BLACKBOX_EXT_REC.SERIAL_NUMBER);

            wwt_upload_generic.LOG (
               0,
               'Insertion into inventory table successfull');
         ELSIF l_record_type = 'S' AND x_retcode < 2 --Record type is serial so insert into serial table.
         THEN
            wwt_upload_generic.LOG (0, 'Record is a Serial Record');

            INSERT_SERIAL (X_RETCODE,
                           X_ERRBUFF,
                           l_user_id,
                           l_serial_batch_id,
                           WWT_BOA_BLACKBOX_EXT_REC.ITEM,
                           WWT_BOA_BLACKBOX_EXT_REC.MANUFACTURER,
                           WWT_BOA_BLACKBOX_EXT_REC.DESCRIPTION,
                           WWT_BOA_BLACKBOX_EXT_REC.QUANTITY,
                           WWT_BOA_BLACKBOX_EXT_REC.SERIAL_NUMBER);

            wwt_upload_generic.LOG (
               0,
               'Insertion into serial table successfull');
         END IF;
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
END wwt_boa_blackbox_upload_pkg;
/