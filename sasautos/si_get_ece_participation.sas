/*********************************************************************************************************
DESCRIPTION: Early childhood education refers to education services for children under the age of 5.
Kohanga Reo is an ECE where education is delivered in Te Reo Maori. Kohanga is designed to involve whanau
and expose children to te reo (language) and the culture (tikanga).

The script identifies children who have been at ECE. There is also the option to specifically identify 
those who have attended Kohanga

INPUT:
si_ece_proj_schema = Project schema used to find your tables in the sandpit
si_ece_table_in = name of the input table
si_ece_type = type of ECE you want to flag {Any | Kohanga}
si_ece_id_col = id column used for joining tables {default = snz_uid}
si_ece_asat_date = name of the column containing a datetime field used to identify outcomes in a 
    specified time period

OUTPUT:
si_ece_table_out = name of the output table containing the indicator ece_&si_ece_type._flag

AUTHOR: E Walsh

DEPENDENCIES:
SIAL v1.1.0 and access to the MOE schemas

NOTES: 

HISTORY: 
19 Jun 2017 EW v1
*********************************************************************************************************/
%macro si_get_ece_participation(si_ece_table_in =, si_ece_type = , si_ece_proj_schema =, si_ece_id_col =,
si_ece_asat_date =, si_ece_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put -------------si_get_ece_participation: Inputs-----------------------;
	%put ....si_ece_proj_schema: &si_ece_proj_schema;
	%put .......si_ece_table_in: &si_ece_table_in;
	%put ...........si_ece_type: &si_ece_type;
	%put .........si_ece_id_col: &si_ece_id_col;
	%put ......si_ece_asat_date: &si_ece_asat_date;
	%put ......si_ece_table_out: &si_ece_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table &si_ece_table_out. as 
			select * from connection to odbc(
			select 
			a.*
				,b.event_type as ece_&si_ece_type._flag
			from [IDI_Sandpit].[&si_ece_proj_schema.].[&si_ece_table_in.] a
				left join [IDI_Sandpit].[&si_proj_schema.].[SIAL_MOE_ece_events] b
				on a.&si_ece_id_col. = b.&si_ece_id_col.
					%if "&si_ece_type" = "Kohanga" %then

				%do;
					/* Kohanga Reo code retrieved from [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moe_ECEClassificationCode] */
					where b.event_type_2 = 20631 and [b.start_date] <= &si_ece_asat_date.
				%end;
			);
			disconnect from odbc;
	quit;

%mend;

/* test */
%si_get_ece_participation(si_ece_proj_schema = DL-MAA2016-15, si_ece_table_in = si_pd_cohort, si_ece_type = Any, 
 si_ece_id_col = snz_uid, si_ece_asat_date =  as_at_date, si_ece_table_out = si_pd_ece_indicator);