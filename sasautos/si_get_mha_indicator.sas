/*********************************************************************************************************
DESCRIPTION: 
This macro creates 2 indicator variables for each individual in the input data supplied to
the macro based on whether they have ever had contact with an MHA related service. Please note that
if an individual does not have interactions with any MHA service, they will be not be in the dataset. 
What this means is that the output of this macro will need to be left-joined with your population dataset
to get indicators for every individual in your population cohort.

INPUT: 
si_proj_schema = The database schema for theproject, in which the population table and the moh_diagnosis
	table reside. For example, [DL-MAA2016-15]
si_table_in =  The name of the population table, eg. resident_population_2013. The id should be numeric 
	and as-at date column should be in datetime format.
si_id_col =  The ID column in the population table. By default, this is assumed to be snz_uid.
si_as_at_date = The "as-at" date for which the mental health and substance abuse history indicators
	need to be created. For each individual, the entire historical data before this date will be 
	examined for use of MHA services.
si_out_table = Name of output table

OUTPUT:
si_out_table, which will have separate indicators for history of MH service access and Substance abuse
service access.

AUTHOR: V Benny

DEPENDENCIES: 
Requires the MHA Data definition to be run before execution of this script. This would create the table
moh_diagnosis in the project schema of the user.

NOTES: 
Note that the earliest available history for Pharms data is 2005, and PRIMHD is 2008. The MHA indicators 
are restricted by this data availability.

ISSUES:

HISTORY: 
22 Jun 2017		V Benny		v1 
*********************************************************************************************************/

%macro si_get_mha_indicator(si_proj_schema=, si_table_in=, si_id_col = snz_uid, si_as_at_date = , si_out_table= );
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put -------si_get_mha_indicator: Inputs-----------------------;
	%put ............si_proj_schema: &si_proj_schema;
	%put ...............si_table_in: &si_table_in;
	%put .................si_id_col: &si_id_col;
	%put .............si_as_at_date: &si_as_at_date;
	%put ..............si_out_table: &si_out_table;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc (dsn=&si_idi_dsnname.);	
		create table work.&si_out_table. as 
			select * from connection to odbc (
				/*Create temporary table for all MH access before as-at date for population table*/
				with mhpop as (
					select pop.&si_id_col.
					from [IDI_Sandpit].[&si_proj_schema.].&si_table_in. pop
					where exists(
							select 1 from  [IDI_Sandpit].[&si_proj_schema.].moh_diagnosis mha 
							where mha.snz_uid = pop.&si_id_col.
								and mha.end_date <= pop.&si_as_at_date.
								and mha.event_type not in ('Potential MH','Substance use'))
				),
				/*Create temporary table for all Substance Abuse access before as-at date for population table*/
				adpop as(
					select pop.&si_id_col.
					from [IDI_Sandpit].[&si_proj_schema.].&si_table_in. pop
					where exists(
							select 1 from  [IDI_Sandpit].[&si_proj_schema.].moh_diagnosis mha 
							where mha.snz_uid = pop.&si_id_col.
								and mha.end_date <= pop.&si_as_at_date.
								and mha.event_type = 'Substance use')
				)
				select 
					coalesce(mhpop.&si_id_col., adpop.&si_id_col.) as &si_id_col., 
					case when mhpop.&si_id_col. is null then 0 else 1 end as prev_mh_ind,
					case when adpop.&si_id_col. is null then 0 else 1 end as prev_sub_ind
				from adpop
				full outer join mhpop on( adpop.&si_id_col. = mhpop.&si_id_col.)
			) ;

		disconnect from odbc;
	quit;

%mend;

