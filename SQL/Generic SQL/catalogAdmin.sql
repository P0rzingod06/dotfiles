select * from wwt_catalog.store_catalog
;
select * from wwt_catalog.store_catalog_product
;
select * from wwt_catalog.pricelist
;
select * from wwt_catalog.product
;
select * from WWT_CATALOG.BOM_COMPONENT
order by last_update_date desc
;
select * from WWT_CATALOG.bom_header
order by last_update_date desc
;
select * from wwt_catalog.catalogs
;
select * from wwt_catalog.pricelist_attribute
;
select * from wwt_catalog.pricelist_attribute_xref
where 1=1
and pricelist_attribute_id = 61
--and pricelist_id = 4
;
select * from wwt_catalog.pricelist_attribute_value
where 1=1
and PRICELIST_ATTRIBUTE_VALUE_ID = 2889
and pricelist_attribute_id = 61
;
select catalog_id from wwt_ods.custom_catalog_components_t2
group by catalog_id
;
CREATE OR REPLACE VIEW WWT_CATALOG.CUSTOM_CATALOG_COMPONENTS_OVMG ("CATALOG_ID", "BOM_CUSTOMER_PART_NUMBER", "BOM_COMPONENT_ID", "BOM_ID", "START_DATE", "END_DATE", "PRICELIST_ID", "CUSTOMER_PRICE", "LEAD_TIME", "VENDOR_SKU", "CUSTOMER_PRODUCT_NUMBER", "MASTER_CHILD", "CUSTOMER_DESCRIPTION", "PRODUCT_DESCRIPTION", "PRODUCT_ID", "MFG_ID", "MFG_PRODUCT_NUMBER", "TAX_CATEGORY_CODE", "BOM_FLAG", "PRIMARY_IMAGE_URL", "UNSPSC", "BOM_HEADER_ID", "MANUFACTURER_NAME","BOM_TYPE") AS
  WITH CATALOG_BOMS AS
  (SELECT CATALOG_ID, CATALOG_BOM_ID from WWT_CATALOG.STORE_CATALOG_PRODUCT scp
  WHERE
    (
      (TRUNC(SYSDATE) BETWEEN TRUNC(scp.START_DATE) and TRUNC(scp.END_DATE))
    OR
      (TRUNC(SYSDATE) >= TRUNC(scp.START_DATE) and scp.END_DATE IS NULL)
    )
  )
SELECT
cb.CATALOG_ID
,bh2.CUSTOMER_PART_NUMBER as BOM_CUSTOMER_PART_NUMBER
,bc.BOM_COMPONENT_ID, bc.BOM_ID,  bc.START_DATE, bc.END_DATE, bc.PRICELIST_ID, bc.CUSTOMER_PRICE, bc.LEAD_TIME, bc.VENDOR_SKU, bc.CUSTOMER_PRODUCT_NUMBER, bc.MASTER_CHILD, bc.CUSTOMER_DESCRIPTION, bc.PRODUCT_DESCRIPTION
,p.PRODUCT_ID, p.MFG_ID, p.MFG_PRODUCT_NUMBER, p.TAX_CATEGORY_CODE, p.BOM_FLAG
,NVL2(pi.FILE_CONTENT, 'product-images/' || pi.PRODUCT_IMAGE_ID, NVL(pi.URL, 'http://www.wwt.com/product_images/noImage.jpg')) as PRIMARY_IMAGE_URL
,pax.PRODUCT_ATTRIBUTE_VALUE as UNSPSC
,bh2.BOM_ID as BOM_HEADER_ID
,m.NAME as MANUFACTURER_NAME
, CASE WHEN p.BOM_FLAG = 'Y' THEN (SELECT pav.pricelist_attribute_value FROM wwt_catalog.pricelist_attribute_xref pax
                                     INNER JOIN wwt_catalog.pricelist_attribute_value pav
                                            ON pax.pricelist_attribute_value_id = pav.pricelist_attribute_value_id
                                     INNER JOIN wwt_catalog.pricelist_attribute pa
                                            ON pax.pricelist_attribute_id = pa.pricelist_attribute_id AND pa.pricelist_attribute_id = 61
                                    WHERE pax.pricelist_id = bc.pricelist_id) ELSE null END BOM_TYPE
FROM CATALOG_BOMS cb
INNER JOIN WWT_CATALOG.BOM_HEADER bh
  INNER JOIN WWT_CATALOG.BOM_COMPONENT bc
    LEFT OUTER JOIN WWT_CATALOG.BOM_HEADER bh2
      on bc.PRODUCT_ID = bh2.PRODUCT_ID
    INNER JOIN WWT_CATALOG.PRODUCT p
      INNER JOIN WWT_PARTNER_HUB.MANUFACTURER_V m
        on p.MFG_ID = m.PARTNER_GROUP_ID
      LEFT OUTER JOIN WWT_CATALOG.PRODUCT_IMAGE pi 
        on p.PRODUCT_ID = pi.PRODUCT_ID
          and LOWER(pi.FILE_SIZE) = 'thumbnail'
      LEFT OUTER JOIN WWT_CATALOG.PRODUCT_ATTRIBUTE_XREF pax
        INNER JOIN WWT_CATALOG.PRODUCT_ATTRIBUTE pa on
          pa.PRODUCT_ATTRIBUTE_ID = pax.PRODUCT_ATTRIBUTE_ID
          and UPPER(pa.PRODUCT_ATTRIBUTE_NAME) = 'UNSPSC' and UPPER(pax.LANGUAGE) = 'EN_US'
        ON p.PRODUCT_ID = pax.PRODUCT_ID
      ON bc.PRODUCT_ID = p.PRODUCT_ID
    ON bh.BOM_ID = bc.BOM_ID
  ON CB.CATALOG_BOM_ID = bh.BOM_ID
    and UPPER(bh.STATUS) = 'ACTIVE'
;
select pricelist_id from WWT_CATALOG.CUSTOM_CATALOG_COMPONENTS_OVMG
where 1=1
and bom_type = 'Catalog'
group by pricelist_id
;
SELECT pav.pricelist_attribute_value FROM wwt_catalog.pricelist_attribute_xref pax
                                     INNER JOIN wwt_catalog.pricelist_attribute_value pav
                                            ON pax.pricelist_attribute_value_id = pav.pricelist_attribute_value_id
                                     INNER JOIN wwt_catalog.pricelist_attribute pa
                                            ON pax.pricelist_attribute_id = pa.pricelist_attribute_id AND pa.pricelist_attribute_id = 61
                                    WHERE pax.pricelist_id = 33248
;
select pav.pricelist_attribute_value 
from wwt_catalog.pricelist_attribute_xref pax, wwt_catalog.pricelist_attribute_value pav, wwt_catalog.pricelist_attribute pa
where 1=1
and pax.pricelist_id = 33248
and pax.pricelist_attribute_value_id = pav.pricelist_attribute_value_id
and pax.pricelist_attribute_id = pa.pricelist_attribute_id 
AND pa.pricelist_attribute_id = 61
;