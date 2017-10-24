CREATE OR REPLACE PACKAGE APPS.wwt_msip_reserve_file_pkg AS
-- CVS Header: $Source: /CVS/oracle11i/database/erp/apps/pkgspec/wwt_msip_reserve_file_pkg.pls,v $, $Revision: 1.1 $, $Author: gassertm $, $Date: 2014/11/10 22:53:21 $
                                                                             /*
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--Package Name        : wwt_msip_reserve_file_pkg                            --
--Description         : This package is called by the msip reserve file      --
--                      upload.                                              --
--===========================================================================--
-- Developer   Ver   Date        RFC       Description                       --
--===========================================================================--
-- Gassertm    1.1  11/18/2014  CHG33211  Creation                           --
-- Gassertm    1.2  1/12/2015   CHG33785  Updated change number in           --
--                                        description                        --
-------------------------------------------------------------------------------
                                                                             */
                                                                              /*
******************************************************************************
*******************************************************************************
**Procedure Name      : MAIN                                                 **
**Description         : Retrieve file from msip_reserve_file ftp folder-     **
**                      guc source id 231. Update reserve quantity in msip   **
**                      item inventory table with quantity in uploaded file. **
**                      If record in file does not have match in table,      **
**                      throw out record.                                    **
*******************************************************************************
*******************************************************************************
                                                                             */
procedure MAIN (x_retcode OUT NUMBER,
                x_errbuff OUT VARCHAR2,
                p_filename IN VARCHAR2,
                p_username IN VARCHAR2);

end wwt_msip_reserve_file_pkg;
/