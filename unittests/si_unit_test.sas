/*********************************************************************************************************
TITLE: si_unit_test.sas

DESCRIPTION: batch of unit tests for the si data foundation

INPUT:
sashelp.cars
sashelp.timedata
[IDI_Sandpit].[DL-MAA2016-15].[mha_pop_sofie_w7_wgt_adj]
[IDI_Sandpit].[DL-MAA2016-15].[distinct_mha_pop]

OUTPUT:
Several exceptions
In si_write_to_db.sas = writing to the database uses an implicit passthrough
In si_write_to_db.sas = non ODBC engine specified. Are you sure you are writing to the database?
sand.delete_me_cars = a SAS table written to the db
sand.test_cluster_index_single = a SAS table written to the db with a cluster index on the id
sand.test_cluster_index_two_col = a SAS table written to the db with a cluster index on the id and date
work.sofie_master_char = table with characteristics
work.mha_pop_master_char = large table with characteristics

AUTHOR: E Walsh

DATE: 08 May 2017

DEPENDENCIES: 

NOTES: 

HISTORY: 
18 Aug 2017 EW added indicator tests
08 May 2017 EW v1
*********************************************************************************************************/

/* setup path and library */
/* these will need to be changed to reflect your schema and path */
%let si_source_path = \\wprdfs08\MAA2016-15 Supporting the Social Investment Unit\si_data_foundation;
%let si_proj_schema = DL-MAA2016-15;
libname sand ODBC dsn= idi_sandpit_srvprd schema = "DL-MAA2016-15" bulkload = yes;

/*********************************************************************************************************/
/* load all the macros */
options obs = MAX mvarsize = max pagesize = 132
	append =(sasautos=("&si_source_path.\sasautos" "&si_source_path.\sasautos\indicators"));

/********************* si_write_to_db **********************/
/* check exception: Should get an Error about implicit passthrough */
%si_write_to_db(
	si_write_table_in  = sashelp.cars,
	si_write_table_out = give_me_error);

/* check exception: Should get an Error about a non ODBC engine being used */
%si_write_to_db(
	si_write_table_in  = sashelp.cars,
	si_write_table_out = sasuser.cars);

/* assert: Should find the table delete_me_cars in the database */
%si_write_to_db(
	si_write_table_in  = sashelp.cars, 
	si_write_table_out = sand.delete_me_cars);

/* cant find a table in sashelp that has an id and a date - will need to make one to test */
/* use the row number as an id so we can test writing a cluster index */
data work.timedata;
	set sashelp.timedata;
	snz_uid = _N_;
run;

/* assert: should construct a cluster index based on snz_uid */
%si_write_to_db(
    si_write_table_in     = work.timedata, 
	si_write_table_out    = sand.test_cluster_index_single, 
	si_cluster_index_flag = True, 
	si_index_cols         = snz_uid);

/* assert: should write a cluster index on two columns snz_uid and the date column */
%si_write_to_db(
    si_write_table_in      = work.timedata, 
	si_write_table_out     = sand.test_cluster_index_two_col,
	si_cluster_index_flag  = True, 
	si_index_cols          = %bquote(snz_uid, datetime));

/* checkException: should give you an error about positional parameters must precede keyword parameters */
%si_write_to_db(
    si_write_table_in      = work.timedata, 
	si_write_table_out, 
	si_cluster_index_flag  = True, 
	si_index_cols          = snz_uid, datetime);

/********************** si_drop_db_table ********************** /
/* deprecated */

/* assert: Should find the table delete_me_cars in the database */
%si_write_to_db(
    si_write_table_in  = sashelp.cars, 
	si_write_table_out = sand.delete_me_cars);

/* assert: Should find the table is dropped from the database */
%si_drop_db_table (
	si_sandpit_libname = sand, 
	si_drop_table_in   = delete_me_cars);

/********************** si_conditional_drop_table **********************/
/* assert: Note in the log saying the table doesnt exist */
%si_conditional_drop_table(
	si_cond_table_in = sand.madeup_table);

data work.timedata;
	set sashelp.timedata;
	snz_uid = _N_;
run;

/* assert: Note in the log saying the table is being dropped */
%si_conditional_drop_table(
	si_cond_table_in = work.timedata);

data work.timedata;
	set sashelp.timedata;
	snz_uid = _N_;
run;

/* assert: Note in the log saying the table is being dropped */
%si_conditional_drop_table(
	si_cond_table_in = timedata);

