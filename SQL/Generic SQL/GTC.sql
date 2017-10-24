select * from apps.wwt_gtc_upload_status
where 1=1
and creation_Date > sysdate - 3
;
select *
from apps.wwt_gtc_upload_status
where 1=1
--and status = 'ACKNOWLEDGE'
and wwt_object_type = 'PRODUCT'
--and wwt_object_id LIKE '%777339-S01.1-04378.US%'
and creation_date >= trunc(sysdate) - 50
;
select apps.wwt_util_constants.get_value('EMAIL_DIST_LIST',
                                         'GTC_CONSTANTS',
                                         'ERROR_RESPONSE')
from dual
;
select attribute26 from apps.wwt_lookups
where 1=1
and lookup_type = 'GTC_CONSTANTS'
and attribute2 = 'EMAIL_DIST_LIST'
;
update apps.wwt_lookups
set attribute26 = 'michael.gassert@wwt.com'
where 1=1
and lookup_type = 'GTC_CONSTANTS'
and attribute2 = 'EMAIL_DIST_LIST'
;
MERGE INTO APPS.WWT_GTC_UPLOAD_STATUS wgus
USING (SELECT ? AS wwt_object_id,
? AS wwt_object_type,
? AS status,
? AS gtc_object_type,
? AS gtc_object_id,
? AS created_by
FROM DUAL) a
--see if this (wwt_) object id exists first
ON (    wgus.wwt_object_id = a.wwt_object_id
AND wgus.wwt_object_type = a.wwt_object_type) --see if this (wwt_) object id exists first
WHEN MATCHED
THEN
--object id is there, so we'll update
UPDATE SET
STATUS = a.status,
LAST_UPDATED_BY = a.created_by,
LAST_UPDATE_DATE = SYSDATE
WHEN NOT MATCHED
THEN
--not found, so let's put it there
INSERT     (WWT_OBJECT_TYPE,
WWT_OBJECT_ID,
GTC_OBJECT_TYPE,
GTC_OBJECT_ID,
STATUS,
CREATED_BY,
CREATION_DATE,
LAST_UPDATE_DATE,
LAST_UPDATED_BY)
VALUES (a.wwt_object_type,
a.wwt_object_id,
a.gtc_object_type,
a.gtc_object_id,
a.status,
a.created_by,
SYSDATE,
SYSDATE,
a.created_by)
;