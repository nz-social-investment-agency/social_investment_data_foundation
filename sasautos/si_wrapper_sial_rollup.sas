/*******************************************************************************************************
TITLE: wrapper_sial_rollup.sas

DESCRIPTION: This is a wrapper script which loops through the SIAL tables to selectively roll up the tables as
specified in the si_setup.sas macro. For each SIAL table, this code runs the si_align_sialevents_to_periods, 
followed by si_apply_discounting and si_create_rollup_vars.inflation adjustment is also done if specified in 
si_setup.sas.

INPUT: 
NA

OUTPUT:
NA

KNOWN ISSUES:
NA

DEPENDENCIES: 
NA

NOTES: 
NA


AUTHOR: 
V Benny

DATE: 15 May 2017

HISTORY: 
15 May 2017 VB v1
*******************************************************************************************************/

%macro si_wrapper_sial_rollup();

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_wrapper_sial_rollup----------------------;
	%put ............si_macro_start_time: %sysfunc(datetime(), datetime20.);

	%local cost_loop_list counter viewname outmacrovar;
	%let cost_loop_list = ; 	/* Stores list of SIAL tables with cost column*/
	%let nocost_loop_list = ; 	/* Stores list of SIAL tables with no cost column, to do just the rollups with counts & durations */
	
	/* Enable rollup for MOE SIAL Tables & Views */
	%if &si_use_moe. eq True %then %do;
		
		/* Fetch list of SIAL MOE tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moe, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar. ;

		/* Fetch list of SIAL MOE tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moe, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for MOH SIAL Tables & Views */
	%if &si_use_moh. eq True %then %do;
	
		/* Fetch list of SIAL MOH tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moh, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;
	
		/* Fetch list of SIAL MOH tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moh, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for MSD SIAL Tables & Views */
	%if &si_use_msd. eq True %then %do;
		
		/* Fetch list of SIAL MSD tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = msd, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;

		/* Fetch list of SIAL MSD tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = msd, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for MOJ SIAL Tables & Views */
	%if &si_use_moj. eq True %then %do;
		
		/* Fetch list of SIAL MOJ tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moj, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;

		/* Fetch list of SIAL MOJ tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = moj, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for Corrections SIAL Tables & Views */
	%if &si_use_cor. eq True %then %do;
		
		/* Fetch list of SIAL COR tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = cor, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;

		/* Fetch list of SIAL COR tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = cor, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for ACC SIAL Tables & Views */
	%if &si_use_acc. eq True %then %do;
	
		/* Fetch list of SIAL ACC tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = acc, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;

		/* Fetch list of SIAL ACC tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = acc, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for IRD SIAL Tables & Views */
	%if &si_use_ird. eq True %then %do;

		/* Fetch list of SIAL IRD tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = ird, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;

		/* Fetch list of SIAL IRD tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = ird, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for Police SIAL Tables & Views */
	%if &si_use_pol. eq True %then %do;
		
		/* Fetch list of SIAL Police tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = pol, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;
		
		/* Fetch list of SIAL Police tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = pol, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for Police SIAL Tables & Views */
	%if &si_use_hnz. eq True %then %do;
		
		/* Fetch list of SIAL Police tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = hnz, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;
		
		/* Fetch list of SIAL Police tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = hnz, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;

	/* Enable rollup for Police SIAL Tables & Views */
	%if &si_use_mix. eq True %then %do;
		
		/* Fetch list of SIAL Police tables with costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = mix, 
			si_fetch_tab_with_column = True, si_column_name = cost, si_out_var = outmacrovar);
		%let cost_loop_list = &cost_loop_list. &outmacrovar.;
		
		/* Fetch list of SIAL Police tables without costs*/
		%si_fetch_sial_datasets_by_agency(si_schema_name = DL-MAA2016-15, si_agency_tag = mix, 
			si_fetch_tab_with_column = False, si_column_name = cost, si_out_var = outmacrovar);
		%let nocost_loop_list = &nocost_loop_list. &outmacrovar. ;

	%end;
	
	/* Loop through SIAL table list with costs and create inflation/discounting-adjusted & period-level rolled up variables*/
	%let counter=1;
	%do %while (%scan (&cost_loop_list., &counter.) ne );
		%let viewname = %scan (&cost_loop_list., &counter.);
		
		/* Create the events subsetted and broken to fit to the specified profile & forecast windows with inflation adjusted costs*/
		%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out._char_ext,	/* Output table from get_characteristics_ext */
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].&viewname. , 				/* The SIAL table in the current loop iteration */						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = &si_amount_type. , 
			si_amount_col = &si_sial_amount_col. , 
			noofperiodsbefore = &si_num_periods_before. , 
			noofperiodsafter = &si_num_periods_after. , 
			period_duration = &si_period_duration. , 
			si_out_table = %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) ),	/* Example: SIAL_MOE_tertiary_events become MOE_tertiary_events_aln */
			period_aligned_to_calendar = False, 
			si_pi_type = &si_price_index_type. , 
			si_pi_qtr = &si_price_index_qtr. );
		
		/* If the inflation adjustment was not specified, the output amount column name will be different. Hence we need to rename the output amount column */
		%if &si_price_index_type. ne NA %then %do;
			data %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) ) 
				(rename=(&si_sial_amount_col._&si_price_index_type._&si_price_index_qtr.=&si_sial_amount_col.));
				set %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) );
			run;
		%end;

		/* Adjust costs to take into account the fact that receiving earlier is preferable to receieving money later, if required */
		%if &si_discount. eq True %then %do;
			%si_apply_discounting(
				si_table_in = %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) ) ,		/* Example: MOE_tertiary_events_aln */
				si_id_col = &si_id_col.  , 
				si_amount_col = &si_sial_amount_col. , 
				si_amount_type = &si_amount_type. , 
				si_as_at_date = &si_asat_date. ,
				si_disc_rate = &si_discount_rate. , 
				si_out_table = %substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) )	/* Example: MOE_tertiary_events_disc */
			);	
			
			/* Since the amount column name after discounting is different, we rename it to have retain the original name. */
			data %substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) ) 
				(rename=( &si_sial_amount_col._disc&si_discount_rate.=&si_sial_amount_col.));
				set %substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) ) ;
			run;
		%end;

		/* If discounting step was skipped, the dataset will be the output of si_align_sialevents_to_periods macro. Rename this to the output table name
			from discounting step to maintain input dataset naming consistency in the next step.*/
		%else %do;

			data %substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) ); 
				set %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) );
			run;

		%end;

		/* Create the roll-up variables */
		%si_create_rollup_vars(
			si_table_in = sand.&si_pop_table_out._char_ext , 
			si_sial_table = %substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) ),	/* Example: MOE_tertiary_events_disc */
			si_out_table = %substr(&viewname._rlp, 6, %eval(%length(&viewname._rlp) - 5) ),		/* Example: MOE_tertiary_events_rlp */	
			si_agg_cols= %str(department datamart subject_area),	/* At the moment, this is hard coded to be at subject area level for all tables*/
			si_id_col = &si_id_col. ,
			si_as_at_date = &si_asat_date. ,
			si_amount_col = &si_sial_amount_col. ,
			cost = True, 
			duration = True, 
			count = True, 
			count_startdate = True, 
			dayssince = True,
			si_rollup_ouput_type = &si_rollup_output_type.
		);

		/* Clean up intermediate datasets*/
		%if %sysfunc(trim(&si_debug.)) = False %then %do;

			proc datasets lib=work;
				delete %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) )  
					%substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) );
			run;

		%end;
		
		/* Increment loop counter*/
		%let counter = %eval( &counter. + 1);

	%end;



	/* Loop through SIAL table list without costs and create inflation/discounting-adjusted & period-level rolled up variables*/
	%let counter=1;
	%do %while (%scan (&nocost_loop_list., &counter.) ne );
		%let viewname = %scan (&nocost_loop_list., &counter.);
		
		/* Create the events subsetted and broken to fit to the specified profile & forecast windows with inflation adjusted costs*/
		%si_align_sialevents_to_periods(
			si_table_in=[IDI_Sandpit].[&si_proj_schema.].&si_pop_table_out._char_ext,	/* Output table from get_characteristics_ext */
			si_sial_table=[IDI_Sandpit].[&si_proj_schema.].&viewname. , 				/* The SIAL table in the current loop iteration */						
			si_id_col = &si_id_col. , 
			si_as_at_date = &si_asat_date. ,
			si_amount_type = NA,  
			noofperiodsbefore = &si_num_periods_before. , 
			noofperiodsafter = &si_num_periods_after. , 
			period_duration = &si_period_duration. , 
			si_out_table = %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) ),	/* Example: SIAL_MOE_tertiary_events become MOE_tertiary_events_aln */
			period_aligned_to_calendar = False );		


		/* Create the roll-up variables */
		%si_create_rollup_vars(
			si_table_in = sand.&si_pop_table_out._char_ext , 
			si_sial_table = %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) ),	/* Example: MOE_tertiary_events_aln */
			si_out_table = %substr(&viewname._rlp, 6, %eval(%length(&viewname._rlp) - 5) ),		/* Example: MOE_tertiary_events_rlp */	
			si_agg_cols= %str(department datamart subject_area),	/* At the moment, this is hard coded to be at subject area level for all tables*/
			si_id_col = &si_id_col. ,
			si_amount_col = NA,
			si_as_at_date = &si_asat_date. ,
			cost = False, 
			duration = True, 
			count = True, 
			count_startdate = True, 
			dayssince = True,
			si_rollup_ouput_type = &si_rollup_output_type.
		);

		/* Clean up intermediate datasets*/
		%if %sysfunc(trim(&si_debug.)) = False %then %do;

			proc datasets lib=work;
				delete %substr(&viewname._aln, 6, %eval(%length(&viewname._aln) - 5) )  
					%substr(&viewname._disc, 6, %eval(%length(&viewname._disc) - 5) );
			run;

		%end;
		
		/* Increment loop counter*/
		%let counter = %eval( &counter. + 1);

	%end;
	
	%put ------------Macro End: si_wrapper_sial_rollup----------------------;

%mend si_wrapper_sial_rollup;