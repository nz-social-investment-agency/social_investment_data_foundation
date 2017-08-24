/*********************************************************************************************************
DESCRIPTION: The 2013 census asks a question about marking the official NZ languages you can speak.
From there those that can speak te reo can be identified

INPUT:
si_reo_dsn = Database name {default = IDI_Clean}
si_reo_proj_schema = Project schema used to find your tables in the sandpit
si_reo_table_in = name of the input table
si_reo_id_col = id column used for joining tables {default = snz_uid}
si_reo_asat_date = name of the column containing a datetime field used to identify outcomes in a 
    specified time period

OUTPUT:
si_reo_table_out = name of the output table containing a te_reo_speaker indicator

AUTHOR: E Walsh

DEPENDENCIES:
Access to [IDI_Clean].[cen_clean].[census_individual]

NOTES: 
This is derived from the 2013 census so there may be quality issues if you deviate too far
away from that time period 

Assumption is that you were speaking the language since you were born but there is a date
macro variable that can be used for filtering

HISTORY: 
19 Jun 2017 EW v1
*********************************************************************************************************/
%macro si_get_te_reo(si_reo_dsn = IDI_Clean, si_reo_proj_schema =, si_reo_table_in =, si_reo_id_col =, 
si_reo_asat_date =, si_reo_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ---------------si_get_te_reo: Inputs----------------------;
	%put ............si_reo_dsn: &si_reo_dsn;
	%put ....si_reo_proj_schema: &si_reo_proj_schema.;
	%put .......si_ece_table_in: &si_reo_table_in;
	%put .........si_reo_id_col: &si_reo_id_col.;
	%put ......si_reo_asat_date: &si_reo_asat_date;
	%put ......si_reo_table_out: &si_reo_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table &si_reo_table_out. as 
			select * from connection to odbc(
			select 
				a.*
				,1 as te_reo_speaker
			from [IDI_Sandpit].[&si_reo_proj_schema.].[&si_reo_table_in.] a
				left join [IDI_Clean].[cen_clean].[census_individual] b
                on a.&si_reo_id_col = b.&si_reo_id_col
					/* Maori speaking derived from the official language questions in the census 
				[IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_OFFLANGIN2] 
				watch out that look up table uses umlauts rather than macrons or regular vowels */
					where b.cen_ind_official_language_code in ('11', '21', '22', '23', '31', '32', '33', '41') 
			);
			disconnect from odbc;
	quit;

%mend;



