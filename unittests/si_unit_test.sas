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
08 May 2017 EW v1
*********************************************************************************************************/

/* setup path and library */
libname sand ODBC dsn= idi_sandpit_srvprd schema="DL-MAA2016-15" bulkload=yes;
%let si_source_path = \\wprdfs08\MAA2016-15 Supporting the Social Investment Unit\si_data_foundation;

/*********************************************************************************************************/
/* load all the macros */
options obs=MAX mvarsize=max pagesize=132
	append=(sasautos=("&si_source_path.\sasautos"));

/* specify global variables that are used by more than one macro */
%include "&si_source_path.\sasprogs\si_control.sas";

/********************* si_write_to_db **********************/
/* check exception: Should get an Error about implicit passthrough */
%si_write_to_db(si_write_table_in=sashelp.cars, si_write_table_out=give_me_error);

/* check exception: Should get an Error about a non ODBC engine being used */
%si_write_to_db(si_write_table_in=sashelp.cars, si_write_table_out=sasuser.cars);

/* assert: Should find the table delete_me_cars in the database */
%si_write_to_db(si_write_table_in=sashelp.cars, si_write_table_out=sand.delete_me_cars);

/* cant find a table in sashelp that has an id and a date - will need to make one to test */
/* use the row number as an id so we can test writing a cluster index */
data work.timedata;
	set sashelp.timedata;
	snz_uid = _N_;
run;

/* assert: should construct a cluster index based on snz_uid */
%si_write_to_db(si_write_table_in=work.timedata, si_write_table_out=sand.test_cluster_index_single, 
	si_cluster_index_flag=True, si_index_cols=snz_uid);

/* assert: should write a cluster index on two columns snz_uid and the date column */
%si_write_to_db(si_write_table_in=work.timedata, si_write_table_out=sand.test_cluster_index_two_col,
	si_cluster_index_flag=True, si_index_cols=%bquote(snz_uid, datetime));

/* checkException: should give you an error about positional parameters must precede keyword parameters */
%si_write_to_db(si_write_table_in=work.timedata, si_write_table_out 
	si_cluster_index_flag=True, si_index_cols=snz_uid, datetime);

/********************** si_drop_db_table ********************** /
/* deprecated */

/* assert: Should find the table delete_me_cars in the database */
%si_write_to_db(si_write_table_in=sashelp.cars, si_write_table_out=sand.delete_me_cars);

/* assert: Should find the table is dropped from the database */
%si_drop_db_table (si_sandpit_libname = sand, si_drop_table_in = delete_me_cars);

/********************** si_conditional_drop_table **********************/
/* assert: Note in the log saying the table doesnt exist */
%si_conditional_drop_table(si_cond_table_in=sand.madeup_table);

data work.timedata;
	set sashelp.timedata;
	snz_uid = _N_;
run;

/* assert: Note in the log saying the table is being dropped */
%si_conditional_drop_table(si_cond_table_in=work.timedata);

data work.timedata;
	set sashelp.timedata;
	snz_uid = _N_;
run;

/* assert: Note in the log saying the table is being dropped */
%si_conditional_drop_table(si_cond_table_in=timedata);

/********************** si_get_characteristics **********************/
/* note the first two tests will only run for those with access to the schema */
/* they were chosen because we needed large sets to stress test */
/* in the future pulling a large table from IDI_Clean will probably be more useful */

/* assert: table &si_char_table_out. exists and is not empty */
/* assert: because this table is not in work you should also get a note about it being written to work */
/* small cohort ~15,000 run time ~ 15 seconds*/
%si_get_characteristics(si_char_proj_schema=DL-MAA2016-15, si_char_table_in=mha_pop_sofie_w7_wgt_adj, 
	si_as_at_date=sofie_id_start_intervw_period_da, si_char_table_out=work.mha_sofie_char);

/* assert: table &si_char_table_out. exists and is not empty */
/* assert: because this table is not in work you should also get a note about it being written to work */
/* stress test ~2.5 million run time ~ 1.5 minutes */
%si_get_characteristics(si_char_proj_schema=DL-MAA2016-15, si_char_table_in=distinct_mha_pop, 
	si_as_at_date=date_diagnosed, si_char_table_out=work.mha_pop_char);

/* checkException: should give you an error about not specifing a libname in si_char_table_in */
%si_get_characteristics(si_char_proj_schema=DL-MAA2016-15, si_char_table_in=work.mha_pop_sofie_w7_wgt_adj, 
	si_as_at_date=sofie_id_start_intervw_period_da, si_char_table_out=work.mha_sofie_char);