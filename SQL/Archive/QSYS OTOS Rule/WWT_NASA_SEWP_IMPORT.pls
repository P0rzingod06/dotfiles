CREATE OR REPLACE PACKAGE REPOS_ADMIN.WWT_NASA_SEWP_IMPORT IS
-- CVS Header: $Source: /CVS/oracle11i/database/repos/repos_admin/pkgspec/wwt_nasa_sewp_import.pls,v $, $Revision: 1.7 $, $Author: mccanna $, $Date: 2011/03/25 15:08:27 $

-- MODIFICATION HISTORY
-- PERSON         DATE                  COMMENTS
-- ---------         ------                  ------------------------------------------
-- TK                20040617             CREATED
-- KONARIKT    20060308              11I UPGRADE
-- JONESL        20071108              added Order Status Report to URL request process
-- AtoosaM      20110310              CHG18058   v1.7  added the return value to main
--                                                                         procedure to control sending th file based
--                                                                         on the return value.

PROCEDURE MAIN( P_DATETIME                    IN VARCHAR2
               ,P_PROCESSDATETIME                   IN VARCHAR2
               ,P_FILENAME                                 IN VARCHAR2
               ,P_PROCESS                                 IN VARCHAR2
               ,X_SEND_VAL                               OUT NUMBER);

PROCEDURE CREATE_ORDER_REPORT( P_DATETIME   IN VARCHAR2
                              ,P_PO_NUMBER  IN VARCHAR2 DEFAULT NULL
					          ,P_FILEPATH   IN VARCHAR2 DEFAULT NULL
							  ,X_S3N       OUT VARCHAR2);

PROCEDURE CREATE_ORDER_STATUS( P_DATETIME   IN VARCHAR2
                              ,P_PO_NUMBER  IN VARCHAR2 DEFAULT NULL
                              ,P_FILEPATH   IN VARCHAR2 DEFAULT NULL);

G_EMAIL_LIST VARCHAR2(25) := 'NASA_SEWP_PARTS_LOAD';

G_EMAIL_FROM VARCHAR2(25) := 'b2bSupport@wwt.com';

END WWT_NASA_SEWP_IMPORT;
/