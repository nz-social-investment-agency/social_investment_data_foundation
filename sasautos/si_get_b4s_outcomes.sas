/*********************************************************************************************************
DESCRIPTION: The B4 School Check is a health service check available to four years olds. It checks
for health, behaviour, social and development issues that might impact on a child's ability to learn.

Part of the B4 School Check involves completing the Strengths and Difficulties Questionnaire (SDQ).
This is a behavioural screening tool for 3-16 year olds. The SDQ is completed by the parents SDQP and 
teachers SDQT and is used to identify behavioural issues.

These indicators show the outcomes of the before school check (e.g. where they referred , advice was given
and so on) as well as the results from the SDQ

INPUT:
si_b4s_dsn = Database name {default = IDI_Clean}
si_b4s_proj_schema = Project schema used to find your tables in the sandpit
si_b4s_table_in = name of the input table
si_b4s_id_col = id column used for joining tables {default = snz_uid}
si_b4s_asat_date = name of the column containing a datetime field used to identify outcomes in a 
specified time period

OUTPUT:
si_b4s_table_out = name of the output table containing the indicators b4sc_outcome, b4sc_sdqp_outcome
and b4sc_sdqt_outcome

AUTHOR: E Walsh

DEPENDENCIES:
Access to [IDI_Clean].[moh_clean].[b4sc]

NOTES: 

HISTORY: 
23 Jun 2017 EW v1
*********************************************************************************************************/
%macro si_get_b4s_outcomes( si_b4s_dsn = IDI_Clean, si_b4s_proj_schema =, si_b4s_table_in =, 
			si_b4s_id_col = snz_uid, si_b4s_asat_date =, si_b4s_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ---------------si_get_b4s_outcomes: Inputs------------------------;
	%put ....si_b4s_proj_schema: &si_b4s_proj_schema;
	%put .......si_b4s_table_in: &si_b4s_table_in;
	%put .........si_b4s_id_col: &si_b4s_id_col;
	%put ......si_b4s_asat_date: &si_b4s_asat_date;
	%put ......si_b4s_table_out: &si_b4s_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table &si_b4s_table_out. as 
			select * from connection to odbc(
			select a.&si_b4s_id_col
				, b.[moh_bsc_general_outcome_text] as b4sc_outcome
				, b.[moh_bsc_sdqp_outcome_text] as b4sc_sdqp_outcome
				, b.[moh_bsc_sdqt_outcome_text] as b4sc_sdqt_outcome
				, b.[moh_bsc_vision_outcome_text] as b4sc_vision_outcome
				, b.[moh_bsc_hearing_outcome_text] as b4sc_hearing_outcome
				, b.[moh_bsc_growth_outcome_text] as b4sc_growth_outcome
				, b.[moh_bsc_dental_outcome_text] as b4sc_dental_outcome
				, b.[moh_bsc_peds_outcome_text] as b4sc_peds_outcome
			from [IDI_Sandpit].[&si_b4s_proj_schema].[&si_b4s_table_in] a
				inner join (
					select [&si_b4s_id_col]
						,[moh_bsc_check_date]
						,[moh_bsc_general_outcome_text]
						,[moh_bsc_sdqp_outcome_text]
						,[moh_bsc_sdqt_outcome_text]
						,[moh_bsc_vision_outcome_text]
						,[moh_bsc_hearing_outcome_text]
						,[moh_bsc_growth_outcome_text]
						,[moh_bsc_dental_outcome_text]
						,[moh_bsc_peds_outcome_text]
					from [IDI_Clean].[moh_clean].[b4sc]
						) b on a.&si_b4s_id_col = b.&si_b4s_id_col
					where b.moh_bsc_check_date <= a.&si_b4s_asat_date
						);
		disconnect from odbc;
	quit;

%mend;