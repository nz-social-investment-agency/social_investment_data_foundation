/****************************************************
TITLE: si_setup.sas

DESCRIPTION: defines global macro variables for
the master dataset

INPUT:
XXXXXX

OUTPUT:
XXXXX

AUTHOR: E Walsh

DATE: 21 Apr 2017

DEPENDENCIES: 

NOTES: 
TODO require the implicit passthrough and explicit passthrough variables

HISTORY: 
21 Apr 2017 EW v1
****************************************************/


%macro si_setup();

/* data base info */
%global si_sandpit_libname si_proj_schema si_debug;
%let si_sandpit_libname = sand;
%let si_proj_schema = DL-MAA2016-15;
%let si_debug = False;



/* variables related to the population cohot */
%global si_pop_table_out si_id_col si_asat_date;
%let si_pop_table_out = si_sofie_cohort;          /* this must be the name of the output table in si_get_cohort macro */
%let si_id_col = snz_uid;                         /* the id column name that you join tables on */
%let si_asat_date = sofie_interview_date;         /* the date at which the intervention occured */


/* variables tied to the windowing for SIAL and possibly expert variables */
%global si_num_periods_before si_num_periods_after si_period_duration si_price_index_type
	si_price_index_qtr si_discount si_discount_rate;

%let si_num_periods_before = -5;				/* number of periods in the profile window for use in windowing script */
%let si_num_periods_after = 5;					/* number of periods in the forecast window for use in windowing script */
%let si_period_duration = Year;					/* duration of period */
%let si_price_index_type = CPI;					/* type of inflation adjustment*/
%let si_price_index_qtr = 2016Q2;				/* reference Quarter to which Inflation adjustment is to be done */
%let si_discount = True;						/* specify if discounting is to be done */
%let si_discount_rate = 3;						/* specify discounting rate(value is ignored if si_discount = False) */


/* rollup flags */
%global si_rollup_agg_cols si_rollup_cost 	si_rollup_duration 	si_rollup_count 
si_rollup_count_startdate si_rollup_dayssince	si_rollup_cost si_rollup_duration 
si_rollup_count si_rollup_count_sdate si_rollup_dayssince si_use_moe si_use_moh
si_use_msd si_use_moj si_use_cor si_use_pol si_use_acc si_use_ird;

/* which datasets to roll up */
%let si_use_moe = True;
%let si_use_moh = False;
%let si_use_msd = False;
%let si_use_moj = True;
%let si_use_cor = False;
%let si_use_pol = False;
%let si_use_acc = False;
%let si_use_ird = False;

%let si_rollup_agg_cols = XXX;
%let si_rollup_cost = True;
%let si_rollup_duration = True;
%let si_rollup_count = True;
%let si_rollup_count_sdate = True;
%let si_rollup_dayssince = True;

/* cost info */
%global si_amount_type si_sial_amount_col;
%let si_amount_type=NA;
%let si_sial_amount_col = cost;


/************************************************************************/


%let si_char_ext_table_out = &si_pop_table_out._char_ext;



/************************************************************************/

/* derived variables do not modify unless you are familiar with the 
underlying structure */



/* libname to write to db via implicit passthrough */
libname &si_sandpit_libname ODBC dsn= idi_sandpit_srvprd schema="&si_proj_schema" bulkload=yes;

/* software information */
%global si_version;
%let si_version=1.0.0;

%global si_bigdate;
data _null_;
	call symput('si_bigdate', "31Dec9999"D);
run;


%put ********************************************************************;
%put --------------------------------------------------------------------;
%put ------------si_setup: Master Dataset Versioning---------------------;
%put ............si_version: &si_version;
%put ............si_license: GNU GPLv3;
%put ............si_runtime: %sysfunc(datetime(),datetime20.);
/* general info */
%put --------------------------------------------------------------------;
%put -------------si_setup: General Info --------------------------------;
%put ....si_sandpit_libname: &si_sandpit_libname;
%put ........si_proj_schema: &si_proj_schema;
%put ..............si_debug: &si_debug;
/* population cohort info */
%put ---------------------------------------------------------------------;
%put ------------si_setup: Population Cohort -----------------------------;
%put ......si_pop_table_out: &si_pop_table_out;
%put .............si_id_col: &si_id_col;
%put ..........si_asat_date: &si_asat_date;

/* Cost parameters */
%put ---------------------------------------------------------------------;
%put ------------si_setup: Cost Parameters---------------------------;
%put ........si_amount_type: &si_amount_type ;

/* These defined in the control table */
%put ---------------------------------------------------------------------;
%put ------------cles_setup: Control Parameters---------------------------;
%put ....si_rollup_agg_cols: &si_rollup_agg_cols;
%put ........si_rollup_cost: &si_rollup_cost;
%put ....si_rollup_duration: &si_rollup_duration;
%put .......si_rollup_count: &si_rollup_count;
%put .si_rollup_count_sdate: &si_rollup_count_sdate;
%put ...si_rollup_dayssince: &si_rollup_dayssince;
%put ...............cles_id: ;
%put .......cles_prfclc_opt:  ; 
%put .......cles_prfcol_opt:  ; 
%put .......cles_prflog_opt:  ; 
%put ............cles_debug: ;
%put ..........cles_templib: ;
%put ............cles_oplbl:  ;
%put .............cles_opds: ;


/* Input datasets */
%put ----------------------------------------------------------------------;
%put ------------cles_setup: Input datasets--------------------------------;
%put ..........cles_control: ;
%put ...............si_inds: ;

/* Intermediate datasets */
%put ----------------------------------------------------------------------;
%put ------------cles_setup: Intermediate datasets-------------------------;
%put .....cles_master_index: ;
%put ..cles_master_clusters: ;
%put ........cles_window_cl: ;
%put .........cles_final_cl: ;
%put ----------------------------------------------------------------------;

%put ......cles_clpr_cl_cyf: ;
%put ......cles_clpr_cl_win: ;
%put ..cles_clpr_cl_win_chd: ; 
%put ......cles_clpr_cl_moe: ;
%put ......cles_clpr_cl_cor: ;
%put ......cles_clpr_cl_dia: ;
%put ......cles_clpr_cl_ird: ;
%put ----------------------------------------------------------------------;
%put ********************************************************************;

%mend si_setup;

%si_setup();