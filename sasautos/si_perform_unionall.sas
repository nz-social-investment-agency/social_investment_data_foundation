/*******************************************************************************************************
TITLE: si_perform_unionall.sas

DESCRIPTION:

Macro si_perform_unionall -
Given an input table and data to be appended, this macro creates the table if it doesn't exist, else 
appends the data


INPUT:
si_table_in = main table, with snz_uid and individual weights. 
append_table = table that gets appended to main table.


OUTPUT:
NA


AUTHOR: Vinay Benny

DATE: 14-Feb-2017

DEPENDENCIES:
NA

NOTES: 

KNOWN ISSUES: 


HISTORY: 
27 Jan 2017 	Vinay Benny 	Version 1
***********************************************************************************************************/


/* Define a macro that performs union all operation between tables*/
%macro si_perform_unionall(si_table_in=, append_table=);

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_perform_unionall----------------------;
	%put ...................si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put .......................si_table_in: &si_table_in. ;
	%put ......................append_table: &append_table.;

	%if %sysfunc(exist(&si_table_in.)) %then %do;
		
		proc append base=&si_table_in. data=&append_table.; run;
	%end;
	%else %do;
		%put &si_table_in. does not exist.. Creating it. ;
		data &si_table_in.; set &append_table.; run;
	%end;

	%put ------------End Macro: si_perform_unionall----------------------;
%mend;
