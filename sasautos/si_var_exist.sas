/*******************************************************************************************************
TITLE: si_var_exist.sas

DESCRIPTION: Check if the dataset already has a column given by the name

INPUT:
si_table_in = input dataset
varname = variable whose existence need to be checked in the dataset 

Sample call:
%align_sialevents_to_periods(si_table_in=work.test, sial_table=sand.SIAL_tester, amount_type= L, noofperiodsbefore=-4, 
noofperiodsafter=5, period_aligned_to_calendar= True, period_duration= H, out_table=test2);


OUTPUT:


AUTHOR: C Wright

DATE: 

DEPENDENCIES:
NA

NOTES: 

KNOWN ISSUES: 


HISTORY: 

***********************************************************************************************************/

%macro si_var_exist (si_table_in=,varname=, si_out_var=);

	%local rc dsid;
	%let dsid=%sysfunc(open(&si_table_in.));

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_var_exist----------------------;
	%put ............Input dataset: &si_table_in. ;
	%put ............Variable name: &varname. ;
	%put .....Output Variable name: &si_out_var. ;


	%if %sysfunc(varnum(&dsid.,&varname.)) %then
		%do;
			%let &si_out_var.=1;
			%put Variable &varname. already exists in dataset;
		%end;
	%else
		%do;
			%let &si_out_var.=0;
			%put Variable &varname. does not exist in dataset;
		%end;

	%let rc=%sysfunc(close(&dsid.));

	%put ------------Macro End: si_var_exist----------------------;

%mend si_var_exist;