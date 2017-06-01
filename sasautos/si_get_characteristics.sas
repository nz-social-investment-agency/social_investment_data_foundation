/********************************************************************************************************
TITLE: si_get_master_chracteristics.sas

DESCRIPTION: Get the master characteristics for
the specificed population

INPUT:
si_char_proj_schema = name of your schema used to retrieve data in the sandpit via explicit pass through
si_char_table_in = input table with a list of ids and dates (must be in the sandpit and must not be 
                   preceeded with a libname)
si_as_at_date = the date from which we will look backto get slowly changing variables such as region

OUTPUT:
si_char_table_out = table with ids and list of static or slow changing characteristics

AUTHOR: E Walsh

DATE: 24 Apr 2017

DEPENDENCIES: 

NOTES: 
Stress tested with 2.5 million ids run time 2.5 min

HISTORY: 
24 Apr 2017 EW v1
*********************************************************************************************************/
%macro si_get_characteristics(si_char_proj_schema=, si_char_table_in=, 
			si_as_at_date=, si_char_table_out=);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ...si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ------------si_get_characteristics: Inputs--------------------------;
	%put ......si_char_table_in: &si_char_table_in;
	%put .........si_as_at_date: &si_as_at_date;
	%put .....si_char_table_out: &si_char_table_out;
	%put ********************************************************************;

	/* ensure that the user has only specified a table name and not libname.dataset */
	%if %scan(&si_char_table_in.,2,.) ~= %then
		%do;
			%put ERROR: In si_get_characteristics - si_char_table_in should be in table format "\n"
				not in libname.table format;
		%end;

	/* extract static characteristics that can be used for descriptive stats */
	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_personal_detail as 
			select *
				from connection to odbc(
					select
						a.snz_uid
						,a.&si_as_at_date
						,b.snz_birth_year_nbr
						,b.snz_birth_month_nbr
						/* an estimate of the age - will be wrong by a max of 16 days */
						, datediff(YEAR 
						,cast(cast(b.snz_birth_year_nbr as varchar(4))+ '-' +
						cast(b.snz_birth_month_nbr as varchar(2)) + '-15' as date)
						, a.&si_as_at_date) as as_at_age
						,b.snz_sex_code
						,b.snz_spine_ind 
						,b.snz_person_ind
					from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a 
						inner join [IDI_Clean].[data].[personal_detail] b
							on a.snz_uid=b.snz_uid
							/* now done in the extension */
							/*where b.snz_spine_ind = 1 and snz_person_ind = 1*/);
	quit;

	/* obtain the prioritised ethnictiy and the individual ethnicities*/
	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_source_ranked_ethnicity as
			select *
				from connection to odbc(
					select
						a.snz_uid					
						, b.snz_ethnicity_grp1_nbr
						, b.snz_ethnicity_grp2_nbr
						, b.snz_ethnicity_grp3_nbr
						, b.snz_ethnicity_grp4_nbr
						, b.snz_ethnicity_grp5_nbr
						, b.snz_ethnicity_grp6_nbr
						,
					case 
						when b.snz_ethnicity_grp2_nbr = 1 then 'M'					
						when b.snz_ethnicity_grp3_nbr = 1 then 'P'				
						when b.snz_ethnicity_grp4_nbr = 1 then 'A'
						when b.snz_ethnicity_grp5_nbr = 1 then 'Z'
						when b.snz_ethnicity_grp1_nbr = 1 then 'E'		
						when b.snz_ethnicity_grp6_nbr = 1 then 'O'
						else 'O'
					end 
				as prioritised_eth
					from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a
						inner join [IDI_Clean].[data].[source_ranked_ethnicity] b
							on a.snz_uid=b.snz_uid
							);
	quit;

	/* the most comprehensive source of iwi is from the census */
	/* grab the first three iwi specified */
	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_census_iwi1 as
			select *
				from connection to odbc(
					select
						a.snz_uid
						,b.cen_ind_iwi1_code
						,c.descriptor_text as iwi1_desc

					from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a
						inner join [IDI_Clean].[cen_clean].[census_individual] b  
							on a.snz_uid = b.snz_uid 
						inner join [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_IWI] c 
							on b.cen_ind_iwi1_code = c.cat_code
						where b.cen_ind_iwi_ind_code = '1'
							);
	quit;

	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_census_iwi2 as
			select *
				from connection to odbc(
					select
						a.snz_uid
						,b.cen_ind_iwi2_code
						,c.descriptor_text as iwi2_desc

					from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a
						inner join [IDI_Clean].[cen_clean].[census_individual] b  
							on a.snz_uid = b.snz_uid 
						inner join [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_IWI] c 
							on b.cen_ind_iwi2_code = c.cat_code
						where b.cen_ind_iwi_ind_code = '1'
							);
	quit;

	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_census_iwi3 as
			select *
				from connection to odbc(
					select
						a.snz_uid
						,b.cen_ind_iwi3_code
						,c.descriptor_text as iwi3_desc

					from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a
						inner join [IDI_Clean].[cen_clean].[census_individual] b  
							on a.snz_uid = b.snz_uid 
						inner join [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_IWI] c 
							on b.cen_ind_iwi3_code = c.cat_code
						where b.cen_ind_iwi_ind_code = '1'
							);
	quit;

	/* region */
	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_address_notification as
			select *
				from connection to odbc(
					select distinct
						a.snz_uid
						,b.ant_region_code
						,b.ant_ta_code
					from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a
						inner join [IDI_Clean].[data].[address_notification] b  
							on a.snz_uid = b.snz_uid and 
							a.&si_as_at_date between b.ant_notification_date and b.ant_replacement_date);
	quit;

	/* flags of other ids */
	/* some projects may like to restrict their cohorts to those who have a particular agency id */
	proc sql;
		connect to odbc (dsn=idi_clean_archive_srvprd);
		create table _temp_security_concordance as
			select snz_uid
				, 
			case 
				when snz_ird_uid is not null then 1 
				else 0 
			end 
		as snz_ird_ind
			, 
		case 
			when snz_moe_uid is not null then 1 
			else 0 
		end 
	as snz_moe_ind
		, 
	case 
		when snz_dol_uid is not null then 1 
		else 0 
	end 
