/*********************************************************************************************************
TITLE: si_main_example_pd.sas

DESCRIPTION: main script to build the master dataset
This main script is an example specifically designed to run all the scripts in the examples/ folder
When you go to build your own data foundation you will use the sasprogs/si_main.sas script

INPUT:
si_control_example_pd.sas = builds dataset with list of parameters
si_source_path = full path to the folder location

OUTPUT:
work.control_file = table used to build the global macro variables
work.xxx = population table with name specified by user
work.xxx_char = characteristics table - name is the population table name with a _char suffix
work.xxx_char_ext = characteristics extension table - name is the population table name with 
a _char_ext suffix
work.XXX_XXXXX_events_rlpl = several rollup tables in a long format
or
work.XXX_XXXXX_events_rlpw = several rollup tables in a wide format

AUTHOR: E Walsh

DATE: 28 Apr 2017

DEPENDENCIES:
macros are all located in the sasautos folder 

NOTES: 
wide tables are preferred but in some cases column names may exceed 32 characters hence a long format
has also been made available

HISTORY: 
28 Apr 2017 EW v1
*********************************************************************************************************/

/*options mlogic mprint;*/
/* user specified input  in the main script */
/* location where the folders are stored */
%let si_source_path = \\wprdfs08\MAA2016-15 Supporting the Social Investment Unit\social_investment_data_foundation;

/*********************************************************************************************************/
/* time the run to help plan for future re-runs if necessary */
%global si_main_start_time;
%let si_main_start_time = %sysfunc(time());

/* load all the macros */
options obs=MAX mvarsize=max pagesize=132
	append=(sasautos=("&si_source_path.\sasautos"));

/* specify global variables that are used by more than one macro */
%include "&si_source_path.\examples\si_control_example_pd.sas";

/* generate a population - the output should contain a column for the ids and a column for the as at date */
%include "&si_source_path.\examples\si_get_cohort_example_pd.sas";

/* formats required by some macros */
%include "&si_source_path.\include\si_moe_formats.sas";

/* push to the database so that master characteristics can run an explicit pass through */
%si_write_to_db(si_write_table_in=&si_pop_table_out.,
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out.
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col., &si_asat_date.)
	);

/* generate static variables tied mainly to demographics and identification */
%si_get_characteristics(
	si_char_proj_schema=&si_proj_schema., 
	si_char_table_in=&si_pop_table_out., 
	si_as_at_date=&si_asat_date., 
	si_char_table_out=work.&si_pop_table_out._char
	);

/* stub for people to restrict records that are linked to a spine etc and the opportunity to add more columns */
/* if you want a characteristic that is not currently generated */
%si_get_characteristics_ext(
	si_char_ext_table_in=&si_pop_table_out._char,
	si_char_ext_table_out=&si_pop_table_out._char_ext
	);

/* push to the database so that master characteristics can run an explicit pass through */
%si_write_to_db(
	si_write_table_in=&si_pop_table_out._char_ext, 
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out._char_ext,
	si_cluster_index_flag=True, 
	si_index_cols=%bquote(&si_id_col., &si_asat_date.)
	);

/* now that we have a final pop table in the database with characteristics we can drop the earlier one */
%si_conditional_drop_table(
	si_cond_table_in =&si_sandpit_libname..&si_pop_table_out.
	);

/* there is potential for some of this code below the line to run in parallel once the grid is up and running */
/* obtain the SIAL related events and costs within the observation horizon for the population table */
/* apply inflation adjustments to costs if required. The SIAL tables that will be rolled up depends on */
/* the configuration in the si_control.sas */
%si_wrapper_sial_rollup(si_wrapper_proj_schema=&si_proj_schema.);

/* this section calls all the outcome variables - users can add extra macro calls in here for their own */
/* customised outcome variables */
%si_get_outcomes_ext;


/* view run statistics such as names of tables, run time etc */
/* this will help users understand what the SI data foundation has built */
/* still a work in progress */
%si_summarise_run(si_summ_proj_schema =&si_proj_schema.);