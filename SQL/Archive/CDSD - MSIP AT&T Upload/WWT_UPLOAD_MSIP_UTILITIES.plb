CREATE OR REPLACE PACKAGE BODY APPS.wwt_upload_msip_utilities IS

-- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgbody/wwt_upload_msip_utilities.plb,v $, $Revision: 1.15 $, $Author: karsts $, $Date: 2011/07/28 17:11:26 $
/**************************************************************************************************

   PURPOSE: utilities for MSIP Integrations

**************************************************************************************************/
/**************************************************************************************************
   REVISIONS:
   Ver       CHG      Date        Author           Description
   --------- -------- ----------  ---------------  ------------------------------------
   1.1       CHG15115 08-MAR-2010  morganc         creation
   1.2       CHG15115 07-APR-2010  morganc         Added global g_msip_id_revision_tab. Added procedure(s): get_next_inventory_revision, get_receipt_qty, release_trigger, files_processed_successfully,
                                                   post_upload_process.
                                                   Made some spelling corrections, and datatype naming convenstion changes.
   1.3       CHG16001 04-MAY-2010  morganc         Added new globals.
                                                   Added new procedure(s): determine_trigger_timestamp;
                                                   Modified procedure(s): get_receipt_qty - changed the logic behind the going back X business days.
                                                                          perform_release - added query to get the release timestamp.
                                                                          release_trigger - added some new parameters and a call to new procedure determine_trigger_timestamp.
                                                                          files_processed_successfully - added new parameters and modified the queires to send back timestamps.
                                                                          post_upload_process - modified parameter from manual release to p_override_release_timestamp; reworked to be more of an all
                                                                          or nothing when processing through the warehouses. if we get a warehouse that is not related to others, then we will need to
                                                                          create a warehouse group, create an outer loop (warehouse group cursor) over the current logic.
  1.4       CHG16413  22-JUN-2010  morganc         Added procedure(s): adjust_inv_outstanding_qty, insert_shipment_data.
                                                   Modified procedure: post_upload_process - added UPPER around warehouse for planning_warehouse_cur Cursor
  1.5       CHG16413  30-JUN-2010  morganc         Removed the Commit and Rollback from insert_shipment_data
  1.6       CHG17259  31-AUG-2010  morganc         Added procedure(s): create_or_modify_min_max, insert_into_min_max_table, msip_planning_item_creating
  1.7       CHG17259  15-SEP-2010  morganc         minor changes.
  1.8       CHG17416  20-SEP-2010  morganc         added procedure(s): min_max_autonomous_api, item_creation_autonomous_api, commitment_copy_process_all, commitment_copy_process
  1.9       CHG17416  04-OCT-2010  morganc         Modified procedure(s): commitment_copy_process- modified the average qty select, and added the date to the Notes
                                                   and appended the new notes to the old notes if dml mode is UPDATE
  1.10      CHG17416  04-OCT-2010  morganc         Removed procedure convert_string_to_date
  1.11      CHG17438  01-11-2010  morganc          Modified procedure(s): determine_trigger_timestamp - added logic around deriving trigger timestamp;
                                                   perform_release - modified the query that determines SO Line ID; get_customer_po_info - added hardware_model to the parameters
                                                   to use during the query
  1.12      CHG17440  24-NOV-2010  morganc         Added new functions: is_msip_id_active; has_active_min_max_records
                                                   Modified procedure(s): post_upload_process - using the new "active" logic
  1.13      CHG17440  24-NOV-2010  morganc         Modified procedure(s): has_active_min_max_records and is_msip_id_active - removed the over-protective NVL's from the RETURNs
  1.14      CHG18638  03-MAR-2011  karsts          Added procedure item_update_autonomous_api. This proc will end date
                                                   and 0 out quantities for associated minmax and commitment recs when
                                                   item is end dated.
  1.15      CHG19847  28-JUL-2011   karsts         added procedure update_release_data - called from apex form, SLA Detail tab,
                                                   Release Detail link column
***************************************************************************************************/

TYPE warehouse_tabtype IS TABLE OF VARCHAR2(2000) INDEX BY BINARY_INTEGER;

-- This global is used during the get_next_inventory_revision;
-- which is called by multiple procedures, including some outside of this package
--
TYPE msip_id_revision_tabtype IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;
g_msip_id_revision_tab   msip_id_revision_tabtype;

g_calendar_code               bom_calendar_dates.calendar_code%TYPE;
g_less_than_release_hour      VARCHAR2(5);
g_greater_than_release_hour   VARCHAR2(5);
g_release_hour                VARCHAR2(30);

/**************************************
|| loops over all active msip ids and calls commitment
|| copy process per each msip id to create/update commitment for
|| the copy to month value. this is currently called from APEX and is autonomous
**************************************/
PROCEDURE commitment_copy_process_all(p_copy_to_month  IN DATE
                                     ,p_ldap_username  IN VARCHAR2
                                     ,x_message       OUT VARCHAR2
                                     ,x_retcode       OUT NUMBER) IS

--
-- get all active msip ids
--
CURSOR get_active_msip_ids_cur IS
   SELECT msip_id
     FROM wwt_msip_planning_item
    WHERE p_copy_to_month BETWEEN NVL(TO_DATE(TO_CHAR(start_effective_date, 'MON-RRRR'), 'MON-RRRR'), p_copy_to_month)
                              AND NVL(TO_DATE(TO_CHAR(end_effective_date, 'MON-RRRR'), 'MON-RRRR'), p_copy_to_month);

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

   x_retcode := 0;

   --
   -- check to make sure the copy to month is a future month
   --
   IF p_copy_to_month <= TRUNC(LAST_DAY(SYSDATE)) THEN
      raise_application_error(-20013, 'Copy To Month must be a future month');
   END IF;

   --
   -- call commitment copy process per each msip id
   --
   FOR get_active_msip_ids_rec IN get_active_msip_ids_cur LOOP

      commitment_copy_process(p_msip_id        => get_active_msip_ids_rec.msip_id
                             ,p_copy_to_month  => p_copy_to_month
                             ,p_ldap_username  => p_ldap_username
                             ,x_message        => x_message
                             ,x_retcode        => x_retcode);

   END LOOP;

   -- if retcode is equal to 2 then we need to rollback
   --
   IF x_retcode = 2 THEN
      ROLLBACK;
   ELSE
      COMMIT;
   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;
      ROLLBACK;

END commitment_copy_process_all;

/**************************************
|| this will create/update a commitment record per msip ID for the copy to month value.
|| It will derive the commitment qty by taking an average usage qty
|| over the last three months. However there has to be three months worth of
|| data else it will just default to zero.
**************************************/
PROCEDURE commitment_copy_process(p_msip_id        IN NUMBER
                                 ,p_copy_to_month  IN DATE
                                 ,p_ldap_username  IN VARCHAR2
                                 ,x_message       OUT VARCHAR2
                                 ,x_retcode       OUT NUMBER) IS

l_dml_mode            VARCHAR(25);
l_target_plan_id      apps.wwt_msip_target_planning.target_plan_id%TYPE;
l_average_qty         NUMBER;
l_buffer_qty          NUMBER;
l_commitment_qty      NUMBER;

BEGIN

   x_retcode := 0;

   --
   -- check to make sure the copy to month is a future month
   --
   IF p_copy_to_month <= TRUNC(LAST_DAY(SYSDATE)) THEN
      raise_application_error(-20013, 'Copy To Month must be a future month');
   END IF;

   --
   -- select average qty per the previous 3 months
   --
   BEGIN

      SELECT ROUND (SUM (monthly.quantity) / COUNT (dates.shipped_month)) average_qty
        INTO l_average_qty
        FROM (  SELECT msip_id
                       ,TO_CHAR (usage_date, 'MON-RRRR') usage_month
                       ,SUM (usage_quantity) quantity
                   FROM apps.wwt_msip_usage
                  WHERE msip_id = p_msip_id
               GROUP BY msip_id, TO_CHAR (usage_date, 'MON-RRRR')) monthly
             , (SELECT TO_CHAR (ADD_MONTHS (SYSDATE, - inner_loop.offset)  ,'MON-RRRR') shipped_month
                  FROM (    SELECT ROWNUM offset
                                  FROM DUAL
                CONNECT BY LEVEL <= 3) inner_loop) dates
       WHERE dates.shipped_month = monthly.usage_month
      HAVING COUNT (dates.shipped_month) = 3;

      --
      -- check to see if average qty value is null
      --
      IF l_average_qty IS NULL THEN
         RAISE no_data_found;
      END IF;

      --
      -- determine buffer amount
      -- if average qty is less than 25 the buffer is 5
      -- otherwise it is 20 percent of the average qty
      --
      IF  l_average_qty <= 25 THEN
         l_buffer_qty := 5;
      ELSE
         l_buffer_qty := ROUND((l_average_qty*(20/100)));
      END IF;


   EXCEPTION
      WHEN no_data_found THEN
         l_average_qty    := 0;
         l_buffer_qty     := NULL;
      WHEN others THEN
         raise_application_error(-20013, 'Monthly average query for MSIP ID '||p_msip_id||' error: '||SQLERRM);
   END;

   --
   -- derive commitment qty
   --
   l_commitment_qty := ROUND((l_average_qty + NVL(l_buffer_qty, 0)));

   --
   -- need to determine if we are updating a record or
   -- creating a new one
   --
   BEGIN

      SELECT target_plan_id
        INTO l_target_plan_id
        FROM apps.wwt_msip_target_planning
       WHERE msip_id = p_msip_id
         AND target_month = p_copy_to_month;

      l_dml_mode := 'UPDATE';

   EXCEPTION
      WHEN no_data_found THEN
         l_dml_mode := 'CREATE';
      WHEN too_many_rows THEN
         raise_application_error(-20013, 'Too many target months exists for MSIP ID: '||p_msip_id);
      WHEN others THEN
         raise_application_error(-20013, 'Target month already exists query for MSIP ID '||p_msip_id||' error: '||SQLERRM);
   END;

   --
   -- depending on DML Mode, we will either do a create or update
   --
   IF l_dml_mode = 'CREATE' THEN

      --
      -- need to create commitment
      --
      INSERT INTO apps.wwt_msip_target_planning
             (target_plan_id, msip_id, target_month, target_quantity, notes
             ,attribute1, attribute2, attribute3, attribute4, attribute5, created_by, creation_date, last_updated_by, last_update_date, request_id
             ,last_update_request_id, login_id, last_update_login_id, ldap_created_by, ldap_last_updated_by)
      VALUES (apps.wwt_msip_target_planning_s.NEXTVAL, p_msip_id, TO_DATE('01-'||TO_CHAR(p_copy_to_month, 'MON-RRRR')), l_commitment_qty, SUBSTR('Commitment Qty Set by Auto Copy Process - '||TO_CHAR(SYSDATE, 'MM/DD/RRRR')||'. ', 1, 2000)
             ,l_buffer_qty, NULL, NULL, NULL, NULL, fnd_global.user_id, SYSDATE, fnd_global.user_id, SYSDATE, fnd_global.conc_request_id
             ,fnd_global.conc_request_id, fnd_global.login_id, fnd_global.login_id, p_ldap_username, p_ldap_username);

   ELSIF l_dml_mode = 'UPDATE' THEN

      --
      -- updating existing record
      -- also if there is a value for attribute2 we want to add that to the commitment
      --
      UPDATE apps.wwt_msip_target_planning
         SET target_quantity = ROUND(l_commitment_qty + NVL(TO_NUMBER(attribute2), 0))
            ,attribute1 = l_buffer_qty
            ,notes = SUBSTR('Commitment Qty Set by Auto Copy Process - '||TO_CHAR(SYSDATE, 'MM/DD/RRRR')||'. '||notes, 1, 2000)
            ,last_updated_by = fnd_global.user_id
            ,last_update_date = SYSDATE
            ,last_update_request_id = fnd_global.conc_request_id
            ,last_update_login_id = fnd_global.login_id
            ,ldap_last_updated_by = p_ldap_username
      WHERE target_plan_id = l_target_plan_id;

   END IF;

EXCEPTION
   WHEN others THEN
      x_message := 'Unexpected error for MSIP ID '||p_msip_id||' error: '||SQLERRM;
      x_retcode := 2;


END commitment_copy_process;

/**************************************
|| purpose: wrapper to call create_or_modify_min_max to handle Commit and Rollback;
|| this is an Autonomous Transaction
**************************************/
PROCEDURE min_max_autonomous_api(p_min_max_id           IN NUMBER
                                ,p_msip_id              IN NUMBER
                                ,p_start_effective_date IN DATE
                                ,p_end_effective_date   IN DATE
                                ,p_min_level_quantity   IN NUMBER
                                ,p_max_level_quantity   IN NUMBER
                                ,p_notes                IN VARCHAR2
                                ,p_ldap_username        IN VARCHAR2
                                ,x_message              OUT VARCHAR2
                                ,x_retcode              OUT NUMBER
                                ) IS

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

   x_retcode := 0;

   create_or_modify_min_max(p_min_max_id           => p_min_max_id
                           ,p_msip_id              => p_msip_id
                           ,p_start_effective_date => p_start_effective_date
                           ,p_end_effective_date   => p_end_effective_date
                           ,p_min_level_quantity   => p_min_level_quantity
                           ,p_max_level_quantity   => p_max_level_quantity
                           ,p_notes                => p_notes
                           ,p_ldap_username        => p_ldap_username
                           ,x_message              => x_message
                           ,x_retcode              => x_retcode
                           );

   -- if retcode is equal to 2 then we need to rollback
   --
   IF x_retcode = 2 THEN
      ROLLBACK;
   ELSE
      COMMIT;
   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;
      ROLLBACK;

END min_max_autonomous_api;

