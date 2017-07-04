/*********************************************************************************************************
DESCRIPTION: Identifies when a person has had diabetes as at certain date

INPUT:


OUTPUT:


AUTHOR: Wen Jhe Lee

DEPENDENCIES:
[IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
[IDI_Clean].[moh_clean].[nnpac]
[IDI_Clean].[moh_clean].[pharmaceutical]
[IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code]
[IDI_Clean].[moh_clean].[chronic_condition]
[IDI_Clean].[moh_clean].[lab_claims] 


NOTES: 
Chronic conditions might be just enough to identify all diabetes - but used Rob code which combines public discharges as well!

HISTORY: 
21 Jun 2017 WJ v1
*********************************************************************************************************/


%macro si_get_diabetes( si_diabetes_dsn = IDI_Clean, si_diabetes_proj_schema =, si_diabetes_table_in =, 
			si_diabetes_id_col = snz_uid, si_diabetes_asat_date =, si_diabetes_table_out =);

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put -------------si_get_diabetes: Inputs-----------------------;
	%put ............si_diabetes_dsn: &si_diabetes_dsn;
	%put ....si_diabetes_proj_schema: &si_diabetes_proj_schema;
	%put .......si_diabetes_table_in: &si_diabetes_table_in;
	%put .........si_diabetes_id_col: &si_diabetes_id_col;
	%put ......si_diabetes_asat_date: &si_diabetes_asat_date;
	%put ......si_diabetes_table_out: &si_diabetes_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;
options mlogic mprint;

proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table diabetes1 as 
			select * from connection to odbc(
/*			Users cohort*/
				select * from [IDI_Sandpit].[&si_diabetes_proj_schema.].[&si_diabetes_table_in.] aa 

				left join (
/*Public hospital discharges - diabetes*/
					select distinct snz_uid, 
									cast(moh_evt_evst_date as datetime) as date,
							1 as diabetes1 from (
  
 							select 	snz_uid,
									moh_evt_evst_date,
									moh_dia_event_id_nbr 
							from [&si_diabetes_dsn.].[moh_clean].[pub_fund_hosp_discharges_event]
							inner join (
 							select moh_dia_event_id_nbr 
							from [&si_diabetes_dsn.].[moh_clean].[pub_fund_hosp_discharges_diag]
							where  moh_dia_clinical_sys_code='10' 
								and substring(moh_dia_clinical_code,1,3) in ('E10','E11','E12','E13','E14','O24')
 								or moh_dia_clinical_sys_code='06' 
								and substring(moh_dia_clinical_code,1,3) in ('250')) diab
	  						on moh_dia_event_id_nbr=moh_dia_event_id_nbr ) a

					union
/*Specialist - diabetes*/
					select distinct snz_uid,
									cast(moh_nnp_service_date as datetime) as date ,
							1 as diabetes1	
							from [&si_diabetes_dsn.].[moh_clean].[nnpac] 
							where  moh_nnp_purchase_unit_code in ('M20006', 'M20007', 'M20004','M20005','M20010','M20015','MAOR0106')

					union 
/*Pharmaceutical  - diabetes*/
  					select distinct snz_uid,
									cast(moh_pha_dispensed_date as datetime) as date ,
							1 as diabetes1 from (
							select 	snz_uid,
									moh_pha_dispensed_date, 
									moh_pha_dim_form_pack_code 
							from [&si_diabetes_dsn.].[moh_clean].[pharmaceutical]
							inner join (
							select chemical_id,DIM_FORM_PACK_SUBSIDY_KEY
							from [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code]
							where chemical_id in (1567,1568,1569,2277,2800,1649,1655,6300,3857,1192,3783,1648,1110,1247,1572,2158,3802,3807,1794,1570,1068,2276,3739)) c
							on moh_pha_dim_form_pack_code=DIM_FORM_PACK_SUBSIDY_KEY ) z

					union
/*Chronic conditions  - diabetes*/
					select distinct snz_uid,
									cast(moh_chr_fir_incidnt_date as datetime) as date ,
							1 as diabetes1 
							from [&si_diabetes_dsn.].[moh_clean].[chronic_condition] 
							where moh_chr_condition_text ='DIA'

					) diab2
			on aa.&si_diabetes_id_col.=diab2.snz_uid and diab2.date <= aa.&si_diabetes_asat_date.
		);
			disconnect from odbc;
