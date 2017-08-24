/*********************************************************************************************************
DESCRIPTION: Identifies how old the parent was when they first gave birth and whether they were a teen
parent (ie someone who gave birth between 11 and 19 inclusive).

INPUT:
si_bir_dsn = Database name {default = IDI_Clean}
si_bir_proj_schema = Project schema used to find your tables in the sandpit
si_bir_table_in = name of the input table
si_bir_id_col = id column used for joining tables {default = snz_uid}
si_bir_asat_date = name of the column containing a datetime field used to identify outcomes in a 
specified time period

OUTPUT:
si_bir_table_out = name of the output table containing the indicators age_at_first_birth and
teen_parent

AUTHOR: E Walsh

DEPENDENCIES:
Access to [IDI_Clean].[dia_clean].[births] and [IDI_Clean].[data].[personal_detail]

NOTES: 
DIA parent demographic data is sparse it is better to retrieve gender and month/year of birth from 
personal details

HISTORY: 
21 Jun 2017 EW v1
*********************************************************************************************************/
%macro si_get_birth_outcomes( si_bir_dsn = IDI_Clean, si_bir_proj_schema =, si_bir_table_in =, 
			si_bir_id_col = snz_uid, si_bir_asat_date =, si_bir_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ---------------si_get_birth_outcomes: Inputs------------------------;
	%put ............si_bir_dsn: &si_bir_dsn;
	%put ....si_bir_proj_schema: &si_bir_proj_schema;
	%put .......si_bir_table_in: &si_bir_table_in;
	%put .........si_bir_id_col: &si_bir_id_col;
	%put ......si_bir_asat_date: &si_bir_asat_date;
	%put ......si_bir_table_out: &si_bir_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table &si_bir_table_out. as 
			select * from connection to odbc(
			select a.&si_bir_id_col.
				, b.num_children
				, datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), b.date_of_first_birth ) as
				age_at_first_birth
				, 
			case 
				/* Stats NZ statistics noted the youngest parents were 11 so this is treated as the lower bound of teen birth 
				anything younger is assumed to be a linking error */
				when datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), b.date_of_first_birth ) 
				between 11 and 19 then 1 
			end 
		as teen_parent
			from [IDI_Sandpit].[&si_bir_proj_schema.].[&si_bir_table_in.] a 
				/* estimate 
				when the baby was born */
			inner join (select snz_uid
				, min(child_birth_date) as date_of_first_birth 
				, count(snz_uid) as num_children
			from 
				(
				/* estimate 
				when the first baby was born */
			select parent1_snz_uid as &si_bir_id_col
				, datefromparts(dia_bir_birth_year_nbr, dia_bir_birth_month_nbr, 15) as child_birth_date 
			from [&si_bir_dsn.].[dia_clean].[births]
				union all 
			select parent2_snz_uid as &si_bir_id_col
				,datefromparts(dia_bir_birth_year_nbr, dia_bir_birth_month_nbr, 15) as child_birth_date 
			from [&si_bir_dsn.].[dia_clean].[births]
				)x group by snz_uid 
					)b on a.&si_bir_id_col.= b.&si_bir_id_col
					/* estimate 
					when the adult was born */
				inner join (
					select snz_uid, snz_birth_year_nbr
						, snz_birth_month_nbr 
					from [&si_bir_dsn.].[data].[personal_detail]
						) c on a.snz_uid=c.&si_bir_id_col.
					where b.date_of_first_birth <= a.&si_bir_asat_date.
						);
		disconnect from odbc;
%mend;