/**************************************
|| wrapper to call msip_planning_item_creating to handle Commit and Rollback;
|| this is an Autonomous Transaction
**************************************/
PROCEDURE item_creation_autonomous_api(p_inventory_item_id      IN NUMBER
                                      ,p_warehouse              IN VARCHAR2
                                      ,p_service_line           IN VARCHAR2
                                      ,p_hardware_model         IN VARCHAR2
                                      ,p_project                IN VARCHAR2
                                      ,p_product_family         IN VARCHAR2
                                      ,p_chasis_flag            IN VARCHAR2
                                      ,p_start_effective_date   IN DATE
                                      ,p_end_effective_date     IN DATE
                                      ,p_ldap_username          IN VARCHAR2
                                      ,x_message                OUT VARCHAR2
                                      ,x_retcode                OUT NUMBER) IS

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

   x_retcode := 0;

   msip_planning_item_creating(p_inventory_item_id     => p_inventory_item_id
                              ,p_warehouse             => p_warehouse
                              ,p_service_line          => p_service_line
                              ,p_hardware_model        => p_hardware_model
                              ,p_project               => p_project
                              ,p_product_family        => p_product_family
                              ,p_chasis_flag           => p_chasis_flag
                              ,p_start_effective_date  => p_start_effective_date
                              ,p_end_effective_date    => p_end_effective_date
                              ,p_ldap_username         => p_ldap_username
                              ,x_message               => x_message
                              ,x_retcode               => x_retcode);

   -- if retcode is equal to 2 then we need to rollback
   --
   IF x_retcode = 2 THEN
      ROLLBACK;
   ELSE
      COMMIT;
   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;
      ROLLBACK;

END item_creation_autonomous_api;

/**************************************
|| to create new MSIP planning items; also creates a min/max and commitment record
**************************************/
PROCEDURE msip_planning_item_creating(p_inventory_item_id      IN NUMBER
                                     ,p_warehouse              IN VARCHAR2
                                     ,p_service_line           IN VARCHAR2
                                     ,p_hardware_model         IN VARCHAR2
                                     ,p_project                IN VARCHAR2
                                     ,p_product_family         IN VARCHAR2
                                     ,p_chasis_flag            IN VARCHAR2
                                     ,p_start_effective_date   IN DATE
                                     ,p_end_effective_date     IN DATE
                                     ,p_ldap_username          IN VARCHAR2
                                     ,x_message                OUT VARCHAR2
                                     ,x_retcode                OUT NUMBER) IS

l_msip_id       apps.wwt_msip_planning_item.msip_id%TYPE;
l_msip_exists   VARCHAR2(1) := 'N';

BEGIN

   x_retcode := 0;

   BEGIN

      SELECT 'Y'
        INTO l_msip_exists
        FROM wwt_msip_planning_item
       WHERE warehouse = p_warehouse
         AND service_line = p_service_line
         AND project = p_project
         AND hardware_model = p_hardware_model;

      raise_application_error(-20013, 'MSIP ID already exists for Warehouse/Service Line/Project/Hardware Model combination');

   EXCEPTION
      WHEN no_data_found THEN
         l_msip_exists := 'N';
      WHEN others THEN
         raise_application_error(-20013, 'Error occurred during MSIP ID check; Error: '||SQLERRM);

   END;

   --
   -- get next MSIP ID
   --
   SELECT apps.wwt_msip_planning_item_s.NEXTVAL
     INTO l_msip_id
     FROM dual;

   --
   -- need to insert the new item
   --
   INSERT INTO apps.wwt_msip_planning_item
          (msip_id, inventory_item_id, warehouse, service_line, hardware_model, project, product_family
          ,chassis_flag, created_by, creation_date, last_updated_by, last_update_date, request_id
          ,last_update_request_id, login_id, last_update_login_id, ldap_created_by, ldap_last_updated_by,
          start_effective_date, end_effective_date)
   VALUES (l_msip_id, p_inventory_item_id, p_warehouse, p_service_line, p_hardware_model, p_project, p_product_family
          ,p_chasis_flag, fnd_global.user_id, SYSDATE, fnd_global.user_id, SYSDATE, fnd_global.conc_request_id
          ,fnd_global.conc_request_id, fnd_global.login_id, fnd_global.login_id, p_ldap_username, p_ldap_username
          ,p_start_effective_date, p_end_effective_date);

   --
   -- need to create a min/max level
   --
   create_or_modify_min_max(p_min_max_id           => NULL
                           ,p_msip_id              => l_msip_id
                           ,p_start_effective_date => p_start_effective_date
                           ,p_end_effective_date   => p_end_effective_date
                           ,p_min_level_quantity   => 0
                           ,p_max_level_quantity   => 0
                           ,p_notes                => 'Item Creation; defaulted quantities to zero'
                           ,p_ldap_username        => p_ldap_username
                           ,x_retcode              => x_retcode
                           ,x_message              => x_message);

   --
   -- check to see if the creat min max failed
   --
   IF x_retcode = 2 THEN
      x_message := 'Error occurred during Min/Max creation: '||x_message;
      RETURN;
   END IF;

   --
   -- need to create commitment
   --
   INSERT INTO apps.wwt_msip_target_planning
          (target_plan_id, msip_id, target_month, target_quantity, notes
          ,attribute1, attribute2, attribute3, attribute4, attribute5, created_by, creation_date, last_updated_by, last_update_date, request_id
          ,last_update_request_id, login_id, last_update_login_id, ldap_created_by, ldap_last_updated_by)
   VALUES (apps.wwt_msip_target_planning_s.NEXTVAL, l_msip_id, TO_DATE('01-'||TO_CHAR(p_start_effective_date, 'MON-RRRR')), 0, 'Item Creation; defaulted quantity to zero'
          ,NULL, NULL, NULL, NULL, NULL, fnd_global.user_id, SYSDATE, fnd_global.user_id, SYSDATE, fnd_global.conc_request_id
          ,fnd_global.conc_request_id, fnd_global.login_id, fnd_global.login_id, p_ldap_username, p_ldap_username);

   --
   -- if message is not null then set retcode to 1
   --
   IF x_message IS NOT NULL THEN
      x_retcode := 1;
   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;

END msip_planning_item_creating;

/**************************************
|| purpose: to create or modify min/max levels
**************************************/
PROCEDURE create_or_modify_min_max(p_min_max_id           IN NUMBER
                                  ,p_msip_id              IN NUMBER
                                  ,p_start_effective_date IN DATE
                                  ,p_end_effective_date   IN DATE
                                  ,p_min_level_quantity   IN NUMBER
                                  ,p_max_level_quantity   IN NUMBER
                                  ,p_notes                IN VARCHAR2
                                  ,p_ldap_username        IN VARCHAR2
                                  ,x_message              OUT VARCHAR2
                                  ,x_retcode              OUT NUMBER
                                  ) IS

l_min_max_insert_table   wwt_upload_msip_utilities.msip_min_max_tabtype;
l_min_max_record         wwt_msip_min_max_planning%ROWTYPE;
l_overlapping_count      NUMBER;
l_min_max_id_count       NUMBER;
l_after_start_date_count NUMBER;
l_previous_min_max_id    wwt_msip_min_max_planning.min_max_id%TYPE;
l_pre_start_date_gap     NUMBER;
l_post_end_date_gap      NUMBER;
l_dml_mode               VARCHAR2(25);
l_dates_validation       VARCHAR2(1) := 'N';
l_start_date             DATE;
l_end_date               DATE;

