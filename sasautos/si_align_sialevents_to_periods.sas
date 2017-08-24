/*******************************************************************************************************
TITLE: si_align_sialevents_to_periods.sas

DESCRIPTION: 
	The purpose of this macro is to break SIAL events into sub-events such that these align
	with the profile and forecast windows of analysis. For example, let us assume that we want to observe 
	the SIAL related events for a set of individuals for 5 years before a particular date (called "as-on" date) 
	and 3 years after. This observation window (with the as-on date as the reference point) is divided into 
	two parts- the Profile window, which starts 5 years before the "as-on" date, and ends on the day before the 
	"as-on" date; and the Forecast window starts on the as-on date and ends 3 years from the as-on date.
	
	This macro will fetch all events in the input SIAL table that intersect with this full interval. It then 
	breaks down the events such that the event periods that fall outside the observation window are trimmed to 
	include only the duration that is within the observation window. This calls for changing the start & end dates 
	of these events to align with the profile start and forecast end dates. The costs are also adjusted to include
	only the cost attributed to the duration that falls within the observation window.

	Further, the macro also breaks down these events to align with the period of interest( ie, Year in this example).
	Hence events that span across years would be broken down in order to align with the year boundary dates. Let us
	assume that the as-on date is 15 Jan 2016, and an event lasts from 12 Dec 2013 to 30 Jan 2014. In this case, the 
	event will be broken into 12 Dec 2013 to 14 Jan 2014 (which will belong to reference period "-3"), and then from 
	15 Jan 2014 to 30 Jan 2014 (which will belong to reference period "-2"). Please note that the period duration
	does not always have to be Year-based. it can also be Half-yearly or quarterly or monthly, depending on the needs
	of analysis. the reference period number will be accordingly assigned to half-years or quarters or months.
	Refer to the input section to see all the options available.

	Each period of interest is given a number with reference to the as-on date. The period that starts with the as-on 
	date is period 0. So all periods in the profile window will have negative integer reference numbers and those in
	forecast window will be positive numbers.

	There is also provision to apply Inflation adjustments to costs in this macro.


INPUT:

si_table_in = main table, with an id column and dates. Please note that the column names needs to 
	be specified under the "si_id_col" & "si_as_at_date" parameter. The date needs to be a DATETIME column.

si_sial_table = the input SIAL table, which has the events that we are interested in subsetting 
	to the time window.

si_amount_type = [NA, L, D] Specify the type of amount in the SIAL table.
			NA - No Amount
			L - Lump sum Amount
			D - Daliy Amount

si_id_col = Name of the ID column. This column should be present in both si_table_in and si_sial_table.
	By default, this is assumed to be "snz_uid". 

si_as_at_date = Name of the "as-on date" column. This column should be present in both si_table_in.
	By default, this is assumed to be "ason_date". 

si_amount_col = Name of the amount column in the SIAL dataset.

noofperiodsbefore =  <integer> Number of periods required in the profile window.

noofperiodsafter =  <integer> Number of periods required in the forecast window.

period_duration = [Year, Halfyear, Quarter, Month, Week, <integer>] 
	Specify  duration of the period. For example, if period duration is "Year", noofperiodsbefore is "4", 
	noofperiodsafter = "3", then the code will create 4 yearly periods of observation, counting backwards from 
	the reference date for that snz_uid, and 3 yearly periods counting forward from reference date. The periods 
	will range from -4 to 2. If periods are to be aligned to the Calendar (such that the beginning and end of each 
	period align with beginning and end of weeks/months/quarters/half-years/years), use this in conjunction with 
	period_aligned_to_calendar parameter. Note that in such cases, this parameter has to be either yearly, 
	half-yearly, quarterly, monthly or weekly. If not, this can be an integer as well, signifying the duration of 
	desired period in days. 

period_aligned_to_calendar = [False	True] 
	If this flag is true, all the periods created will be algned to the calendar. For example, if the reference date is 
	15Jan2014 and period duration is monthly, then ref_period "0" would be from 01Jan2014 to 31Jan2014; reference period "-1" 
	would be 01Dec2013 to 31Dec2013, and so on. If the flag is False, then reference period "0" in the same example would be 
	15Jan2014 to 14Feb2014 and reference period "-1" would be 15Dec2013 to 14Jan2014. Please note that if the period duration 
	is numeric (ie, in days), then making this flag True will not mean anything; it will be forced to be False during code 
	execution. Use this option with extreme caution to avoid confusion with dates later on.

si_pi_type = [NA CPI PPI QEX ] Type of price index used for column and table names. If not required, use NA

si_pi_qtr = [ <YYYY>Q<1-4> ] The price index baseline year-quarter.


Sample call:
%si_align_sialevents_to_periods(si_table_in=[IDI_Sandpit].[DL-MAA2016-15].inp_tester, si_sial_table=[IDI_Sandpit].[DL-MAA2016-15].SIAL_tester, 
si_id_col = snz_uid, si_amount_type= L, si_amount_col=cost, noofperiodsbefore=-5, noofperiodsafter=5, period_duration= Year, si_out_table=test2, 
period_aligned_to_calendar = False, si_pi_type=CPI, si_pi_qtr=2016Q2);


OUTPUT:
si_out_table = a subset of SIAL table events for snz_uids in input table marked with a window period specified.
	The window periods are counted from the dates specified in input table for each individual.

AUTHOR: 
Vinay Benny

DATE: 04 May 2017

DEPENDENCIES:
NA

NOTES: 
	Use the macro parameter period_aligned_to_calendar = True with caution. This will rebase the as-at dates
	to the start of the period.

KNOWN ISSUES: 

HISTORY:
04 May 2017 VB v1


***********************************************************************************************************/

