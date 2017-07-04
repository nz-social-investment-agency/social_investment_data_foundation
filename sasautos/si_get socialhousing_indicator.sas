/*********************************************************************************************************
DESCRIPTION: 
From the input dataset, this macro returns a set of individuals consisting of those who have lived in a 
social house before the supplied "as-at" date.

INPUT: 
si_proj_schema = The database schema for the project, in which the population table resides. 
	For example, [DL-MAA2016-15].
si_table_in =  The name of the population table, eg. resident_population_2013. The id should be numeric 
	and as-at date column should be in datetime format.
si_id_col =  The ID column in the population table. By default, this is assumed to be snz_uid.
si_as_at_date = The "as-at" date column in the input dataset.  For each individual, the entire historical 
	social housing tenancy snapshot data before this date will be searched for whether the person has ever 
	lived in social housing.
si_out_table = Name of output table

OUTPUT:
si_out_table, which will have the set of individuals who have ever lived in social housing before the supplied
as-at date for the individual.

AUTHOR: V Benny

DEPENDENCIES: 
Requires the user to have access to hnz_clean schema on the IDI_Clean or archived IDI_Clean versions.

NOTES: 


ISSUES:
Note that the data availability for hnz_clean.tenancy_household_snapshot (as on 20 April 2017 IDI Refresh)
is patchy. This tables are missing data for 2009-10 period. For this period, it is best to get data from
the IDI_Sandpit version of this table, [clean_read_HNZ].[adhoc_clean_tenancy_household_snapshot]. The
tenancy snapshot data is available only from 2001 onwards, so any tenancies before that point will not be
considered in the output.


HISTORY: 
23 Jun 2017		Vinay Benny		v1 
*********************************************************************************************************/


%macro si_get_socialhousing_indicator(si_idiclean_version=, si_proj_schema=, si_table_in=, si_id_col = snz_uid, si_as_at_date = , si_out_table= );

	proc sql;

		connect to odbc (dsn=idi_clean_archive_srvprd);	

		create table work.&si_out_table. as 
			select * from connection to odbc(
				select &si_id_col. from IDI_Sandpit.&si_proj_schema..&si_table_in. as pop
				where exists (
					/* If the individual is found in the tenancy snapshot table at any point before "as-at" date, return 1 */
					select 1 from &si_idiclean_version..hnz_clean.tenancy_household_snapshot ths
					where pop.&si_id_col. = ths.snz_uid
						and ths.hnz_ths_snapshot_date <= pop.&si_as_at_date.
					)
			);

		disconnect from odbc;
	quit;

%mend;

/*%si_get_socialhousing_indicator(si_idiclean_version = IDI_Clean , si_proj_schema=[DL-MAA2016-15], si_table_in = respop_2013_char_ext, 
si_id_col = snz_uid, si_as_at_date = as_at_date , si_out_table= shpop ) */
