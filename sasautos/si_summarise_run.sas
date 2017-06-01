/*********************************************************************************************************
TITLE: si_summarise_run.sas

DESCRIPTION: Summary of the dataset run

INPUT:
TBA


OUTPUT:
TBA

AUTHOR: E Walsh

DATE: 19 May 2017

DEPENDENCIES: 

NOTES: 
A complete example is shown in ../examples/XXXXX

HISTORY: 
19 May 2017 EW v1
*********************************************************************************************************/
%macro si_summarise_run(si_summ_proj_schema=);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ...si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_summarise_run: Inputs--------------------------------;
	%put ...si_summ_proj_schema: &si_summ_proj_schema;
	%put ********************************************************************;

	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_sandpit_tables as
			select *
				from connection to odbc(
					select
						s.name as schema_name
						,t.name as table_name
						,t.create_date
						,t.modify_date
					from [IDI_Sandpit].[sys].[tables] t 
						inner join [IDI_Sandpit].[sys].[schemas] s
							on t.schema_id=s.schema_id
						where s.name =%bquote('&si_summ_proj_schema') and cast(modify_date as date) >= cast(getdate() as date));
	quit;

	title "SI Data Foundation: Tables written to the sandpit today";
	ods text = "Note that if you have written other work to the sandpit today then this will also be listed here";
	ods text = " ";
	title;

	proc print data=_temp_sandpit_tables;
	run;

%mend;