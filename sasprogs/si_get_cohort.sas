/*********************************************************************************************************
DESCRIPTION: This is where you write code to fetch the individuals in your population, and the date 
	as on which you want to create variables for the individuals. Note that each person in your population
	can have a different date as on which the variables would be created by the SI Data Foundation.

INPUT: 
To be determined by the user.


OUTPUT:
To be determined by the user. The name of the output table should be the same as what is specified by
"&si_pop_table_out" variable in the si_control.sas file. The output table should have at least 2 columns, 
one for the uid that uniquely identifies the individual, and a date-time column that specifies the reference date 
as on which all variables will be created by the data foundation.

AUTHOR: E Walsh

DATE: 05 May 2017

DEPENDENCIES: NA

NOTES: 

HISTORY: 
05 May 2017 EW v1 example
*********************************************************************************************************/

%put INFO: This is the place for you to insert your code. The final table needs snz_uid and an as at date. See ../examples ;
