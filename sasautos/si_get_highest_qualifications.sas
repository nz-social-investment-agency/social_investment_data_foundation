/*******************************************************************************************************
TITLE: si_get_highest_qualifications.sas

DESCRIPTION: 
code stages
	1, extract school qualifications
	2, tertiary qualifications 
	3, work based training qualifications
	4, moe targeted training  tops ffto gateways qualifications
	5, get qualification from census if not available in above steps and individual is 18 year old or more
	6, combine education qualifications	



INPUT:
	si_table_in: infile containing the snz_uids to extract. if null it will extract all records

	si_id_col = sial identification column/idi subsetting variable in the idi source table [si_id_idi_dataset]
	            This column should be present in both si_table_in and si_sial_table,	eg si_id_col = snz_uid

	si_as_at_date = sial profile ending date/date column we  are interested in to find highest qualification

	si_idi_refresh_date: idi extract date, leave null for the current extract
    
	si_target_schema: This is your schema on the SQL server (eg DL-MAA2016-XX)

	si_out_table: output dataset with qualifcations gained ;



Sample call:
provide the required parameters to the macro call and excute it:
%si_get_highest_qualification( si_table_in = [sail table containing the snz_uids to extract. if null it will extract all records]
								,si_id_col = sial identification column/idi subsetting variable in the idi source table [sidid_ididataset], eg si_id_col = snz_uid 
								,si_as_at_date = sail profile ending date/any date column we  are interested in to find highest qualification
								,si_idi_refresh_date = [idi refresh date, leave null for the current refresh](eg 20161020)
								,si_target_schema= This is your schema on the SQL server (eg DL-MAA2016-XX)
								,si_out_table = [output dataset with qualifcations gained]
								);


OUTPUT:
si_out_table :output dataset with qualifications gained ;

Contributor:
Marc de Boer's (MSD) 
Sarah Tumen's  (Treasury)
Nafees Anwar   (SIA)	


DATE: 12 May 2017

DEPENDENCIES:
	these macros are prerequisites to this code & will be submitted as part of this code
	macro: subset an sql idi table into a sas dataset macro.sas (on idi code sharing library); %subset_ididataset (subset an idi source table)
	macro: dataset_to_format_macros.sas (on idi code sharing library) %frmtdatatight(dataset_to_format_macros.sas)

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
Arbitrary age selection for the qualification to be extracted from census 2013. Hard coded Age (18 years) 

HISTORY:
 7 Nov 2017 NA v3 Changes in tables names for house keeping and can be wrote to IDI sanddpit area 
17 Oct 2017 NA v2 Change in variables names for moe_provider_lookup_table and moe_nzsced_code table
15 May 2017 NA v1
May 2019 PNH SAS Grid changes.
June 2019 PNH: the format qualtif_qualcode returns string values, so changed qualificationcode to be a string variable to avoid warnings

************************************************************************************/;
%MACRO si_get_highest_qualifications( si_table_in =
                                  ,si_id_col = 
    							  ,si_as_at_date =  
 								  ,si_IDI_refresh_date =
								  ,si_target_schema=
                                  ,si_out_table =
                                  ) ;

%put Macro: si_get_highest_qualifications;
%put si_table_in = &si_table_in;
%put si_id_col = &si_id_col;
%put si_as_at_date = &si_as_at_date;
%put si_IDI_refresh_date=&si_IDI_refresh_date;
%put si_target_schema=&si_target_schema;
%put si_out_table = &si_out_table;

/*	 parameters ;*/
/*	 variables to include in outputs ;*/
	%let qualvars =snz_uid
		snz_moe_uid
		attainedsd
		qualtype
		qualification
		qualfield 
		nqflevel;

	**define lib names **;
	libname sandmoe odbc dsn=idi_sandpit_srvprd schema="clean_read_moe";

	** load look up tables from sandpit **;
	data moe_provider_lookup_table;
		set  sandmoe.moe_provider_lookup_table;
	run;

	data moe_nzsced_code;
		set  sandmoe.moe_nzsced_code;
	run;

	data moe_ito_programme_lookup_table;
		set sandmoe.moe_ito_programme_lookup_table;
	run;

	** moe qualifications look up **;
	/* SAS-GRID April 2019 - changes to connect string*/

	proc sql;
		connect to odbc(dsn=&si_idi_dsnname.);
