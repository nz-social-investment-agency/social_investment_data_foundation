/*******************************************************************************************************
TITLE: si_create_rollup_vars.sas

DESCRIPTION: This macro creates rolled-up variables for each individual from the SIAL events. For each
	individual in the population dataset, this macro looks at the profile and forecast windows for the individual
	and creates	the total amounts/costs for events in each period, the count of events, duration(in number of 
	days) spent on each event, and other variables like days from ast event in profile window and days to first 
	event in forecast window.


INPUT:
si_table_in = Input table, with UIDs and as-at dates . Please note that the column name needs to 
	be specified in the si_id_col and si_as_at_date parameters to the macro and datatype should be datetime.

si_sial_table = The table with SIAL events aligned to reference periods. This table should be the 
	output of si_align_sial_events_to_periods macro. 

si_agg_cols = A string with the list of events columns that the costs in SIAL table needs to be aggregated at.

si_id_col = The ID column available in the input table and the SIAL table.
	
si_as_at_date =  The name of the as-at date column

si_amount_col= the amount/cost in the SIAL table that needs to be aggregated. Default is "cost".

cost = [True False] Specify whether the event cost\revenue related variables are to be rolled up.

duration = [True False] Specify whether the event duration related variables are to be rolled up.

count = [True False] Specify whether the event count related-variables are to be rolled up. If an event spans 
	multiple periods, it is counted once in each of those periods.

count_startdate = [True False] Specify whether the event count-related variables are to be rolled up. if an event 
	spans multiple periods, it is only counted in the period in which it starts.

dayssince = [True False] Specify whether the days since last event (in profile window) and days to first event
	(in the forecast window) need to be created.

out_format = [Long Wide Both] Specify if the output format of the table should be a "Long" version, which has
	multiple rows per ID, one for each variable. The alternative is "Wide" version, which has one row per ID,
	with the variables showing up as columns. Another alternative is to request "Both".

entity = [True False] Specify whether to include a roll up of entities for output checking (MOE, PRIMHD, PHARMS)
Sample call:
%si_create_rollup_vars(si_table_in=work.test, si_sial_table=work.test2, si_out_table=work.test3, 
	si_agg_cols= %str(department datamart subject_area), cost = True, duration = False, count = True, dayssince = True, entity=True );



OUTPUT:
si_out_table = a subset of SIAL table events rolled up to the events list and roi period specified,
	for the relevant UIDs and time frames with costs adjusted to the quarter specified.

AUTHOR: Vinay Benny

DATE: 27-Jan-2017

DEPENDENCIES:

NOTES: 

KNOWN ISSUES: 
1. This macro creates equal sized time windows based on the daysinperiod parameter. This will
	not align itself with calendar months or years.
2. If the aggregation level is too granular, the wide version may run out of the 32 character limit imposed by SAS
	on column names. This may cause failure of the macro. In such cases, make sure to specify the "Long" output table 
	format only, and create your own column name abbreviations from it if you want to do a "Wide" table.

HISTORY: 
04 May 2017		VB	Created a generic version with duration, counts and days-since variables
14 Feb 2017		VB	Adapted for mental health rollups
27 Jan 2017 	VB 	Version 1
Aug 2019 PH Added option of rolling up distinct entity counts for output checking
***********************************************************************************************************/



