--Two rows updated
update apps.wwt_punchin_info
set internal_sales_rep = 'McDonough, Shamus S',last_updated_by=55386,last_update_date=sysdate
where 1=1
and customer_name = 'Charter Communications'
/