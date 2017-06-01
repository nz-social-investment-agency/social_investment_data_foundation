/********************************************************************************************************
TITLE: si_join_tables_manual

DESCRIPTION: manual join to create a master table that contains variables that you specify
This script shows an example of how to do a manual join based on subject matter expertise.
Users will need to build their own manual script based on this so that it is relevant
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


HISTORY: 
23 May 2017 EW v1
*********************************************************************************************************/

/* create a single table with all the characteristics in an efficient manner */
data si_data_foundation_pd (drop = return_code:);
	set si_pd_cohort_char_ext;

	if _N_ = 1 then
		do;
			if 0 then set work.cor_sentence_events_rlpw;
			declare hash hcor (dataset: 'work.cor_sentence_events_rlpw (keep = snz_uid p_cor_mmp_sar_dur)');
			hcor.defineKey('snz_uid');
			/* example of returning a single column*/
         	hcor.defineData('p_cor_mmp_sar_dur');
			hcor.defineDone();

			if 0 then set work.moe_ece_events_rlpw;
			declare hash hece (dataset: 'moe_ece_events_rlpw');
			hece.defineKey('snz_uid');
			/* example of returning all columns */
	        hece.defineData(all:'yes');
			hece.defineDone();

			/* example of only keeping all profile variables */
			if 0 then set work.moe_intervention_events_rlpw (keep = snz_uid p:);
			declare hash hint (dataset: 'work.moe_intervention_events_rlpw (keep = snz_uid p:)');
			hint.defineKey('snz_uid');
         	hint.defineData(all: 'yes');
			hint.defineDone();

			/* example of only keeping the forecast variables */
			if 0 then set work.moe_itl_events_rlpw (keep = snz_uid f:);
			declare hash hitl (dataset: 'work.moe_itl_events_rlpw (keep = snz_uid f:)');
			hitl.defineKey('snz_uid');
	        hitl.defineData(all: 'yes');
			hitl.defineDone();

            /* example of keeping a particular year */
			if 0 then set work.moe_school_events_rlpw (keep = snz_uid p1: f1:);
			declare hash hsch (dataset: 'work.moe_school_events_rlpw (keep = snz_uid p1: f1:)');
			hsch.defineKey('snz_uid');
        	hsch.defineData(all: 'yes');
			hsch.defineDone();

			/* keeping the window variables p_ and f_ */
			if 0 then set work.moe_tertiary_events_rlpw (keep = snz_uid p_: f_:);
			declare hash hter (dataset: 'work.moe_tertiary_events_rlpw (keep = snz_uid p_: f_:)');
			hter.defineKey('snz_uid');
	        hter.defineData(all: 'yes');
			hter.defineDone();

			if 0 then set work.moj_courtcase_events_rlpw (keep = snz_uid p_moj_cou_cas_cnt p_moj_cou_cas_dur);
			declare hash hmoj (dataset: 'work.moj_courtcase_events_rlpw (keep = snz_uid p_moj_cou_cas_cnt p_moj_cou_cas_dur)');
			hmoj.defineKey('snz_uid');
			/* returning two columns */
	        hmoj.defineData('p_moj_cou_cas_cnt', 'p_moj_cou_cas_dur');
			hmoj.defineDone();

			/* couple of forecast variables */
			if 0 then set work.pol_offender_events_rlpw (keep = snz_uid f1: f2:);
			declare hash hoff (dataset: 'work.pol_offender_events_rlpw (keep = snz_uid f1: f2:)');
			hoff.defineKey('snz_uid');
	        hoff.defineData(all:'yes');
			hoff.defineDone();

			/* couple of profile variables */
			if 0 then set work.pol_victim_events_rlpw (keep = snz_uid p1: p_:);
			declare hash hvic (dataset: 'work.pol_victim_events_rlpw (keep = snz_uid p1: p_:)');
			hvic.defineKey('snz_uid');
	        hvic.defineData(all: 'yes');
			hvic.defineDone();

			/* the outcome variable */
			if 0 then set work.sial_qualifications (keep = snz_uid nqflevel highest_qual);
			declare hash hhqu (dataset: 'work.sial_qualifications (keep = snz_uid nqflevel highest_qual)');
			hhqu.defineKey('snz_uid');
	        hhqu.defineData('nqflevel', 'highest_qual');
			hhqu.defineDone();

		end;



	return_code_hcor = hcor.find();
	return_code_hece = hece.find();
	return_code_hint = hint.find();
	return_code_hitl = hitl.find();
	return_code_hsch = hsch.find();
	return_code_hter = hter.find();
	return_code_hmoj = hmoj.find();
	return_code_hoff = hoff.find();
	return_code_hvic = hvic.find();
	return_code_hhqu = hhqu.find();
run;

proc contents data=si_data_foundation_pd;
run;