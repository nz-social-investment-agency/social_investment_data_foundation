/*********************************************************************************************************
DESCRIPTION: Identifies children with contact records and police family violence notifications
When the CYF National Contact Centre (NCC) receieves information regarding a child it will be 
assessed and triaged accordingly. If it is decided that further action is required (FAR) it will 
become a report of concern. If it is decided that no further action is required (NFA) it becomes
a contact record which is added to the child's file.

When this information has been referred to the NCC as per Police Family Violence policy and procedures
then this is flagged in the police_fv indicator.

INPUT:
si_crd_dsn = Database name {default = IDI_Clean}
si_crd_proj_schema = Project schema used to find your tables in the sandpit
si_crd_table_in = name of the input table
si_crd_id_col = id column used for joining tables {default = snz_uid}
si_crd_asat_date = name of the column containing a datetime field used to identify outcomes in a 
    specified time period

OUTPUT:
si_crd_table_out = name of the output table containing the indicators contact_record and police_fv

AUTHOR: E Walsh

DEPENDENCIES:
Access to IDI_Clean.[cyf_clean].[cyf_identity_cluster] and 
[IDI_Sandpit].[clean_read_CYF].[cyf_CYF_clients_CR]

NOTES: 
There are no sunz_uids in the contact record table so they are retrieved from the cyf identity cluster

The dates time looking variables in the contact records have a varchar(26) data type and require
converting to use them as date times

HISTORY: 
22 Jun 2017 EW v1
*********************************************************************************************************/
%macro si_get_cr_outcomes( si_crd_dsn = IDI_Clean, si_crd_proj_schema =, si_crd_table_in =, 
			si_crd_id_col = snz_uid, si_crd_asat_date =, si_crd_table_out =);
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ----------------------SI Data Foundation----------------------------;
	%put ............si_runtime: %sysfunc(datetime(), datetime20.);
	%put --------------------------------------------------------------------;
	%put ---------------si_get_crd_outcomes: Inputs------------------------;
	%put ....si_crd_proj_schema: &si_crd_proj_schema;
	%put .......si_crd_table_in: &si_crd_table_in;
	%put .........si_crd_id_col: &si_crd_id_col;
	%put ......si_crd_asat_date: &si_crd_asat_date;
	%put ......si_crd_table_out: &si_crd_table_out;
	%put --------------------------------------------------------------------;
	%put ********************************************************************;

	/*	options sastrace=',,,d' sastraceloc=saslog nostsuffix; */
	proc sql;
		connect to odbc(dsn=&si_idi_dsnname.);
		create table &si_crd_table_out. as 
			select * from connection to odbc(
			select distinct a.&si_crd_id_col.
				,b.snz_systm_prsn_uid
				,c.contact_record
				,c.police_fv
			from [IDI_Sandpit].[&si_crd_proj_schema.].[&si_crd_table_in.] a
				inner join (select snz_systm_prsn_uid, snz_uid
					from [&si_crd_dsn.].[cyf_clean].[cyf_identity_cluster] 
						where cyf_idc_role_type_text ='Client') b on a.&si_crd_id_col. = b.&si_crd_id_col.
							inner join (select  [snz_prsn_uid]
								, 1 as contact_record
								, 
							case 
								when caller_role = 'PFV' then 1 
							end 
						as police_fv 
							/* need a datetime for the where clause but the creation dates are stored in the database as 
						       varchar(26) with padding at the end */
							,cast(convert(varchar(9), CR_created_datetime, 106) + ' ' + right(left(CR_created_datetime, 18), 8) 
                                as datetime)  as converted_time
						from [IDI_Sandpit].[clean_read_CYF].[cyf_CYF_clients_CR]
							) c on b.snz_systm_prsn_uid = c.snz_prsn_uid
						where c.converted_time <= a.&si_crd_asat_date.
							);
		disconnect from odbc;
	quit;

%mend;