/********************** si_get_characteristics **********************/
/* note the first two tests will only run for those with access to the schema */
/* they were chosen because we needed large sets to stress test */
/* in the future pulling a large table from IDI_Clean will probably be more useful */
/* assert: table &si_char_table_out. exists and is not empty */
/* assert: because this table is not in work you should also get a note about it being written to work */
/* small cohort ~15,000 run time ~ 15 seconds*/
%si_get_characteristics(
	si_char_proj_schema = DL-MAA2016-15, 
	si_char_table_in    = mha_pop_sofie_w7_wgt_adj, 
	si_as_at_date       = sofie_id_start_intervw_period_da, 
	si_char_table_out   = work.mha_sofie_char);

/* assert: table &si_char_table_out. exists and is not empty */
/* assert: because this table is not in work you should also get a note about it being written to work */
/* stress test ~2.5 million run time ~ 1.5 minutes */
%si_get_characteristics(
    si_char_proj_schema = DL-MAA2016-15, 
	si_char_table_in    = distinct_mha_pop, 
	si_as_at_date       = date_diagnosed, 
	si_char_table_out   = work.mha_pop_char);

/* checkException: should give you an error about not specifing a libname in si_char_table_in */
%si_get_characteristics(
    si_char_proj_schema = DL-MAA2016-15, 
	si_char_table_in    = work.mha_pop_sofie_w7_wgt_adj, 
	si_as_at_date       = sofie_id_start_intervw_period_da, 
	si_char_table_out   = work.mha_sofie_char);

/********************** test the outcomes/ indicators **********************/
proc sql;
	connect to odbc (dsn=idi_clean_archive_srvprd);
	create table si_pd_cohort as 
		select snz_uid
			,dhms(input(as_at_date,yymmdd10.), 0, 0, 0) as as_at_date format=datetime20.
		from connection to odbc(
			select top 10000
				/* identifiers and trackers */
				person.snz_uid
				,cast('2014-' + right('0' + cast(person.snz_birth_month_nbr as varchar(2)), 2) + '-01' as date) as [as_at_date]
			from data.personal_detail person
				/* normally this is done in the characteristics extension but because we are doing a top 10000 we cant risk having
				only a small percentage of the people with data and dates so we do it here */
				/* for your populations you will want to do spine indicators and other identity filters in the characteristics 
				extension */
			where person.snz_spine_ind = 1)
				/* not everyone has birth info in the personal_detail table */
	where as_at_date is not missing;
quit;

%si_write_to_db(
    si_write_table_in      = si_pd_cohort,
	si_write_table_out     = sand.si_pd_cohort,
	si_cluster_index_flag  = True,
	si_index_cols          = %bquote(snz_uid, as_at_date)
	);

/********************** si_get_mothersmoke **********************/
/* assert: table &si_pd_mothersmoke with flag column mother_smoke_birth 1 denoting smoked at least 1 year before birth */
%si_get_mother_smoke(
    si_mother_smoke_dsn          = IDI_Clean, 
	si_mother_smoke_proj_schema  = DL-MAA2016-15, 
	si_mother_smoke_table_in     = si_pd_cohort,	
	si_mother_smoke_id_col       = snz_uid, 
	si_mother_smoke_asat_date    = as_at_date,
	si_mother_smoke_table_out    = si_mothers_smoke);

/********************** si_get_hh_type_outcomes **********************/
/* assert: table &si_hht_table_out with num_hh_age_* variables denoting the number of people in each age band */
/* column will be missing if there is noone in the relevant age band */
%si_get_hh_type_outcomes(
    si_hht_dsn          = IDI_Clean, 
	si_hht_proj_schema  = DL-MAA2016-15, 
	si_hht_table_in     = si_pd_cohort, 
	si_hht_id_col       = snz_uid, 
	si_hht_asat_date    = as_at_date, 
	si_hht_table_out    = work.hht_indicators);

/********************** si_get_ece_participation **********************/
/* assert: &si_ece_table_out with &ece_&si_ece_type._flag = 1 if they attended the ece type specified */
%si_get_ece_participation(
    si_ece_proj_schema  = DL-MAA2016-15, 
	si_ece_table_in     = si_pd_cohort, 
	si_ece_type         = Any, 
	si_ece_id_col       = snz_uid, 
	si_ece_asat_date    =  as_at_date, 
	si_ece_table_out    = si_pd_ece_indicator);