/*			connect to sqlservr (server = snz-idiresearch-prd-sql\ileed*/
/*			database = idi_metadata*/
/*			);*/
/*		*/
		create table moe_qual_lookup as
			select a.*
				from connection to odbc (select * from [IDI_metadata].clean_read_classifications.moe_qualification_lookup
					) as a;
		disconnect from odbc;
	quit;

	* formats *;
	
	%si_frmt_data_tight(fcminfile = moe_provider_lookup_table (where = (provider_code ne .) ) 
		,fcmfmtnm = provider_name
		,fcmstart = provider_code
		,fcmlabel = Provider_type
		);
/*	%si_frmt_data_tight(fcminfile = moe_provider_lookup_table (where = (provider_code ne .) ) */
/*		,fcmfmtnm = prvdcode_inst*/
/*		,fcmstart = provider_code*/
/*		,fcmlabel = subsector*/
/*		);*/
	%si_frmt_data_tight(fcminfile = moe_ito_programme_lookup_table(where = (ito_prg_code ne .) ) 
		,fcmfmtnm = itocode_name
		,fcmstart = ito_prg_code
		,fcmlabel = programmename
		);
	%si_frmt_data_tight(fcminfile = moe_qual_lookup (where = (qualificationtableid ne .) ) 
		,fcmfmtnm = qualtid_nqflvl
		,fcmstart = qualificationtableid
		,fcmlabel = nqflevel
		);

	
	%si_frmt_data_tight(fcminfile = moe_qual_lookup (where = (qualificationtableid ne .) ) 
		,fcmfmtnm = qualtid_qualtyp
		,fcmstart = qualificationtableid
		,fcmlabel = qualificationtype
		);
	%si_frmt_data_tight(fcminfile = moe_qual_lookup (where = (qualificationtableid ne .) ) 
		,fcmfmtnm = qualtid_qualcde
		,fcmstart = qualificationtableid
		,fcmlabel = qualificationcode
		);

	** moe_nzsced_code **;

	%si_frmt_data_tight(fcminfile = moe_nzsced_code (where = (MOE_NZSCEDq_code ne "") ) 
		,fcmfmtnm =  $nzscedcode_desc
		,fcmstart = MOE_NZSCEDq_code
		,fcmlabel = label
		);
/*	%si_frmt_data_tight(fcminfile = moe_nzsced_code (where = (nzscedcode ne "") ) */
/*		,fcmfmtnm =  $nzscedcode_desc*/
/*		,fcmstart = nzscedcode*/
/*		,fcmlabel = label*/
/*		);*/

	************************************************************************************;
	** 1 school qualifications  **;
	** 1.1 subset moe school qualifcations table to ids of interest *;
	%si_subset_idi_dataset ( sidid_infile = &si_table_in
										,sidid_id_var = &si_id_col
										,sidid_targetschema=&si_target_schema
										,sidid_ason_var = &si_as_at_date
										,sidid_idiextdt = &si_idi_refresh_date
										,sidid_ididataset = moe_clean.student_qualification
										,sidid_ididataset_com_var = moe_sql_attained_year_nbr
										,sidioutfile = moe_schqual1
						);

	** 1.2 tidy and prep school qualification dataset *;
	data moe_schqual2 (keep = &qualvars.);
		format snz_uid nqflevel attainedsd;
		set moe_schqual1 (keep = snz_uid snz_moe_uid moe_sql_qual_code
			moe_sql_exam_result_code
			moe_sql_attained_year_nbr
			moe_sql_endorsed_year_nbr
			moe_sql_nzqa_load_date);

		** create date variables *;
		length attainedsd attaineded endorseddate nzqa_loaddate 8.;
		format attainedsd
			attaineded
			endorseddate 
			nzqa_loaddate ddmmyy10.;
		/* May 2019: SAS-GRID changes moe_sql_nzqa_load_date now comes through as SAS date*/
		nzqa_loaddate = moe_sql_nzqa_load_date;
