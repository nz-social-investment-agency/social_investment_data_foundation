/*********************************************************************************************************
DESCRIPTION: 
This macro creates a subset of individuals from the input dataset that have had at least "x" number of 
address changes in the last "y" previous years (calculated backwards from the as-on date provided in the 
input dataset). Here "x" and "y" will be specified by the user as part of the input to the macro.
For example, if we need all individuals that had at least 5 address changes in the 5 years before as-at date, 
this macro will output all such individuals in the supplied input dataset that satisfy this criteria. 

INPUT: 
si_proj_schema = The database schema for the project, in which the population table resides. 
	For example, [DL-MAA2016-15].
si_table_in =  The name of the input population table with ids and as-at dates, 
	eg. resident_population_2013. The id should be numeric and as-at date column should be in datetime format.
si_id_col =  The ID column in the population table. By default, this is assumed to be snz_uid.
si_as_at_date = The "as-at" date for which the mental health and substance abuse history indicators
	need to be created. For each individual, the historical data before this date will be 
	examined for changes in addresses. This has to be a datetime column.
si_nbr_address_changes = An integer specifying the number of address changes that is considered to be the 
	threshold for an individual to be included in the output dataset. For example, 5.
si_nbr_periods = An integer specifying the number of previous periods (counted backwards from the as-at date) that 
	need to be considered, during which the individual had the address changes. For example, 5.
si_out_table = Name of output table

OUTPUT:
si_out_table, which will have the set of individuals from the supplied dataset who has had at least "x" address 
changes in the last "y" years.

AUTHOR: V Benny

DEPENDENCIES: 
Requires the user to have access to the address_notification table in IDI_Clean.

NOTES: 
NA

ISSUES:
The address changes are limited by the duration for which the address changes are available, and whether the 
individual interacts/notifies the agencies of the change in address.

HISTORY: 
26 Jun 2017		Vinay Benny		v1 
*********************************************************************************************************/

%macro si_get_freq_address_changes(si_idiclean_version=, si_proj_schema=, si_table_in=, si_id_col = snz_uid, si_as_at_date = , 
	si_nbr_address_changes= , si_nbr_periods= , si_out_table= );

	proc sql;

		connect to odbc (dsn=idi_clean_archive_srvprd);	

		create table work.si_out_table as 
			select * from connection to odbc(
				select pop.&si_id_col. 
				from 
				IDI_Sandpit.&si_proj_schema..&si_table_in. pop
				inner join &si_idiclean_version..data.address_notification addr on (pop.&si_id_col. = addr.snz_uid)
				where ant_notification_date between dateadd(yyyy, -1 * &si_nbr_periods., pop.&si_as_at_date.) and pop.&si_as_at_date.
				group by pop.&si_id_col.
				having count(*) > &si_nbr_address_changes.
			);

		disconnect from odbc;

	quit;

%mend;

/*%si_get_freq_address_changes(si_idiclean_version = IDI_Clean , si_proj_schema = [DL-MAA2016-15], si_table_in = respop_2013_char_ext, 
si_id_col = snz_uid, si_as_at_date = as_at_date , si_nbr_address_changes= 5, si_nbr_periods= 3, si_out_table= addrchange_ind ) */