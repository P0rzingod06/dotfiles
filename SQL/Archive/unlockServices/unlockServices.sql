select CONCAT(SUBSTR(email_address,0,INSTR(email_address,'@',5)-1), '@wwt.com')
from fnd_user
where 1=1
and user_name = UPPER('gassertm')
;
select EMAIL_ADDRESS
from fnd_user
where 1=1
and user_name = 'GASSERTM'