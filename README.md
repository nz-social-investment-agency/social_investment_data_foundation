## Social Investment Data Foundation

## Overview
The Social Investment Data Foundation is a group of scripts and macros pulled together into a process-flow, with the purpose of creating an analysis-ready dataset very quickly with all the required variables. Given a SAS dataset consisting of individuals in the IDI and dates for each of these individuals, this process flow creates the following-

* A set of static and slow changing characteristics such as demographics for each individual (as on the date for that individual).
* A set of service metrics that are the summarised versions of the SIAL tables, for example- duration on benefit, total cost on benefit, number of times on benefit.
* Outcome variables that involve complex logic that doesn't fit into the above two examples- for example, the highest educational qualification as on the given date.


## Dependencies
* It is necessary to have an IDI project if you wish to run the code. Visit the Stats NZ website for more information about this.
* It is necessary to download and run the `social_investment_analytical_layer` scripts so that the SIAL tables exist for creating the service metrics. Note when you create the SIAL tables the scripts will attempt to access to the following schemas in IDI_Clean (or the archives if you wish to use an older refresh). 
	* acc_clean
	* cor_clean
	* cyf_clean
	* data
	* dia_clean
	* moe_clean
	* moh_clean
	* moj_clean
	* msd_clean
	* pol_clean
	* security
* If there are specific schemas listed above that you don't have access to, the **SIAL** main script (after it finishes running) will give you a detailed report on which SIAL tables were not created and why. You can use the Data Foundation to roll up only those SIAL tables that were created. If you attempt to run the data foundation to create a variable from SIAL table that does not exist in your schema, the variables won't be created. You won't get an error, the variable just won't exist.

## How it Works
You are given the provision to create a SAS dataset with individuals and a date for each individual. Once this dataset is supplied to the Data Foundation, it will perform the following steps on the dataset-

* A set of static and slow changing characteristics such as demographics for each individual are created, which will be as on the date given for that individual;
* The timeline for each individual is split into two observation windows, based on the date supplied for the individual- one for the history of that individual before that time point, and one for the recorded future of the individual after that time point. These observation windows are called profile and forecast windows respectively.
* These profile and forecast windows are further sub-divided into specific periods. The periods can be yearly/half-yearly/quarterly/monthly/weekly or any period unit (in days) as defined by the user.
* The events in the SIAL tables are then broken down such that the events align with the periods. What this means is that an event that span multiple periods will be broken down into several events, each that sit within that period. The costs are also adjusted to align with these broken events. The total costs for these broken down events will be the same as the cost for the whole event.
* A set of service metrics are then created for that individual for each period, both in the profile and forecast observation windows. These service metrics are derived from the `social_investment_analytical_layer` (SIAL) tables. The service metrics may be total duration spent by the individual in a specific event type for a particular period, or the total cost incurred for the individual for an event type during a period, or the counts of events in the period and so on. 
* In case of cost-related service metrics, the data foundation can automatically apply inflation adjustments and perform discounting, if required by the user.
* A set of outcome variables are also created. In the current version 1.0.0, there is only one outcome variable (highest qualification as on the given date), but there is provision for the users to define their own outcome variables that plug right into the code. You are invited to share the code for the outcome variables that you create and contribute to this repository so that others can reuse it.

Refer to the User Guide (once it is available) for more details.


## Folder descriptions
This folder contains all the code necessary to build characteristics and service metrics. Code is also given to create an outcome variable (highest qualification) for use and as an example of how the more complex variables are created and added to the main dataset.

**docs:** This folder contains the detailed user guide (once it is made available).

**examples:** This folder contains an example for training purposes.

**include:** This folder contains generic formatting scripts.

**logs:** This folder is used to store the output logs that SAS generates. This is used for the cross agency outcomes that have a lot of code to run.

**sasautos:** This folder contains SAS macros. All scripts in here will be loaded into the SAS environment during the running of setup in the main script.

**sasprogs:** This folder contains SAS programs. The main script that builds the dataset is located in here as well as the control file that needs to be populated with parameters for your analysis. 

**unittests:** This folder contains unit tests for those who wish to debug the code.


Note `sasprogs` is the only folder with scripts you need to edit to create a data foundation, unless you want to make changes to any source code.

## Installation
1. Ensure you have an IDI project so you can run the code.
2. Confirm you have the SIAL tables are in your schema. If you do not then you will have to download the social investment analytical layer zip file from Github and follow the installation instructions in that repository first.
3. Download the zipped file for the social investment data foundation from Github.
4. Email the zipped file(s) to access2microdata@stats.govt.nz and ask them to move it into your project folder.
5. Unzip the files into your project.


