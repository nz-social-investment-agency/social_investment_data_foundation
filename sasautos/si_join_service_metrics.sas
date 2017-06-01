/********************************************************************************************************
TITLE: si_join_service_metrics

DESCRIPTION: join all service metrics into a single wide form table

INPUT:
si_service_table_in    = base table with set of ids and dates
si_use_acc             = include ACC data {True | False} 
si_use_cor             = include Corrections data {True | False} 
si_use_ird             = include IRD data {True | False} 
si_use_moe             = include MOE data {True | False} 
si_use_moh             = include MOH data {True | False} 
si_use_moj             = include MOJ data {True | False} 
si_use_msd             = include MSD data {True | False} 
si_use_pol             = include Police data {True | False} 

OUTPUT:
si_service_table_out   = output table with all the service metrics in a single table  

AUTHOR: E Walsh

DATE: 23 May 2017

DEPENDENCIES: 

NOTES: 


HISTORY: 
23 May 2017 EW v1
*********************************************************************************************************/
%put ********************************************************************;
%put --------------------------------------------------------------------;
%put ----------------------SI Data Foundation----------------------------;
%put ...si_macro_start_time: %sysfunc(datetime(), datetime20.);
%put --------------------------------------------------------------------;
%put ------------si_join_service_metrics: Inputs-------------------------;
%put ...si_service_table_in: &si_service_table_in;
%put ..si_service_table_out: &si_service_table_out;
%put ...........si_use_acc : &si_use_acc;
%put ...........si_use_cor : &si_use_cor;
%put ...........si_use_ird : &si_use_ird;
%put ...........si_use_moe : &si_use_moe;
%put ...........si_use_moh : &si_use_moh;
%put ...........si_use_moj : &si_use_moj;
%put ...........si_use_msd : &si_use_msd;
%put ...........si_use_pol : &si_use_pol;
%put ********************************************************************;

/* create a single table with all the characteristics in an efficient manner */
data &si_service_table_out. (drop = return_code:);
	set &si_service_table_in.;

	if _N_ = 1 then
		do;
			%if &si_use_acc = True %then
				%do;
					/* sneaky way to load the columns into the pdv without the data */
					if 0 then
						set work.XXX_XXXXX_events_rlp_wide;
					declare hash hacc(dataset: 'work.XXX_XXXXX_events_rlp_wide');
					hacc.defineKey('snz_uid');
			hacc.defineData(all:
					'yes');
					hacc.defineDone();
				%end;

			%if &si_use_cor  = True %then
				do;
					if 0 then
						set work.XXX_XXXXX_events_rlp_wide;
					declare hash hcor(dataset: 'work.XXX_XXXXX_events_rlp_wide');
					hcor.defineKey('snz_uid');
			hcor.defineData(all:
					'yes');
					hcor.defineDone();
%end;

					%if &si_use_ird = True %then
						do;
							if 0 then
								set work.XXX_XXXXX_events_rlp_wide;
							declare hash hird(dataset: 'work.XXX_XXXXX_events_rlp_wide');
							hird.defineKey('snz_uid');
					hird.defineData(all:
							'yes');
							hird.defineDone();
%end;

							%if &si_use_moe = True %then
								%do;
									if 0 then
										set work.XXX_XXXXX_events_rlp_wide;
									declare hash hmoe(dataset: 'work.XXX_XXXXX_events_rlp_wide');
									hmoe.defineKey('snz_uid');
							hmoe.defineData(all:
									'yes');
									hmoe.defineDone();
								%end;

							%if &si_use_moh = True %then
								%do;
									if 0 then
										set work.XXX_XXXXX_events_rlp_wide;
									declare hash hmoh(dataset: 'work.XXX_XXXXX_events_rlp_wide');
									hmoh.defineKey('snz_uid');
							hmoh.defineData(all:
									'yes');
									hmoh.defineDone();
								%end;

							%if &si_use_moj = True %then
								%do;
									if 0 then
										set work.XXX_XXXXX_events_rlp_wide;
									declare hash hmoj(dataset: 'work.XXX_XXXXX_events_rlp_wide');
									hmoj.defineKey('snz_uid');
							hmoj.defineData(all:
									'yes');
									hmoj.defineDone();
								%end;

							%if &si_use_msd = True %then
								%do;
									if 0 then
										set work.XXX_XXXXX_events_rlp_wide;
									declare hash hmsd(dataset: 'work.XXX_XXXXX_events_rlp_wide');
									hmsd.defineKey('snz_uid');
							hmsd.defineData(all:
									'yes');
									hmsd.defineDone();
								%end;

							%if &si_use_pol = True %then
								%do;
									if 0 then
										set work.XXX_XXXXX_events_rlp_wide;
									declare hash hpol(dataset: 'work.XXX_XXXXX_events_rlp_wide');
									hpol.defineKey('snz_uid');
							hpol.defineData(all:
									'yes');
									hpol.defineDone();
								%end;
						end;

					%if &si_use_acc = True %then return_code_hacc = hacc.find();
					%if &si_use_cor = True %then return_code_hcor = hcor.find();
					%if &si_use_ird = True %then return_code_hird = hird.find();
					%if &si_use_moe = True %then return_code_hmoe = hmoe.find();
					%if &si_use_moh = True %then return_code_hmoh = hmoh.find();
					%if &si_use_moj = True %then return_code_hmoj = hmoj.find();
					%if &si_use_msd = True %then return_code_hmsd = hmsd.find();
					%if &si_use_pol = True %then return_code_hpol = hpol.find();
run;