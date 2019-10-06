/****************************************************************
TITLE: si_get_outcomes_ext.sas

DESCRIPTION: A stub to allow users the option to
incorporate outcomes that are not able to be easily
derived from the SIAL tables such as highest qualifcation

INPUT:
&si_outcomes_table_in - table needed to figure out who 
to generate the outcomes from and when (probably going
to be the master characteristics table

OUTPUT:
&si_char_ext_table_out = not sure if we need this yet


AUTHOR: E Walsh

DATE: 28 Apr 2017

DEPENDENCIES: 

NOTES: 


HISTORY: 
28 Apr 2017 EW v1
May 2019 - Changes for SAS Grid - PNH
****************************************************************/
%macro si_get_outcomes_ext();
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_get_outcomes_ext: Inputs-----------------------------;
	%put ............No macro parameters currently specified;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	%si_get_highest_qualifications( 
		si_table_in = &si_pop_table_out._char_ext
		,si_id_col = &si_id_col.
		,si_as_at_date = &si_asat_date. 
		,si_IDI_refresh_date = %substr(&si_idi_clean_version,11,8)
		,si_target_schema = &si_proj_schema.
		,si_out_table = SIAL_Qualifications
		);

	%put INFO si_get_outcomes_ext: Enter additional macro calls here;

%mend si_get_outcomes_ext;