## Instructions to build the social investment data foundation
It is strongly recommended that first time users run the data foundation examples to become familiar with the software framework first.

## Example

This example involves running the SI data foundation with ~ top 10000 SNZ_uid's from the personal details table based on the first day of each person’s birthday month in 2014. It is approximately 10000 because we confirm they are attached to the spine and that they have a birth month.

The necessary example scripts are contained in examples folder. There are four scripts you will run as part of this example:

1. `examples/si_get_cohort_example_pd.sas` creates the population. For the example this is a population of the ~ top 10000 snz_uid's from the personal details table and a date e.g. 01 June 2014.
2. `examples/si_control_example_pd.sas` is where you specify the variables you want to create.
3. `examples/si_main_example_pd.sas` is where you create all of the variables. There are many of them so they are created in separate tables depending on their type.
4. `examples/si_join_tables_manual_example_pd.sas` is what creates the data foundation, an analysis ready dataset. It uses the output from `examples/si_main_example_pd.sas` and simply joins the variables onto the population so you have one dataset to work off. This manual example illustrates how you would do subject matter expertise selection. If you wish to do statistical selection a separate script to identify correlations and clustered variables would be required.

### Part A: Create population
1. Start a new SAS session
2. Open and run `examples/si_get_cohort_example_pd.sas`. It will generate a dataset with a list of snz_uid's, each with a date (in datetime format). In this example all dates are set to 1 "birthmonth” 2014.

### Part B: Specify arguments
1. Open `examples/si_control_example_pd.sas`. This is where you specify the arguments needed to build the social investment data foundation, or what variables you want to generate. Read the header to understand all the variables. Variables with data validation have their possible options specified in the curly brackets e.g. {True | False}.
2. Scroll down to the datalines - you can easily spot them because they are yellow in SAS. The first column represents the variable name and the second column represents the variable value. Since this is an example the second column is already populated, so you don't need to change anything here. When you run the SI data foundation you will need to specify your own arguments.
3. Hit run on this script so SAS can identify the variables you are after. It will generate a wide dataset containing each argument. The script also puts these arguments into global macro variables.

### Part C: Generate variables
1. Now that you have specified a population (step A) and some arguments needed for the SI data foundation (step B) you are ready to run the main scripts. Open `examples/si_main_example_pd.sas`
2. Scroll down to the first let statement. This is where you specify where you put the data foundation root folder. You will need to change this to reflect where you put the files.
3. Save `examples/si_main_example_pd.sas`
4. Scroll down a few lines to a set of include statements Notice that they refer to the two files that you created in steps 1 and 2.
5. Run `examples/si_main_example_pd.sas`. This should only take a few minutes

#Look at the results
Open up the work library and explore the tables. The script `examples/si_main_example_pd.sas` explains what some of the tables represent. Refer to the documentation in the documents folder or the Wiki for descriptions of each variable.
Note you should receive the warning `WARNING: Amount type is NA, so any Price Index/Discounting adjustments will be forced to NA`. This is OK and means that when there are no available costs, they cannot be inflated, deflated, or discounted. Tables such as the police tables (as at June 2017) do not have costs available.
After looking at the results you would have noticed multiple tables were created with many variables. Usually you would want these all in one dataset so you can begin your analysis. The next steps help you do this.

### Step D: Create your Social Investment data foundation (an analysis ready dataset)
1. Open `examples/si_join_tables_manual_example_pd.sas` This shows you a manual method of selecting a subset of the variables to be joined into a single table using a datastep and hash objects. You can modify the datastep to make sure you are selecting the variables you want.
In future releases it is intended that an automated version will be made available. The automated method will return all available variables for your population. Depending on your arguments in step 2 this can be over a thousand variables. Generally, you only want to choose this method if you have an easy way to choose the variables you want to analyse (1000+ is too many). For example variable clustering or correlation testing you can apply to a whole dataset (with categorical and numeric variables).
2. Run `examples/si_join_tables_manual_example_pd.sas`. If you haven’t changed the control file arguments you should find that a 9928 x 164 table has been generated.
3. You are finished. Your Social Investment data foundation (an analysis ready dataset) is ready to use.

**End of example**

## Running the SI data foundation on your own population
* This section repeats the steps from the example, except the population is not defined for you, these instructions will help you create your own population