BEGIN

   x_retcode := 0;

   --
   -- truncate these dates because we do not want any time value other than midnight time
   --
   l_start_date := TRUNC(p_start_effective_date);
   l_end_date   := TRUNC(p_end_effective_date);

   --
   -- check to see if we are updaing an min/max ID
   -- or creating a new one
   --
   IF p_min_max_id IS NOT NULL THEN
      --
      -- going into UPDATE mode
      --
      l_dml_mode := 'UPDATE';
   ELSE
      IF l_start_date IS NULL THEN
         raise_application_error(-20013, 'Cannot allow Start Effective Date to be NULL');
      END IF;
      --
      -- going into CREATE mode
      --
      l_dml_mode := 'CREATE';
   END IF;

   --
   -- go into CREATE only validations
   --
   IF l_dml_mode IN ('CREATE') THEN

      IF l_start_date < TRUNC(SYSDATE+1) THEN
         raise_application_error(-20013, 'We only allow creation of new recrods for future dates');
      END IF;

      --
      -- assign appropriate data to min max record
      --
      l_min_max_record.msip_id                := p_msip_id;
      l_min_max_record.start_effective_date   := l_start_date;
      l_min_max_record.end_effective_date     := l_end_date;
      l_min_max_record.min_level_quantity     := NVL(p_min_level_quantity, 0);
      l_min_max_record.max_level_quantity     := NVL(p_max_level_quantity, 0);
      l_min_max_record.notes                  := p_notes;

   --
   -- get min max id data
   --
   ELSIF l_dml_mode IN ('UPDATE') THEN

      --
      -- check to see if the dates are changing; might as well get all the data
      --
      BEGIN
         SELECT min_max_id
              , msip_id
              , TRUNC(start_effective_date)
              , TRUNC(end_effective_date)
              , min_level_quantity
              , max_level_quantity
              , notes
           INTO l_min_max_record.min_max_id
              , l_min_max_record.msip_id
              , l_min_max_record.start_effective_date
              , l_min_max_record.end_effective_date
              , l_min_max_record.min_level_quantity
              , l_min_max_record.max_level_quantity
              , l_min_max_record.notes
           FROM apps.wwt_msip_min_max_planning
          WHERE min_max_id = p_min_max_id;

      EXCEPTION
         WHEN no_data_found THEN
            --
            -- could not find min max id
            --
            raise_application_error(-20013, 'Min Max ID: '||p_min_max_id||' does not exist');
         WHEN others THEN
            --
            -- oh noes! what do I do?
            --
            raise_application_error(-20013, 'Error occurred during Min Max ID select for Min Max ID: '||p_min_max_id||'; Error: '||SQLERRM);

      END;

      --
      -- we do not allow null-ing out of end effective date if a date already exists
      --
      IF l_min_max_record.end_effective_date IS NOT NULL
         AND p_end_effective_date IS NULL
      THEN
         raise_application_error(-20013, 'Cannot allow a NULL for End Effective Date to an existing record');
      END IF;

      --
      -- we only allow the change of min/max quantities and/or notes if the
      -- record begins in the future
      --
      IF (l_min_max_record.start_effective_date < TRUNC(SYSDATE+1))
         AND (NVL(p_min_level_quantity, 0) != NVL(l_min_max_record.min_level_quantity, 0)
            OR NVL(p_max_level_quantity, 0) != NVL(l_min_max_record.max_level_quantity, 0)
            OR NVL(p_notes, 'NA') != NVL(l_min_max_record.notes, 'NA'))
      THEN

         raise_application_error(-20013, 'Min Max Quantities and/or Notes can only be modified for records that begin in the future');

      ELSE

         --
         -- if quanitites were sent in we will use them, otherwise we will just use the data
         -- from the table
         --
         l_min_max_record.min_level_quantity := NVL(p_min_level_quantity, l_min_max_record.min_level_quantity);
         l_min_max_record.max_level_quantity := NVL(p_max_level_quantity, l_min_max_record.max_level_quantity);

         --
         -- min/max quantity cannot be a negative number
         --
         IF l_min_max_record.min_level_quantity < 0
           OR l_min_max_record.max_level_quantity < 0
         THEN
            raise_application_error(-20013, 'Cannot allow a Min/Max quantity to be negative');
         END IF;

         --
         -- cannot allow min quantity to be greater than the max quantity
         --
         IF l_min_max_record.min_level_quantity > l_min_max_record.max_level_quantity THEN
            raise_application_error(-20013, 'Cannot allow Min quantity to be greater than the Max quantity');
         END IF;

         --
         -- we are just going to overwrite the notes because we do not know
         -- if the user will be sending in old notes with new notes, etc.
         --
         l_min_max_record.notes := p_notes;

      END IF;

   END IF;

   --
   -- determine if we need to do date validations
   --
   IF l_dml_mode IN ('CREATE') THEN

      --
      -- check to see if msip ID already has any min/max ids
      --
      SELECT COUNT(*)
        INTO l_min_max_id_count
        FROM apps.wwt_msip_min_max_planning
       WHERE msip_id = l_min_max_record.msip_id;

      --
      -- if min/max id count is equal to zero
      -- then just insert a new record; no need to do validations
      --
      IF NVL(l_min_max_id_count, 0) != 0 THEN
         --
         -- creating new min max records requires date validations
         --
         l_dates_validation := 'Y';
      END IF;

   ELSIF l_dml_mode IN ('UPDATE') THEN
      --
      -- we should only have to do date validations if one of the dates
      -- is changing
      --
      IF (l_min_max_record.start_effective_date != l_start_date)
         OR (NVL(l_min_max_record.end_effective_date, l_end_date+1) != l_end_date)
      THEN

         --
         -- we do not allow modifying of an expired record
         --
         IF NVL(l_min_max_record.end_effective_date, SYSDATE+1) < TRUNC(SYSDATE) THEN
            raise_application_error(-20013, 'Can only modify records that are currently active or begin in the future');
         END IF;

         --
         -- we do not want to allow any changes to the start effective date if the record is
         -- currently active or has expired; and start dates must begin in the future
         --
         IF (l_min_max_record.start_effective_date != l_start_date) THEN
            IF l_min_max_record.start_effective_date < TRUNC(SYSDATE+1) THEN
               raise_application_error(-20013, 'Can only modify Start Effective Date for records that begin in the future');
            END IF;
            IF l_start_date < TRUNC(SYSDATE+1) THEN
               raise_application_error(-20013, 'Start Effective Date must begin in the future');
            END IF;
         END IF;

         --
         -- End Effective Date must be in the future; or today's date
         --
         IF (NVL(l_min_max_record.end_effective_date, l_end_date+1) != l_end_date) THEN
            IF l_end_date < TRUNC(SYSDATE) THEN
               raise_application_error(-20013, 'End Effective Date must be current date or the future');
            END IF;
         END IF;

         --
         -- WOOT! we have made it this far
         --
         l_min_max_record.start_effective_date := NVL(l_start_date, l_min_max_record.start_effective_date);
         l_min_max_record.end_effective_date   := NVL(l_end_date, l_min_max_record.end_effective_date);

         --
         -- only if the data between what exists in the table and the input parameters differ
         -- do we need to do date validations
         --
         l_dates_validation := 'Y';

      END IF;

   END IF;

   IF NVL(l_dates_validation, 'N') = 'Y' THEN /* date validations */

      --
      -- we do not let the end date to be before the start date
      --
      IF NVL(l_min_max_record.end_effective_date, l_min_max_record.start_effective_date+1) < l_min_max_record.start_effective_date THEN
         raise_application_error(-20013, 'Start Effective date cannot start after the End Effective date');
      END IF;

      --
      -- create only validations
      --
      IF l_dml_mode IN ('CREATE') THEN

         --
         -- select previous min max id to determine if end date is NULL
         --
         BEGIN
            SELECT min_max_id
              INTO l_previous_min_max_id
              FROM apps.wwt_msip_min_max_planning
             WHERE start_effective_date IN (SELECT MAX(start_effective_date)
                                              FROM apps.wwt_msip_min_max_planning
                                             WHERE start_effective_date < l_min_max_record.start_effective_date
                                               AND msip_id = l_min_max_record.msip_id)
               AND msip_id = l_min_max_record.msip_id
               AND end_effective_date IS NULL;

         EXCEPTION
            WHEN no_data_found THEN
               l_previous_min_max_id := NULL;
            WHEN others THEN
               raise_application_error(-20013, 'Error occurred during Previous Min Max ID select; Error: '||SQLERRM);

         END;

         --
         -- if previous min max id end date is NULL
         -- then we are going to end date it
         --
         IF l_previous_min_max_id IS NOT NULL THEN

            BEGIN

               --
               -- need to update the end date to start date minus one
               --
               UPDATE apps.wwt_msip_min_max_planning
                  SET end_effective_date     = TRUNC(l_min_max_record.start_effective_date - 1)
                     ,last_updated_by        = fnd_global.user_id
                     ,last_update_date       = SYSDATE
                     ,last_update_request_id = fnd_global.conc_request_id
                     ,last_update_login_id   = fnd_global.login_id
                     ,ldap_last_updated_by   = p_ldap_username
                WHERE min_max_id = l_previous_min_max_id;

                l_previous_min_max_id := NULL;

             EXCEPTION
                WHEN others THEN
                   raise_application_error(-20013, 'Error occurred during Previous Min Max ID update; Error '||SQLERRM);
             END;

         END IF;
      END IF;

      --
      -- get count of all future dates that start after this date
      --
      IF l_dml_mode IN ('CREATE') THEN

         --
         -- check to see if there are any min/max ids that start after this new record
         --
         SELECT COUNT(*)
         INTO l_after_start_date_count
         FROM apps.wwt_msip_min_max_planning
         WHERE msip_id = l_min_max_record.msip_id
            AND start_effective_date > l_min_max_record.start_effective_date;

      ELSIF l_dml_mode IN ('UPDATE') THEN

         --
         -- check to see if there are any min/max ids that start after this new record
         --
         SELECT COUNT(*)
         INTO l_after_start_date_count
         FROM apps.wwt_msip_min_max_planning
         WHERE msip_id = l_min_max_record.msip_id
            AND min_max_id != l_min_max_record.min_max_id --<-- need this for join, otherwise it will see itself and freak out
            AND start_effective_date > l_min_max_record.start_effective_date;

      END IF;

      --
      -- check to see if future date count is greater than zero
      --
      IF NVL(l_after_start_date_count, 0) > 0 THEN

         --
         -- there are Start Effective dates that begin after our date
         -- so we cannot allow the End Effective date of our date to be NULL
         --
         IF l_min_max_record.end_effective_date IS NULL THEN

            raise_application_error(-20013, 'Cannot allow End Effective Date to be NULL');

         END IF;

      END IF; -- IF NVL(l_after_start_date_count, 0) = 0...

      --
      -- get overlapping count; this is record where the start and end date falls
      -- on and between any other records data range
      --
      IF l_dml_mode IN ('CREATE') THEN

         --
         -- we need to check to ensure we can insert this record and it will
         -- not overlap any other min/max ids
         --
         SELECT COUNT(*)
           INTO l_overlapping_count
           FROM apps.wwt_msip_min_max_planning
          WHERE msip_id = l_min_max_record.msip_id
            AND (l_min_max_record.start_effective_date BETWEEN start_effective_date  AND NVL(end_effective_date, TRUNC(SYSDATE+1))
              OR l_min_max_record.end_effective_date BETWEEN start_effective_date  AND NVL(end_effective_date, TRUNC(SYSDATE+1))
              OR start_effective_date BETWEEN l_min_max_record.start_effective_date AND NVL(l_min_max_record.end_effective_date, TRUNC(SYSDATE+1))
              OR end_effective_date BETWEEN l_min_max_record.start_effective_date AND NVL(l_min_max_record.end_effective_date, TRUNC(SYSDATE+1))
              OR start_effective_date = l_min_max_record.start_effective_date);

      ELSIF l_dml_mode IN ('UPDATE') THEN

         --
         -- we need to check to ensure we can insert this record and it will
         -- not overlap any other min/max ids
         --
         SELECT COUNT(*)
           INTO l_overlapping_count
           FROM apps.wwt_msip_min_max_planning
          WHERE msip_id = l_min_max_record.msip_id
            AND min_max_id != l_min_max_record.min_max_id --<-- need this for join, otherwise it will see itself and freak out
            AND (l_min_max_record.start_effective_date BETWEEN start_effective_date  AND NVL(end_effective_date, TRUNC(SYSDATE+1))
              OR l_min_max_record.end_effective_date BETWEEN start_effective_date  AND NVL(end_effective_date, TRUNC(SYSDATE+1))
              OR start_effective_date BETWEEN l_min_max_record.start_effective_date AND NVL(l_min_max_record.end_effective_date, TRUNC(SYSDATE+1))
              OR end_effective_date BETWEEN l_min_max_record.start_effective_date AND NVL(l_min_max_record.end_effective_date, TRUNC(SYSDATE+1))
              OR start_effective_date = l_min_max_record.start_effective_date);

      END IF;

      --
      -- check if overlapping count is greater than zero
      --
      IF NVL(l_overlapping_count, 0) > 0 THEN
         raise_application_error(-20013, 'Could not create new record because the start/end date(s) overlap existing records');
      END IF;

      --
      -- check to see if there are going to be any gaps
      --
      -- checking for gap before start date
      --
      BEGIN

         SELECT TO_NUMBER(l_min_max_record.start_effective_date - end_effective_date) date_count
           INTO l_pre_start_date_gap
           FROM apps.wwt_msip_min_max_planning
          WHERE end_effective_date IN (SELECT MAX(end_effective_date)
                                           FROM apps.wwt_msip_min_max_planning
                                          WHERE end_effective_date < l_min_max_record.start_effective_date
                                            AND msip_id = l_min_max_record.msip_id)
            AND msip_id = l_min_max_record.msip_id;


      EXCEPTION
         WHEN no_data_found THEN
            l_pre_start_date_gap := 0;
         WHEN others THEN
            raise_application_error(-20013, 'Error occurred during Pre-Start Date Gap select for MSIP ID: '||l_min_max_record.msip_id||' Error: '||SQLERRM);
      END;

      IF NVL(l_pre_start_date_gap, 0) > 1 THEN
         x_message := LTRIM(x_message||'; There is a gap between last End Effective Date and Start Effective Date: '||l_min_max_record.start_effective_date, '; ');
      END IF;

      --
      -- checking for gap after end date
      --
      BEGIN
         SELECT TO_NUMBER(start_effective_date - l_min_max_record.end_effective_date) date_count
           INTO l_post_end_date_gap
           FROM apps.wwt_msip_min_max_planning
          WHERE start_effective_date IN (SELECT MIN(start_effective_date)
                                           FROM apps.wwt_msip_min_max_planning
                                          WHERE start_effective_date > l_min_max_record.end_effective_date
                                            AND msip_id = l_min_max_record.msip_id)
            AND msip_id = l_min_max_record.msip_id;

      EXCEPTION
         WHEN no_data_found THEN
            l_post_end_date_gap := 0;
         WHEN others THEN
            raise_application_error(-20013, 'Error occurred during Post End Date Gap select for MSIP ID: '||l_min_max_record.msip_id||' Error: '||SQLERRM);
      END;

      IF NVL(l_post_end_date_gap, 0) > 1 THEN
         x_message := LTRIM(x_message||'; There is a gap between End Effective Date: '||l_min_max_record.end_effective_date||' and the next Start Effective Date', '; ');
      END IF;

      l_dates_validation := 'N';

   END IF; /* date validations */

   --
   -- inserting min max id data
   --
   IF l_dml_mode IN ('CREATE') THEN


      SELECT apps.wwt_msip_min_max_planning_s.NEXTVAL
        INTO l_min_max_record.min_max_id
        FROM dual;

      l_min_max_record.created_by             := fnd_global.user_id;
      l_min_max_record.creation_date          := SYSDATE;
      l_min_max_record.last_updated_by        := fnd_global.user_id;
      l_min_max_record.last_update_date       := SYSDATE;
      l_min_max_record.last_update_request_id := fnd_global.conc_request_id;
      l_min_max_record.last_update_login_id   := fnd_global.login_id;
      l_min_max_record.ldap_last_updated_by   := p_ldap_username;

      --
      -- assign record to table
      --
      l_min_max_insert_table(l_min_max_insert_table.COUNT+1) := l_min_max_record;

      --
      -- make call to insert record
      --
      wwt_upload_msip_utilities.insert_into_min_max_table(p_min_max_tab => l_min_max_insert_table);

   --
   -- update the min max id
   --
   ELSIF l_dml_mode IN ('UPDATE') THEN

      BEGIN

         UPDATE apps.wwt_msip_min_max_planning
            SET start_effective_date   = TRUNC(NVL(l_min_max_record.start_effective_date, start_effective_date))
               ,end_effective_date     = TRUNC(NVL(l_min_max_record.end_effective_date, end_effective_date))
               ,min_level_quantity     = NVL(l_min_max_record.min_level_quantity, min_level_quantity)
               ,max_level_quantity     = NVL(l_min_max_record.max_level_quantity, max_level_quantity)
               ,notes                  = NVL(l_min_max_record.notes, notes)
               ,last_updated_by        = fnd_global.user_id
               ,last_update_date       = SYSDATE
               ,last_update_request_id = fnd_global.conc_request_id
               ,last_update_login_id   = fnd_global.login_id
               ,ldap_last_updated_by   = p_ldap_username
          WHERE min_max_id = l_min_max_record.min_max_id;

      EXCEPTION
             WHEN others THEN
                raise_application_error(-20013, 'Error occurred during Min Max ID update; Error '||SQLERRM);
      END;

   END IF;

   IF x_message IS NOT NULL THEN
       x_retcode := 1;
   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;

END create_or_modify_min_max;

/**************************************
|| purpose: to determine the release trigger timestamp
||
**************************************/
PROCEDURE determine_trigger_timestamp(p_upload_time       IN VARCHAR2
                                     ,p_msip_id          IN NUMBER
                                     ,x_release_timestamp IN OUT VARCHAR2) IS

l_next_business_day     bom_calendar_dates.next_date%TYPE;
l_loop_count            NUMBER := 0;
l_so_release_count      NUMBER := 0;
l_temp_timestamp        DATE;

BEGIN

   wwt_runtime_utilities.debug (7, 'begin Determine Trigger Timestamp (dtt)');
   wwt_runtime_utilities.debug (7, 'dtt.upload time => '||TO_DATE(p_upload_time, 'DD-MON-RRRR HH24:MI:SS'));

   --
   -- determine if there is already an open trigger timestamp;
   -- this would be a trigger that has occurred since the last SO RELEASE.
   -- We want to keep using the same trigger timestamp until an SO RELEASE occurs
   --
   BEGIN

      l_loop_count := 0;
      l_temp_timestamp := NULL;

      LOOP  /* find previous trigger_timestamp */

         l_loop_count :=  (l_loop_count + 1);

         --
         -- select previous trigger_timestamp sysdate-x
         --
         SELECT MIN(mii.release_timestamp) trigger_timestamp
           INTO l_temp_timestamp
           FROM wwt_msip_item_inventory mii
          WHERE mii.msip_id = p_msip_id
            AND mii.reason_code = 'RELEASE_TRIGGER'
            AND mii.release_timestamp IS NOT NULL
            AND TRUNC(mii.creation_date) = (SELECT TRUNC(prior_date)
                                              FROM bom_calendar_dates
                                             WHERE calendar_code = g_calendar_code
                                               AND calendar_date = TRUNC(SYSDATE-l_loop_count)
                                              );
         --
         -- previous x date does not have a trigger timestamp;
         -- exit loop
         --
         IF l_temp_timestamp IS NULL THEN
            EXIT;
         END IF;

         --
         -- check to ensure there was no SO Release
         -- sysdate-x
         --
         SELECT COUNT(mii2.creation_date)
           INTO l_so_release_count
           FROM apps.wwt_msip_item_inventory mii2
          WHERE mii2.msip_id = p_msip_id
            AND mii2.reason_code = 'SO_RELEASE'
            AND TRUNC(mii2.creation_date) = TRUNC(SYSDATE-l_loop_count);

         --
         -- check if a SO release occurred on this day;
         -- if so, we want to exit
         --
         IF NVL(l_so_release_count, 0) > 0  THEN
            EXIT;
         END IF;

         --
         -- trigger timestamp must be valid;
         -- so we will assign but keep looking for
         -- an eariler version
         --
         x_release_timestamp := TO_CHAR(l_temp_timestamp, 'DD-MON-RRRR HH24:MI:SS');

      END LOOP;

   EXCEPTION
      WHEN no_data_found THEN
         x_release_timestamp := NULL;
      WHEN others THEN
         raise_application_error(-20013, 'Determine if release trigger already exists query error: '||SUBSTR(SQLERRM, 1, 120));

   END;

   --
   -- a release trigger exists since last SO RELEASE;
   -- so we are going to use that one instead of deriving one
   --
   IF x_release_timestamp IS NOT NULL THEN
      RETURN;
   END IF;

   --
   -- determine trigger timestamp
   --
   IF TO_NUMBER(TO_CHAR(TO_DATE(p_upload_time, 'DD-MON-RRRR HH24:MI:SS'), 'HH24')) < TO_NUMBER(g_less_than_release_hour) THEN
      x_release_timestamp := TO_CHAR(TO_DATE(TRUNC(TO_DATE(p_upload_time, 'DD-MON-RRRR HH24:MI:SS'))
                                                  ||' '||g_release_hour
                                            , 'DD-MON-RRRR HH24:MI:SS')
                                     , 'DD-MON-RRRR HH24:MI:SS'
                                     );

   ELSIF TO_NUMBER(TO_CHAR(TO_DATE(p_upload_time, 'DD-MON-RRRR HH24:MI:SS'), 'HH24')) > TO_NUMBER(g_greater_than_release_hour) THEN

      --
      -- we need to select the next business day
      --
      SELECT TO_CHAR(next_date, 'DD-MON-RRRR')
        INTO l_next_business_day
        FROM bom_calendar_dates
       WHERE calendar_code = g_calendar_code
         AND calendar_date = TRUNC(SYSDATE+1)
      ORDER BY calendar_date;

      x_release_timestamp := TO_CHAR(TO_DATE(TO_DATE(l_next_business_day, 'DD-MON-RRRR')||' '||g_release_hour
                                            , 'DD-MON-RRRR HH24:MI:SS')
                                    , 'DD-MON-RRRR HH24:MI:SS'
                                    );

   ELSE--IF TO_CHAR(TO_DATE(p_upload_time, 'DD-MON-RRRR HH24:MI:SS'), 'HH24') BETWEEN 9 AND 15 THEN
      x_release_timestamp := TO_CHAR(TO_DATE(p_upload_time, 'DD-MON-RRRR HH24:MI:SS')
                                    , 'DD-MON-RRRR HH24:MI:SS'
                                    );


   END IF;

   wwt_runtime_utilities.debug (7, 'dtt.release time => '||TO_DATE(x_release_timestamp, 'DD-MON-RRRR HH24:MI:SS'));

