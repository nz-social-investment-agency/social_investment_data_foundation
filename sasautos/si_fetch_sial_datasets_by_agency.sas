/*******************************************************************************************************
TITLE: si_fetch_sial_datasets_by_agency.sas

DESCRIPTION: Fetch all SIAL dataset names from the specified schema in IDI Sandpit for the specified agency,
	such that a specific column exists (or does not exist) in that SIAL dataset.
	

INPUT:
si_schema_name = Database project schema in IDI_Sandpit where the SIAL datasets are created
si_agency_tag = [MOE MSD MOH POL COR MOJ MIX IRD ACC CYF]Agency for which the SIAL table names are to be 
	fetched.
si_column_name = Only those SIAL tables that have this column, (or does not have this column depending on the 
	value of si_fetch_tab_with_column parameter) will be fetched.
si_fetch_tab_with_column = [True False] This parameter is used to specifiy whether the column is to be checked
	for presence or absence in the SIAL table. True means all SIAL tables(for a particular agency) that have 
	the column will be fetched,	False means all tables that have the column will not be fetched.
si_out_var = This should be a local/global SAS variable that is used to store the list of SIAL table names
	that are fetched.

Sample call:

%local testervar;
%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAAXXXX-XX, si_agency_tag = moe, 
	si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = testervar);
%put &testervar;



OUTPUT: Outputs a list of SIAL table names that satify the input conditions.


AUTHOR: V Benny

DATE: 

DEPENDENCIES:
This macro requires a global or local macro variable defined before the macro call and then passed into this macro 
to store the output list. This is being used as SAS macros have no inherent functionality of returning a value 
from the execution of a macro. 

NOTES: 

KNOWN ISSUES: 


HISTORY: 
18 May 2017	VB	v1

***********************************************************************************************************/

%macro si_fetch_sial_datasets_by_agency(si_schema_name = , si_agency_tag = , si_column_name = cost,
	si_fetch_tab_with_column = True, si_out_var = );

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_fetch_sial_datasets_by_agency----------------------;
	%put ...................si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put ......................SIAL Schema name: &si_schema_name.;
	%put ...........................Agency name: &si_agency_tag.;
	%put ...........................Column Name: &si_column_name.;
	%put ..............Column Exists/Not Exists: &si_fetch_tab_with_column.;
	%put .................Output macro variable: &si_out_var.;
	
	/* If si_fetch_tab_with_column is True, check for the existence of the column in SIAL tables*/
	%if &si_fetch_tab_with_column. eq True %then %do;

		proc sql;

			connect to odbc (dsn=idi_clean_archive_srvprd);

			select tname 
				into :&si_out_var. separated by " " 
			from connection to odbc (
				select distinct v.name as tname from [IDI_Sandpit].sys.objects v
				inner join [IDI_Sandpit].sys.schemas s on (v.schema_id = s.schema_id)
				where 
					s.name = %bquote('&si_schema_name.') 
					and upper(v.name) like upper('SIAL_' + upper( %bquote('&si_agency_tag.') ) +'_%_events')
					and exists (select 1 from [IDI_Sandpit].sys.columns c 
								where c.object_id=v.object_id and upper(c.name) = upper(%bquote('&si_column_name.') ) )
			);

			disconnect from odbc;

		quit;		

	%end;

	/* If si_fetch_tab_with_column is False, check for the non-existence of the column in SIAL tables*/
	%else %do;
		proc sql;

			connect to odbc (dsn=idi_clean_archive_srvprd);

			select tname 
				into :&si_out_var. separated by " " 
			from connection to odbc (
				select distinct v.name as tname from [IDI_Sandpit].sys.objects v
				inner join [IDI_Sandpit].sys.schemas s on (v.schema_id = s.schema_id)
				where 
					s.name = %bquote('&si_schema_name.') 
					and upper(v.name) like upper('SIAL_' + upper( %bquote('&si_agency_tag.') ) +'_%_events')
					and not exists (select 1 from [IDI_Sandpit].sys.columns c 
								where c.object_id=v.object_id and upper(c.name) = upper(%bquote('&si_column_name.') ) )
			);

			disconnect from odbc;

		quit;

	%end;

	%put ------------End Macro: si_fetch_sial_datasets_by_agency----------------------;

%mend si_fetch_sial_datasets_by_agency;

/*
options mlogic mprint;

%macro tester;
%local testervar;
%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moe, si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = testervar);
%put &testervar;
%mend;

%tester;
*/