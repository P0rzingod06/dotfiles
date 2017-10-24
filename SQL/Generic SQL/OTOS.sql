WWT_OM_DEFINE_PROCESS_GROUPS;WWT_OM_RULE_INSERTS;WWT_ORDER_IMPORT_PKG;WWT_OM_JOB
;
select * from APPS.WWT_OM_DATASET
;
select * from APPS.WWT_OM_DATASET_ELEMENTS
where 1=1
and NAME like '%FREIGHT%'
;
select child.process_group_id PROCESS_GROUP_ID, 
    parent.process_group_id PARENT_GROUP_ID,
    child.edi_production_id,
    child.edi_test_id
from apps.wwt_om_process_groups child,
     apps.wwt_om_process_groups parent
where parent.name (+)= child.parent_process_group
and child.name = ? || '_' || ? || '_' || child.edi_production_id
and ((apps.wwt_get_env IN ('DEV', 'TEST') and ? = child.edi_test_id) OR ? = child.edi_production_id)
;
select * from apps.wwt_om_process_groups
where 1=1
AND rule_source = 'EDI'
and name LIKE '%IB850%GTNEXUS%'
;
select * from wwt_om_action_parameters
where 1=1
and value LIKE '%WWT_ATTRIBUTE41%'
;
SELECT OPG.PROCESS_GROUP_ID, 
       COUNT(OH.HEADER_ID) ORDER_COUNT, 
       NVL(FLOOR(COUNT(OH.HEADER_ID) / ORDERS_PER_BATCH),0) ADDITIONAL_BATCHES
FROM APPS.WWT_ORIG_ORDER_HEADERS OH,
     APPS.WWT_OM_PROCESS_GROUPS OPG
WHERE 1=1
AND OH.STATUS = 'UNPROCESSED'
AND OH.PROCESS_GROUP_ID = OPG.PROCESS_GROUP_ID
GROUP BY OPG.PROCESS_GROUP_ID, OPG.PRIORITY, OPG.ORDERS_PER_BATCH
ORDER BY OPG.PRIORITY
;
select * from APPS.WWT_OM_PROCESS_GROUPS_CRITERIA
where 1=1
--and process_group_id = 287
order by request_id
;
select * from APPS.WWT_OM_ACTION_CLASS
;
select * from dba_objects
where 1=1
and object_type LIKE '%PACKAGE%BODY'
and object_name LIKE '%ORDER%'
;
select parent.process_group_id
from apps.wwt_om_process_groups child,
     apps.wwt_om_process_groups parent
where parent.name = child.parent_process_group
and child.process_group_id = ?
;
select wor.rule_id RULE_ID, 
       wor.name RULE, 
       worc.name CLASS, 
       wor.order_of_operation ORDER_OF_OPERATION,
       wor.EXECUTE_ON_NEW_LINE
from apps.wwt_om_rule_class worc,
     apps.wwt_om_rules wor
where wor.process_group_id = ?
and worc.name = ?
and worc.rule_class_id = wor.rule_class_id (+)
and (wor.enabled_flag = 'Y' or wor.end_date_active >= sysdate)
and (wor.execute_on_reprocess = 'Y' OR NVL(?, 'N') = 'N')
order by wor.order_of_operation asc
;
select * from apps.wwt_om_rules
;
select * from APPS.wwt_om_action_class
where 1=1
--and name = 'setShipSet'
;
update  wwt_om_action_class
set action_class_path = 'WWT_OrderInbound_RuleActions.flowServices.mixed:setShipSet'
where name = 'setShipSet'
;
select * from dba_tables
where 1=1
and lower(table_name) LIKe '%om_action%'
;
select * from APPS.WWT_OM_ACTION_CLASS_GROUP
;
select * from WWT_OM_ACTION_PARAMETERS
;
select * from WWT_OM_RULE_CLASS_X_ACTN_CLASS
;