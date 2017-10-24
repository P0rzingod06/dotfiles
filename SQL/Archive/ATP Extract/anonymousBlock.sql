declare
l_retcode NUMBER;
l_errbuff VARCHAR2(100);

begin

apps.WWT_OM_CASCADE_VALUES_TO_LINES.mass_so_update (l_errbuff, l_retcode, 120, 53667);

end;
/

declare
l_consigned VARCHAR2(10);
begin
      BEGIN
         SELECT NVL (wlav.attribute6, 'N')
           INTO l_consigned
           FROM apps.wwt_dgh_line wdl,
                apps.wwt_dgh_hub_zone_mrp_site hzm,
                apps.mtl_system_items_vl msiv,
                apps.qp_list_lines qll,
                apps.qp_list_headers qlh,
                apps.wwt_dgh_hub_zone whz,
                apps.qp_pricing_attributes qpa,
                apps.wwt_lookups_active_v wlav
          WHERE     wdl.line_id = 264479
                AND wdl.inventory_item_id = msiv.inventory_item_id
                AND wdl.price_list_line_id = qll.list_line_id
                AND msiv.organization_id = wdl.organization_id
                AND qll.list_header_id = qlh.list_header_id
                AND hzm.hub_zone_id = wdl.hub_zone_id
                AND hzm.price_list_header_id = qlh.list_header_id
                AND wdl.hub_zone_id = whz.hub_zone_id
                AND qpa.product_attr_value = msiv.inventory_item_id
                AND qpa.product_attribute_context = 'ITEM'
                AND qpa.product_attribute = 'PRICING_ATTRIBUTE1'
                AND qll.list_line_id = qpa.list_line_id
                AND wlav.attribute2 = qll.attribute4
                AND wlav.lookup_type = 'WWT_ALPHA_PRICING_CATEGORY';
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            LOG (
                  'Get_Consigned query returned a null set.  Setting l_consigned to E');
            l_consigned := 'E';
         WHEN OTHERS
         THEN
            LOG (
                  'Unknown error getting consigned for ghub_line: '
               || P_GHUB_LINE_ID
               || ' error message: '
               || SQLERRM);
            l_consigned := 'E';
      END;
      RETURN l_consigned;
end;
/

