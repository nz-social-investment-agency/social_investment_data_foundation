/* Load all the macros */

/*********************************************************************************************************
DESCRIPTION: Alligns cost by year of T1 benefits by population cohort

INPUT:

Must have sas macros
%si_align_sialevents_to_periods
%si_create_rollup_vars

OUTPUT:
2 tables with L or W prefix identifying variables by width or column depending on users preference

In the table cost and count of benefits for the last 30 years


AUTHOR: Wen Jhe Lee

DEPENDENCIES:
[IDI_usercode].[DL-MAA2016-15].[SIAL_MSD_T1_events]


NOTES: 

Havent added discounting or CPI adjustment


HISTORY: 
21 Jun 2017 WJ v1
*********************************************************************************************************/
%macro si_get_T1benefits( si_T1_benefits_dsn = IDI_Clean, si_T1_benefits_proj_schema =, si_T1_benefits_table_in =, 
			si_T1_benefits_id_col = snz_uid, si_T1_benefits_asat_date =, si_T1_benefits_table_out =);


	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_get_T1_benefits: Inputs-----------------------;
	%put ............si_T1_benefits_dsn: &si_T1_benefits_dsn;
	%put ....si_T1_benefits_proj_schema: &si_T1_benefits_proj_schema;
	%put .......si_T1_benefits_table_in: &si_T1_benefits_table_in;
	%put .........si_T1_benefits_id_col: &si_T1_benefits_id_col;
	%put ......si_T1_benefits_asat_date: &si_T1_benefits_asat_date;
	%put ......si_T1_benefits_table_out: &si_T1_benefits_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

options mlogic mprint;

/*%let sasdirgen = \\WPRDFS08\Datalab-MA\MAA2016-15 Supporting the Social Investment Unit\si_data_foundation;*/
/**/
/*options obs=MAX mvarsize=max pagesize=132 */
/*        append=(sasautos=("&sasdirgen.\sasautos"*/
/*						  "&sasdir.\sasautos"));*/



libname sand ODBC dsn= idi_sandpit_srvprd schema="&si_T1_benefits_proj_schema." bulkload=yes;
%global si_debug;
data _null_;
	call symput('si_debug', 'False');
run;

/*MSD T1*/
%si_align_sialevents_to_periods(si_table_in=[IDI_Sandpit].[&si_T1_benefits_proj_schema.].[&si_T1_benefits_table_in.],
si_sial_table=[IDI_Usercode].[&si_T1_benefits_proj_schema.].[SIAL_MSD_T1_events], si_as_at_date =&si_T1_benefits_asat_date., 
si_amount_type= L, noofperiodsbefore=-30, noofperiodsafter=0, 
si_amount_col = cost, period_duration= Year, si_out_table=raw, period_aligned_to_calendar = False
);

/*MSD T1*/
%si_create_rollup_vars(si_table_in=sand.&si_T1_benefits_table_in.,
si_sial_table=raw, 
si_out_table=&si_T1_benefits_table_out., 
	si_as_at_date=&si_T1_benefits_asat_date.,
si_agg_cols= %str(department),
cost = True, si_amount_col= cost, 
duration = False, 
count = True, 
count_startdate = False,
dayssince = False, si_rollup_ouput_type =Both);

proc delete data=raw; run;


%mend;
/**/
/*%si_get_T1benefits( si_T1_benefits_dsn = IDI_Clean, si_T1_benefits_proj_schema = DL-MAA2016-15, si_T1_benefits_table_in = si_pd_cohort, */
/*			si_T1_benefits_id_col = snz_uid, si_T1_benefits_asat_date = as_at_date, si_T1_benefits_table_out = test2);*/
/**/
/**/
/**/
/**/
