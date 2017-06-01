/*********************************************************************************************************
TITLE: si_conditional_drop_table.sas

DESCRIPTION: Macro to conditionally check a table exists and drop it if it does

INPUT:
si_cond_table_in = table that you wish to conditionally drop

OUTPUT:
NA

AUTHOR: E Walsh

DATE: 16 May 2017

DEPENDENCIES: 

NOTES: 


HISTORY: 
16 May 2017 EW v1
*********************************************************************************************************/

%macro si_conditional_drop_table(si_cond_table_in = );
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_conditional_drop_table: Inputs-----------------------;
	%put ....si_sandpit_libname: &si_sandpit_libname;
	%put .....si_drop_table_int: &si_cond_table_in.
;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	/* this will prevent warnings in the sas log about dropping tables that dont exist */
	%if %sysfunc(exist(&si_cond_table_in.)) %then
		%do;
			%put INFO: In conditional_drop_table.sas - Dropping table &si_cond_table_in.;

	proc sql;
		drop table &si_cond_table_in.;
	quit;

		%end;
	%else
		%do;
			%put INFO: In conditional_drop_table.sas - Table &si_cond_table_in does not exist;
		%end;
%mend;