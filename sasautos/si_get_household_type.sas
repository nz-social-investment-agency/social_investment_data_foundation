/*********************************************************************************************************
DESCRIPTION: Identifies counts of the types of people (in terms of age bands)a person lives with in a 
particular household

INPUT:
si_hht_dsn = Database name {default = IDI_Clean}
si_hht_proj_schema = Project schema used to find your tables in the sandpit
si_hht_table_in = name of the input table
si_hht_id_col = id column used for joining tables {default = snz_uid}
si_hht_asat_date = name of the column containing a datetime field used to identify outcomes in a 
specified time period

OUTPUT:
si_hht_table_out = name of the output table containing the indicators num_hh_age_under_5
num_hh_age_school_5_12 num_hh_age_teen_13_18 num_hh_age_adult_19_64 num_hh_age_over_64

AUTHOR: E Walsh

DEPENDENCIES:
Access to [IDI_Clean].[data].[address_notification] and [IDI_Clean].[data].[personal_detail]

NOTES: 
TBA

HISTORY: 
21 Jun 2017 EW v1
*********************************************************************************************************/
%macro si_get_hh_type_outcomes( si_hht_dsn = IDI_Clean, si_hht_proj_schema =, si_hht_table_in =, 
			si_hht_id_col = snz_uid, si_hht_asat_date =, si_hht_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ---------------si_get_hht_outcomes: Inputs------------------------;
	%put ............si_hht_dsn: &si_hht_dsn;
	%put ....si_hht_proj_schema: &si_hht_proj_schema;
	%put .......si_hht_table_in: &si_hht_table_in;
	%put .........si_hht_id_col: &si_hht_id_col;
	%put ......si_hht_asat_date: &si_hht_asat_date;
	%put ......si_hht_table_out: &si_hht_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	/*	options mlogic mprint;*/
	/*	options sastrace=',,,d' sastraceloc=saslog nostsuffix;*/
	proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table _temp_households_people_age as 
			select * from connection to odbc(
			select a.&si_hht_id_col. 
				, datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), a.as_at_date) as age_as_at_date
				, b.[snz_idi_address_register_uid]
				,
			    case 
				  when datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), a.as_at_date) < 5 then 1 
			    end as age_under_5
		      	,
	         	case 
		        	when datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), a.as_at_date) between 5 and 12 then 1 
		        end as age_school_5_12
	         	,
	            case 
		            when datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), a.as_at_date) between 13 and 18 then 1 
              	end as age_teen_13_18
	            ,
                case 
	                when datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), a.as_at_date) between 19 and 64 then 1 
                end as age_adult_19_64
                ,
                case 
                    when datediff(yyyy, datefromparts(c.snz_birth_year_nbr , c.snz_birth_month_nbr, 15), a.as_at_date) > 64 then 1 
                end as age_over_64
            from [IDI_Sandpit].[&si_hht_proj_schema.].[&si_hht_table_in.] a  

		 /* figure when people lived at a particular house */
         inner join (
             select 
	             [&si_hht_id_col.]
	             ,[ant_notification_date]
	             ,[ant_replacement_date]
	             ,[snz_idi_address_register_uid]
             from [&si_hht_dsn.].[data].[address_notification]
	     ) b on a.&si_hht_id_col. = b.&si_hht_id_col.

	     /* estimate when the person in the house was born */
         inner join (
	         select &si_hht_id_col., snz_birth_year_nbr, snz_birth_month_nbr from [&si_hht_dsn.].[data].[personal_detail]
		 ) c on a.&si_hht_id_col.=c.&si_hht_id_col. 
	    where a.&si_hht_asat_date. between b.[ant_notification_date] and b.[ant_replacement_date]
		order by [snz_idi_address_register_uid]
		);
		disconnect from odbc;
	quit;

	/* first up do a break down of properties of the household */
	proc sql;
		create table _temp_hh_comp as
			select snz_idi_address_register_uid
				,sum(age_under_5) as num_hh_age_under_5
				,sum(age_school_5_12) as num_hh_age_school_5_12
				,sum(age_teen_13_18) as num_hh_age_teen_13_18
				,sum(age_adult_19_64) as num_hh_age_adult_19_64
				,sum(age_over_64) as num_hh_age_over_64
			from _temp_households_people_age
				group by snz_idi_address_register_uid;
	quit;

	/* then relate back to the individual */
	proc sql;
		create table &si_hht_table_out. as
			select
				b.&si_hht_id_col.
				,a.*
			from _temp_hh_comp a
				left join _temp_households_people_age b
					on a.snz_idi_address_register_uid = b.snz_idi_address_register_uid
				order by snz_idi_address_register_uid;
	quit;

%mend;

/* test */
%si_get_hh_type_outcomes( si_hht_dsn = IDI_Clean, si_hht_proj_schema = DL-MAA2016-15, si_hht_table_in = si_pd_cohort, 
	si_hht_id_col = snz_uid, si_hht_asat_date = as_at_date, si_hht_table_out = work.hht_indicators);