/*******************************************************************************************************
TITLE: si_apply_pi_adjustment

DESCRIPTION: Perform the price index inflation adjustment on the appropriate amount column.

INPUT: 
si_table_in = Input event table containing a dollar column, and has a start and end date for the event.
cost = name of the cost variable (or revenue variable)
si_pi_type = [ CPI PPI QEX ] Type of price index used for column and table names
si_ref_quarter = [ <YYYY>Q<1-4> ] The price index baseline year-quarter
si_amount_type = [D L] Cost type in input dataset D(aily) or L(umpsum)
si_amount_col = Name of the amount column that is to be CPI adjusted.

OUTPUT:
inds = input dataset with CPI adjusted column appended

DEPENDENCIES: 


NOTES: 
Price adjustment is always applied on a quarterly basis using this code.
Note that this macro deletes temporary tables only specific to this macro.

AUTHOR: 
C Wright

DATE: 01 Aug 2016

KNOWN ISSUES: 

HISTORY: 
02 May 2017 VB	Rewrote the code to fit in with the SIAL. Added the functionality to base the inflation
				adjustment to be read from the database rather than excel files.
20 Feb 2017	VB	Added CPI, PPI and QEX as dynamic inputs.
24 Oct 2016 EW made more generic for any price index
02 Aug 2016 EW repurposed to be more generic and meet
               coding conventions
01 Aug 2016 CW v1
*******************************************************************************************************/

%macro si_apply_pi_adjustment(si_table_in = , si_pi_type = CPI, si_ref_quarter =, si_amount_type =, si_amount_col =  );

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_apply_pi_adjustment----------------------;
	%put .......si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put ...............Input table: &si_table_in.;
	%put ............Inflation type: &si_pi_type.;
	%put .........Reference Quarter: &si_ref_quarter.;	
	%put ...............Amount Type: &si_amount_type.;
	%put .............Amount Column: &si_amount_col.;

	
	/* Get the appropriate price index values to which the adjustment needs to be made*/
	proc sql;
		create table work._temp_&si_pi_type._values(where=(yq ne '')) as 
			select 
				quarter as yq, 
				value / (select value from sand.inflation_index where inflation_type = "&si_pi_type." and quarter = "&si_ref_quarter.") as adj_&si_pi_type.
			from 
			sand.inflation_index
			where inflation_type = "&si_pi_type." and quarter >= "1925Q3";
	quit;

	/* Quarter-ise  the events table. this is the level at which inflation adjustment will be done. */
	data work._temp_quarterise (keep= _id_ temp_amount yyq);

		length event_sdate event_edate 4;
		set &si_table_in.;

		/* Store the start & end datetimes for the events tables  */
		event_sdate=start_date;
		event_edate=end_date;
		start_date=.;
		end_date=.;

		/* Store Row id for aggregating back up costs*/
		_id_=_n_;

		/* Work out how many quarters an event spans */
		diff=(intck('DTQUARTER',event_sdate,event_edate));

		do counter=0 to diff;
			d_begin = intnx('DTQUARTER',event_sdate,counter,'begin');
			d_end = intnx('DTQUARTER',event_sdate,counter,'end');

			/* if an event spans multiple quarters create a new record for each quarter */
			if counter=0 then
				start_date=event_sdate;

			if counter=diff then
				end_date=event_edate;

			if counter ne 0 then
				start_date=d_begin;

			if counter ne diff then
				end_date=d_end;
			yyq=put( datepart(start_date) ,yyq6.);
			d1=1 + intck('DTDAY', start_date, end_date);
			d2=1 + intck('DTDAY', event_sdate, event_edate);

			/* the rollup can calculate either a daily amount or a lump sum amount for an event */
			/* note event though we refer to cost this can still be applied to a revenue column */
			if "&si_amount_type"='D' then
				temp_amount=d1*&si_amount_col.;
			else if "&si_amount_type"='L' then
				temp_amount=(d1/d2)*&si_amount_col.;
			output;
		end;


	run;

	/* Aggregate the amounts back up to the original events*/
	proc sql;
		create table work._temp_events_&si_pi_type._adj as
			select a._id_,
				sum(a.temp_amount/b.adj_&si_pi_type.) as &si_amount_col._&si_pi_type._&si_ref_quarter.
			from  work._temp_quarterise as a 
				left join work._temp_&si_pi_type._values as b
					on a.yyq=b.yq
				group by a._id_	;
	quit;
	
	%local out_var_exist;
	%si_var_exist(si_table_in=&si_table_in.,varname=&si_amount_col._&si_pi_type._&si_ref_quarter., si_out_var=out_var_exist);

	/* Add the cpi adjusted column to the input table */
	data &si_table_in.;
		merge &si_table_in. work._temp_events_&si_pi_type._adj (drop=_id_);

		/* by default the cpi adjusted costs are lump sum */
		/* if you require a daily rate then use ctype_out */
		if "&si_amount_type"='D' then
			&si_amount_col._&si_pi_type._&si_ref_quarter.=&si_amount_col._&si_pi_type._&si_ref_quarter./(1 + intck('DTDAY', start_date, end_date) );

	run;

	/* Clean up temp datasets*/
	%if &si_debug. = False %then %do;
		proc datasets lib=work;
			delete _temp_events_&si_pi_type._adj _temp_quarterise _temp_&si_pi_type._values;
		run;
	%end;
	

	%put ------------End Macro: si_apply_pi_adjustment----------------------;

%mend;


/*
%si_apply_pi_adjustment(si_table_in = test2,si_pi_type = CPI, si_ref_quarter=2015Q1, si_amount_type =L, si_amount_col = cost);
*/
