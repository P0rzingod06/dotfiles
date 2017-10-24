wwt_dsh_gcfi_saf_pkg
wwt_dsh_gcfi_saf_alloc_pkg

select * from wwt_dsh_gcfi_saf_header order by last_update_date DESC

select * from wwt_dsh_gcfi_saf_header where saf_id = 6747
delete from wwt_dsh_gcfi_saf_header where saf_id = 6747 

/** insert line stuff **/
select * from wwt_dsh_gcfi_saf_lines order by last_update_date DESC
select * from wwt_dsh_gcfi_saf_lines where saf_id = 6747

delete * from wwt_dsh_gcfi_saf_header where saf_id = 6747

/** insert profile stuff **/
select * from WWT_DSH_GCFI_SAF_PROFILES order by last_update_date DESC

/** select from SAF profiles**/
SELECT hdr.saf_id,
       lines.line_id,
       prf.profile_id,
       'SAF TRANSFER' transfer_type,
       lines.customer_item_id,
       lines.mfg_item_id,
       lines.region_id,
       lines.rva_site_id,
       lines.mrp_site_id,
       hdr.si_number,
       lines.saf_line_number,
       hdr.customer_number,
       lines.status,
       NVL(prf.detail_quantity,0) - NVL(prf.consumed_quantity,0)  qty
FROM   apps.wwt_dsh_gcfi_saf_header hdr,
       apps.wwt_dsh_gcfi_saf_lines lines,
       apps.wwt_dsh_gcfi_saf_profiles prf
WHERE  hdr.saf_id = lines.saf_id
AND    lines.line_id = prf.line_id
AND    hdr.saf_id = 4655
AND    lines.saf_line_number = 1
AND    lines.status <> 'MANUAL'
AND    NVL(prf.detail_quantity,0) - NVL(prf.consumed_quantity,0) > 0 
ORDER  BY saf_id desc

select * from apps.wwt_dsh_gcfi_saf_header hdr, apps.wwt_dsh_gcfi_saf_lines lines where hdr.saf_id = lines.saf_id

/** see if we should generate SAF alert **/
select apps.wwt_util_constants.get_value('ALERT_ON_MANUAL', 'DSH_CONSTANTS', 'SAF INBOUND INTEGRATION') from dual

select * from wwt_dsh_gcfi_saf_header where saf_id = 1

select hdr.saf_id from wwt_dsh_gcfi_saf_header hdr, apps.wwt_dsh_gcfi_saf_lines lines where hdr.saf_id = lines.saf_id

/** insert into SAFtrx in create from Saftrx **/
select * from wwt_dsh_gcfi_saf_transactions order by last_update_date DESC