/* Define a macro for costs rollup*/
%macro si_create_rollup_vars_entities(si_table_in=, si_sial_table=, si_out_table=, si_agg_cols=, si_id_col = snz_uid,
	si_as_at_date = , si_amount_col = cost,	cost = True, duration= True, count = True, count_startdate = True,
	dayssince=True, si_rollup_ouput_type =  );
	
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_create_rollup_vars----------------------;
	%put ...................si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put ...........................Input table: &si_table_in.;
	%put ............................SIAL table: &si_sial_table.;
	%put .............................ID Column: &si_id_col.;
	%put ...................Aggregation Columns: &si_agg_cols.;
	%put .....................As at Date Column: &si_as_at_date.;
	%put .........................Amount Column: &si_amount_col.;
	%put .................Output Cost variables: &cost.;
	%put .............Output Duration variables: &duration.;
	%put ................Output Count variables: &count.;
	%put ..................Output entity counts: &si_rollup_entities.;
	%put ....Output Count(based on event start): &count_startdate.;
	%put ...........Output Days Since variables: &dayssince.;
	%put ....................Rollup Output type: &si_rollup_ouput_type.;
	%put ..........................Output table: &si_out_table.;	
	
	/* Create a macro variable with comma-separated values for the aggregation columns. This can be used in proc sql statements */
	%if not( &si_agg_cols.=%str() ) %then %do;
		%let i = 1;
		%let commasep_aggcols = ;
		%let pipesep_aggcols = ;
		%do %while ( %scan(&si_agg_cols., &i.) ^= %str() );
			%let word = %scan(&si_agg_cols., &i.) ;
			%if &i. eq 1 %then %do;
				%let commasep_aggcols = %str(&word. );
				%let pipesep_aggcols = %str(&word. );
			%end;
			%else %do;
				%let commasep_aggcols = %str(&commasep_aggcols , &word. );
				%let pipesep_aggcols = %str(&pipesep_aggcols || '_' || &word. );
			%end;
			%let i = %eval(&i. + 1);
		%end;
		
	%end;
	
	%put &commasep_aggcols.;
	%put &pipesep_aggcols.;
	

	/* Drop output tables if these exist*/
	%si_conditional_drop_table(si_cond_table_in=&si_out_table.l);
	%si_conditional_drop_table(si_cond_table_in=&si_out_table.w);

	/* Check if the cost variable specified as input exists in the dataset. If yes, construct a variable with 
		an sql statement reference to cost.	Else, leave the variable null*/
	%local out_var_exist sql_cost_statement;
	%si_var_exist(si_table_in=&si_sial_table.,varname=&si_amount_col., si_out_var=out_var_exist);
	%if &out_var_exist. = 0 %then %do;
		%let cost = False;
		%let sql_cost_statement = ;
	%end;
	%else %do;
		%let sql_cost_statement = sum(sial.&si_amount_col.) as cst, ;
	%end;
	/* Check if the entity variable specified as input exists in the dataset. If yes, construct a variable with 
		an sql statement reference to cost.	Else, leave the variable null*/
	%if %TRIM(&entity.) = True %then %do;
		%si_var_exist(si_table_in=&si_sial_table.,varname=entity_id., si_out_var=out_var_exist);
		%if &out_var_exist. = 0 %then %do;
			%let entity = False;
		%end;
		%else %do;
			%let sql_cost_statement = &sql_cost_statement, count(distinct(entity_id)) as ents;
		%end;
	%end;
	

	/* For each value of ref_periods, create the cost, duration and count rolled-up variables for every individual in main table.*/
	proc sql;
		/* Do all aggregation in one go*/
		create table work._temp_summary_tab as			
			select 
				intab.&si_id_col.,
				ref_period,
				&commasep_aggcols. ,
				compress(case when ref_period < 0 then 'P' || put(abs(ref_period), 4.) else 'F' || 
					put(abs(ref_period), 4.) end)  || '_' || &pipesep_aggcols. as vartype,
				&sql_cost_statement.	/* Use the sql statement reference created earlier */
				sum( intck('DTDAYS', start_date, end_date) ) as dur,
				count( distinct event_id ) as cnt,
				sum(case when event_sdate = start_date then 1 else 0 end) as ct2
			from &si_table_in. intab
			inner join &si_sial_table. sial on (intab.&si_id_col. = sial.&si_id_col. and intab.&si_as_at_date. = sial.&si_as_at_date.)
			group by 
				intab.&si_id_col.,
				ref_period,
				&commasep_aggcols. ,
				calculated vartype;
		
	quit;

	/* Do another level of aggregation for the aggregated table, taking out the ref_period also. This gives aggregate variables
		for the whole of profile and forecast windows.*/
	proc sql;

		create table work._temp_summary_tab_l2 as			
			select 
				intab.&si_id_col.,
				intab.&si_as_at_date.,
				&commasep_aggcols. ,
				case when ref_period < 0 then 'P' else 'F' end as ref_window,
				compress(case when ref_period < 0 then 'P' else 'F' end)  || '_' || &pipesep_aggcols. as vartype,
				&sql_cost_statement.	/* Use the sql statement reference created earlier */
				sum( intck('DTDAYS', start_date, end_date) ) as dur,
				count( distinct event_id ) as cnt,
				sum(case when event_sdate = start_date then 1 else 0 end) as ct2,
				min(start_date) as first_sdate format datetime20.,
				max(end_date) as last_edate  format datetime20.
			from &si_table_in. intab
			inner join &si_sial_table. sial on (intab.&si_id_col. = sial.&si_id_col. and intab.&si_as_at_date. = sial.&si_as_at_date.)
			group by 
				intab.&si_id_col.,
				intab.&si_as_at_date.,
				calculated ref_window,
				calculated vartype,
				&commasep_aggcols. ;
		
	quit;
	
	
	/* If the cost variables are required*/
	%if %TRIM(&cost.) = True %then %do;

		proc sql;
			create table work._temp_cst_tab as
				select &si_id_col., compress(vartype || '_CST') as vartype format=$100. length=100 , cst as value from work._temp_summary_tab
				union all 
				select &si_id_col., compress(vartype || '_CST') as vartype format=$100. length=100 , cst as value from work._temp_summary_tab_l2;
		quit;

		%si_perform_unionall(si_table_in=&si_out_table.l, append_table=work._temp_cst_tab); /*Suffix "l" for Long table format*/
 
		
	%end;
	/* If the cost variables are required*/
	%if %TRIM(&entitity.) = True %then %do;

		proc sql;
			create table work._temp_ents_tab as
				select &si_id_col., compress(vartype || '_ENT') as vartype format=$100. length=100 , ents as value from work._temp_summary_tab
				union all 
				select &si_id_col., compress(vartype || '_ENT') as vartype format=$100. length=100 , ents as value from work._temp_summary_tab_l2;
		quit;

		%si_perform_unionall(si_table_in=&si_out_table.l, append_table=work._temp_ents_tab); /*Suffix "l" for Long table format*/
 
		
	%end;

	/* If the duration variables are required*/
	%if &duration. = True %then %do; 

		proc sql;
			create table work._temp_dur_tab as
				select &si_id_col., compress(vartype || '_DUR') as vartype format=$100. length=100 , dur as value from work._temp_summary_tab
				union all 
				select &si_id_col., compress(vartype || '_DUR') as vartype format=$100. length=100 , dur as value from work._temp_summary_tab_l2;
		quit;
		
		%si_perform_unionall(si_table_in=&si_out_table.l, append_table=work._temp_dur_tab);

		
	%end;

	/* If the count variables are required. If an event spans multiple periods, it is counted once in each of those periods*/
	%if &count. = True %then %do; 

		proc sql;
			create table work._temp_cnt_tab as
				select &si_id_col., compress(vartype || '_CNT') as vartype format=$100. length=100 , cnt as value from work._temp_summary_tab
				union all 
				select &si_id_col., compress(vartype || '_CNT') as vartype format=$100. length=100 , cnt as value from work._temp_summary_tab_l2;
		quit;

		%si_perform_unionall(si_table_in=&si_out_table.l, append_table=work._temp_cnt_tab);

		
	%end;

	/* If the counts based on start_date are required*/
	%if &count_startdate. = True %then %do; 

		proc sql;
			create table work._temp_ct2_tab as
				select &si_id_col., compress(vartype || '_CT2') as vartype format=$100. length=100 , ct2 as value from work._temp_summary_tab
				union all
				select &si_id_col., compress(vartype || '_CT2') as vartype format=$100. length=100 , ct2 as value from work._temp_summary_tab_l2;
		quit;

		%si_perform_unionall(si_table_in=&si_out_table.l, append_table=work._temp_ct2_tab);

		
	%end;

	/* If the days_since variables are required- this includes days since last event before as-at date, and days to first event after as-at date*/
	%if &dayssince. = True %then %do; 

		proc sql;
			create table work._temp_dayssince_tab as
				select &si_id_col., compress(vartype || '_DSLE') as vartype format=$100. length=100 , intck('DTDAYS', last_edate, intnx('DTDAYS', &si_as_at_date., -1) )  as value 
				from work._temp_summary_tab_l2
				where ref_window='P'
				union all
				select &si_id_col., compress(vartype || '_DFFE') as vartype format=$100. length=100 , intck('DTDAYS', &si_as_at_date., first_sdate) as value 
				from work._temp_summary_tab_l2
				where ref_window='F';
		quit;

		%si_perform_unionall(si_table_in=&si_out_table.l, append_table=work._temp_dayssince_tab);

		
	%end;


	/* Sort and transpose the long-form dataset based on ID and aggregation columns */
	proc sort data=&si_out_table.l; by &si_id_col. vartype ; run;
	


	/* Do the transpose of the "long" version table if required by input */
	%if &si_rollup_ouput_type. eq Wide or &si_rollup_ouput_type. eq Both %then %do;
		proc transpose data=&si_out_table.l delim=_ out=&si_out_table.w (drop=_NAME_); /*Suffix "w" for Wide table format*/
			  
			by &si_id_col.;
			id vartype;   
			var value;

		run;
	%end;
	%put ---DEBUG Line 1---;
	/* If only wide version is requested, drop the long version of output table*/
	%if &si_rollup_ouput_type. eq Wide %then %do;
		proc sql;
			drop table &si_out_table.l;
		quit;
	%end;
	
	%put ---DEBUG Line2---;
	/* Clean up temp datasets*/
	%if &si_debug. = False %then %do;
		proc datasets lib=work;
			delete _temp_: ;
		run;
	%end;

	%put ------------End Macro: si_create_rollup_vars----------------------;

%mend si_create_rollup_vars;


/*

%si_create_rollup_vars(si_table_in=sand.inp_tester, si_sial_table=work.test2, si_out_table=work.test3, 
	si_agg_cols= %str(department datamart subject_area), cost = True, duration = True, count = True, count_startdate = True, dayssince = True );

*/