%macro si_align_sialevents_to_periods(si_table_in=, si_sial_table=, si_amount_type= NA, si_id_col = snz_uid, si_as_at_date = ,
	si_amount_col = cost, noofperiodsbefore=0, noofperiodsafter=1, period_duration= Year, period_aligned_to_calendar = False, 
	si_pi_type=NA, si_pi_qtr=NA, si_out_table= , return_status= exit_code);
	
	
	/********************************** INPUT VALIDATION****************************************/

	%put ********************************************************************;
	%put --------------------------------------------------------------------;
	%put ------------Macro: si_align_sialevents_to_periods----------------------;
	%put ............si_macro_start_time: %sysfunc(datetime(), datetime20.);
	%put ....................Input table: &si_table_in.;
	%put .....................SIAL table: &si_sial_table.;
	%put ....................Amount type: &si_amount_type.;
	%put ......................ID Column: &si_id_col.;
	%put ..............As-on date Column: &si_as_at_date.;
	%put ..................Amount Column: &si_amount_col.;
	%put ................Starting period: &noofperiodsbefore.;
	%put ..................Ending period: &noofperiodsafter.;

	/* Set return status from this macro to be Fail by default- will be reset to success at the end if all statements execute*/
	/* This is experimental at this stage. */
	%let &return_status. = 1;
	
	/* If the period duration is numeric (days), there is no guarantee that the periods will be aligned to the calendar periods.
		So we force the period_aligned_to_calendar flag to be False*/
	%if %datatyp(&period_duration.)=NUMERIC %then %do;
		%put WARNING: Period counting unit is numeric, and hence assumed to be &period_duration. days. 
			Please note that the windowed events will not necessarily align with calendar dates;
		%let period_aligned_to_calendar = False;
		
	%end;
	%else %do;
		%put ................Period Duration: &period_duration.;
	%end;

	%put .....Periods Aligned to Calendar: &period_aligned_to_calendar.;
	%put ................Price Index type: &si_pi_type.;
	%put ............Inflation PI Quarter: &si_pi_qtr.;
	%put ....................Output table: &si_out_table.;

	/* Input validation 1- if si_amount_type is NA, then there can be no Price Index adjustments or cost splitting*/	
	%if &si_amount_type. eq NA %then %do;
		%put WARNING: Amount type is NA, so any Price Index/Discounting adjustments will be forced to NA;
		%let si_amount_col = NA;
		%let si_pi_type=NA;
		%let si_pi_qtr=NA;
	%end;

	/* Input validation 2- if si_pi_qtr is NA, then there can be no Price Index adjustments or cost splitting*/
	%if (&si_pi_qtr. eq NA) and (&si_pi_type. ne NA) %then %do;
		%put WARNING: Price Inflation reference quarter is NA, so any Inflation adjustments will not be applied.;
		%let si_pi_type= NA;
	%end;


	
	/********************************** PROCESSING STARTS****************************************/

	/* Check how periods are defined and assign the right interval function*/	
	%if &period_duration. eq Year %then %do;
		%let interval = 'DTYEAR';
		%let period_duration = 1;		
		%let sqlinterval = yy;
		%let sql_period_duration = 1;	
	%end;
	%else %if &period_duration. eq Halfyear %then %do;
		%let interval = 'DTSEMIYEAR';
		%let period_duration = 1;		
		%let sqlinterval = mm;
		%let sql_period_duration = 6;
	%end;
	%else %if &period_duration. eq Quarter %then %do;
		%let interval = 'DTQUARTER';
		%let period_duration = 1;
		%let sqlinterval = qq;
		%let sql_period_duration = 1;
	%end;
	%else %if &period_duration. eq Month %then %do;
		%let interval = 'DTMONTH';
		%let period_duration = 1;
		%let sqlinterval = mm;
		%let sql_period_duration = 1;
	%end;
	%else %if &period_duration. eq Week %then %do;
		%let interval = 'DTWEEK';
		%let period_duration = 1;
		%let sqlinterval = ww;
		%let sql_period_duration = 1;
	%end;
	%else %if %datatyp(&period_duration.)=NUMERIC %then %do;
		%let interval = 'DTDAY';
		%let sqlinterval = dd;
		%let sql_period_duration = &period_duration. ;
	%end;
	%else %do;
		%put ERROR: Invalid period duration value supplied. ;
	%end;		

	
	/* Subset the SIAL data to fetch only those events that overlap with the profile and forecast windows.*/
	/*proc sql;
		create table work.sial_sub as 
			select 
				sial.*, 
				inp.&si_as_at_date.,
				intnx(&interval., inp.&si_as_at_date., &noofperiodsbefore. * &period_duration., 'SAME' ) as profile_start_date format datetime20.,
				intnx(&interval., inp.&si_as_at_date., &noofperiodsafter. * &period_duration., 'SAME' ) as forecast_end_date format datetime20.
			from 
			sand.&si_sial_table. sial
			inner join sand.&si_table_in. inp on ( sial.&si_id_col. = inp.&si_id_col. 
						and sial.start_date <= intnx(&interval., inp.&si_as_at_date., &noofperiodsafter. * &period_duration., 'SAME' )   
						and sial.end_date >= intnx(&interval., inp.&si_as_at_date., &noofperiodsbefore. * &period_duration., 'SAME' )
			);
	quit; */
	
	/* Delete the output table if it already exists */
	%si_conditional_drop_table(si_cond_table_in=&si_out_table.);


	proc sql;

		connect to odbc(dsn=idi_clean_archive_srvprd);



		create table work._temp_sial_sub as 
			select * from connection to odbc(
				select 
					sial.*, 
					inp.&si_as_at_date.,
					dateadd(&sqlinterval., &noofperiodsbefore. * &sql_period_duration., inp.&si_as_at_date. ) as profile_start_date,
					dateadd(&sqlinterval., &noofperiodsafter. * &sql_period_duration., inp.&si_as_at_date. ) as forecast_end_date
				from 
				&si_sial_table. sial
				inner join &si_table_in. inp on ( sial.&si_id_col. = inp.&si_id_col. 
							and sial.start_date <= dateadd(&sqlinterval., &noofperiodsafter. * &sql_period_duration., inp.&si_as_at_date. )   
							and sial.end_date >= dateadd(&sqlinterval., &noofperiodsbefore. * &sql_period_duration., inp.&si_as_at_date. )
				)
			);

		disconnect from odbc;

	quit;
	
	/* Apply inflation adjustment if required by input parameters*/
	%if &si_pi_type. ne NA %then %do;
		%si_apply_pi_adjustment(si_table_in = work._temp_sial_sub, si_pi_type = &si_pi_type. , si_ref_quarter = &si_pi_qtr. , si_amount_type = &si_amount_type. , 
			si_amount_col = &si_amount_col. );
		%let si_amount_col = &si_amount_col._&si_pi_type._&si_pi_qtr. ;
	%end;


	
	/* This section breaks SIAL events into profile and forecast periods as defined by input macro parameters */
	data &si_out_table. (keep= event_id &si_id_col. department datamart subject_area event_type: &si_as_at_date. start_date end_date event_sdate event_edate 
		currperiod_begin_date currperiod_end_date profile_start_date forecast_end_date ref_period &si_amount_col. );
		
		format event_sdate event_edate currperiod_begin_date currperiod_end_date profile_start_date forecast_end_date datetime20.;

		set work._temp_sial_sub;

		/* Temporarily store the event start & end dates */
		event_sdate = start_date;
		event_edate = min(end_date, datetime() );		
		start_date = .;
		end_date = .;
		full_amount = &si_amount_col. ;
		&si_amount_col. = .;

		/* Preserve Row ID to signify that the broken-up event records belong to same original SIAL event record*/
		event_id = _n_;
		
		/* Find the number of periods that the SIAL event record spans*/
		if symget('period_aligned_to_calendar') eq "True" then do;
			start_period = 0;
			end_period = floor(intck(&interval., event_sdate, event_edate ) );
		end;
		else do;
			start_period = floor( intck(&interval., &si_as_at_date., event_sdate, 'C' ) / &period_duration. );
			end_period = floor( intck(&interval., &si_as_at_date., event_edate, 'C' ) / &period_duration. ) ;
		end;
		
		/* For each SIAL event, break it into separate events with a new start & end date that align with the period start and end dates*/
		do i = start_period to end_period;

			/* Find the beginning and end date of the current period being processed */
			if symget('period_aligned_to_calendar') eq "True" then do;
				currperiod_begin_date = intnx(&interval., event_sdate, i , 'BEGINNING');
				currperiod_end_date = intnx(&interval., event_sdate, i , 'END');
			end;
			else do;
				currperiod_begin_date = intnx(&interval., &si_as_at_date., i * &period_duration., 'SAME' );
				currperiod_end_date = intnx('DTDAY', intnx(&interval., &si_as_at_date., ((i + 1) * &period_duration.) , 'SAME' ), -1 );
			end;


			/* If an event spans multiple periods create a new record for each quarter */
			/* For 0th period of SIAL event record, the start date should be the same as original start date*/
			if i=start_period then
				start_date=event_sdate;
			/* For last period of the SIAL event record, the end date should be the same as original end date*/
			if i=end_period then
				end_date=event_edate;
			/* In cases where the period is not the first period of the event record, the start date should be the begin date of the period */
			if i ne start_period then
				start_date=currperiod_begin_date;
			/* In cases where the period is not the last period of the event record, the end date should be the end date of the period*/
			if i ne end_period then
				end_date=currperiod_end_date;
			
			/* Store the number of days in the newly defined event and the original event record for later use in cost adjustment*/
			subset_duration = 1 + intck('DTDAY', start_date, end_date);
			tot_duration = 1 + intck('DTDAY', event_sdate, event_edate);
			
			if symget('period_aligned_to_calendar') eq "True" then do;
				ref_period = floor( intck(&interval., &si_as_at_date., start_date, 'D')  / &period_duration. );
			end;
			else do;
				ref_period = floor( intck(&interval., &si_as_at_date., start_date, 'C')  / &period_duration. );
			end;

			/* The rollup can calculate either a daily cost or a lump sum cost for an event */				
			if symget('si_amount_type') eq "D" then &si_amount_col. = full_amount*subset_duration ;
			else if symget('si_amount_type') eq "L" then &si_amount_col. = (full_amount/tot_duration)*subset_duration;					
			
			/* Filter the output only to the reference periods specified*/
			if &noofperiodsbefore. <= ref_period <= (&noofperiodsafter. - 1) then
				output;

		end;		
		

	run;	

	/* If the amount type is NA then drop the dummy column NA in the final dataset*/
	%if &si_amount_type. = NA %then %do;
		data &si_out_table. (drop=NA);
			set &si_out_table.;
		run;
	%end;	
	
	/* Clean up temp datasets*/
	%if &si_debug. = False %then %do;
		proc datasets lib=work;
			delete _temp_: ;
		run;
	%end;
	
	
	/* Set return status from this code to be Success*/
	%let &return_status. = 0;
	%put ------------End Macro: si_align_sialevents_to_periods----------------------;
		
	/********************************** PROCESSING ENDS****************************************/


%mend;
