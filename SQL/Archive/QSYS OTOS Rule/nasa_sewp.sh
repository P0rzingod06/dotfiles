#! /bin/ksh
# CVS Header: $Source: /CVS/oracle11i/datarep/upload/nasa_sewp.sh,v $, $Revision: 1.13 $, $Author: mccanna $, $Date: 2011/03/30 22:03:07 $
#--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Name:    nasa_sewp.sh 
# Purpose: Script to load nasa sewp items into database
#        
#          Multiple files can be dropped.  The process will loop
#          through each file.
#
# Creator: Tony Konarik
#
# Versions: 
# ---------------------------------------------
# v1.0    Gave birth 06/17/2003
#
# v1.7    Modified from csh to ksh and changed stuff for FTP and RAC projects
#
# v1.11   CHG18058 Modified the pkg call. Added ret value. On process type
#         of load sends email based on ret val 
#--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
YEARMONTH=`date +%Y%m`

#####################################################
# Define the various directories used in this script#
#####################################################
FILETYPE=$1
if [ $# -eq 0 ]
then
	FILETYPE=ITEMLOAD
fi

INBOXDIR=${FTPROOT}nasa_sewp/Item_Load
ARCHIVEDIR=$ARCROOT/upload/nasa_sewp/item_load
REPORTDIR=$ARCROOT/upload/nasa_sewp/item_load/reports

LOGINUP=$REPOSUSER
PROCESS=LOAD
EMAILNAMES=`$SRCROOT/getEmail.ksh NASASEWP`
echo Email To: $EMAILNAMES
echo YearMonth:  $YEARMONTH
echo Inbox:  $INBOXDIR
echo Archive:  $ARCHIVEDIR

echo $FILETYPE

########################################################
#  This section will create the ORDER REPORT           #
########################################################
if [ $FILETYPE = "ORDERREPORT" ] 
then
	datetime=`date +%Y%m%d%H%M%S`
	REPORTDIR=$LOGROOT/upload/nasa_sewp/OrderReports
	REPORTARC=$ARCROOT/upload/nasa_sewp/OrderReports
	#########################################
	# Call PL/SQL to generate Report        #
	#########################################
	echo EXECUTING PL/SQL to generate ORDERREPORT

sqlplus -s $LOGINUP <<EOD1
whenever sqlerror exit -1
set serveroutput on size 1000000;
set linesize 400
var ret number;
declare
l_ret number;
begin
     repos_admin.wwt_nasa_sewp_import.main('$datetime','$datetime','none','ORDERREPORT',l_ret);
     dbms_output.put_line('RET VAL: ' || l_ret);
     :ret := l_ret; 
end;
/      
exit :ret;
EOD1
RET_VAL=$?
echo RET_VAL IS : $RET_VAL
wait
	REPORTNAME='WWT'$datetime'.txt'
	echo $REPORTNAME
	###################################
	# Send report as email attachment #
	###################################
	cd $REPORTDIR
	for file in `ls *.txt`
	do
		echo file: $file
		if [ -f $REPORTDIR/$file ] 
		then
			echo Report file found
			echo " "
			( echo "Attached is the Order Report."
			  uuencode $REPORTDIR/$file $file
			) | mailx -s "$CURRENT_ENV - Order Report:  $file" $EMAILNAMES
  			mv $REPORTDIR/$file $REPORTARC/$file
		else
  			echo mail not sent...no ORDERREPORT file
		fi
	done

##################################################
# This section will create the ORDERSTATUS REPORT#
##################################################
elif [ $FILETYPE = 'ORDERSTATUS' ] 
then
	datetime=`date +%Y%m%d%H%M%S`
	REPORTDIR=$LOGROOT/upload/nasa_sewp/OrderStatusReports
	RPTSHPDIR=$LOGROOT/upload/nasa_sewp/OrderStatusReports/Shipping
	###################################
	# Call pl/sql to create report    #
	###################################
	echo EXECUTING PL/SQL to generate ORDERSTATUS

sqlplus -s $LOGINUP <<EOD1
whenever sqlerror exit -1
set serveroutput on size 1000000;
set linesize 400
var ret number;
declare
l_ret number;
begin
     repos_admin.wwt_nasa_sewp_import.main('$datetime','$datetime','none','ORDERSTATUS',l_ret);
     dbms_output.put_line('RET VAL: ' || l_ret);
     :ret := l_ret;
end;
/
exit :ret;
EOD1
RET_VAL=$?
echo RET_VAL IS : $RET_VAL
wait
	REPORTNAME='WWT'$datetime'.txt'
	echo $REPORTNAME
	####################################
	# email the report as attachment   #
	####################################
	if [ -e $REPORTDIR/$REPORTNAME ] 
	then
  		( echo "Attached is the Order Status Report."
			uuencode $REPORTDIR/$REPORTNAME $REPORTNAME
		) | mailx -s "$CURRENT_ENV - Order Status:  $REPORTNAME" $EMAILNAMES
	else
  		echo mail not sent...no ORDERSTATUS file
	fi

	if [ -e $RPTSHPDIR/$REPORTNAME ] 
	then
  		( echo "Attached is the Order Status Report."
			uuencode $RPTSHPDIR/$REPORTNAME $REPORTNAME
		) | mailx -s "$CURRENT_ENV - Order Exception:  $REPORTNAME" $EMAILNAMES
	else
  		echo mail not sent...no ORDERSTATUS Exception file
	fi

else
#############################################
# Change to the inbox directory and loop    #
# through each file that is in there        #
# to load items into the repository         #
#############################################
cd $INBOXDIR
for file in `ls *`
do
	echo file:  $file
	datetime=`date +%Y%m%d%H%M%S`

	REPORTNAME=$file
	#################################################################
	# Check the size of the file twice to determine if it is static #
	#################################################################
	FILESIZE=`ls -lrt $INBOXDIR/$file | awk '{ print $5 }'` 
	echo Filesize:  $FILESIZE
	# Wait 30 seconds before getting the filesize again
	sleep 30 
	FILESIZE2=`ls -lrt $INBOXDIR/$file | awk '{ print $5 }'`
	echo Filesize2:  $FILESIZE2

	######################################
	# Only move the file if it is static #
	######################################
	if [ $FILESIZE -eq $FILESIZE2 ] 
	then
		echo Moving $file to WWT Archive directory
		mv $INBOXDIR/$file $ARCHIVEDIR/$datetime'_'$file
		dos2unix $ARCHIVEDIR/$datetime'_'$file $ARCHIVEDIR/tempfile.txt
		rm -f $ARCHIVEDIR/$datetime'_'$file
		mv $ARCHIVEDIR/tempfile.txt $ARCHIVEDIR/$datetime'_'$file
	fi

	echo EXECUTING PL/SQL..........
	
sqlplus -s $LOGINUP <<EOD1
whenever sqlerror exit -1
set serveroutput on size 1000000;
set linesize 400
var ret number;
declare
l_ret number;
begin
     repos_admin.wwt_nasa_sewp_import.main('$datetime','$datetime','$file','$PROCESS',l_ret);
     dbms_output.put_line('RET VAL: ' || l_ret);
     :ret := l_ret;
end;
/
exit :ret;
EOD1
RET_VAL=$?
echo RET_VAL IS : $RET_VAL
wait

       if [ $RET_VAL = 0 ] 
       then
	if [ -e $REPORTDIR/$REPORTNAME ] 
	then
		( echo "Attached is the TR Report."
		  uuencode $REPORTDIR/$REPORTNAME $REPORTNAME
		) | mailx -s "$CURRENT_ENV - TR Report:  $REPORTNAME" $EMAILNAMES
	else
  		echo mail not sent...no TR Report file
	fi
       fi

done
fi

exit

