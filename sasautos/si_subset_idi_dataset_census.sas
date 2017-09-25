/*******************************************************************************************************
TITLE: si_subset_idi_dataset_census.sas

DESCRIPTION: 
This macro will get all the qualification from the census 2013 if not avialable from MoE datasets:

	sidid_infile: sial dataset containing the idi subsetting variable [sidid_id_var] if left
	             null then the macro will extract the whole dataset
	sidid_id_var: sial identification column/idi subsetting variable in the idi source table [sidid_ididataset]
	             eg sidid_id_var = snz_uid 
	sidid_ason_var: sial dataset containing the age var 
	sidid_idiextdt: idi dataset version (eg 20161020) if left empty recent refresh would be considered.
	sidid_ididataset: idi clean census individual macro
	sidioutfile: output dataset.


Sample call:
provide the required parameters to the macro call and excute it:
%si_subset_idi_dataset_census( sidid_infile = &si_table_in
								,sidid_id_var = &si_id_col
								,sidid_ason_var = as_at_age
								,sidid_idiextdt = &si_idi_refresh_date
								,sidid_ididataset = idi_clean.cen_clean.census_individual
								,sidioutfile = census_qual
								);


OUTPUT:
sidioutfile: output dataset.

Author:
Nafees Anwar   (SIA)	


DATE: 12 May 2017

DEPENDENCIES:
	these macros are prerequisites to si_get_highest_qualifications 
	si_MoE formats sas codes

	access to:
	idi_clean.cen_clean.census_individual
	

KNOWN ISSUES:
NA

HISTORY:
15 May 2017 NA v1
************************************************************************************/;


%macro si_subset_idi_dataset_census (sidid_infile =
			,sidid_id_var =
			,sidid_ason_var =
			,sidid_idiextdt = 
			,sidid_ididataset =
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
				from connection to sqlservr (select t1.snz_uid,
					cen_ind_sndry_scl_qual_code,
					cen_ind_post_scl_level_code,
					cen_ind_std_highest_qual_code 
				from &sidid_ididataset. t1
					inner join [idi_sandpit].[&sidid_targetschema].&sidid_infile. t2 
						on t1.snz_uid = t2.&sidid_id_var
					where  t2.&sidid_ason_var. >= 18 
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

%mend si_subset_idi_dataset_census;