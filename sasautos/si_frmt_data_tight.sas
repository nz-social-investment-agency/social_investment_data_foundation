/*******************************************************************************************************
TITLE: si_frmt_data_tight.sas

DESCRIPTION: 
This macro will get all the names of qualification earned, provider names, type of qualifications and NQF Level

Sample call:
provide the required parameters to the macro call and excute it:
 %si_frmt_data_tight(FCMinfile = MOE_Provider_Lookup_table (WHERE = (provider_code ne .) ) 
		               ,FCMFmtNm = PrvdCode_Inst
		               ,FCMStart = provider_code
		               ,FCMLabel = subsector
		               ) ;

  %si_frmt_data_tight(FCMinfile = MOE_ITO_programme_Lookup_table(WHERE = (ITO_Prg_code ne .) ) 
			             ,FCMFmtNm = ITOCode_Name
			             ,FCMStart = ITO_Prg_code
			             ,FCMLabel = ProgrammeName
			             ) ;
  
  %si_frmt_data_tight(FCMinfile = MOE_Qual_lookup (WHERE = (QualificationTableId ne .) ) 
			               ,FCMFmtNm = QualTid_NQFlvl
			               ,FCMStart = QualificationTableId
			               ,FCMLabel = NQFLevel
			               ) ;


Author:
Nafees Anwar   (SIA)	

DATE: 12 May 2017

DEPENDENCIES:
	access to:
	clean_read_classifications.moe_school_profile
	idi_sandpit (clean_read_moe).moe_provider_lookup_table
	idi_sandpit (clean_read_moe).moe_nzsced_code
	idi_sandpit (clean_read_moe).moe_ito_programme_lookup_table
	

KNOWN ISSUES:
NA

HISTORY:
15 May 2017 NA v1
************************************************************************************/;
%macro si_frmt_data_tight(fcminfile
			,fcmfmtnm
			,fcmstart
			,fcmlabel
			);
	%put frmtdatatight macro starting;

	/*
	%let fcminfile = moe_provider_lookup_table  ;
	%let fcmfmtnm = prvdcode_inst  ;
	%let fcmstart = provider_code        ;
	%let fcmlabel = subsector        ;
	*/
	proc sort data = &fcminfile 
		out = fcmtemp1 (keep = &fcmstart &fcmlabel) 
		nodupkey;
		by &fcmstart;
	run;

	proc contents data= fcmtemp1 noprint 
		out = fcmtemp2;
	run;

	data fcmtemp3;
		set fcmtemp2 (where = (lowcase(name) = lowcase("&fcmlabel")) );

		if type = 2 then
			call symputx("fcmnullv", "label = '!format error!'" );
		else call symputx("fcmnullv", "label = ." );
	run;

	data fcmtemp3;
		set fcmtemp2 (where = (lowcase(name) = lowcase("&fcmstart")) );

		if type = 2 then
			call symputx("fcmnulls", "start = 'other'" );
		else call symputx("fcmnulls", "start = ." );
	run;

	*options symbolgen;
	data fcmtemp4;
		set fcmtemp1 (rename = (&fcmstart. = start
			&fcmlabel.  = label
			) 
			) end = eof;
		fmtname = "&fcmfmtnm.";
		output;
		&fcmnulls.;
		&fcmnullv.;
	run;

	proc format library = work cntlin = fcmtemp4;
	run;

	proc datasets lib = work nolist;
		delete fcmtemp:;
	run;

%mend;