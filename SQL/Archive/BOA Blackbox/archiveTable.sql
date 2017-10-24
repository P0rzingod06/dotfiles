--DROP TABLE WWT.WWT_BOA_BLACKBOX_SERIAL_ARC CASCADE CONSTRAINTS;

CREATE TABLE WWT.WWT_BOA_BLACKBOX_SERIAL_ARC
(
  ID                    NUMBER                  NOT NULL,
  ITEM                            VARCHAR2(250),
  ITEM_ID                        NUMBER,
  MANUFACTURER           VARCHAR2(250),
  DESCRIPTION               VARCHAR2(2000),
  QUANTITY                      NUMBER,
  SERIAL_NUMBER           VARCHAR2(250),
  STATUS                        VARCHAR2(250),
  STATUS_MESSAGE         VARCHAR2(4000),
  REQUEST_ID                 NUMBER,
  BATCH_ID                    NUMBER,
  CREATED_BY            NUMBER,
  CREATION_DATE         DATE,
  LAST_UPDATED_BY       NUMBER,
  LAST_UPDATE_DATE      DATE
)
TABLESPACE WWT_DATA;

COMMENT ON TABLE WWT.WWT_BOA_BLACKBOX_SERIAL_ARC IS 'Creation Date: 20-MAY-2015
   Developer: Michael Gassert
   Reference: STRY0147147
   Description:This table will be used to archive inventory data for Boa blackbox.';
   
CREATE INDEX WWT.WWT_BOA_BLACKBOX_SERIAL_ARC_N1
   ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC (ITEM, MANUFACTURER, STATUS)
   TABLESPACE WWT_IDX;

CREATE INDEX WWT.WWT_BOA_BLACKBOX_SERIAL_ARC_N2
   ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC (MANUFACTURER, STATUS)
   TABLESPACE WWT_IDX;

CREATE INDEX WWT.WWT_BOA_BLACKBOX_SERIAL_ARC_N3
   ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC (ITEM_ID, STATUS)
   TABLESPACE WWT_IDX;
   
CREATE UNIQUE INDEX WWT.WWT_BOA_BLACKBOX_SERIAL_ARC_PK
ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC (ID)
TABLESPACE WWT_IDX;
   
GRANT ALL ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC TO APPS WITH GRANT OPTION;

GRANT SELECT ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC TO VIEWER_LIMITED_HR;

GRANT SELECT ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC TO WWT_B2B;

--DROP SEQUENCE WWT.WWT_BOA_SERIAL_BATCH_ID_S;

CREATE SEQUENCE WWT.WWT_BOA_SERIAL_BATCH_ID_S
START WITH 10
MAXVALUE 9999999999999999999999999999
MINVALUE 1
NOCYCLE
NOCACHE
NOORDER;

GRANT SELECT ON WWT.WWT_BOA_SERIAL_BATCH_ID_S TO VIEWER_LIMITED_HR;

GRANT SELECT ON WWT.WWT_BOA_SERIAL_BATCH_ID_S TO WWT_B2B;

GRANT ALL ON WWT.WWT_BOA_BLACKBOX_SERIAL_ARC TO APPS WITH GRANT OPTION;

CREATE OR REPLACE SYNONYM APPS.WWT_BOA_BLACKBOX_INVENTORY FOR WWT_BOA_BLACKBOX_INVENTORY;