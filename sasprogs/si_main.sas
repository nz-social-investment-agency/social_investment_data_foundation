/*********************************************************************************************************
DESCRIPTION: 
	This is the main script that will build the master dataset ready for analysis. It is advised 
	that you run this script step-by-step to understand how this works. Refer to the readme for details on
	what the SI Data Foundation does.

	Before execution, please note the following-

	1. Remember that you need to update the "si_control.sas" file with all your user parameters before you actually start
		running this SAS file. You don't need to execute it; the script will automatically be run from this main
		file.
	2. You also need to have edited the "si_get_cohort.sas" file with the necessary code that creates the population of 
		individuals that you are interested in. Again, you do't need to execute it; it will be automatically run from this
		main file.
	3. If required, you can also edit the "si_get_characteristics_ext.sas" macro in case you want to add your own custom 
		variables to your final dataset, which are not currently available in this data foundation.

	The data foundation creates 3 kinds of variables for every individual in your population dataset, and the "as-at" date 
	column in your population table is the reference date for those variables. The demographic/characteristic variables include 
	things like sex, gender, region/ta/meshblock, age, etc as on the "as-at" date. The rollup variables include things like
	duration spent on benefits, hospitalisation costs, count of events, etc for each period before and after the as-at date. 
	The full list depends on which SIAL tables you choose to roll up. Finally, the indicator/outcome variables include things 
	like highest qualification, disability flag, etc as on the "as-at" date.

	At the end of execution, you will have a population table with all your individuals and their demographics/
	characteristics, one rollup table for each SIAL table that you specified to be rolled up in the 
	"si_control.sas" file, and one table per indicator variable.

INPUT:
	si_control.sas = Specify the parameters which decide how the data foundation works and what variables to create.
	si_source_path = Specify the path where you saved the SI data foundation code.

OUTPUT:
	1. work.control_file = Table with the SI Data Foundation parameters specified by you.
	2. work.xxx_char_ext = A table with all the individuals in your population, along with demographics/characteristics of 
			those individuals as on the date specified by you.
	3. work.XXX_XXXXX_events_rlpl = Several rollup tables in a long format with the variables you specified in the control file.
			There will be one row per person per variable.

		OR

		work.XXX_XXXXX_events_rlpw = Several rollup tables in a long format with the variables you specified in the control file.
			There will be one row per person, with each variable as a column.
	4. work.<indicator variable> =  Several tables, one for each indicator variable.

AUTHOR: E Walsh

DEPENDENCIES:
1. The Data Foundation requires you to have the Social Investment Analytical Layer (SIAL) created on your project schema. 
2. You need to edit the si_control.sas file and add the parameters required to run the data foundation.
3. Edit the si_get_cohort.sas file to identify the individuals that you want to create the variables for, and the date as on
	which these variables will be created for. Every individual can have a different date if required.

NOTES: 

HISTORY: 
25 Aug 2017 VB Added more comments.
28 Apr 2017 EW v1
Apri 2019 PNH: SAS-GRID Updates
*********************************************************************************************************/


/*	This section is for the user of the data foundation to edit and set up the environment variables in the main script.
	Uncomment the below statement for detailed logs for the code execution- Use this when you  are troubleshooting*/
/*options mlogic mprint;*/

/* This is the location where you've stored the data foundation code- including the top level folder name of the data foundation. 
	Ensure you've read the DESCRIPTION and DEPENDENCIES section above before you run the main script!!
*/
%let si_source_path = /nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/social_investment_data_foundation;;



/*********************************************************************************************************/

/* Set up a variable to store the runtime of the script; this helps to plan for future re-runs of code if necessary */
%global si_main_start_time;
%let si_main_start_time = %sysfunc(time());

/* Load all the macros required for the data foundation*/
options obs=MAX mvarsize=max pagesize=132
        append=(sasautos=("&si_source_path./sasautos"));