## Instructions - Running the SI data foundation with your own population. 
* The necessary scripts you need to modify are contained in sasprogs folder. There are four scripts in here you will run:
1. `sasprogs/si_get_cohort.sas` reads in your population. 
2. `sasprogs/si_control.sas` is where you specify the arguments used to build the data foundation.
3. `sasprogs/si_main.sas` is where you create all of the variables. There are many of them so they are created in separate tables depending on their type.
4. You can join the tables together as you please to create the data foundation, an analysis ready dataset. There are so many combinations it has been up to the user to choose how they build their final dataset. An example of how one was built can be found in `examples/si_join_tables_manual_example_pd.sas`

### Step A: Create population
1. Start a new SAS session
2. Open `sasprogs/si_get_cohort.sas`.
3. Populate with the code necessary to build your population: The inputs will vary depending on what populations you are interested but the final output should be a table that has a set of ids and a date for each. The date is the reference date for the variables to be created as at and needs to have a datetime format.
4. Run the code and make sure you are happy with the output that has been produced (a table that has a set of ids a date (in datetime format) for each). Refer to the example folder if you want an example.
5. When you are happy make note of: the table name, the id column name and the date column name.

### Step B: Specify arguments
1. Open `sasprogs\si_control.sas`. This is where you specify the arguments needed to build the social investment data foundation, or what variables you want to generate. Read the header to understand all the variables. 
2. Scroll down to the yellow datalines and specify your arguments after the comma. Do not put spaces before or after your arguments and make sure all of the arguments have a value, don't leave them blank. If you have trouble remember what the arguments are referred to the header or check `examples/si_control_example_pd.sas` for an example.
3. Make sure the values for `si_pop_table_out`, `si_id_col` and `si_asat_date` match what you made note of in step 1e.
4. Hit run on this script so SAS can identify the variables you are after. It will generate a wide dataset and also put all your arguments into global macro variables.

### Step C: Generate variables
1. Now that you have specified a population (step A) and some arguments needed for the SI data foundation (step B) you are ready to run the main scripts. Open` sasprogs/si_main.sas`.
2. Scroll down to the first let statement. This is where you specify where you put the data foundation root folder. You will need to change this to reflect where you put the files.
3. Save `sasprogs/si_main.sas`.
4. Scroll down a few lines to a set of include statements Notice that they refer to the two files that you created in steps 1 and 2. Unless you've changed the names of these files (which you don't need to do) you don't need to make changes here.
5. Run `sasprogs/si_main.sas`. If your population is < 100,000 (and doesn’t require main benefits or pharmaceutical data) it should only take a few minutes. If it is bigger you could go get a coffee.

#Look at the results
Open up the work library and explore the tables. The script `sasprogs/si_main.sas` explains what some of the tables represent. Refer to the documentation in the documents folder for descriptions of each variable.
Note you should receive the warning `WARNING: Amount type is NA, so any Price Index/Discounting adjustments will be forced to NA`. This is OK and means that when there are no available costs, they cannot be inflated, deflated, or discounted.
If you don't receive this warning that's OK too, it means all the costs you've asked for are available, or you've not asked for costs.
After looking at the results you would have noticed multiple tables were created with many variables. Usually you would want these all in one dataset so you can begin your analysis. The next steps help you do this.

### Step D: Create your Social Investment data foundation (an analysis ready dataset)
1. Open `examples/si_join_tables_manual_example_pd.sas` This shows you a manual method of selecting a subset of the variables to be joined into a single table using a datastep and hash objects. You can modify the datastep to make sure you are selecting the variables you want.
In future releases it is intended that an automated version will be made available. The automated method will return all available variables for your population. Depending on your arguments in step 2 this can be over a thousand variables. Generally, you only want to choose this method if you have an easy way to choose the variables you want to analyse (1000+ is too many). For example variable clustering or correlation testing you can apply to a whole dataset (with categorical and numeric variables).
2. Use `examples/si_join_tables_manual_example_pd.sas` to give you an idea of how to write a script to manually join the tables. Save this script in `sasprogs`.
3. Run the script that you just created and confirm that it runs without error. 
4. You are finished. Your Social Investment data foundation (an analysis ready dataset) is ready to use.

## Advanced users

Advanced users who are interested in adding additional variables to the code can do so. The code is written in a manual way to help you write your additions in an automated way.

You can change the scripts in the `sasautos` folder if you want to do this. The scripts ending in `_ext` are the scripts you can add to.

Additional characteristic variables can be added into the `sasautos/si_get_characteristics_ext.sas` script.
Additional outcomes variables can be added to the `sasautos/si_get_outcomes_ext.sas` script.

## Getting Help
A guide will be made available in due course. For now if you have any questions email

info@siu.govt.nz