EXCEPTION
   WHEN OTHERS THEN
      raise_application_error(-20013, 'Determine Release Trigger Timestamp procedure error: '||SUBSTR(SQLERRM, 1, 120));

END determine_trigger_timestamp;

/**************************************
|| purpose: to get the next revision for msip id. this is done by getting the max
|| revision and adding one to it. New revisions are created per file.
**************************************/
PROCEDURE get_next_inventory_revision(p_msip_id  IN   wwt_msip_item_inventory.msip_id%TYPE
                                     ,x_revision OUT  NUMBER
                                     ,x_errbuff  OUT  VARCHAR2) IS

BEGIN

   x_errbuff := NULL;

   BEGIN

      x_revision := (g_msip_id_revision_tab(p_msip_id)+1);

   EXCEPTION
      WHEN no_data_found THEN

         SELECT NVL(MAX(revision), 0)+1
           INTO x_revision
           FROM wwt_msip_item_inventory
          WHERE msip_id = p_msip_id;
    END;

    --
    -- the reason for capturing this info is because in the case
    -- of the same msip id on the same file, we need to keep
    -- track of the latest revisions we are generating.
    --
    g_msip_id_revision_tab(p_msip_id) := x_revision;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := SQLERRM;

END get_next_inventory_revision;

/**************************************
|| purpose: to get outstanding quantity. this is done by getting the outstanding qty
|| of the current revision minus the received qty per the misp id.
||
|| During this process, we go back X days to get the receipt qty. I hope you are
|| reading this, because this is actually IMPORTANT. Changing this value could result
|| in inaccruate data. For example, if go from looking back 2 days to looking back 3,
|| then we will end up pulling a receipt qty we have already took into account, skewing
|| the oustanding qty value. If you go from 2 to 1, then we are going to miss a day of receipt
|| qty. Basically, lets hope this number does not have to change.
**************************************/
PROCEDURE get_receipt_qty(p_msip_id         IN   wwt_msip_item_inventory.msip_id%TYPE
                         ,p_warehouse       IN   wwt_msip_planning_item.warehouse%TYPE
                         ,x_receipt_qty     OUT  wwt_msip_receipt_history.receipt_quantity%TYPE
                         ,x_errbuff         OUT  VARCHAR2
                         ,x_retcode         OUT  NUMBER
                         ,p_ldap_username   IN   VARCHAR2) IS

CURSOR get_receipt_qty_cur (cp_msip_id    NUMBER
                           ,cp_end_date   DATE) IS
   SELECT receipt_id
         ,receipt_quantity
        FROM wwt_msip_receipt_history
       WHERE msip_id = cp_msip_id
         AND TRUNC(creation_date) <= cp_end_date
         AND NVL(consumed_flag, 'N') != 'Y';

l_last_business_date       DATE;
l_day_of_week              VARCHAR2(10);
l_previous_business_day_x  PLS_INTEGER;
l_business_day_count       PLS_INTEGER := 0;
l_previous_x               PLS_INTEGER := 1;

BEGIN

   wwt_runtime_utilities.debug (5, 'begin Get Receipt Qty(grq)');

   x_receipt_qty := 0;

   --
   -- get reverse business date count per warehouse
   --
   l_previous_business_day_x := TO_NUMBER(wwt_upload_generic_ext_util.get_upload_constant_value ('WAREHOUSE_PREVIOUS_BUSINESS_COUNT',
                                                                                                 p_warehouse,
                                                                                                 x_retcode,
                                                                                                 x_errbuff
                                                                                                 ));

   wwt_runtime_utilities.debug (5, 'grq.previous business day count => '||l_previous_business_day_x);

   IF x_errbuff IS NOT NULL THEN
      RETURN;
   END IF;

   IF l_previous_business_day_x = 0 THEN
      l_last_business_date  := TRUNC(SYSDATE);
   ELSE

      SELECT prior_date
        INTO l_last_business_date
        FROM bom_calendar_dates
       WHERE calendar_code = g_calendar_code
         AND calendar_date = TRUNC(SYSDATE - l_previous_business_day_x)
      ORDER BY calendar_date;

   END IF;

   wwt_runtime_utilities.debug (5, 'grq.end date => '||l_last_business_date);

   FOR get_receipt_qty_rec IN get_receipt_qty_cur (cp_msip_id    => p_msip_id
                                                  ,cp_end_date   => l_last_business_date)
   LOOP

      wwt_runtime_utilities.debug (7, 'grq.receipt qty found for receipt id => '||get_receipt_qty_rec.receipt_id);
      wwt_runtime_utilities.debug (7, 'grq.receipt qty => '||get_receipt_qty_rec.receipt_quantity);

      BEGIN

         UPDATE wwt_msip_receipt_history
            SET consumed_flag = 'Y'
               ,last_updated_by        = fnd_global.user_id
               ,last_update_date       = SYSDATE
               ,last_update_request_id = fnd_global.conc_request_id
               ,last_update_login_id   = fnd_global.login_id
               ,ldap_last_updated_by   = p_ldap_username
          WHERE receipt_id = get_receipt_qty_rec.receipt_id;

         x_receipt_qty := (NVL(x_receipt_qty, 0) + get_receipt_qty_rec.receipt_quantity);

      END;

   END LOOP get_receipt_qty_rec;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := 'Get Receipt Qty Error: '||SQLERRM;

END get_receipt_qty;

/*************************
|| purpose: takes in data to insert into the wwt_msip_shipment_info table. Being called from APEX.
|| This procedure does not do a commit nor rollback. the calling procedure is responsible.
*************************/
PROCEDURE insert_shipment_data(p_shipment_id    IN NUMBER
                              ,p_sla_met        IN VARCHAR2
                              ,p_sla_measurable IN VARCHAR2
                              ,p_notes          IN VARCHAR2
                              ,p_ldap_username  IN VARCHAR2
                              ,x_errbuff        OUT VARCHAR2) IS

l_shipment_id_exists             VARCHAR2(1) := 'N';

BEGIN

   x_errbuff := NULL;

   --
   -- check to see if the shipment ID already exists in the table
   --
   BEGIN

      SELECT 'Y'
        INTO l_shipment_id_exists
        FROM wwt_msip_shipment_info
       WHERE shipment_id = p_shipment_id;

   EXCEPTION
      WHEN no_data_found THEN
        l_shipment_id_exists := 'N';
   END;

   --
   -- if shipment ID already exists, then update that record
   --
   IF (l_shipment_id_exists = 'Y') THEN

      UPDATE apps.wwt_msip_shipment_info
         SET sla_met = NVL(p_sla_met, sla_met)
            ,sla_measurable = NVL(p_sla_measurable, sla_measurable)
            ,notes = NVL(p_notes, notes)
            ,last_update_date = SYSDATE
            ,ldap_last_updated_by = p_ldap_username
       WHERE shipment_id = p_shipment_id;

   ELSE

      INSERT INTO apps.wwt_msip_shipment_info
           VALUES(p_shipment_id, p_sla_met, p_sla_measurable, p_notes, fnd_global.user_id, SYSDATE, fnd_global.user_id, SYSDATE,
                  fnd_global.conc_request_id, fnd_global.conc_request_id, fnd_global.login_id, fnd_global.login_id, p_ldap_username, p_ldap_username);

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := SUBSTR(SQLERRM, 1, 120);

END insert_shipment_data;

/*************************
|| purpose: takes in the SO and item info to derive SO Line info
|| and insert a new record into the release table and a new revision
|| in the item inventory table. Being called from APEX.
|| This procedure does not do a commit nor rollback. the calling procedure is responsible.
*************************/
PROCEDURE perform_release(p_inventory_id        IN NUMBER
                         ,p_so_number           IN NUMBER
                         ,p_sla_measurable      IN VARCHAR2
                         ,p_notes               IN VARCHAR2
                         ,p_trigger_timestamp   IN DATE
                         ,p_ldap_username       IN VARCHAR2
                         ,x_errbuff            OUT VARCHAR2) IS

l_release_table            wwt_upload_msip_utilities.msip_release_tabtype;
l_so_line_id               oe_order_lines_all.line_id%TYPE;
l_so_line_qty              oe_order_lines_all.ordered_quantity%TYPE;
l_so_line_id_exists        VARCHAR2(1);
l_trigger_timestamp        DATE;
l_inventory_tab            wwt_upload_msip_utilities.msip_inventory_tabtype;
l_release_timestamp        wwt_msip_item_inventory.release_timestamp%TYPE;

