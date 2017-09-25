/*******************************************************************************************************
TITLE: si_subset_idi_dataset.sas

DESCRIPTION: 
	sidid_infile: sial dataset containing the idi subsetting variable [sidid_id_var] if left
	             null then the macro will extract the whole dataset
	sidid_id_var: sial identification column/idi subsetting variable in the idi source table [sidid_ididataset]
	             eg sidid_id_var = snz_uid 
	sidid_ason_var: sail profile ending date/any date column we interested in
	sidid_idiextdt: idi dataset version (eg 20161020)
	sidid_ididataset: idi dataset on the sql server to be subsetted by the macro.
	sidid_ididataset_com_var: idi dataset completion date on the sql server
	sidioutfile: output dataset.
	sidisandpit:if the table is in the sql idi sandpit area then set this value to y	


Sample call:
provide the required parameters to the macro call and excute it:
%si_subset_idi_dataset ( sidid_infile = &si_table_in
										,sidid_id_var = &si_id_col
										,sidid_ason_var = &si_as_at_date
										,sidid_idiextdt = &si_idi_refresh_date
										,sidid_ididataset = moe_clean.student_qualification
										,sidid_ididataset_com_var = moe_sql_attained_year_nbr
										,sidioutfile = moe_schqual1
						);


OUTPUT:
sidioutfile: output dataset.

Author:
Nafees Anwar   (SIA)	


DATE: 12 May 2017

DEPENDENCIES:
	these macros are prerequisites to si_get_highest_qualifications 
	macro: dataset_to_format_macros.sas (on idi code sharing library) %si_frmt_data_tight(dataset_to_format_macros.sas)

	access to:
	clean_read_classifications.moe_school_profile
	[idi_clean].[moe_clean].student_enrol
	[idi_clean].[moe_clean].enrolment
	[idi_clean].[moe_clean].course
	[idi_clean].[moe_clean].tec_it_learner
	[idi_clean].[moe_clean].targeted_training
	idi_sandpit (clean_read_moe).moe_provider_lookup_table
	idi_sandpit (clean_read_moe).moe_nzsced_code
	idi_sandpit (clean_read_moe).moe_ito_programme_lookup_table


KNOWN ISSUES:
NA

HISTORY:
15 May 2017 NA v1
************************************************************************************/;

%macro si_subset_idi_dataset (sidid_infile =
			,sidid_id_var =
			,sidid_ason_var =
			,sidid_idiextdt = 
			,sidid_ididataset =
			,sidid_ididataset_com_var = 
			,sidioutfile =
			,sidid_targetschema=
			,sidisandpit =
			);
	
	********************************************************************************;
	** identify whether the dataset needs to be subsetted **;
	data sidi_temp1;
		if lengthn(strip("&sidid_infile.")) gt 0 then
			call symputx("sidisubset",1);
		else  call symputx("sidisubset",0);
	run;

	%put subset idi dataset (yes:1): &sidisubset.;

	********************************************************************************;

	** identify whether the dataset needs to be come from the sandpit 
	 or from current idi dataset (idi_clean)
	**;
	data sidi_temp2;
		if strip("&sidisandpit.") = "y" then
			call symputx("databasecall", "idi_sandpit");

		if lengthn(strip("&sidid_idiextdt")) = 0 then
			call symputx("databasecall", "idi_clean");
		else call symputx("databasecall", "idi_clean_&sidid_idiextdt.");
	run;

	%put database called: &databasecall;

	********************************************************************************;
	********************************************************************************;
	proc datasets lib = work nolist;
		delete &sidioutfile;
	run;

	** run extract with subsetting **;
	** extract ids from idi tables in sandpit area using pass through *;
	proc sql;
		connect to sqlservr (server = snz-idiresearch-prd-sql\ileed
			database = &databasecall.);
		create table sidi_temp5 as
			select a.*
				from connection to sqlservr (select t1.* from &sidid_ididataset. t1
					inner join [idi_sandpit].[&sidid_targetschema].&sidid_infile. t2 
						on t1.snz_uid = t2.&sidid_id_var
					where cast(left(cast(t1.&sidid_ididataset_com_var. as varchar(8)),4) as int) <= year(t2.&sidid_ason_var.)
						) as a;
		disconnect from sqlservr;
	quit;

	proc append base = &sidioutfile. data = sidi_temp5;
		** extract the whole dataset *;
		%if &sidisubset. = 0 %then
			%do;
				** loop 1 *;
	proc sql;
		connect to sqlservr (server = snz-idiresearch-prd-sql\ileed
			database = &databasecall.
			);
		create table &sidioutfile. as
			select a.*
				from connection to sqlservr (select * from &sidid_ididataset
					) as a;
		disconnect from sqlservr;
	quit;

			%end;

		* end loop 1 *;
		proc datasets lib = work nolist;
			delete sidi_temp:;
		run;

%mend si_subset_idi_dataset;

