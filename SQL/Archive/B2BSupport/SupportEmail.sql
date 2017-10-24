select *
from wwt_lookups
where 1=1
and lookup_Type = 'WWT_B2B_SUPPORT_EMAIL_VALUES'
--and attribute1 = 'Other_Contact_Info'
;
select Attribute1 First_Name,Attribute10 Last_Name,Attribute2 Cell_number,Attribute3 Work_Number,
Attribute4 Home_Number,Attribute6 Next_Support_Week,Attribute7 Start_PTO_Date,Attribute8 End_PTO_Date,Attribute9 EDI
from apps.wwt_lookups
where 1=1
and lookup_Type = 'WWT_B2B_CONTACT_INFORMATION'
and attribute9 = 'N'
order by attribute6 desc
;
select Attribute1 First_Name,Attribute10 Last_Name,MAX(Attribute6) Next_Support_Week,Attribute7 Start_PTO_Date,Attribute8 End_PTO_Date,Attribute9 EDI
from apps.wwt_lookups
where 1=1
and lookup_Type = 'WWT_B2B_CONTACT_INFORMATION'
and attribute9 = 'Y'
group by attribute6
--order by attribute9,attribute6
;
select NVL(Attribute1,'N/A') First_Name,NVL(Attribute10,'N/A') Last_Name,NVL(Attribute2,'N/A') Cell_number,NVL(Attribute3,'N/A') Work_Number,
NVL(Attribute4,'N/A') Home_Number,NVL(Attribute6,'N/A') Next_Support_Week,NVL(Attribute7,'N/A') Start_PTO_Date,NVL(Attribute8,'N/A') End_PTO_Date
from apps.wwt_lookups
where 1=1
and lookup_Type = 'WWT_B2B_CONTACT_INFORMATION'
;
select ATTRIBUTE2
from wwt_lookups
where 1=1
and lookup_Type = 'WWT_B2B_SUPPORT_EMAIL_VALUES'
;
select *
from fnd_lookups
WHERE FND_LOOKUPS.LOOKUP_TYPE = 'YES_NO'
;