BEGIN

   x_errbuff := NULL;

   --
   -- get SO Item info
   --
   BEGIN /* get SO Item info */

       SELECT item.quantity,
            (SELECT MIN(line_id) so_line_id
               FROM oe_order_lines_all
             WHERE NVL(cancelled_flag,'N') <> 'Y'
               AND header_id = item.header_id
               AND line_number = item.line_number) so_line_id
        INTO l_so_line_qty
            ,l_so_line_id
        FROM (SELECT SUM(oola.ordered_quantity) quantity
                    ,oola.line_number
                    ,ooha.header_id
                FROM apps.oe_order_headers_all ooha
                    ,apps.oe_order_lines_all oola
                    ,apps.ra_salesreps_all ras
                    ,apps.wwt_so_headers_dff wsdf
                    ,wwt_so_lines_dff wsld
                    ,(SELECT mpi.inventory_item_id, mpi.warehouse, mpi.service_line, mpi.project, mpi.msip_id
                        FROM apps.wwt_msip_planning_item mpi
                            ,apps.wwt_msip_item_inventory mii
                       WHERE mii.inventory_id = p_inventory_id
                         AND mpi.msip_id = mii.msip_id) item_info
              WHERE ooha.salesrep_id = ras.salesrep_id
                AND ras.name = 'CDSD - MSIP'
                AND ooha.header_id = wsdf.header_id
                AND ooha.header_id = oola.header_id
                AND ooha.order_number = p_so_number
                AND NVL(ooha.booked_flag,'N') = 'Y'
                AND oola.inventory_item_id = item_info.inventory_item_id
                AND wsdf.attribute16 = item_info.warehouse
                AND wsdf.attribute17 = item_info.service_line
                AND wsdf.attribute19 = item_info.project
                AND oola.line_id = wsld.line_id
                AND wsld.attribute35 = TO_CHAR(item_info.msip_id)
                AND NVL(oola.cancelled_flag,'N') <> 'Y'
           GROUP BY oola.line_number,ooha.header_id) item;


   EXCEPTION
      WHEN no_data_found THEN
         x_errbuff := 'Could not determine SO Line ID for SO: '||p_so_number||'; Error: No SO Line data found';
      WHEN too_many_rows THEN
         x_errbuff := 'Could not determine SO Line ID for SO: '||p_so_number||'; Error: Too many SO Lines was found';
      WHEN OTHERS THEN
         x_errbuff := 'Unexpected error during SO info select for SO: '||p_so_number||'; Error: '||SQLERRM;
   END; /* get SO Item info */

   --
   -- check if errbuff is NULL; if it is not NULL then we will not continue
   --
   IF x_errbuff IS NOT NULL THEN
      RETURN;
   END IF;

   --
   -- check to make sure SO Line ID does not already exists
   --
   BEGIN /* SO Line ID check */

      SELECT 'Y'
        INTO l_so_line_id_exists
        FROM wwt_msip_release
       WHERE so_line_id = l_so_line_id;

      IF NVL(l_so_line_id_exists, 'N') = 'Y' THEN
         x_errbuff := 'SO Line ID: '||l_so_line_id||' already exists in MSIP Release table';
         RETURN;
      END IF;

   EXCEPTION
      WHEN no_data_found THEN
         NULL;
   END; /* SO Line ID check */

   --
   -- assign to relase table array
   --
   SELECT wwt_msip_release_s.NEXTVAL
     INTO l_release_table(l_release_table.COUNT+1).release_id
     FROM DUAL;

   --
   -- does trigger timestamp info exist
   --
   IF p_trigger_timestamp IS NOT NULL THEN
      l_release_timestamp := p_trigger_timestamp;
   ELSE
      --
      -- get trigger timestamp
      --
      BEGIN

         SELECT release_timestamp
           INTO l_release_timestamp --l_release_table(l_release_table.COUNT).trigger_timestamp
           FROM wwt_msip_item_inventory mii
          WHERE mii.inventory_id = p_inventory_id;

         IF l_release_timestamp IS NULL THEN
            l_release_timestamp := SYSDATE;
         END IF;

      EXCEPTION
         WHEN no_data_found THEN
            l_release_table(l_release_table.COUNT).trigger_timestamp := SYSDATE;
      END;
   END IF;

   l_release_table(l_release_table.COUNT).trigger_timestamp      := l_release_timestamp;
   l_release_table(l_release_table.COUNT).inventory_id_reference := p_inventory_id;
   l_release_table(l_release_table.COUNT).released_quantity      := l_so_line_qty;
   l_release_table(l_release_table.COUNT).so_line_id             := l_so_line_id;
   l_release_table(l_release_table.COUNT).sla_measurable         := p_sla_measurable;
   l_release_table(l_release_table.COUNT).notes                  := p_notes;
   l_release_table(l_release_table.COUNT).created_by             := fnd_global.user_id;
   l_release_table(l_release_table.COUNT).creation_date          := SYSDATE;
   l_release_table(l_release_table.COUNT).last_updated_by        := fnd_global.user_id;
   l_release_table(l_release_table.COUNT).last_update_date       := SYSDATE;
   l_release_table(l_release_table.COUNT).request_id             := fnd_global.conc_request_id;
   l_release_table(l_release_table.COUNT).last_update_request_id := fnd_global.conc_request_id;
   l_release_table(l_release_table.COUNT).login_id               := fnd_global.login_id;
   l_release_table(l_release_table.COUNT).last_update_login_id   := fnd_global.login_id;
   l_release_table(l_release_table.COUNT).ldap_created_by        := p_ldap_username;
   l_release_table(l_release_table.COUNT).ldap_last_updated_by   := p_ldap_username;

   --
   -- insert into release table
   --
   wwt_upload_msip_utilities.insert_into_release_table(p_release_rec_tab => l_release_table);

   l_release_table.DELETE;

   --
   -- need to create new revision of inventory id
   --
   -- select the current revision info based in the inventory id
   --
   SELECT *
     INTO l_inventory_tab(1)
     FROM wwt_msip_item_inventory
    WHERE inventory_id = p_inventory_id;

   --
   -- generate new inventory ID
   --
   SELECT wwt_msip_item_inventory_s.NEXTVAL
     INTO l_inventory_tab(1).inventory_id
     FROM DUAL;

   --
   -- create new revision
   --
   SELECT NVL(MAX(revision), 0)+1
     INTO l_inventory_tab(1).revision
     FROM wwt_msip_item_inventory
    WHERE msip_id = (SELECT DISTINCT msip_id
                       FROM wwt_msip_item_inventory
                      WHERE inventory_id = p_inventory_id);

   --
   -- add the SO Line Qty to the current outstanding qty
   --
   l_inventory_tab(1).outstanding_quantity   := (l_inventory_tab(1).outstanding_quantity + l_so_line_qty);

   l_inventory_tab(1).reason_code            := 'SO_RELEASE';
   l_inventory_tab(1).release_timestamp      := l_release_timestamp;
   l_inventory_tab(1).created_by             := fnd_global.user_id;
   l_inventory_tab(1).creation_date          := SYSDATE;
   l_inventory_tab(1).last_updated_by        := fnd_global.user_id;
   l_inventory_tab(1).last_update_date       := SYSDATE;
   l_inventory_tab(1).request_id             := fnd_global.conc_request_id;
   l_inventory_tab(1).last_update_request_id := fnd_global.conc_request_id;
   l_inventory_tab(1).login_id               := fnd_global.login_id;
   l_inventory_tab(1).last_update_login_id   := fnd_global.login_id;
   l_inventory_tab(1).ldap_created_by        := p_ldap_username;
   l_inventory_tab(1).ldap_last_updated_by   := p_ldap_username;

   --
   -- insert into inventory table
   --
   wwt_upload_msip_utilities.insert_into_inventory_table(p_inventory_rec_tab => l_inventory_tab);

   l_inventory_tab.DELETE;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := SUBSTR(SQLERRM, 1, 120);

END perform_release;

/*************************
|| purpose: to manually adjust the inventory oustanding qty. Called by APEX.
|| This procedure does not do a commit nor rollback. the calling procedure is responsible.
*************************/
PROCEDURE adjust_inv_outstanding_qty(p_msip_id         IN  NUMBER
                                    ,p_adjustment_qty  IN  NUMBER
                                    ,p_notes           IN  VARCHAR2
                                    ,p_ldap_username   IN  VARCHAR2
                                    ,x_errbuff         OUT VARCHAR2) IS

l_inventory_tab            wwt_upload_msip_utilities.msip_inventory_tabtype;

BEGIN

   x_errbuff := NULL;

   --
   -- need to create new revision of inventory id
   --
   -- select the current revision info based in the inventory id
   --
   SELECT mii1.*
     INTO l_inventory_tab(1)
     FROM wwt_msip_item_inventory mii1
    WHERE mii1.revision = (SELECT MAX(mii2.revision)
                            FROM wwt_msip_item_inventory mii2
                           WHERE mii2.msip_id = p_msip_id)
      AND mii1.msip_id = p_msip_id;

   --
   -- generate new inventory ID
   --
   SELECT wwt_msip_item_inventory_s.NEXTVAL
     INTO l_inventory_tab(1).inventory_id
     FROM DUAL;

   --
   -- create new revision
   --
   l_inventory_tab(1).revision := (l_inventory_tab(1).revision + 1);

   --
   -- override current outstanding qty with the adjustment qty
   --
   l_inventory_tab(1).outstanding_quantity   := (l_inventory_tab(1).outstanding_quantity + p_adjustment_qty);

   l_inventory_tab(1).reason_code            := 'MANUAL_ADJUSTMENT';
   l_inventory_tab(1).notes                  := p_notes;
   l_inventory_tab(1).created_by             := fnd_global.user_id;
   l_inventory_tab(1).creation_date          := SYSDATE;
   l_inventory_tab(1).last_updated_by        := fnd_global.user_id;
   l_inventory_tab(1).last_update_date       := SYSDATE;
   l_inventory_tab(1).request_id             := fnd_global.conc_request_id;
   l_inventory_tab(1).last_update_request_id := fnd_global.conc_request_id;
   l_inventory_tab(1).login_id               := fnd_global.login_id;
   l_inventory_tab(1).last_update_login_id   := fnd_global.login_id;
   l_inventory_tab(1).ldap_created_by        := p_ldap_username;
   l_inventory_tab(1).ldap_last_updated_by   := p_ldap_username;

   --
   -- insert into inventory table
   --
   wwt_upload_msip_utilities.insert_into_inventory_table(p_inventory_rec_tab => l_inventory_tab);

   l_inventory_tab.DELETE;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := SUBSTR(SQLERRM, 1, 120);

END adjust_inv_outstanding_qty;

/*************************
|| purpose: get customer po info based on customer PO Number
*************************/
PROCEDURE get_customer_po_info(p_cust_po_number     IN mtl_system_items_b.segment2%TYPE
                              ,p_hardware_model     IN wwt_msip_planning_item.hardware_model%TYPE
                              ,x_warehouse         OUT wwt_msip_planning_item.warehouse%TYPE
                              ,x_service_line      OUT wwt_msip_planning_item.service_line%TYPE
                              ,x_project           OUT wwt_msip_planning_item.project%TYPE
                              ,x_errbuff           OUT VARCHAR2) IS

BEGIN

   wwt_upload_generic.LOG (2, 'BEGIN Get Customer PO Info (gcpi)');
   wwt_upload_generic.LOG (2, 'gcpi.customer_po_number => '||p_cust_po_number);
   wwt_upload_generic.LOG (2, 'gcpi.hardware_model => '||p_hardware_model);

   x_errbuff := NULL;

   --
   -- using distinct because there could be multiple order headers wtih the same cust po number
   --
   SELECT DISTINCT wsdf.attribute16 warehouse
         ,wsdf.attribute17 service_line
         ,wsdf.attribute19 pool_project
    INTO x_warehouse
        ,x_service_line
        ,x_project
    FROM oe_order_headers_all ooh
        ,oe_order_lines_all oola
        ,wwt_msip_planning_item_v mpiv
        ,ra_salesreps_all ras
        ,wwt_so_headers_dff wsdf
   WHERE ooh.salesrep_id = ras.salesrep_id
     AND ras.name = 'CDSD - MSIP'
     AND ooh.header_id = wsdf.header_id
     AND ooh.cust_po_number = p_cust_po_number
     AND ooh.header_id = oola.header_id
     AND oola.inventory_item_id = mpiv.inventory_item_id
     AND mpiv.hardware_model = p_hardware_model;

   --
   -- check to see if Warehouse is NULL
   --
   IF x_warehouse IS NULL THEN
      x_errbuff := 'Customer PO Number info Warehouse is NULL';
   END IF;

   --
   -- check to see if Service Line is NULL
   --
   IF x_service_line IS NULL THEN
      x_errbuff := 'Customer PO Number info Service Line is NULL; '||x_errbuff;
   END IF;

   --
   -- check to see if Project is NULL
   --
   IF x_project IS NULL THEN
      x_errbuff := 'Customer PO Number info Project is NULL; '||x_errbuff;
   END IF;

EXCEPTION
   WHEN no_data_found THEN
      x_errbuff := 'No data found for Customer PO Number Info: '||p_cust_po_number;
      wwt_upload_generic.LOG (1, x_errbuff);
   WHEN too_many_rows THEN
      x_errbuff := 'Too many rows found for Customer PO Number Info: '||p_cust_po_number;
      wwt_upload_generic.LOG (1, x_errbuff);
   WHEN OTHERS THEN
      x_errbuff := 'Get Customer PO Info Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, x_errbuff);
      raise_application_error(-20013, x_errbuff);

END get_customer_po_info;

/*************************
|| purpose: get msip ID based on warehouse, service line, project, hardware model
*************************/
PROCEDURE get_msip_id(p_warehouse         IN  wwt_msip_planning_item.warehouse%TYPE
                     ,p_service_line      IN  wwt_msip_planning_item.service_line%TYPE
                     ,p_project           IN  wwt_msip_planning_item.project%TYPE
                     ,p_hardware_model    IN  wwt_msip_planning_item.hardware_model%TYPE
                     ,x_msip_id           OUT wwt_msip_planning_item.msip_id%TYPE
                     ,x_errbuff           OUT VARCHAR2) IS

BEGIN

   wwt_upload_generic.LOG (2, 'BEGIN Get MSIP ID (gmi)');
   wwt_upload_generic.LOG (2, 'gmi.warehouse => '||p_warehouse);
   wwt_upload_generic.LOG (2, 'gmi.service_line => '||p_service_line);
   wwt_upload_generic.LOG (2, 'gmi.project => '||p_project);
   wwt_upload_generic.LOG (2, 'gmi.hardware_model => '||p_hardware_model);

   SELECT msip_id
     INTO x_msip_id
     FROM wwt_msip_planning_item
    WHERE warehouse = p_warehouse
      AND service_line = p_service_line
      AND project = p_project
      AND hardware_model = p_hardware_model;

EXCEPTION
   WHEN no_data_found THEN
      x_errbuff := 'No data found for MISP ID';
      wwt_upload_generic.LOG (1, x_errbuff);
   WHEN too_many_rows THEN
      x_errbuff := 'Too many rows found for MISP ID';
      wwt_upload_generic.LOG (1, x_errbuff);
   WHEN OTHERS THEN
      x_errbuff := 'Get MSIP ID Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, x_errbuff);
      raise_application_error(-20013, x_errbuff);

END get_msip_id;

/**************************************
|| purpose: to determine if a MSIP ID is "active"
**************************************/
FUNCTION is_msip_id_active(p_msip_id         IN   wwt_msip_item_inventory.msip_id%TYPE)
RETURN VARCHAR2 IS

l_is_active    VARCHAR2(1) := 'N';
l_errbuff      VARCHAR2(2000);

BEGIN

   SELECT 'Y'
     INTO l_is_active
     FROM apps.wwt_msip_planning_item wmpi
    WHERE wmpi.msip_id = p_msip_id
      AND TRUNC(NVL(wmpi.end_effective_date, SYSDATE+1)) >= TRUNC(SYSDATE);

   RETURN(l_is_active);

EXCEPTION
   WHEN no_data_found THEN
      RETURN('N');
   WHEN OTHERS THEN
      l_errbuff := 'Is MSIP ID Active Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, l_errbuff);
      raise_application_error(-20013, l_errbuff);

END is_msip_id_active;

/**************************************
|| purpose: to get the next revision for msip id. this is done by getting the max
|| revision and adding one to it. New revisions are created per file.
**************************************/
FUNCTION has_active_min_max_records(p_msip_id IN   wwt_msip_item_inventory.msip_id%TYPE)
RETURN NUMBER IS

l_min_max_rec_count    NUMBER := 0;
l_errbuff              VARCHAR2(2000);

BEGIN

   SELECT COUNT(*)
     INTO l_min_max_rec_count
     FROM wwt_msip_min_max_planning
    WHERE msip_id = p_msip_id
      AND TRUNC(start_effective_date) <= TRUNC(SYSDATE)
      AND TRUNC(NVL(end_effective_date, SYSDATE+1)) >= TRUNC(SYSDATE);

   RETURN(l_min_max_rec_count);

EXCEPTION
   WHEN no_data_found THEN
      RETURN(0);
   WHEN OTHERS THEN
      l_errbuff := 'Has Active Min Max Records Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, l_errbuff);
      raise_application_error(-20013, l_errbuff);

END has_active_min_max_records;

/*************************
|| purpose: appends temp error buff data to error buff
*************************/
PROCEDURE append_to_errbuff(x_temp_errbuff IN OUT VARCHAR2
                           ,x_errbuff      IN OUT VARCHAR2) IS

