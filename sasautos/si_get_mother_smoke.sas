/*********************************************************************************************************
DESCRIPTION: Finding out mothers in the cohort who have smoked at least 1 year before childbirth  
or 2 years after childbirth

INPUT:
si_mother_smoke_dsn = Database name {default = IDI_Clean}
si_mother_smoke_proj_schema = Project schema used to find your tables in the sandpit
si_mother_smoke_table_in = name of the input table
si_mother_smoke_id_col = id column used for joining tables {default = snz_uid}
si_mother_smoke_asat_date = name of the column containing a datetime field used to identify outcomes 
in a specified time period

OUTPUT:
si_mother_smoke_table_out = name of the output table containing the flag mother_smoke_birth

AUTHOR: W.Lee

DEPENDENCIES:
IDI_Clean.data.personal_detail
IDI_Clean.dia_clean.births
IDI_Clean. [moh_clean].[pub_fund_hosp_discharges_event]


NOTES: 
Only using public hospital discharges to identify smoking mothers
Business rule for identifying mothers who smoked during childbirths is if they had a discharge event 
within a year before childbirth and 2 years after

HISTORY: 
18 Aug 2017 EW tidy up of headers and removed macro options
07 Jul 2017 WJ v1
*********************************************************************************************************/
%macro si_get_mother_smoke( si_mother_smoke_dsn = IDI_Clean, si_mother_smoke_proj_schema =, si_mother_smoke_table_in =, 
			si_mother_smoke_id_col = snz_uid, si_mother_smoke_asat_date =, si_mother_smoke_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put -------------si_get_mother_smoke: Inputs-----------------------;
	%put ............si_mother_smoke_dsn: &si_mother_smoke_dsn;
	%put ....si_mother_smoke_proj_schema: &si_mother_smoke_proj_schema;
	%put .......si_mother_smoke_table_in: &si_mother_smoke_table_in;
	%put .........si_mother_smoke_id_col: &si_mother_smoke_id_col;
	%put ......si_mother_smoke_asat_date: &si_mother_smoke_asat_date;
	%put ......si_mother_smoke_table_out: &si_mother_smoke_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	proc sql;
		connect to odbc(dsn=idi_clean_archive_srvprd);
		create table &si_mother_smoke_table_out. as 
			select * from connection to odbc(
			select distinct * from (
			select y.*,
				case 
					when cast(moh_evt_evst_date as datetime)
					between cast(datediff(yy,1,date_of_childbirth) as datetime)
					and cast(dateadd(yy,2,date_of_childbirth) as datetime) then 1 
					else 0 
				end 
			as mother_smoke_birth 
				from [IDI_Sandpit].[&si_mother_smoke_proj_schema.].[&si_mother_smoke_table_in.] y
					left join (
						select 
							case 
								when per1.snz_sex_code = 2 then parent1_snz_uid 
								when per2.snz_sex_code = 2 then parent2_snz_uid 
							end 
						as mother_snz_uid
							, datefromparts(dia_bir_birth_year_nbr , dia_bir_birth_month_nbr, 15) as date_of_childbirth
						from [&si_mother_smoke_dsn.].[dia_clean].[births] bir
							left join [&si_mother_smoke_dsn.].[data].[personal_detail] per1 
								on (per1.snz_uid = bir.parent1_snz_uid)
							left join [&si_mother_smoke_dsn.].[data].[personal_detail] per2 
								on (per2.snz_uid = bir.parent2_snz_uid)) as z
								on ( y.&si_mother_smoke_id_col. =z.mother_snz_uid and 
								z.date_of_childbirth <=  y.&si_mother_smoke_asat_date. )
							left join (
								select snz_uid, 
									moh_evt_event_id_nbr,
									moh_evt_evst_date 
								from [&si_mother_smoke_dsn.].[moh_clean].[pub_fund_hosp_discharges_event] a
									inner join (
										select  moh_dia_event_id_nbr from  
											[&si_mother_smoke_dsn.].[moh_clean].[pub_fund_hosp_discharges_diag] 
										where substring(moh_dia_clinical_code,1,4) in ('Z720') ) b
											on a.moh_evt_event_id_nbr=b.moh_dia_event_id_nbr ) zz
											on ( y.&si_mother_smoke_id_col. =zz.snz_uid ) ) final 
										where mother_smoke_birth =1
											);
		disconnect from odbc;
	quit;

%mend;