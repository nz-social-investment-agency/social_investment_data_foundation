/*******************************************************************************************************
TITLE: si_apply_discounting.sas

DESCRIPTION: This macro is used to apply yearly discounting to the cost variable, with the "ason_date" column
	as the reference. The rate of discounting is to be given as the input. This macro runs on the output dataset 
	from the si_align_sial_events_to_periods macro.

INPUT: 
si_table_in = input table, which has a UID, start & end dates 	for an event, the amount to which the discounting is 
	applied to, and the as-on date which is taken as year 0 for applying discounting.

si_id_col = name of ID column, for example: snz_uid.

si_amount_column = name of the amount column to which discounting is to be applied. 

si_amount_type= [L D] Specify whether the amount column is Lumpsum or a Daily amount.

si_as_at_date = column containing the intervention date in datetime20 format. Discounting is performed on this 
	column.

si_disc_rate = discount rate  specified in percentage(%).

OUTPUT:
si_out_table = table containing costs that have been discounted by si_disc_rate.

DEPENDENCIES: 
	si_align_sial_events_to_periods should be run before this macro is applied.

NOTES: 
	Using discount rates of 3% and 7% is consistent with CBAx as at 4th August 2016. Another popular
	rate is the long yield Government bond coupon rate (e.g. 5%).
	Discounting is done at a yearly level.
	There is no need to reconsitute the events once these are broken into yearly components, since we do not 
	expect events to be longer than 1 year. This is because the highest grain that is possible in the 
	align_sialevents_to_periods macro is at the yearly level.


AUTHOR: 
V Benny, Adapted from C Wright/E Walsh's original code.

DATE: 02 Aug 2016

HISTORY: 
03 May 2017 VB Rewrote logic as part of SIAL. Removed reverse discounting.
11 Aug 2016 EW incorporated the ability to reverse discount
03 Aug 2016 EW repurposed to be more generic and meet coding conventions
02 Aug 2016 CW v1
*******************************************************************************************************/

%macro si_apply_discounting(si_table_in= , si_id_col=snz_uid , si_amount_col=, si_amount_type =, si_as_at_date = as_at_date,
			si_disc_rate = , si_out_table = );
	
	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_apply_discounting----------------------;
	%put .......si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put ...............Input table: &si_table_in;
	%put .................Id column: &si_id_col;
	%put .............Amount Column: &si_amount_col.;
	%put ...............Amount Type: &si_amount_type.;
	%put .........As-On date Column: &si_as_at_date.;
	%put .............Discount rate: &si_disc_rate.;
	%put ..............Output table: &si_out_table.;

	/**/ 
	data &si_out_table. (drop= d_begin d_end cost_evt daily start_year end_year i &si_amount_col.);

		length disc_start_date disc_end_date 8;
		format disc_start_date disc_end_date datetime20.;

		set &si_table_in. ;

		if symget('si_amount_type') = "L" then do;
			daily = &si_amount_col. / (1+intck('DTDAY', start_date, end_date));
		end;
		else do;
			daily = &si_amount_col. ;
		end;
		
		/* calculate start & end years for an event. these are calculated from the as-at date*/
		start_year = intck('DTYEAR', &si_as_at_date., start_date, 'C') ;
		end_year = intck('DTYEAR', &si_as_at_date., end_date, 'C') ;

		/* For each year, break the event up to align with the year, do a discounting of the amount column for the event*/
		do i = start_year to end_year;

			d_begin = intnx('DTYEAR', &si_as_at_date., i , 'SAME' );
			d_end = intnx('DTDAY', intnx('DTYEAR', &si_as_at_date., ( (i + 1) ) , 'SAME' ), -1 );

			if i=start_year then
				disc_start_date=start_date;

			if i=end_year then
				disc_end_date=end_date;

			if i ne start_year then
				disc_start_date=d_begin;

			if i ne end_year then
				disc_end_date=d_end;


			cost_evt = (1 + intck('DTDAY', disc_start_date, disc_end_date) )*daily;
			&si_amount_col._disc&si_disc_rate. = cost_evt / ((1+(&si_disc_rate./100))**i);

			output;

		end;

	run;

	/* Clean up temp datasets*/
	%if &si_debug. = False %then %do;
		proc datasets lib=work;
			delete temp: ;
		run;
	%end;
	

	%put ------------End Macro: si_apply_discounting----------------------;

%mend;
/*
%si_apply_discounting(si_table_in=work.test2 , si_id_col=snz_uid , si_amount_col=cost, si_amount_type =L, si_as_at_date = ason_date,
			si_disc_rate = 3, si_out_table = disctest);

*/