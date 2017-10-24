select * from archive_bizdoccontent
where 1=1
--and docid = '5042br00b41phtg000000m65'
and partname = 'EDIdata'
;
select * from ARCHIVE_BIZDOC
order by lastmodified
;
select * from editracking
where 1=1
--and trunc(doctimestamp) = to_date('26-AUG-14','DD-MON-YY')
--and envelopeid in ('5041jr00908rfb3f00020qnk',
--'5041jr0090afmrlf00023dt5',
--'5041jr00908g5d2m00020o7a')
order by doctimestamp
;
select * from bizdoc
where 1=1
and trunc(doctimestamp) = to_date('26-AUG-14','DD-MON-YY')
;
select * from edistatus
where 1=1
and trunc(timecreated) = to_date('26-AUG-14','DD-MON-YY')
;
SELECT
    p.CorporationName,
    bdtd.typename, 
    bda.stringvalue, 
    TO_CHAR(wwt_wm_admin.from_gmt(bd.doctimestamp), 'mm/dd/YYYY HH:MI PM') doctimestamp, 
    bd.conversationid, 
    bd.groupid, 
    bd.nativeid ST_CONTROL_NUMBER,
    NVL(et.fastatus,0) fastatus_number,
    DECODE(wema.docid, NULL, NVL(wef.description, 'No FA data available'), 'Manually Acknowledged') fa_st_status,
    bd.docid,
    bd_gs.docid gs_docid,
    wema.created_by_user LDAP_USER,
    et.RELATEDDOCID FA_DOCID,
    p_send.CorporationName SENDER_NAME,
    p_receive.CorporationName RECEIVER_NAME
FROM wm9_tn1.bizdoc bd,
     wm9_tn1.bizdocattribute bda,
     wm9_tn1.bizdocattributedef bdad,
     wm9_tn1.bizdoctypedef bdtd,
     wm9_tn1.editracking et,
     wm9_tn1.partner p,
     wm9_tn1.partner p_send,
     wm9_tn1.partner p_receive,
     wm9_tn1.bizdocrelationship bd_gs,
     wwt_wm_admin.wm_edi_fastatus wef,
     wwt_wm_admin.wwt_edi_manual_acks wema
WHERE 1=1
--AND bdtd.typename like '%' || ? || '%'
AND bdtd.typeid = bd.doctypeid
AND bda.docid = bd.docid
AND wwt_wm_admin.from_gmt(bd.doctimestamp) >= NVL(TO_DATE('08-26-2014 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), SYSDATE - 14)
AND wwt_wm_admin.from_gmt(bd.doctimestamp) <= NVL(TO_DATE('09-28-2014 23:59:00', 'MM/DD/YYYY HH24:MI:SS'), SYSDATE + 1)
AND bdad.attributeid = bda.attributeid
AND bdad.attributename = 'BizDocNumber'
AND bd_gs.relateddocid = bd.docid
AND bd_gs.docid = et.docid (+)
AND bd_gs.docid = wema.docid (+)
AND et.fastatus = wef.fastatus (+)
--AND ( ( (NVL(wef.description, '-99') = ? AND wema.docid IS NULL) OR  ? IS NULL )
--      OR
--      (? = 'Manually Acknowledged' AND wema.docid IS NOT NULL)
--    )
AND bda.stringvalue LIKE NVL(null, bda.stringvalue)
--AND p.CorporationName = ?
AND (p.partnerid = (CASE 'inbound'
                    WHEN 'inbound' THEN BD.SENDERID
            	    WHEN 'outbound' THEN BD.RECEIVERID
                    END)
     OR (null = 'both' AND (p.partnerid = BD.SENDERID OR p.partnerID = BD.RECEIVERID))
    )
AND p_send.partnerid = bd.senderid
AND p_receive.partnerid = bd.receiverid
ORDER BY p.CorporationName, bd.doctimestamp DESC