quit;

/*Keeping only events that were relevant - will join to the main cohort table later*/
proc sort data=diabetes1 out=diabetes2(where=(diabetes1=1)); by snz_uid; run;


/*Retrieving lab related diabetes events*/
proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table diabetes3 as 
			select * from connection to odbc(
select * from [IDI_Sandpit].[&si_diabetes_proj_schema.].[&si_diabetes_table_in.] a

left join (
  select distinct snz_uid, cast(moh_lab_visit_date as datetime) as date ,1 as diabetes2,moh_lab_test_code from (
select moh_lab_test_code,snz_uid,moh_lab_visit_date from [&si_diabetes_dsn.].[moh_clean].[lab_claims] 
where moh_lab_test_code in ('BG2','BP8') ) aa )z
on a.&si_diabetes_id_col.=z.snz_uid and z.date  <= a.&si_diabetes_asat_date.

				);
			disconnect from odbc;
quit;

/*Using Rob's code of identifying Lab related events that are diabetes - detailed*/
proc sort data=diabetes3(rename=(date=event_date));
by snz_uid event_date;
run;

data diabetes4 (keep=snz_uid);
set diabetes3(keep=snz_uid event_date moh_lab_test_code diabetes2 where=(diabetes2=1));
retain microalbumin count_hba hba_1 hba_2 hba_3 hba_4 lastmicroalbumin diabetes_lab;
by snz_uid event_date;

if first.snz_uid then do;
  diabetes_lab=0;
  count_hba=0;
  microalbumin=0;
  hba_1=.;
  hba_2=.;
  hba_3=.;
  hba_4=.;
end;

eventsasdate=mdy(scan(event_date,2,'/-'),scan(event_date,3,'/-'),scan(event_date,1,'/-'));

if moh_lab_test_code = 'BG2' then do;
count_hba+1 ;
*always keep latest 4 dates;
hba_4=hba_3;
hba_3=hba_2;
hba_2=hba_1;
hba_1=eventsasdate;
end;

if  moh_lab_test_code = 'BP8' then microalbumin+1 ;
if  moh_lab_test_code = 'BP8' then lastmicroalbumin=eventsasdate ;

if (count_hba>=4) and ((hba_1-hba_4)<366) and (microalbumin and (hba_4<= lastmicroalbumin <=hba_1)) then diabetes_lab=1;

if last.snz_uid and diabetes_lab then do;
output;
end;
run;
/**/
/*Combining all snz_uid - which had pharama, hospital , lab test and in chronic tables*/

proc sort data=diabetes4; by snz_uid; run;

data diabetes5;
set diabetes2(keep=snz_uid) diabetes4 ;
by snz_uid;
run;

proc sort data=diabetes5 out=diabetes6(rename=(snz_uid=&si_diabetes_id_col.)) nodupkey; by snz_uid; run;


/*Retrieving cohort of interest*/
proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table cohort as 
			select * from connection to odbc(
			select *
			from [IDI_Sandpit].[&si_diabetes_proj_schema.].[&si_diabetes_table_in.]

	);
			disconnect from odbc;
quit;

proc sort data= cohort; by &si_diabetes_id_col.; run;

/*Identifying which users had diabetes based on their as at date*/
data &si_diabetes_table_out.;
merge cohort(in=a) diabetes6(in=b);
by &si_diabetes_id_col.;
if a and b then diabetes=1 ;
else diabetes =0;
if a;
run;

proc datasets lib=work;
delete diabetes: cohort; 
run;


%mend;

/**/
/* %si_get_diabetes( si_diabetes_dsn = IDI_Clean, si_diabetes_proj_schema = DL-MAA2016-15, si_diabetes_table_in = si_pd_cohort, */
/*			si_diabetes_id_col = snz_uid, si_diabetes_asat_date = as_at_date, si_diabetes_table_out = si_pd_diabetes);*/