/********************** si_get_b4s_outcomes **********************/
/* assert: &si_b4s_table_out. with b4sc_*_outcome columns denoting the outcomes of each of the cbefore school checks */
%si_get_b4s_outcomes(
    si_b4s_dsn         = IDI_Clean, 
	si_b4s_proj_schema = DL-MAA2016-15, 
	si_b4s_table_in    = si_pd_cohort, 
	si_b4s_id_col      = snz_uid, 
	si_b4s_asat_date   = as_at_date, 
	si_b4s_table_out   = work.b4s_indicators);

/********************** si_get_pah **********************/
/* assert: &si_pah_table_out with columns for potentially avoidable hospitalisations flag and description */
%si_get_pah(
    si_pah_dsn         = IDI_Clean, 
	si_pah_proj_schema = DL-MAA2016-15, 
    si_pah_table_in    = si_pd_cohort ,
	si_pah_id_col      = snz_uid,
	si_pah_date        = as_at_date , 
	si_pah_table_out   = work.pah_indicator);


/********************** si_get_disability_needs **********************/
/* assert: &si_din_table_out with disability_needs_flag for whether or not a person has a disability */
%si_get_disability_needs(
    si_din_proj_schema = DL-MAA2016-15, 
	si_din_table_in    = si_pd_cohort,  
	si_din_id_col      = snz_uid, 
	si_din_table_out   = si_disability_needs);

/********************** si_get_cr_outcomes **********************/
/* assert: &si_crd_table_out with contact record and police family violence flags (contact_record and police_fv) */
%si_get_cr_outcomes(
    si_crd_dsn         = IDI_Clean, 
	si_crd_proj_schema = DL-MAA2016-15, 
	si_crd_table_in    = si_pd_cohort, 
	si_crd_id_col      = snz_uid, 
	si_crd_asat_date   = as_at_date, 
	si_crd_table_out   = work.crd_indicators);

/********************** si_get_diabetes **********************/
/* assert: &si_diabetes_table_out with diabetes flag */
%si_get_diabetes(
    si_diabetes_dsn         = IDI_Clean, 
	si_diabetes_proj_schema = DL-MAA2016-15, 
	si_diabetes_table_in    = si_pd_cohort,
	si_diabetes_id_col      = snz_uid, 
	si_diabetes_asat_date   = as_at_date, 
	si_diabetes_table_out   = si_pd_diabetes);

/********************** si_get_mha_indicator **********************/
/* assert: &si_out_table with mental health and addiction flags prev_mh_ind prev_sub_ind */
%si_get_mha_indicator(
    si_proj_schema = [DL-MAA2016-15], 
	si_table_in    = si_pd_cohort, 
	si_id_col      = snz_uid,
	si_as_at_date  = as_at_date, 
	si_out_table   = si_mha_outcomes);

/********************** si_get_socialhousing_indicator **********************/
/* assert: &si_out_table with list of snz_uid that are in the tenancy snapshot table */
%si_get_socialhousing_indicator(
    si_idiclean_version = IDI_Clean, 
	si_proj_schema      = [DL-MAA2016-15], 
	si_table_in         = si_pd_cohort, 
	si_id_col           = snz_uid, 
	si_as_at_date       = as_at_date, 
	si_out_table        = shpop);


/********************** si_get_freq_address_changes **********************/
/* assert: &si_out_table with list of snz_uid that have more than &si_nbr_address_changes address. changes */
%si_get_freq_address_changes(
    si_idiclean_version    = IDI_Clean, 
	si_proj_schema         = [DL-MAA2016-15], 
	si_table_in            = si_pd_cohort, 
	si_id_col              = snz_uid, 
	si_as_at_date          = as_at_date , 
	si_nbr_address_changes = 5, 
	si_nbr_periods         = 3, 
	si_out_table           = addrchange_ind);


/********************** si_get_te_reo **********************/
/* assert: &si_reo_table_out with a te_reo_speaker flag*/
%si_get_te_reo(
    si_reo_proj_schema = DL-MAA2016-15,
	si_reo_table_in    = si_pd_cohort,  
	si_reo_id_col      = snz_uid,
	si_reo_table_out   = si_pd_reo_indicator);

/********************** si_get_birth_outcomes **********************/
/* experimental may not run */
%si_get_birth_outcomes( 
	si_bir_dsn         = IDI_Clean, 
	si_bir_proj_schema = DL-MAA2016-15, 
	si_bir_table_in    = si_pd_cohort, 
	si_bir_id_col      = snz_uid, 
	si_bir_asat_date   = as_at_date, 
	si_bir_table_out   = work.birth_indicators);