/* Load the user's parameters and global variables that define how the data foundation works from the control file */
%include "&si_source_path./sasprogs/si_control.sas";
%include "&si_source_path./include/libnames.sas";

/* Generate the population for which the data foundation variables will be created - the output of the below script
	will be a SAS dataset that should contain a column for the IDs of individuals,  and a column for the as-at date (which
	is the date as on which the variables will be calculated).*/
%include "&si_source_path./sasprogs/si_get_cohort.sas";

/* Loads SAS formats required by the data foundation */
%include "&si_source_path./include/si_moe_formats.sas";

/* Push the population cohort table to the database so that the characteristic/demographic variables of the individuals can be obtained,
	using an explicit pass-through which is more efficient.*/
%si_write_to_db(si_write_table_in=&si_pop_table_out.,
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out.
	,si_cluster_index_flag=True,si_index_cols=%bquote(&si_id_col., &si_asat_date.)
	);

/* Generate static variables for individuals in the population, which mainly consist of demographics and IDI linking variables */
%si_get_characteristics(
	si_char_proj_schema=&si_proj_schema., 
	si_char_table_in=&si_pop_table_out., 
	si_as_at_date=&si_asat_date., 
	si_char_table_out=work.&si_pop_table_out._char
	);

/* This macro is a stub for users of the data foundation to add custom variables or perform additional filtering/processing.
   You would have edited this macro if you wanted to customise the dataset. If not, the output of this macro is the same
	as the input dataset. */
%si_get_characteristics_ext(
	si_char_ext_table_in=&si_pop_table_out._char,
	si_char_ext_table_out=&si_pop_table_out._char_ext
);

/* Push to the database so that master characteristics can run an explicit pass through */
%si_write_to_db(
	si_write_table_in=&si_pop_table_out._char_ext, 
	si_write_table_out=&si_sandpit_libname..&si_pop_table_out._char_ext,
	si_cluster_index_flag=True, 
	si_index_cols=%bquote(&si_id_col., &si_asat_date.)
);

/* Now that we have a final population table in the database with characteristics, we drop the first table as it is not 
	required anymore.*/
%si_conditional_drop_table(
si_cond_table_in =&si_sandpit_libname..&si_pop_table_out.
);

/* IMPORTANT NOTE: 
	At this point, you may want to check your schema in IDI_Sandpit to ensure that the population dataset is created there.
	The table will be called &si_pop_table_out._char_ext (where &si_pop_table_out is the name you specified in the si_control file.)
*/


/* Now, we move to stage 2 of the code.
	Here, we roll up the SIAL tables to create a bunch of variables for the individuals in your population dataset. These variables
	will be what you specified in the control file- you can have costs, durations, counts, etc for each period duration as specified 
	in the control file. These variables will be created for each agency datasets you specified in the control file.

	There is potential for some of this code below the line to run in parallel once STATSNZ enables the SASGRID 
*/


/* This macro is a wrapper to roll up each SIAL table to create cost/duration/count variables within the observation horizon for your 
	population table. Also applies inflation adjustments & discounting to costs if specified. The SIAL tables that will be rolled up 
	depends on the configuration in the si_control.sas */
%si_wrapper_sial_rollup(si_wrapper_proj_schema=&si_proj_schema.);



/* Now, we move to stage 3 of the code.
	This section creates the "indicator" variables for the individuals in the population. These would be variables like highest 
	educational qualification for individuals on the as-at date, or mental health services access flag, or other similar indicators,
	which can be quite bespoke or ad-hoc. You can add extra indicator variables in this macro, and you're welcome to contribute your 
	new variables to the dictionary of such variables that we maintain on the Github repository.
*/
%si_get_outcomes_ext;

/* View run-statistics such as names of tables, run-time etc */
/* This will help you understand what the SI data foundation has built, and plan future runs */
%si_summarise_run(si_summ_proj_schema =&si_proj_schema.);



