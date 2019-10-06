/*********************************************************************************************************
DESCRIPTION: Identify any functional needs that have been identified in the SOCRATES disability data

INPUT:
si_din_dsn = Database name {default = IDI_Clean}
si_din_proj_schema = Project schema used to find your tables in the sandpit
si_din_table_in = name of the input table
si_din_id_col = id column used for joining tables {default = snz_uid}

OUTPUT:
si_din_table_out = name of the output table containing disability_needs_flag

AUTHOR: E Walsh

DEPENDENCIES:
macros are all located in the sasautos folder 
access to [IDI_Sandpit].[clean_read_MOH_SOCRATES].[moh_support_needs]

NOTES: 
The current structure assumes that they were born with a disability and that the support needs have
been present since birth

HISTORY:
14 Jul 2017 WJ v1.1 - changing to innder join rather than left join - commenting out test
14 Jul 2017 EW v1
July 2019 PNH - SOCRATES table moved to IDI_Adhoc 
*********************************************************************************************************/
%macro si_get_disability_needs(si_din_dsn = IDI_Clean, si_din_proj_schema =, si_din_table_in =, si_din_id_col =, 
			si_din_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ---------------si_get_disability_needs: Inputs----------------------;
	%put ............si_din_dsn: &si_din_dsn;
	%put ....si_din_proj_schema: &si_din_proj_schema.;
	%put .......si_ece_table_in: &si_din_table_in;
	%put .........si_din_id_col: &si_din_id_col.;
	%put ......si_din_table_out: &si_din_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc(dsn=&si_idi_dsnname.);
		create table &si_din_table_out. as 
			select * from connection to odbc(
			select distinct a.* 
				, 1 as disability_needs_flag
				/*				,c.code as disability_needs_code */
				/*				,c.description as disability_needs_desc*/
			from
				[IDI_SANDPIT].[&si_din_proj_schema.].[&si_din_table_in.] a
			left join [&si_din_dsn].[security].[concordance] b
				on a.&si_din_id_col = b.&si_din_id_col
			inner join [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_support_needs] c
				on b.snz_moh_uid = c.snz_moh_uid
				);
		disconnect from odbc;
	quit;

%mend;