/*********************************************************************************************************
DESCRIPTION: Generic macro that executes and SQL file on the database and schema of choice.

INPUT:
filepath = path_to_file\filename, which is the SQL script to be executed
db_odbc = IDI database odbc name on which the SQL script is to be executed
db_schema = Schema on which the SQL script is to be executed
replace_string = If the SQL code has a placeholder in it that needs to be replaced with
	the actual target schema name, use this to specify that placeholder string.

OUTPUT:
Executes the SQl script on the database and schema of choice

AUTHOR: V Benny

DEPENDENCIES:


NOTES: 
NA

HISTORY:
07 Sep 2017 VB v1

*********************************************************************************************************/
%macro si_run_sqlscript(filepath = , db_odbc = , db_schema = , replace_string = "{schemaname}")

filename file0 %tslit(&filepath.);

	data _null_;
		infile file0 recfm=f lrecl=32767 pad;
		input @1 sialuninst $32767.;
		sqlscript = tranwrd(sialuninst, &replace_string. , &db_schema.);
		call symputx('sqlscript', sqlscript);
	run;

	proc sql;
		connect to odbc(dsn=&db_odbc.);
		execute(&sqlscript.) by odbc;
	quit;

%mend;