/*		nzqa_loaddate = input(compress(moe_sql_nzqa_load_date,"-"),yymmdd10.);*/

		attainedsd = min(nzqa_loaddate, mdy(12,31,moe_sql_attained_year_nbr));
		endorseddate = min(nzqa_loaddate, mdy(12,31,moe_sql_endorsed_year_nbr));
		attaineded = "01dec9999"d;

		** nql levels from qual table id *;
		length nqflevel 8.;

		if moe_sql_qual_code < 45501 then
			nqflevel = put(moe_sql_qual_code, qualtid_nqflvl.);
		else nqflevel = '';
		department = 'moe';
		datamart = 'school';
		subject_area = 'qualification';

		** qualification type id *;
		*length qualificationtype 8.;
		qualificationtype = put(moe_sql_qual_code, qualtid_qualtyp.);

		** qualification code *;
		/* PNH: the format qualtif_qualcode returns string values, so changed qualificationcode to be a string variable to avoid warnings*/
		/* Note: also changed checks on qualificationcode below*/
		length qualificationcode $8.;
		qualificationcode = put(moe_sql_qual_code, qualtid_qualcde.);

		** determine if the ncea is counted *;
		length countstoncea $3.;
		countstoncea = "no";
		;
		** count if attainment is within two years of nzqa load year *;
		if    moe_sql_attained_year_nbr=year(nzqa_loaddate) 
			or year(nzqa_loaddate)-moe_sql_attained_year_nbr<=2 
			or year(nzqa_loaddate)=. then
			countstoncea = "yes";

		** exclude nqf level 0 *;
		if nqflevel in (0,.) then
			countstoncea = "no";
		;
		** exclude any before 2003 *;
		if moe_sql_attained_year_nbr < 2003 then
			countstoncea = "no";

		** ncea buisness rule **;
		** based on the logic in "02_education_indicators" by sarah tumen (a&i, nz treasury)*;
		** define ncea achievements *;
		if nqflevel >= 4 then
			do;
				ha=42;

				if qualificationtype=21 then
					ha=41;

				if qualificationtype=10 then
					ha=40;
			end;

		if nqflevel = 3 then
			do;
				ha=35;

				if qualificationcode= "1039" then
					do;
						if moe_sql_exam_result_code='E' then
							ha=39;

						if moe_sql_exam_result_code='M' then
							ha=38;

						if moe_sql_exam_result_code='ZZ' then
							ha=37;

						if moe_sql_exam_result_code='N' then
							ha=36;
					end;
			end;

		if nqflevel = 2 then
			do;
				ha=25;

				if qualificationcode= "0973" then
					do;
						if moe_sql_exam_result_code='E' then
							ha=29;

						if moe_sql_exam_result_code='M' then
							ha=28;

						if moe_sql_exam_result_code='ZZ' then
							ha=27;

						if moe_sql_exam_result_code='N' then
							ha=26;
					end;
			end;

		if nqflevel = 1 then
			do;
				ha=15;

				if qualificationcode= "0928" then
					do;
						if moe_sql_exam_result_code='E' then
							ha=19;

						if moe_sql_exam_result_code='M' then
							ha=18;

						if moe_sql_exam_result_code='ZZ' then
							ha=17;

						if moe_sql_exam_result_code='N' then
							ha=16;
					end;
			end;

		if countstoncea = "yes" then
			qualification = put(ha, nceaqual.);
		else qualification = "not applicable";
		qualtype = "school";
		qualfield = "";

		if countstoncea = "yes" then
			output;
	run;

/*	*************************************************************************************/
/*	** 2 tertiary qualifications  ***/
/*	** 2.1 subset moe tertiary qualifcations table to ids of interest **/
	%si_subset_idi_dataset( sidid_infile = &si_table_in
						,sidid_id_var = &si_id_col
						,sidid_targetschema=&si_target_schema
						,sidid_ason_var = &si_as_at_date
						,sidid_idiextdt = &si_idi_refresh_date
						,sidid_ididataset = moe_clean.completion
						,sidid_ididataset_com_var = moe_com_year_nbr
						,sidioutfile = moe_terqual1
						);

	
