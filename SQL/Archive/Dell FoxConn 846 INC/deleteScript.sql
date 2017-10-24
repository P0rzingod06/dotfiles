--654 records deleted.

delete from partner_admin.WWT_DSH_SUPPLIER_ONHAND_QTY
where 1=1
and creation_date < to_date('01-APR-2015');