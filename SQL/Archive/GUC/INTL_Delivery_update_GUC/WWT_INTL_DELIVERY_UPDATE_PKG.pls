CREATE OR REPLACE PACKAGE APPS.wwt_intl_delivery_update_pkg AS
-- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgspec/wwt_intl_delivery_update_pkg.pls,v $, $Revision: 1.1 $, $Author: gassertm $, $Date: 2014/10/03 10:04:14 $
                                                                             /*
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Package Name        : WWT_INTL_DELIVERY_UPDATE_PKG                         --
--Description         : This package is called by the international delivery --
--                      update file upload.              .                   --
--===========================================================================--
-- Developer   Ver   Date        RFC       Description                       --
--===========================================================================--
-- Gassertm    1.1  10/03/2014  CHG33211  Creation                           --
-------------------------------------------------------------------------------
                                                                             */
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
procedure MAIN (x_retcode OUT NUMBER,
                x_errbuff OUT VARCHAR2,
                p_filename IN VARCHAR2,
                p_username IN VARCHAR2);

end wwt_intl_delivery_update_pkg;
/