/*** 2.2 tidy and prep dataset for output **/
	data moe_terqual2 (keep = &qualvars.);
		format snz_uid;
		set moe_terqual1 (keep = snz_uid
			snz_moe_uid
			moe_com_year_nbr
			moe_com_qacc_code
			moe_com_qual_level_code
			moe_com_qual_nzsced_code 
			);
		qualtype = "tertiary";

		** qualifcation start and end dates **;
		length attainedsd
			attaineded 8.;
		format attainedsd
			attaineded ddmmyy10.;
		attainedsd = mdy(12,31,moe_com_year_nbr);
		attaineded = "01dec9999"d;
		department = 'moe';
		datamart = 'tertiary';
		subject_area = 'enrolment';

		** format qualification codes *;
		length qacccode 
			qaccnqflevel
			comnqflevel 8.;
		comnqflevel= moe_com_qual_level_code;
		drop moe_com_qual_level_code;
		qacccode = moe_com_qacc_code;
		drop moe_com_qacc_code;
		qaccnqflevel = put(qacccode ,lv8id.);
		qualification = put(qacccode ,qacccode.);
		qualfield = put(moe_com_qual_nzsced_code ,$nzscedcode_desc.);
		drop moe_com_qual_nzsced_code;

		* there are some levels missing ( not many) and some levels seems to be too high;
		* giving priority to qual type classification by moe and overwriting level variable;
		* logic in 02_edu_integrated_qual though most of the problem stems from lv8id format *;
		* level 1-3 tertiary certificates;
		if      qaccnqflevel=1 and (comnqflevel=. or comnqflevel=1) then
			nqflevel=1;

		* few missing set to level 1;
		if qaccnqflevel=1 and comnqflevel=2 then
			nqflevel=2;

		if qaccnqflevel=1 and comnqflevel>=3 then
			nqflevel=3;

		* some have level 4,5 and 10... setting them to level 3;
		* level 4 tertiary certificates;
		if qaccnqflevel=2 and (comnqflevel=. or comnqflevel<=4) then
			nqflevel=4;

		if qaccnqflevel=2 and comnqflevel>4 then
			nqflevel=4;

		* tertiary diplomas;
		if qaccnqflevel=3 and (comnqflevel=. or comnqflevel<=5) then
			nqflevel=5;

		if qaccnqflevel=3 and comnqflevel>=6 then
			nqflevel=6;

		* bachelor degrees;
		if qaccnqflevel=4 and (comnqflevel=. or comnqflevel<=7) then
			nqflevel=7;

		* postgraduate degrees;
		if qaccnqflevel=6 then
			nqflevel=8;

		* masters and phds;
		if qaccnqflevel=7 then
			nqflevel=9;

		if qaccnqflevel=8 then
			nqflevel=10;
		drop comnqflevel qaccnqflevel qacccode;
	run;

	************************************************************************************;
	** 3 industry training organisation qualifications  **;
	** 3.0 qual variables do not end in a numeric *;
	%let itoqual = moe_itl_level1_qual_awarded_nbr
		moe_itl_level2_qual_awarded_nbr
		moe_itl_level3_qual_awarded_nbr
		moe_itl_level4_qual_awarded_nbr
		moe_itl_level5_qual_awarded_nbr
		moe_itl_level6_qual_awarded_nbr
		moe_itl_level7_qual_awarded_nbr
		moe_itl_level8_qual_awarded_nbr
	;

/*** 3.1 subset moe industry training organisation table to ids of interest **/
	%si_subset_idi_dataset( sidid_infile = &si_table_in
		,sidid_id_var = &si_id_col
		,sidid_targetschema=&si_target_schema
		,sidid_ason_var = &si_as_at_date
		,sidid_idiextdt = &si_idi_refresh_date
		,sidid_ididataset = moe_clean.tec_it_learner
		,sidid_ididataset_com_var = moe_itl_end_date
		,sidioutfile = moe_itoqual1
		);

/*** 3.2 qualifcation type code **/
	proc format;
		value $itoqual 
			"lcp" = "limited credit programme"
			"nc"  = "national certificate, national diploma"
			"tc"  = "trade certificate"
			"scp" =  "scp"
		;
	run;

/*** 3.3 format and output results **/
	data moe_itoqual2 (keep = &qualvars.
		where = (nqflevel ne 0) 
		);
		set moe_itoqual1 (keep = snz_uid
			snz_moe_uid
			moe_itl_start_date
			moe_itl_end_date
			moe_itl_pms_course_nbr
			moe_itl_itr_course_nbr
			moe_itl_duration_months_nbr
			moe_itl_programme_type_code
			&itoqual.
			);

		** event end can be null impute from course duration *;
		format moe_event_sd 
			attainedsd
			attaineded 
			event_ed_dur 8.;
		format moe_event_sd 
			attainedsd 
			attaineded
			event_ed_dur ddmmyy10.;
		department = 'moe';
		datamart = 'work based';
		subject_area = 'training';
/* May 2019: SAS-GRID changes: dates now coming through as SAS dates*/
/*		moe_event_sd=input(compress(moe_itl_start_date,"-"),yymmdd10.);*/
		moe_event_sd=moe_itl_start_date;
		event_ed_dur = intnx('month',moe_event_sd, moe_itl_duration_months_nbr, 's');
