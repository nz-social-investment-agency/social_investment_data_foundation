/*********************************************************************************************************
TITLE: si_get_cohort.sas

DESCRIPTION: this is a test population to feed into the social investment data foundation

INPUT: 
To be determined by the user. In this example
sofie_clean.person_waves = eligibility and tracking info
sofie_clean.person_fixed = person vars that stay constant
sofie_clean.hq_id = interview date is stored in here


OUTPUT:
To be determined by the user. In this example
si_sofie_cohort = table with a list of ids an as at dates

AUTHOR: E Walsh

DATE: 05 May 2017

DEPENDENCIES: 
Requires access to the IDI_Clean.sofie_clean schema

NOTES: 

HISTORY: 
05 May 2017 EW v1 example
*********************************************************************************************************/

%put INFO: This is the place for you to insert your code. The final table needs snz_uid and an as at date. See ../examples ;