BEGIN

    --
    -- if errbuff is NULL; LTRIM will remove the ; and space out of the string
    --
    IF x_temp_errbuff IS NOT NULL THEN
        x_errbuff := SUBSTR(LTRIM(x_errbuff||'; '||x_temp_errbuff, '; '), 1, 2000);
    END IF;

    x_temp_errbuff := NULL;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := 'Append To Errbuff Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, x_errbuff);
      raise_application_error(-20013, x_errbuff);

END append_to_errbuff;

/**********************************
|| purpose: inserts into table wwt_msip_receipt_history
**********************************/
PROCEDURE insert_into_receipt_table(p_receipt_rec_tab IN msip_receipt_history_tabtype) IS

l_errors             NUMBER;
l_errbuff            VARCHAR2(2000);
dml_errors           EXCEPTION;
PRAGMA exception_init(dml_errors, -24381);

BEGIN

   wwt_upload_generic.LOG (2, 'BEGIN Insert Into Receipt Table');

   -- This is a FORALL Insert; it inserts all rows from the record table         --
   -- We are using the SAVE EXCEPTIONS option to save all errors that            --
   -- may occur during the insert till the end. When the transaction is complete --
   -- it will raise the dml_errors exception and handle errors at that point     --
   --------------------------------------------------------------------------------
   FORALL x IN p_receipt_rec_tab.first .. p_receipt_rec_tab.last SAVE EXCEPTIONS
   INSERT /*+ append */ INTO wwt_msip_receipt_history VALUES p_receipt_rec_tab(x);

EXCEPTION
   WHEN dml_errors THEN
      -- One or more rows failed in the DML --
      ----------------------------------------
      l_errors   := SQL%BULK_EXCEPTIONS.COUNT;
      l_errbuff  := 'Error(s) occured during the MSIP Receipt Table Load procedure.';

      wwt_upload_generic.LOG(1, l_errbuff);
      wwt_upload_generic.LOG(1, 'Number of INSERT statements that failed: ' || l_errors);

      FOR i IN 1.. l_errors LOOP
         wwt_upload_generic.LOG(2, 'Error # '|| i ||' occurred during iteration # '||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX
                                || ' Error message is ' || SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE), 1, 120));
      END LOOP;

      raise_application_error(-20013, l_errbuff);

   WHEN OTHERS THEN
      l_errbuff := 'MSIP Receipt Table Load Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, l_errbuff);
      raise_application_error(-20013, l_errbuff);

END insert_into_receipt_table;

/**********************************
|| purpose: inserts into table wwt_msip_item_inventory
**********************************/
PROCEDURE insert_into_inventory_table(p_inventory_rec_tab  IN  msip_inventory_tabtype) IS

l_errors             NUMBER;
l_errbuff            VARCHAR2(2000);
dml_errors           EXCEPTION;
PRAGMA exception_init(dml_errors, -24381);

BEGIN

   -- This is a FORALL Insert; it inserts all rows from the record table         --
   -- We are using the SAVE EXCEPTIONS option to save all errors that            --
   -- may occur during the insert till the end. When the transaction is complete --
   -- it will raise the dml_errors exception and handle errors at that point     --
   --------------------------------------------------------------------------------
   FORALL x IN p_inventory_rec_tab.first .. p_inventory_rec_tab.last SAVE EXCEPTIONS
   INSERT /*+ append */ INTO wwt_msip_item_inventory VALUES p_inventory_rec_tab(x);

EXCEPTION
   WHEN dml_errors THEN

      -- One or more rows failed in the DML --
      ----------------------------------------
      l_errbuff  := SQL%BULK_EXCEPTIONS.COUNT||' Error(s) occurred during the MSIP Inventory Table Load procedure. Error # 1 occurred during iteration # '||SQL%BULK_EXCEPTIONS(1).ERROR_INDEX
                                || ' Error message is ' || SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE), 1, 120);

      raise_application_error(-20013, l_errbuff);

   WHEN OTHERS THEN
      l_errbuff := 'MSIP Inventory Table Load Error: '||SUBSTR(SQLERRM, 1, 120);
      raise_application_error(-20013, l_errbuff);

END insert_into_inventory_table;

/**********************************
|| purpose: inserts into table wwt_msip_usage
**********************************/
PROCEDURE insert_into_usage_table(p_usage_rec_tab  IN  msip_usage_tabtype) IS

l_errors             NUMBER;
l_errbuff            VARCHAR2(2000);
dml_errors           EXCEPTION;
PRAGMA exception_init(dml_errors, -24381);

BEGIN

   wwt_upload_generic.LOG (2, 'BEGIN Insert Into Usage Table');

   -- This is a FORALL Insert; it inserts all rows from the record table         --
   -- We are using the SAVE EXCEPTIONS option to save all errors that            --
   -- may occur during the insert till the end. When the transaction is complete --
   -- it will raise the dml_errors exception and handle errors at that point     --
   --------------------------------------------------------------------------------
   FORALL x IN p_usage_rec_tab.first .. p_usage_rec_tab.last SAVE EXCEPTIONS
   INSERT /*+ append */ INTO wwt_msip_usage VALUES p_usage_rec_tab(x);

EXCEPTION
   WHEN dml_errors THEN
      -- One or more rows failed in the DML --
      ----------------------------------------
      l_errors   := SQL%BULK_EXCEPTIONS.COUNT;
      l_errbuff  := 'Error(s) occured during the MSIP Usage Table Load procedure.';

      wwt_upload_generic.LOG(1, l_errbuff);
      wwt_upload_generic.LOG(1, 'Number of INSERT statements that failed: ' || l_errors);

      FOR i IN 1.. l_errors LOOP
         wwt_upload_generic.LOG(2, 'Error # '|| i ||' occurred during iteration # '||SQL%BULK_EXCEPTIONS(i).ERROR_INDEX
                                || ' Error message is ' || SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE), 1, 120));
      END LOOP;

      raise_application_error(-20013, l_errbuff);

   WHEN OTHERS THEN
      l_errbuff := 'MSIP Usage Table Load Error: '||SUBSTR(SQLERRM, 1, 120);
      wwt_upload_generic.LOG (1, l_errbuff);
      raise_application_error(-20013, l_errbuff);

END insert_into_usage_table;

/**********************************
|| purpose: inserts into table wwt_msip_release
**********************************/
PROCEDURE insert_into_release_table(p_release_rec_tab  IN  msip_release_tabtype) IS

l_errbuff            VARCHAR2(2000);
dml_errors           EXCEPTION;
PRAGMA exception_init(dml_errors, -24381);

BEGIN

   -- This is a FORALL Insert; it inserts all rows from the record table         --
   -- We are using the SAVE EXCEPTIONS option to save all errors that            --
   -- may occur during the insert till the end. When the transaction is complete --
   -- it will raise the dml_errors exception and handle errors at that point     --
   --------------------------------------------------------------------------------
   FORALL x IN p_release_rec_tab.first .. p_release_rec_tab.last SAVE EXCEPTIONS
   INSERT /*+ append */ INTO wwt_msip_release VALUES p_release_rec_tab(x);

EXCEPTION
   WHEN dml_errors THEN
      -- One or more rows failed in the DML --
      ----------------------------------------
      l_errbuff  := SQL%BULK_EXCEPTIONS.COUNT||' Error(s) occurred during the MSIP Release Table Load procedure. Error # 1 occurred during iteration # '||SQL%BULK_EXCEPTIONS(1).ERROR_INDEX
                                || ' Error message is ' || SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE), 1, 120);

      raise_application_error(-20013, l_errbuff);

   WHEN OTHERS THEN
      l_errbuff := 'MSIP Release Table Load Error: '||SUBSTR(SQLERRM, 1, 120);
      raise_application_error(-20013, l_errbuff);

END insert_into_release_table;

/**********************************
|| purpose: inserts into table wwt_msip_min_max_planning
**********************************/
PROCEDURE insert_into_min_max_table(p_min_max_tab  IN  msip_min_max_tabtype) IS

l_errbuff            VARCHAR2(2000);
dml_errors           EXCEPTION;
PRAGMA exception_init(dml_errors, -24381);

BEGIN

   -- This is a FORALL Insert; it inserts all rows from the record table         --
   -- We are using the SAVE EXCEPTIONS option to save all errors that            --
   -- may occur during the insert till the end. When the transaction is complete --
   -- it will raise the dml_errors exception and handle errors at that point     --
   --------------------------------------------------------------------------------
   FORALL x IN p_min_max_tab.first .. p_min_max_tab.last SAVE EXCEPTIONS
   INSERT /*+ append */ INTO wwt_msip_min_max_planning VALUES p_min_max_tab(x);

EXCEPTION
   WHEN dml_errors THEN
      -- One or more rows failed in the DML --
      ----------------------------------------
      l_errbuff  := SQL%BULK_EXCEPTIONS.COUNT||' Error(s) occurred during the MSIP Min Max Table Load procedure. Error # 1 occurred during iteration # '||SQL%BULK_EXCEPTIONS(1).ERROR_INDEX
                                || ' Error message is ' || SUBSTR(SQLERRM(-SQL%BULK_EXCEPTIONS(1).ERROR_CODE), 1, 120);

      raise_application_error(-20013, l_errbuff);

   WHEN OTHERS THEN
      l_errbuff := 'MSIP Min Max Table Load Error: '||SUBSTR(SQLERRM, 1, 120);
      raise_application_error(-20013, l_errbuff);

END insert_into_min_max_table;

/**************************************
|| purpose: this determines if we need to create a release trigger.
|| release triggers are created if the sum of outstanding qty and on-hand qty is less than the min level qty
**************************************/
PROCEDURE release_trigger(x_inventory_tab         IN OUT  msip_inventory_tabtype
                         ,p_inventory_id          IN      apps.wwt_msip_item_inventory.inventory_id%TYPE
                         ,p_use_current_array_rec IN      VARCHAR2 DEFAULT 'Y'
                         ,p_ldap_username         IN      VARCHAR2 DEFAULT NULL
                         ,p_upload_timestamp      IN      VARCHAR2 DEFAULT NULL) IS

l_inventory_table_rec      apps.wwt_msip_item_inventory%ROWTYPE;
l_errbuff                  VARCHAR2(2000);
l_release_timestamp        VARCHAR2(30);

BEGIN

   wwt_runtime_utilities.debug (5, 'begin release trigger (rt)');
   wwt_runtime_utilities.debug (5, 'rt.inventory_id => '||p_inventory_id);
   wwt_runtime_utilities.debug (5, 'rt.inventory array count => '||x_inventory_tab.COUNT);
   wwt_runtime_utilities.debug (5, 'rt.use current array rec => '||p_use_current_array_rec);
   wwt_runtime_utilities.debug (5, 'rt.upload timestamp => '||TO_CHAR(TO_DATE(p_upload_timestamp, 'DD-MON-RRRR HH24:MI:SS'), 'DD-MON-RRRR HH24:MI:SS'));

   --
   -- if table is empty, then select inventory data based on inventory ID
   --
   IF (NVL(x_inventory_tab.COUNT, 0) < 1)
     OR (p_use_current_array_rec != 'Y')
   THEN

      SELECT *
        INTO l_inventory_table_rec
        FROM wwt_msip_item_inventory
       WHERE inventory_id = p_inventory_id;

   ELSE

      --
      -- assign current record to local record
      --
      l_inventory_table_rec := x_inventory_tab(x_inventory_tab.COUNT);

   END IF;

   --
   -- determine we need a release trigger
   -- if inventory qty plus oustanding qty is less than the min level qty
   -- we need to release a trigger
   --
   IF (NVL(l_inventory_table_rec.inventory_quantity, 0) + NVL(l_inventory_table_rec.outstanding_quantity, 0) - NVL(l_inventory_table_rec.reserve_quantity, 0))
        < l_inventory_table_rec.min_level_quantity
   THEN

      wwt_runtime_utilities.debug (5, 'rt.trigger being released');

      --
      -- create a release trigger record
      --
      -- assign to inventory table array
      --
      SELECT wwt_msip_item_inventory_s.NEXTVAL
        INTO x_inventory_tab(x_inventory_tab.COUNT+1).inventory_id
        FROM DUAL;

      --
      -- get next revision
      --
      get_next_inventory_revision(p_msip_id  => l_inventory_table_rec.msip_id
                                 ,x_revision => x_inventory_tab(x_inventory_tab.COUNT).revision
                                 ,x_errbuff  => l_errbuff);

      IF l_errbuff IS NOT NULL THEN
         raise_application_error(-20013, l_errbuff);
      END IF;

      wwt_runtime_utilities.debug (5, 'rt.new revision => '||x_inventory_tab(x_inventory_tab.COUNT).revision);

      x_inventory_tab(x_inventory_tab.COUNT).msip_id                := l_inventory_table_rec.msip_id;
      x_inventory_tab(x_inventory_tab.COUNT).inventory_quantity     := l_inventory_table_rec.inventory_quantity;
      x_inventory_tab(x_inventory_tab.COUNT).outstanding_quantity   := l_inventory_table_rec.outstanding_quantity;
      x_inventory_tab(x_inventory_tab.COUNT).reserve_quantity       := l_inventory_table_rec.reserve_quantity;
      x_inventory_tab(x_inventory_tab.COUNT).min_level_quantity     := l_inventory_table_rec.min_level_quantity;
      x_inventory_tab(x_inventory_tab.COUNT).max_level_quantity     := l_inventory_table_rec.max_level_quantity;
      x_inventory_tab(x_inventory_tab.COUNT).reason_code            := 'RELEASE_TRIGGER';
      x_inventory_tab(x_inventory_tab.COUNT).created_by             := l_inventory_table_rec.created_by;
      x_inventory_tab(x_inventory_tab.COUNT).creation_date          := SYSDATE;
      x_inventory_tab(x_inventory_tab.COUNT).last_updated_by        := l_inventory_table_rec.last_updated_by;
      x_inventory_tab(x_inventory_tab.COUNT).last_update_date       := SYSDATE;
      x_inventory_tab(x_inventory_tab.COUNT).request_id             := l_inventory_table_rec.request_id;
      x_inventory_tab(x_inventory_tab.COUNT).last_update_request_id := l_inventory_table_rec.last_update_request_id;
      x_inventory_tab(x_inventory_tab.COUNT).login_id               := l_inventory_table_rec.login_id;
      x_inventory_tab(x_inventory_tab.COUNT).last_update_login_id   := l_inventory_table_rec.last_update_login_id;
      x_inventory_tab(x_inventory_tab.COUNT).ldap_created_by        := p_ldap_username;
      x_inventory_tab(x_inventory_tab.COUNT).ldap_last_updated_by   := p_ldap_username;

      --
      -- determine trigger timestamp
      --
      determine_trigger_timestamp(p_upload_time       => p_upload_timestamp
                                 ,p_msip_id           => l_inventory_table_rec.msip_id
                                 ,x_release_timestamp => l_release_timestamp);

      wwt_runtime_utilities.debug (5, 'rt.release timestamp => '||TO_CHAR(TO_DATE(l_release_timestamp, 'DD-MON-RRRR HH24:MI:SS'), 'DD-MON-RRRR HH24:MI:SS'));

      x_inventory_tab(x_inventory_tab.COUNT).release_timestamp := TO_DATE(l_release_timestamp, 'DD-MON-RRRR HH24:MI:SS');

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      raise_application_error(-20013, 'Release Trigger procedure error: '||SUBSTR(SQLERRM, 1, 120));

