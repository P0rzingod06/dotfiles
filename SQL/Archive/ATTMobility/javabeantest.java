import java.text.*;
import java.util.regex.*;
String inputDate = %PLANNED_DEPLOYMENT_DATE%;
SimpleDateFormat newFormat = new SimpleDateFormat("dd-MMM-yyyy");
SimpleDateFormat oldFormat;
if(inputDate == "-"){
	newFormat = "";
	return newFormat;
}
if  (inputDate != null && !inputDate.equals("")) {
	if (Pattern.matches("\\d{1,2}/\\d{1,2}/\\d{4}", inputDate)) {
		oldFormat= new SimpleDateFormat("MM/dd/yyyy");
	}
	else if (Pattern.matches("\\d{1,2}-[a-zA-Z]*-\\d{2}", inputDate)) {
		oldFormat= new SimpleDateFormat("dd-MMM-yy");
	}
	else {
		oldFormat = new SimpleDateFormat("dd-MMM-yyyy");
	}
	Date oldDate = oldFormat.parse(inputDate);
	return newFormat.format(oldDate);
}