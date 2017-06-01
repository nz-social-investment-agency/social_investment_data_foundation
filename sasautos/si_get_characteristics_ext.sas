/*********************************************************************************************************
TITLE: si_get_master_chracteristics_extension.sas

DESCRIPTION: A stub to allow users the option to apply specific filtering to suit their analysis
e.g only using those linked to the spine or those who are known to a particular agency

INPUT:
&si_char_table_out = output table containing master characteristics

OUTPUT:
&si_char_ext_table_out = output table containing a subset of rows from master characteristics macro 
or potentially extra characteristic columns


AUTHOR: E Walsh

DATE: 28 Apr 2017

DEPENDENCIES: 

NOTES: 


HISTORY: 
28 Apr 2017 EW v1
*********************************************************************************************************/
%macro si_get_characteristics_ext(si_char_ext_table_in=,si_char_ext_table_out=);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ...si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_get_char_extension: Inputs-------------;
	%put ..si_char_ext_table_in: &si_char_ext_table_in;
	%put .si_char_ext_table_out: &si_char_ext_table_out;
	%put --------------------------------------------------------------------;
	%put ------------ Global variables available: Inputs---------------------;
	%put ********************************************************************;
	%put INFO: si_get_characteristics_ext: Enter additional code here;
	%put INFO: extra code could add additional char columns;
	%put INFO: extra code could filter the rows eg those with a spine ind of 1;

	/* example of an extension */
	/* we prefer to use those linked to the spine because the spine is the dataset that allows */
	/* us to link to all the other datasets in the IDI if someone isnt attached to the spine */
	/* we might make incorrect inferences about the population */
	proc sql;
		create table &si_char_ext_table_out. as
			select *
		from &si_char_ext_table_in.
			where snz_spine_ind = 1;
	quit;

%mend si_get_characteristics_ext;