END release_trigger;

/**********************************
|| purpose: checks against the application log table per warehouse
|| to determine if they have sent over the files for the day.
**********************************/
PROCEDURE files_processed_successfully(p_warehouse         IN wwt_msip_planning_item.warehouse%TYPE
                                      ,x_files_processed  OUT BOOLEAN
                                      ,x_upload_timestamp OUT VARCHAR2) IS


l_inventory_upload_time       VARCHAR2(30);
l_receipt_upload_time         VARCHAR2(30);

BEGIN

   wwt_runtime_utilities.debug (5, 'begin files processed for warehouse(fps)');

   x_files_processed := FALSE;

   BEGIN /* check Inventory upload */

      SELECT TO_CHAR(MAX(creation_date), 'DD-MON-RRRR HH24:MI:SS')
        INTO l_inventory_upload_time
        FROM wwt_application_log
       WHERE application_name = 'MSIP_CUSTOMER_UPLOAD'
         AND module_name = 'INVENTORY'
         AND TRUNC(creation_date) = TRUNC(SYSDATE)
         AND INSTR(reference_value, p_warehouse) > 0
         AND severity_level = apps.wwt_application_logger.g_info;

   EXCEPTION
      WHEN no_data_found THEN
         l_inventory_upload_time := NULL;
   END;

   BEGIN /* check PO Receipt upload */

      SELECT TO_CHAR(MAX(creation_date), 'DD-MON-RRRR HH24:MI:SS')
        INTO l_receipt_upload_time
        FROM wwt_application_log
       WHERE application_name = 'MSIP_CUSTOMER_UPLOAD'
         AND module_name = 'PO_RECEIPT'
         AND TRUNC(creation_date) = TRUNC(SYSDATE)
         AND INSTR(reference_value, p_warehouse) > 0
         AND severity_level = apps.wwt_application_logger.g_info;

    EXCEPTION
       WHEN no_data_found THEN
          l_receipt_upload_time := NULL;
    END;

    wwt_runtime_utilities.debug (5, 'fps.inventory upload time: '||TO_DATE(l_inventory_upload_time, 'DD-MON-RRRR HH24:MI:SS'));
    wwt_runtime_utilities.debug (5, 'fps.receipt upload time: '||TO_DATE(l_receipt_upload_time, 'DD-MON-RRRR HH24:MI:SS'));

    --
    -- check to see if we have upload times for both files
    --
    IF (l_inventory_upload_time IS NOT NULL)
      AND (l_receipt_upload_time IS NOT NULL) THEN

       wwt_runtime_utilities.debug (5, 'fps.files processed: TRUE');

       x_upload_timestamp := TO_CHAR(GREATEST(TO_DATE(l_inventory_upload_time, 'DD-MON-RRRR HH24:MI:SS')
                                     ,TO_DATE(l_receipt_upload_time, 'DD-MON-RRRR HH24:MI:SS')), 'DD-MON-RRRR HH24:MI:SS');
       x_files_processed := TRUE;

       wwt_runtime_utilities.debug (5, 'fps.fps.upload timestamp => '||TO_DATE(x_upload_timestamp, 'DD-MON-RRRR HH24:MI:SS'));

    END IF;

EXCEPTION
   WHEN OTHERS THEN
      raise_application_error(-20013, 'Files Processed Successfully procedure error: '||SUBSTR(SQLERRM, 1, 120));

END files_processed_successfully;

/**********************************
|| purpose: this process verifies that the po and inventory file for
|| MSIP warehouses have been received. If not, it will send an alert.
|| If all files have been successfully processed, it will
**********************************/
PROCEDURE post_upload_process(x_errbuff                    OUT VARCHAR2
                             ,x_retcode                    OUT NUMBER
                             ,p_override_release_timestamp IN VARCHAR2 DEFAULT NULL
                             ,p_ldap_username              IN  VARCHAR2 DEFAULT NULL) IS

CURSOR planning_warehouse_cur IS
   SELECT DISTINCT UPPER(warehouse) warehouse
     FROM wwt_msip_planning_item;

--
-- this select is pulling inventory data based on
-- max revison, sysdate, and warehouse
--
CURSOR item_inventory_cur(cp_warehouse IN VARCHAR2) IS
   SELECT mii2.inventory_id
         ,mii2.msip_id
         ,mii2.outstanding_quantity
         ,mii2.revision
     FROM wwt_msip_item_inventory mii2
        , (SELECT mii.msip_id msip_id
                 ,MAX(mii.revision) revision
             FROM wwt_msip_planning_item mpi
                 ,wwt_msip_item_inventory mii
            WHERE mii.msip_id = mpi.msip_id
              AND mpi.warehouse = cp_warehouse
              AND TRUNC(mii.creation_date) = TRUNC(SYSDATE)
           GROUP BY mii.msip_id) max_revision
   WHERE mii2.msip_id = max_revision.msip_id
     AND mii2.revision = max_revision.revision;

p_files_processed              BOOLEAN;
l_receipt_qty                  wwt_msip_receipt_history.receipt_quantity%TYPE;
l_inventory_tab                wwt_upload_msip_utilities.msip_inventory_tabtype;
l_stage                        VARCHAR2(2000);
p_use_current_array_rec        VARCHAR2(1);
l_warehouse_tab                warehouse_tabtype;
l_greatest_upload_timestamp    VARCHAR2(30);
l_upload_timestamp             VARCHAR2(30);

BEGIN

   l_stage := 'Begin Post Upload Process(pup)';

   wwt_runtime_utilities.debug (1, 'pup.BEGIN post upload process');
   wwt_runtime_utilities.debug (3, 'pup.ldap username => '||p_ldap_username);
   wwt_runtime_utilities.debug (3, 'pup.override timestamp => '||p_override_release_timestamp);

   g_msip_id_revision_tab.DELETE;

   --
   -- begin warehouse cursor
   -- we want to get all the distinct planning warehouses.
   -- this keeps us from having the hard-code warehouses, or maintain a lookup
   -- if we begin to start planning for more warehouses
   --
   FOR planning_warehouse_rec IN planning_warehouse_cur LOOP

      l_stage := 'Inside Warehouse Cursor Loop; Current Warehouse: '||planning_warehouse_rec.warehouse;

      wwt_runtime_utilities.debug (3, 'pup.current warehouse => '||planning_warehouse_rec.warehouse);

      --
      -- initialize
      --
      g_calendar_code   := NULL;
      p_files_processed := FALSE;

      --
      -- check to ensure receipt and inventory files have been processed successfully
      -- per sysdate
      --
      files_processed_successfully(p_warehouse        => planning_warehouse_rec.warehouse
                                  ,x_files_processed  => p_files_processed
                                  ,x_upload_timestamp => l_upload_timestamp);

      --
      -- if files process is TRUE then we store the warehouse and start
      -- determining which upload timestamp we are going to use
      --
      IF (p_files_processed) THEN

         wwt_runtime_utilities.debug (3, 'pup.files processed');

         --
         -- assign warehouse to array
         --
         l_warehouse_tab(l_warehouse_tab.COUNT+1) := planning_warehouse_rec.warehouse;

         --
         -- get Calendar Code
         --
         g_calendar_code := wwt_upload_generic_ext_util.get_upload_constant_value('WAREHOUSE_CALENDAR_CODE',
                                                                                  planning_warehouse_rec.warehouse,
                                                                                  x_retcode,
                                                                                  x_errbuff
                                                                                  );

         wwt_runtime_utilities.debug (3, 'pup.calendar code => '||g_calendar_code);

         IF x_errbuff IS NOT NULL THEN
            raise_application_error(-20013, 'Error when determining Calendar Code, error: '||x_errbuff);
         END IF;

         wwt_runtime_utilities.debug (3, 'pup.upload timestamp => '||TO_CHAR(TO_DATE(l_upload_timestamp, 'DD-MON-RRRR HH24:MI:SS'), 'DD-MON-RRRR HH24:MI:SS'));

         --
         -- determine which timestamp we are going to use:
         -- if override release timestamp is not NULL then we will use that one
         -- otherwise we will determine which upload timestamp is the latest.
         --
         IF p_override_release_timestamp IS NOT NULL THEN
            l_greatest_upload_timestamp := TO_CHAR(TO_DATE(p_override_release_timestamp, 'DD-MON-RRRR HH24:MI:SS'), 'DD-MON-RRRR HH24:MI:SS');
         ELSE
            l_greatest_upload_timestamp := TO_CHAR(GREATEST(TO_DATE(l_upload_timestamp, 'DD-MON-RRRR HH24:MI:SS'), TO_DATE(NVL(l_greatest_upload_timestamp, l_upload_timestamp), 'DD-MON-RRRR HH24:MI:SS')), 'DD-MON-RRRR HH24:MI:SS');
         END IF;

         wwt_runtime_utilities.debug (3, 'pup.greatest upload timestamp => '||TO_CHAR(TO_DATE(l_greatest_upload_timestamp, 'DD-MON-RRRR HH24:MI:SS'), 'DD-MON-RRRR HH24:MI:SS'));

      ELSE
         raise_application_error(-20013, 'Files have not been processed Successfully for warehouse: '||planning_warehouse_rec.warehouse);

      END IF; -- (p_files_processed) OR (p_manual_release_trigger = 'Y')

   END LOOP planning_warehouse_cur;

   wwt_runtime_utilities.debug (3, 'pup.warehouse count => '||l_warehouse_tab.COUNT);
   wwt_runtime_utilities.debug (3, 'pup.greatest upload timestamp => '||TO_CHAR(TO_DATE(l_greatest_upload_timestamp, 'DD-MON-RRRR HH24:MI:SS'), 'DD-MON-RRRR HH24:MI:SS'));

   --
   -- loop over warehouses
   --
   FOR x IN 1.. l_warehouse_tab.COUNT LOOP

      l_stage := 'Inside Warehouse Process Loop; Current Warehouse: '||l_warehouse_tab(x);

      --
      -- initialize
      --
      g_less_than_release_hour      := NULL;
      g_greater_than_release_hour   := NULL;
      g_release_hour                := NULL;

      --
      -- get Less Than Release Hour
      --
      g_less_than_release_hour := wwt_upload_generic_ext_util.get_upload_constant_value('LESS_THAN_RELEASE_HOUR',
                                                                               l_warehouse_tab(x),
                                                                               x_retcode,
                                                                               x_errbuff
                                                                               );

      --
      -- get Greater Than Release Hour
      --
      g_greater_than_release_hour := wwt_upload_generic_ext_util.get_upload_constant_value('GREATER_THAN_RELEASE_HOUR',
                                                                               l_warehouse_tab(x),
                                                                               x_retcode,
                                                                               x_errbuff
                                                                               );

      --
      -- get Release Hour
      --
      g_release_hour := wwt_upload_generic_ext_util.get_upload_constant_value('RELEASE_HOUR',
                                                                               l_warehouse_tab(x),
                                                                               x_retcode,
                                                                               x_errbuff
                                                                               );

      --
      -- run inventory cursor per current warehouse and SYSDATE to determine what MSIP IDs have
      -- been processed today
      --
      FOR item_inventory_rec IN item_inventory_cur(cp_warehouse => l_warehouse_tab(x)) LOOP

         l_stage := 'Inside Inventory Item Cursor loop; Current Warehouse: '||l_warehouse_tab(x)||
                    '; Current Inventory ID: '||item_inventory_rec.inventory_id;

         p_use_current_array_rec := 'N';

         wwt_runtime_utilities.debug (5, 'pup.call receipt qty; msip id => '||item_inventory_rec.msip_id);

         --
         -- check for any po receipts
         --
         get_receipt_qty(p_msip_id         => item_inventory_rec.msip_id
                        ,p_warehouse       => l_warehouse_tab(x)
                        ,x_receipt_qty     => l_receipt_qty
                        ,x_errbuff         => x_errbuff
                        ,x_retcode         => x_retcode
                        ,p_ldap_username   => p_ldap_username);

         IF x_errbuff IS NOT NULL THEN
            x_retcode := 2;
            RETURN;
         END IF;

         wwt_runtime_utilities.debug (5, 'pup.receipt qty found => '||l_receipt_qty);

         --
         -- if receipt qty found is greater than zero, then we need to create a new item revision
         --
         IF NVL(l_receipt_qty, 0) > 0 THEN

            --
            -- need to create new revision of inventory id
            --
            -- select the current revision info based in the inventory id
            --
            SELECT *
              INTO l_inventory_tab(l_inventory_tab.COUNT+1)
              FROM wwt_msip_item_inventory
             WHERE inventory_id = item_inventory_rec.inventory_id;

            --
            -- generate new inventory ID
            --
            SELECT wwt_msip_item_inventory_s.NEXTVAL
              INTO l_inventory_tab(l_inventory_tab.COUNT).inventory_id
              FROM DUAL;

            --
            -- get next revision
            --
            get_next_inventory_revision(p_msip_id  => item_inventory_rec.msip_id
                                       ,x_revision => l_inventory_tab(l_inventory_tab.COUNT).revision
                                       ,x_errbuff  => x_errbuff);

            IF x_errbuff IS NOT NULL THEN
               x_retcode := 2;
               RETURN;
            END IF;

            wwt_runtime_utilities.debug (5, 'pup.new revision => '||l_inventory_tab(l_inventory_tab.COUNT).revision);

            --
            -- subtract the receipt qty to the current outstanding qty
            --
            l_inventory_tab(l_inventory_tab.COUNT).outstanding_quantity   := (l_inventory_tab(l_inventory_tab.COUNT).outstanding_quantity - l_receipt_qty);
            l_inventory_tab(l_inventory_tab.COUNT).reason_code            := 'PO_RECEIPT';
            l_inventory_tab(l_inventory_tab.COUNT).created_by             := fnd_global.user_id;
            l_inventory_tab(l_inventory_tab.COUNT).creation_date          := SYSDATE;
            l_inventory_tab(l_inventory_tab.COUNT).last_updated_by        := fnd_global.user_id;
            l_inventory_tab(l_inventory_tab.COUNT).last_update_date       := SYSDATE;
            l_inventory_tab(l_inventory_tab.COUNT).request_id             := fnd_global.conc_request_id;
            l_inventory_tab(l_inventory_tab.COUNT).last_update_request_id := fnd_global.conc_request_id;
            l_inventory_tab(l_inventory_tab.COUNT).login_id               := fnd_global.login_id;
            l_inventory_tab(l_inventory_tab.COUNT).last_update_login_id   := fnd_global.login_id;
            l_inventory_tab(l_inventory_tab.COUNT).ldap_created_by        := p_ldap_username;
            l_inventory_tab(l_inventory_tab.COUNT).ldap_last_updated_by   := p_ldap_username;

            --
            -- set use current array rec flag to 'Y' since we created a new array record
            --
            p_use_current_array_rec := 'Y';

         END IF; -- NVL(l_receipt_qty, 0) > 0

         --
         -- determine is we are going to do the release trigger process
         -- item has to be active and have active min/max record(s)
         --
         IF (has_active_min_max_records(p_msip_id => item_inventory_rec.msip_id) > 0)
           AND (is_msip_id_active(p_msip_id => item_inventory_rec.msip_id) = 'Y') THEN

            --
            -- check to see if we need to release a trigger
            --
            release_trigger(x_inventory_tab         => l_inventory_tab
                           ,p_inventory_id          => item_inventory_rec.inventory_id
                           ,p_use_current_array_rec => p_use_current_array_rec
                           ,p_ldap_username         => p_ldap_username
                           ,p_upload_timestamp      => l_greatest_upload_timestamp);

         END IF;

         --
         -- set use current array rec flag back to default value of 'N'
         --
         p_use_current_array_rec := 'N';

      END LOOP item_inventory_rec;

   END LOOP l_warehouse_tab;

   IF NVL(l_inventory_tab.COUNT, 0) > 0 THEN
      --
      -- insert into inventory table
      --
      wwt_upload_msip_utilities.insert_into_inventory_table(p_inventory_rec_tab => l_inventory_tab);

      l_inventory_tab.DELETE;

   END IF;

   COMMIT;

   g_msip_id_revision_tab.DELETE;

