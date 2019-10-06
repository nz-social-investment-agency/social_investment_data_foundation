/*********************************************************************************************************
TITLE: si_get_cohort_example_pd.sas

DESCRIPTION: this is a test population to feed into the social investment data foundation. Users will
have to add code to sasprogs/si_get_cohort.sas to defube their own population

INPUT: 
To be determined by the user. In this example
data.personal_detail = table with some birthday info and spine indicator


OUTPUT:
To be determined by the user. In this example
si_pd_cohort = table with a list of ids an as at dates

AUTHOR: E Walsh

DATE: 05 May 2017

DEPENDENCIES: 
Requires access to the IDI_clean_archive_srvprd schema

NOTES: 

HISTORY: 
05 May 2017 EW v1 example
*********************************************************************************************************/
%put INFO: This is the place for you to insert your code. The final table needs snz_uid and an as at date. An example is shown below;

/* obtain a list of ids we would like to analyse */
/* we chose to use the personal detail table in the hope that most people have access to this table */
/* dates were randomly chosen */
proc sql;
	connect to odbc (dsn=&si_idi_dsnname);
	create table SIDF_example_dataset as 
		select snz_uid
			,dhms(as_at_date, 0, 0, 0) as as_at_date format=datetime20.
		from connection to odbc(
			select top 10000
				/* identifiers and trackers */
				person.snz_uid
				,cast('2017-' + right('0' + cast(person.snz_birth_month_nbr as varchar(2)), 2) + '-01' as date) as [as_at_date]
			from data.personal_detail person
			/* normally this is done in the characteristics extension but because we are doing a top 10000 we cant risk having
			only a small percentage of the people with data and dates so we do it here */
			/* for your populations you will want to do spine indicators and other identity filters in the characteristics 
			extension */
			where person.snz_spine_ind = 1 and snz_birth_month_nbr >= 1)
				/* not everyone has birth info in the personal_detail table */
	where as_at_date is not missing
	
	;
disconnect from odbc;

quit;