/*		attainedsd = coalesce(input(compress(moe_itl_end_date,"-"),yymmdd10.), event_ed_dur);*/
		attainedsd = coalesce(moe_itl_end_date, event_ed_dur);
		attaineded = "01jan9999"d;
		drop event_ed_dur moe_itl_duration_months_nbr moe_itl_start_date moe_itl_end_date moe_event_sd;
		qualtype = "industry training";
		qualification = put(moe_itl_programme_type_code, $itoqual.);
		length itco_prg_code 8.;
		itco_prg_code = coalesce( moe_itl_pms_course_nbr, moe_itl_itr_course_nbr);
		qualfield = strip(tranwrd(put(itco_prg_code, itocode_name.),strip(moe_itl_programme_type_code),""));

		if substr(qualfield,1,3) = "in " then
			qualfield = strip(substr(qualfield,3,length(qualfield)));

		** identify highest qual achieved *;
		itoquallevel = 0;
		array itoq(*) &itoqual.;

		do i = 1 to dim(itoq);
			if itoq(i) ne 0 then
				itoquallevel = i;
		end;

		drop i &itoqual.;

		*br from 02_edu_integrated_qual: most of the quals 1-4, some 5 and 6, setting them to 4;
		nqflevel = min(itoquallevel, 4);
	run;

	************************************************************************************;
	** 4 combine qualifications data **;
	data tmp /*/
		view== tmp*/
		;
		format &qualvars.;
		length qualtype $20. 
			qualification $60.
			qualfield $200.;
		set moe_schqual2  
			moe_terqual2 
			moe_itoqual2;
	run;

	/*to get maximum qualification */
	proc sql;
		create table mql_0506_qual as 
			select a.* from tmp a
				inner join (
					select snz_uid,
						max(nqflevel) as max_nqf_lvl 

					from tmp
						group by snz_uid) b on 
							a.snz_uid=b.snz_uid and a.nqflevel=b.max_nqf_lvl 
		;
	quit;

	run;

	proc sort data=mql_0506_qual;
		by snz_uid;
	run;

	data tmp;
		set mql_0506_qual;
		by snz_uid;

		if first.snz_uid then
			output;
	run;

	%let byvars = snz_uid attainedsd;

	proc sort data = tmp;
		by &byvars.;
	run;

	** 4.1 subset census 2013 table to ids of interest *;
	%si_subset_idi_dataset_census(sidid_infile = &si_table_in
		,sidid_id_var = &si_id_col
		,sidid_targetschema=&si_target_schema
		,sidid_ason_var = as_at_age
		,sidid_idiextdt = &si_idi_refresh_date
		,sidid_ididataset = [&si_idi_clean_version.].cen_clean.census_individual
		,sidioutfile = census_qual
		);

	proc sql;
		create table work.cen_qual as
			select a.snz_uid,
				put(cen_ind_sndry_scl_qual_code, $sec_qual.) as cen_ind_sec_qual,
				put(cen_ind_post_scl_level_code, $postsec_qual.) as cen_ind_postsec_qual,
				put(cen_ind_std_highest_qual_code, $highest_qual.) as cen_ind_std_highest_qual,
				input(put(put(cen_ind_std_highest_qual_code, $highest_qual.), $highest_qual_lev.),3.0)  as nqflevel
			from census_qual a
				where a.snz_uid not in (select snz_uid from tmp);
	quit;

	data tmp_1;
		set tmp cen_qual (keep=snz_uid cen_ind_std_highest_qual nqflevel);

		if qualification="" then
			highest_qual=cen_ind_std_highest_qual;
		else highest_qual=qualification;

		if qualification="" then
			qual_from_census=1;
		else qual_from_census=0;
		drop cen_ind_std_highest_qual;
	run;
/* to get the consistent qualification level from either datesets */
			proc sql;
			create table &si_out_table. as
				select  snz_uid,attainedsd,nqflevel, 
					put(put(nqflevel, z2.), $highest_qual.) as highest_qual_moe_cen

				from tmp_1
			;
		quit;

run;

	** house keeping **;
	proc datasets lib = work nolist;
		delete moe_schqual:
			moe_terqual:
			moe_itoqual:
			mql_0506_qual:
			moe_provider_lookup_table:
			moe_nzsced_code:
			moe_qual_lookup:
			moe_ito_programme_lookup_table:
			census_qual:
			cen_qual:
			tmp:
			tmp_1:
		;
	run;

%mend;