EXCEPTION
   WHEN others THEN
      x_errbuff := SUBSTR(l_stage||'; Error: '||SQLERRM, 1, 2000);
      x_retcode := 2;
      ROLLBACK;
      g_msip_id_revision_tab.DELETE;

END post_upload_process;

/**************************************
|| This procedure will update associated minmax records when an item is end dated.
|| If the item is end dated in the middle of a current active period, proc will
|| end date the minmax record, but leave quantities untouched. If the item is end
|| dated before a minmax period (future period), proc will change quantities to 0
|| and leave the dates untouched. Also will update Notes for all updates.
**************************************/
PROCEDURE modify_minmax_for_item_enddate(p_msip_id            IN NUMBER
                                        ,p_end_effective_date IN DATE
                                        ,p_ldap_username      IN VARCHAR2
                                        ,x_retcode            OUT NUMBER
                                        ,x_message            OUT VARCHAR2)
IS

BEGIN

   UPDATE wwt_msip_min_max_planning
   SET    end_effective_date = -- Update minmax end date to item end date for current period. Leave unchanged for future periods.
             (CASE
                 WHEN TRUNC(start_effective_date) <= TRUNC(p_end_effective_date) THEN
                    p_end_effective_date
                 ELSE
                    end_effective_date
              END),
          notes =
             SUBSTR('Item End Date process ' ||
                    (CASE
                        WHEN TRUNC(start_effective_date) <= TRUNC(p_end_effective_date) THEN
                           'end dated this current period'
                        ELSE
                           'set Min/Max to 0/0 from ' || to_char(min_level_quantity) || '/' || to_char(max_level_quantity)
                     END) ||
                    ' on ' || to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') ||
                    (CASE WHEN notes IS NULL THEN NULL ELSE '; ' END) || notes,
             1, 2000),
          min_level_quantity = -- Update min qty = 0 for future periods. Leave unchanged for current period.
             (CASE
                 WHEN TRUNC(start_effective_date) <= TRUNC(p_end_effective_date) THEN
                    min_level_quantity
                 ELSE
                    0
              END),
          max_level_quantity = -- Update max qty = 0 for future periods. Leave unchanged for current period.
             (CASE
                 WHEN TRUNC(start_effective_date) <= TRUNC(p_end_effective_date) THEN
                    max_level_quantity
                 ELSE
                    0
              END),
          last_updated_by = fnd_global.user_id,
          last_update_date = SYSDATE,
          last_update_request_id = fnd_global.conc_request_id,
          last_update_login_id = fnd_global.login_id,
          ldap_last_updated_by = p_ldap_username
   WHERE  msip_id = p_msip_id
   AND    p_end_effective_date < NVL(end_effective_date, p_end_effective_date+1);

EXCEPTION
   WHEN OTHERS THEN
      x_message := SQLERRM;
      x_retcode := 2;
END modify_minmax_for_item_enddate;

/**************************************
|| This procedure will update associated commitment records when an item is end dated.
|| Proc will set quantities to 0 and update notes for all future periods. Current period
|| is untouched.
**************************************/
PROCEDURE modify_cmt_for_item_enddate (p_msip_id            IN NUMBER
                                      ,p_end_effective_date IN DATE
                                      ,p_ldap_username      IN VARCHAR2
                                      ,x_retcode            OUT NUMBER
                                      ,x_message            OUT VARCHAR2)
IS

BEGIN

   UPDATE wwt_msip_target_planning
   SET    notes = SUBSTR('Item End Date process set Commitments to 0 from Qty:' ||
                         to_char(target_quantity) || ', SLA:' || NVL(attribute2,'NULL') ||
                         ', NonSLA:' || NVL(attribute3,'NULL') ||
                         ' on ' || to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS') ||
                         (CASE WHEN notes IS NULL THEN NULL ELSE '; ' END) || notes,
                  1, 2000),
          target_quantity = 0,
          attribute2 = (CASE WHEN attribute2 IS NULL THEN NULL ELSE '0' END),
          attribute3 = (CASE WHEN attribute3 IS NULL THEN NULL ELSE '0' END),
          last_updated_by = fnd_global.user_id,
          last_update_date = SYSDATE,
          last_update_request_id = fnd_global.conc_request_id,
          last_update_login_id = fnd_global.login_id,
          ldap_last_updated_by = p_ldap_username
   WHERE  msip_id = p_msip_id
   AND    p_end_effective_date < target_month;

EXCEPTION
   WHEN OTHERS THEN
      x_message := SQLERRM;
      x_retcode := 2;
END modify_cmt_for_item_enddate;

/**************************************
|| This procedure performs update to item record, and if end date is changed,
|| proc will attempt to end date associated minmax and commitment records.
|| Proc will also stop user from end dating an item to a past date.
**************************************/
PROCEDURE msip_planning_item_updating(p_msip_id                IN NUMBER
                                     ,p_warehouse              IN VARCHAR2
                                     ,p_service_line           IN VARCHAR2
                                     ,p_hardware_model         IN VARCHAR2
                                     ,p_project                IN VARCHAR2
                                     ,p_product_family         IN VARCHAR2
                                     ,p_chasis_flag            IN VARCHAR2
                                     ,p_start_effective_date   IN DATE
                                     ,p_end_effective_date     IN DATE
                                     ,p_ldap_username          IN VARCHAR2
                                     ,x_message                OUT VARCHAR2
                                     ,x_retcode                OUT NUMBER) IS

   l_db_end_date VARCHAR2(11);
   l_date_changed BOOLEAN;

BEGIN

   x_retcode := 0;

   -- derive existing end_effective_date from database
   SELECT NVL(TO_CHAR(end_effective_date,'DD-MON-YYYY'),'NULL')
   INTO   l_db_end_date
   FROM   wwt_msip_planning_item
   WHERE  msip_id = p_msip_id;

   -- If user has changed end date on item
   IF l_db_end_date <> NVL(TO_CHAR(p_end_effective_date,'DD-MON-YYYY'),'NULL') THEN

      -- If user has set item end date to past date, exit with error
      IF p_end_effective_date IS NOT NULL AND
         TRUNC(p_end_effective_date) < TRUNC(SYSDATE) THEN

         x_retcode := 2;
         x_message := 'Item end date cannot be set to a past date';
         RETURN;

      END IF;

      -- User has changed item end date to current or future date
      l_date_changed := TRUE;

   END IF;

   -- perform update on item
   UPDATE wwt_msip_planning_item
   SET    warehouse = p_warehouse,
          service_line = p_service_line,
          hardware_model = p_hardware_model,
          project = p_project,
          product_family = p_product_family,
          chassis_flag = p_chasis_flag,
          last_updated_by = fnd_global.user_id,
          last_update_date = SYSDATE,
          last_update_request_id = fnd_global.conc_request_id,
          last_update_login_id = fnd_global.login_id,
          ldap_last_updated_by = p_ldap_username,
          start_effective_date = p_start_effective_date,
          end_effective_date = p_end_effective_date
   WHERE  msip_id = p_msip_id;

   -- If user has changed end date, then attempt to update associated
   -- minmax and commitment records
   IF l_date_changed AND p_end_effective_date IS NOT NULL THEN

      -- modify existing min/max levels if applicable
      modify_minmax_for_item_enddate(p_msip_id              => p_msip_id
                                    ,p_end_effective_date   => p_end_effective_date
                                    ,p_ldap_username        => p_ldap_username
                                    ,x_retcode              => x_retcode
                                    ,x_message              => x_message);

      IF x_retcode = 2 THEN
         x_message := 'Error occurred during Min/Max update: ' || x_message;
         RETURN;
      END IF;

      -- modify existing commitments if applicable
      modify_cmt_for_item_enddate(p_msip_id           => p_msip_id
                                 ,p_end_effective_date => p_end_effective_date
                                 ,p_ldap_username      => p_ldap_username
                                 ,x_retcode            => x_retcode
                                 ,x_message            => x_message);

      IF x_retcode = 2 THEN
         x_message := 'Error occurred during Commitment update: ' || x_message;
      END IF;

   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;

END msip_planning_item_updating;

/**************************************
|| This procedure is API called from Apex MSIP form, used to
|| update an item.
**************************************/
PROCEDURE item_update_autonomous_api(p_msip_id                IN NUMBER
                                    ,p_warehouse              IN VARCHAR2
                                    ,p_service_line           IN VARCHAR2
                                    ,p_hardware_model         IN VARCHAR2
                                    ,p_project                IN VARCHAR2
                                    ,p_product_family         IN VARCHAR2
                                    ,p_chasis_flag            IN VARCHAR2
                                    ,p_start_effective_date   IN DATE
                                    ,p_end_effective_date     IN DATE
                                    ,p_ldap_username          IN VARCHAR2
                                    ,x_message                OUT VARCHAR2
                                    ,x_retcode                OUT NUMBER)
IS

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

   x_retcode := 0;

   msip_planning_item_updating(p_msip_id               => p_msip_id
                              ,p_warehouse             => p_warehouse
                              ,p_service_line          => p_service_line
                              ,p_hardware_model        => p_hardware_model
                              ,p_project               => p_project
                              ,p_product_family        => p_product_family
                              ,p_chasis_flag           => p_chasis_flag
                              ,p_start_effective_date  => p_start_effective_date
                              ,p_end_effective_date    => p_end_effective_date
                              ,p_ldap_username         => p_ldap_username
                              ,x_message               => x_message
                              ,x_retcode               => x_retcode);

   -- if retcode is equal to 2 then we need to rollback
   --
   IF x_retcode = 2 THEN
      ROLLBACK;
   ELSE
      COMMIT;
   END IF;

EXCEPTION
   WHEN others THEN
      x_message := SQLERRM;
      x_retcode := 2;
      ROLLBACK;

END item_update_autonomous_api;

PROCEDURE update_release_data(p_so_line_id     IN NUMBER
                             ,p_sla_measurable IN VARCHAR2
                             ,p_notes          IN VARCHAR2
                             ,p_ldap_username  IN VARCHAR2
                             ,x_errbuff        OUT VARCHAR2)
IS

   l_release_exists VARCHAR2(1) := 'N';

BEGIN

   x_errbuff := NULL;

   BEGIN

      SELECT 'Y'
      INTO   l_release_exists
      FROM   wwt_msip_release
      WHERE  so_line_id = p_so_line_id;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         x_errbuff := 'ERROR: No release data exists for update';
         RETURN;
   END;

   UPDATE wwt_msip_release
   SET    notes                = NVL(p_notes, notes),
          sla_measurable       = NVL(p_sla_measurable, sla_measurable),
          last_update_date     = SYSDATE,
          ldap_last_updated_by = p_ldap_username
   WHERE  so_line_id           = p_so_line_id;

EXCEPTION
   WHEN OTHERS THEN
      x_errbuff := SUBSTR(SQLERRM, 1, 120);

END update_release_data;

END wwt_upload_msip_utilities;
/