as snz_dol_ind
	, 
case 
	when snz_msd_uid is not null then 1 
	else 0 
end 
as snz_msd_ind
, 
case 
when snz_jus_uid is not null then 1 
else 0 
end 
as snz_jus_ind
, 
case 
when snz_acc_uid is not null then 1 
else 0 
end 
as snz_acc_ind
, 
case 
when snz_moh_uid is not null then 1 
else 0 
end 
as snz_moh_ind
, 
case 
when snz_dia_uid is not null then 1 
else 0 
end 
as snz_dia_ind
, 
case 
when snz_cen_uid is not null then 1 
else 0 
end 
as snz_cen_ind
/* sometimes we use this as a quality control flag to identify which records we should use */

		,nmiss(snz_ird_uid, snz_moe_uid, snz_dol_uid,
		snz_msd_uid, snz_jus_uid, snz_acc_uid,
		snz_moh_uid, snz_cen_uid, snz_dia_uid
		) as uid_miss_ind_cnt
		from connection to odbc(
			select distinct
				a.snz_uid
				,b.[snz_ird_uid]
				,b.[snz_moe_uid]
				,b.[snz_dol_uid]
				,b.[snz_msd_uid]
				,b.[snz_jus_uid]
				,b.[snz_acc_uid]
				,b.[snz_moh_uid]
				,b.[snz_dia_uid]
				,b.[snz_cen_uid]
				from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.] a
					inner join [IDI_Clean].[security].[concordance] b  
						on a.snz_uid = b.snz_uid);
	quit;

	/* use of hash objects requires a table in work first */
	%if %sysfunc(exist(work.&si_char_table_in.)) = 0 %then
		%do;
		%put NOTE: In si_get_characteristics - si_char_table_in needs to be in work to use the hash objects;
		%put NOTE: writing a copy of si_char_table_in into the work area;

			proc sql;
				connect to odbc (dsn=idi_clean_archive_srvprd);
				create table work.&si_char_table_in. as
					select *
						from connection to odbc(
							select *
								from [IDI_Sandpit].[&si_char_proj_schema.].[&si_char_table_in.]);
									quit;
		%end;

	/* create a single table with all the characteristics in an efficient manner */
	data &si_char_table_out. (drop = return_code:);
		set &si_char_table_in.;

		if _N_ = 1 then
			do;
				/* sneaky way to load the columns into the pdv without the data */
				if 0 then
					set work._temp_personal_detail;
				declare hash hpd(dataset: 'work._temp_personal_detail');
				hpd.defineKey('snz_uid');
				hpd.defineData('snz_birth_year_nbr','snz_birth_month_nbr','as_at_age','snz_sex_code','snz_spine_ind');
				hpd.defineDone();

				if 0 then
					set work._temp_source_ranked_ethnicity;
				declare hash hsre(dataset: 'work._temp_source_ranked_ethnicity');
				hsre.defineKey('snz_uid');
				hsre.defineData('prioritised_eth');
				hsre.defineDone();

				if 0 then
					set work._temp_census_iwi1;
				declare hash hci1(dataset: 'work._temp_census_iwi1');
				hci1.defineKey('snz_uid');
				hci1.defineData('cen_ind_iwi1_code', 'iwi1_desc');
				hci1.defineDone();

				if 0 then
					set work._temp_census_iwi2;
				declare hash hci2(dataset: 'work._temp_census_iwi2');
				hci2.defineKey('snz_uid');
				hci2.defineData('cen_ind_iwi2_code', 'iwi2_desc');
				hci2.defineDone();

				if 0 then
					set work._temp_census_iwi3;
				declare hash hci3(dataset: 'work._temp_census_iwi3');
				hci3.defineKey('snz_uid');
				hci3.defineData('cen_ind_iwi3_code', 'iwi3_desc');
				hci3.defineDone();

				if 0 then
					set work._temp_address_notification;
				declare hash han(dataset: 'work._temp_address_notification');
				han.defineKey('snz_uid');
				han.defineData('ant_region_code', 'ant_ta_code');
				han.defineDone();

				if 0 then
					set work._temp_security_concordance;
				declare hash hsc(dataset: 'work._temp_security_concordance');
				hsc.defineKey('snz_uid');
				hsc.defineData('snz_ird_ind', 'snz_moe_ind', 'snz_dol_ind' , 
					'snz_msd_ind', 'snz_jus_ind', 'snz_acc_ind',
					'snz_moh_ind', 'snz_dia_ind', 'snz_cen_ind',
					'uid_miss_ind_cnt');
				hsc.defineDone();
			end;

		return_code_pd = hpd.find();
		return_code_sre = hsre.find();
		return_code_hci1 = hci1.find();
		return_code_hci2 = hci2.find();
		return_code_hci3 = hci3.find();
		return_code_han = han.find();
		return_code_hsc = hsc.find();
	run;

	/* clean up */
	%if %sysfunc(trim(&si_debug.)) = False %then
		%do;

			proc datasets lib=work;
				delete _temp_:;
			run;

		%end;
%mend si_get_characteristics;