/********************************************************************************************************
TITLE: si_join_tables_manual_example_pd

DESCRIPTION: manual join to create a master table that contains variables that you specify
this script shows an example of how to do a manual join based on subject matter expertise.
users will need to build their own manual script based on this so that it is relevant
to the variables that they have in their data foundation.

INPUT:
si_pd_cohort_char_ext   = base table with set of ids and dates we use this table because
the char extension filters those who arent attached to the the spine

OUTPUT:
si_data_foundation_pd   = output table with all the service metrics in a single table  

AUTHOR: E Walsh

DATE: 23 May 2017

DEPENDENCIES:
requires si_main_example_pd.sas to have run  so that all the tables are in the work area

NOTES: 
This is designed to work the si_control_example_pd.sas if you have modified the control script
it is likely that this script will not work.

Expect a sparse dataset most people dont have an MOJ or Corrections history

HISTORY: 
15 Jun 2017 EW bug fix #1 hash objects returning incorrect values
23 May 2017 EW v1
*********************************************************************************************************/

/* create a single table with all the characteristics in an efficient manner */
data si_data_foundation_pd (drop = return_code:);
	set si_pd_cohort_char_ext;

	if _n_ = 1 then
		do;
			if 0 then
				set work.cor_sentence_events_rlpw (keep = snz_uid p_cor_mmp_sar_dur);
			declare hash hcor (dataset: 'work.cor_sentence_events_rlpw (keep = snz_uid p_cor_mmp_sar_dur)');
			hcor.definekey('snz_uid');

			/* example of returning a single column*/
			hcor.definedata('p_cor_mmp_sar_dur');
			hcor.definedone();

			if 0 then
				set work.moe_ece_events_rlpw;
			declare hash hece (dataset: 'moe_ece_events_rlpw');
			hece.definekey('snz_uid');

			/* example of returning all columns */
	        hece.definedata(all: 'yes');
			hece.definedone();

			/* example of only keeping all profile variables */
			if 0 then
				set work.moe_intervention_events_rlpw (keep = snz_uid p:);
			declare hash hint (dataset: 'work.moe_intervention_events_rlpw (keep = snz_uid p:)');
			hint.definekey('snz_uid');
         	hint.definedata(all: 'yes');
			hint.definedone();

			/* example of only keeping the forecast variables */
			if 0 then
				set work.moe_itl_events_rlpw (keep = snz_uid f:);
			declare hash hitl (dataset: 'work.moe_itl_events_rlpw (keep = snz_uid f:)');
			hitl.definekey('snz_uid');
	        hitl.definedata(all: 'yes');
			hitl.definedone();

			/* example of keeping a particular year */
			if 0 then
				set work.moe_school_events_rlpw (keep = snz_uid p1: f1:);
			declare hash hsch (dataset: 'work.moe_school_events_rlpw (keep = snz_uid p1: f1:)');
			hsch.definekey('snz_uid');
            hsch.definedata(all: 'yes');
			hsch.definedone();

			/* keeping the window variables p_ and f_ */
			if 0 then
				set work.moe_tertiary_events_rlpw (keep = snz_uid p_: f_:);
			declare hash hter (dataset: 'work.moe_tertiary_events_rlpw (keep = snz_uid p_: f_:)');
			hter.definekey('snz_uid');
	        hter.definedata(all: 'yes');
			hter.definedone();

			if 0 then
				set work.moj_courtcase_events_rlpw (keep = snz_uid p_moj_cou_cas_cnt p_moj_cou_cas_dur);
			declare hash hmoj (dataset: 'work.moj_courtcase_events_rlpw (keep = snz_uid p_moj_cou_cas_cnt p_moj_cou_cas_dur)');
			hmoj.definekey('snz_uid');

			/* returning two columns */
			hmoj.definedata('p_moj_cou_cas_cnt', 'p_moj_cou_cas_dur');
			hmoj.definedone();

			/* couple of forecast variables */
			if 0 then
				set work.pol_offender_events_rlpw (keep = snz_uid f1: f2:);
			declare hash hoff (dataset: 'work.pol_offender_events_rlpw (keep = snz_uid f1: f2:)');
			hoff.definekey('snz_uid');
	        hoff.definedata(all: 'yes');
			hoff.definedone();

			/* couple of profile variables */
			if 0 then
				set work.pol_victim_events_rlpw (keep = snz_uid p1: p_:);
			declare hash hvic (dataset: 'work.pol_victim_events_rlpw (keep = snz_uid p1: p_:)');
			hvic.definekey('snz_uid');
	        hvic.definedata(all: 'yes');
			hvic.definedone();

			/* the outcome variable */
			if 0 then
				set work.sial_qualifications (keep = snz_uid nqflevel highest_qual);
			declare hash hhqu (dataset: 'work.sial_qualifications (keep = snz_uid nqflevel highest_qual)');
			hhqu.definekey('snz_uid');
			hhqu.definedata('nqflevel', 'highest_qual');
			hhqu.definedone();
		end;

	return_code_hcor = hcor.find();

	if return_code_hcor ne 0 then
		call missing (p_cor_mmp_sar_dur);
	return_code_hece = hece.find();

	/* the easy way to retrieve these long lists is to run the datastep without any call missing functions,
	once you have an output dataset start the filter task on the output dataset and then pull the non executable 
	code from the filter task then copy it into here */
	/* highlight then Ctrl + Shift + L will drop it all to lower case */
	if return_code_hece ne 0 then
		call missing (f0_moe_ece_enr_cnt, f0_moe_ece_enr_ct2, f0_moe_ece_enr_dur, f1_moe_ece_enr_cnt, 
		f1_moe_ece_enr_ct2, f1_moe_ece_enr_dur, f_moe_ece_enr_cnt, f_moe_ece_enr_ct2, 
		f_moe_ece_enr_dffe, f_moe_ece_enr_dur, p1_moe_ece_enr_cnt, p1_moe_ece_enr_ct2, 
		p1_moe_ece_enr_dur, p_moe_ece_enr_cnt, p_moe_ece_enr_ct2, p_moe_ece_enr_dsle, 
		p_moe_ece_enr_dur, p2_moe_ece_enr_cnt, p2_moe_ece_enr_ct2, p2_moe_ece_enr_dur, 
		p3_moe_ece_enr_cnt, p3_moe_ece_enr_ct2, p3_moe_ece_enr_dur, p4_moe_ece_enr_cnt, 
		p4_moe_ece_enr_ct2, p4_moe_ece_enr_dur, p5_moe_ece_enr_cnt, p5_moe_ece_enr_ct2, 
		p5_moe_ece_enr_dur);

	return_code_hint = hint.find();

	if return_code_hint ne 0 then
		call missing(p5_moe_stu_int_cnt, p5_moe_stu_int_ct2, p5_moe_stu_int_dur, 
		p_moe_stu_int_cnt, p_moe_stu_int_ct2, p_moe_stu_int_dsle, p_moe_stu_int_dur, 
		p3_moe_stu_int_cnt, p3_moe_stu_int_ct2, p3_moe_stu_int_dur, p4_moe_stu_int_cnt, 
		p4_moe_stu_int_ct2, p4_moe_stu_int_dur, p2_moe_stu_int_cnt, p2_moe_stu_int_ct2, 
		p2_moe_stu_int_dur, p1_moe_stu_int_cnt, p1_moe_stu_int_ct2, p1_moe_stu_int_dur);

	return_code_hitl = hitl.find();

	if return_code_hint ne 0 then
		call missing( 
		f0_moe_itl_enr_cnt, f0_moe_itl_enr_cst, f0_moe_itl_enr_ct2, f0_moe_itl_enr_dur, 
		f_moe_itl_enr_cnt, f_moe_itl_enr_cst, f_moe_itl_enr_ct2, f_moe_itl_enr_dffe, f_moe_itl_enr_dur, 
		f1_moe_itl_enr_cnt, f1_moe_itl_enr_cst, f1_moe_itl_enr_ct2, f1_moe_itl_enr_dur);

	return_code_hsch = hsch.find();

	if return_code_hsch ne 0 then
		call missing(f1_moe_stu_enr_cnt, f1_moe_stu_enr_cst, f1_moe_stu_enr_ct2, f1_moe_stu_enr_dur, 
		p1_moe_stu_enr_cnt, p1_moe_stu_enr_cst, p1_moe_stu_enr_ct2, p1_moe_stu_enr_dur);

	return_code_hter = hter.find();

	if return_code_hter ne 0 then
		call missing(p_moe_ter_enr_cnt, p_moe_ter_enr_cst, p_moe_ter_enr_ct2, p_moe_ter_enr_dsle, p_moe_ter_enr_dur, 
		f_moe_ter_enr_cnt, f_moe_ter_enr_cst, f_moe_ter_enr_ct2, f_moe_ter_enr_dffe, f_moe_ter_enr_dur);

	return_code_hmoj = hmoj.find();

	if return_code_hmoj ne 0 then
		call missing(p_moj_cou_cas_cnt, p_moj_cou_cas_dur);

	return_code_hoff = hoff.find();

	if return_code_hoff ne 0 then
		call missing(f2_pol_off_off_cnt, f2_pol_off_off_ct2, 
		f2_pol_off_off_dur, f1_pol_off_off_cnt, f1_pol_off_off_ct2, f1_pol_off_off_dur);

		return_code_hvic = hvic.find();

	if return_code_hvic ne 0 then
		call missing(p1_pol_vic_vic_cnt, p1_pol_vic_vic_ct2, p1_pol_vic_vic_dur, p_pol_vic_vic_cnt, 
		p_pol_vic_vic_ct2, p_pol_vic_vic_dsle, p_pol_vic_vic_dur);

	return_code_hhqu = hhqu.find();

	if return_code_hhqu ne 0 then
		call missing(nqflevel, highest_qual);
run;

proc contents data=si_data_foundation_pd;
run;