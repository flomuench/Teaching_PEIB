***********************************************************************
* 			PEIB Tutorial 7: main do-file
***********************************************************************
*
*	PURPOSE: The ONLY file you run. It defines all folder paths (globals) and then
*		 runs every other do-file in the right order.
*
*	OUTLINE: 	PART 1: Settings, packages and paths (always runs)
*			PART 2: Cleantech FDI projects (prefix fdi)
*			PART 3: Solar capacity (prefix sol)
*			PART 4: Analysis data set: merge, visualise, regress (prefix an)
*		 Each part starts with a bookmark (**#, listed in the Navigator) and sits
*		 between { and }, so that it can be folded.
*
*	Author:  	[your name]
*	Requires: 	cm-fdi-projects.csv, installed-solar-pv-capacity.csv
*	Creates:  	all files in the inter and final data folders and in output
*			(never write a slash followed by a star in a do-file comment:
*			Stata reads it as the start of a block comment)
***********************************************************************

***********************************************************************
**# 	PART 1: 	Settings, packages and paths
***********************************************************************
{
version 17
clear all
set more off
set varabbrev off

	* esttab (package estout) exports the regression table; installed once if missing
capture which esttab
if _rc ssc install estout

	* Stata reads your user name on this computer, so nobody has to type it into a path
global user_name "`c(username)'"

	* lecturer's version: code on GitHub (repo Teaching_PEIB, folder tutorial7), data and output
	* on OneDrive (module folder, week7/project/tutorial7_project)
	* the student version uses Documents/GitHub/tutorial7_code and OneDrive/tutorial7_project
if "`c(os)'" != "Windows" {
	display as error "The lecturer's version is set up for Windows only."
	exit 198
}
global code_root "C:/Users/${user_name}/Documents/GitHub/Teaching_PEIB/tutorial7/tutorial7_code_lecturer"
global data_root "C:/Users/${user_name}/OneDrive - University College London/UCL teaching/Political Economy of International Business/PEIB_Florian_Irakli/lectures_tutorials/week7/project/tutorial7_project"
	* check: show both paths and test that both folders exist (1 = exists)
* Response to Question 3.1 c)
display "${code_root}"
display "${data_root}"
mata: direxists("${code_root}"), direxists("${data_root}")

global code "${code_root}/code"

global fdi_raw   "${data_root}/data/fdi/raw"
global fdi_inter "${data_root}/data/fdi/inter"
global fdi_final "${data_root}/data/fdi/final"

* Response to Question 3.2
global sol_raw   "${data_root}/data/sol/raw"
global sol_inter "${data_root}/data/sol/inter"
global sol_final "${data_root}/data/sol/final"

global an_final  "${data_root}/data/an/final"

global out_fig   "${data_root}/output/figures"
* Response to Question 3.2
global out_tab   "${data_root}/output/tables"
}

***********************************************************************
**# 	PART 2: 	Cleantech FDI projects (fdi)
***********************************************************************
{
	* switch a step on with if (1) and off with if (0)

	* 2.1: import the raw project list
	*   Requires: cm-fdi-projects.csv
	*   Creates:  fdi_raw.dta
if (1) do "${code}/fdi_import.do"

	* 2.2: clean: keep and rename variables (no values change)
	*   Requires: fdi_raw.dta
	*   Creates:  fdi_inter.dta
if (1) do "${code}/fdi_clean.do"

	* 2.3: correct: fix country names, drop projects that did not go ahead
	*   Requires: fdi_inter.dta
	*   Creates:  fdi_inter.dta
if (1) do "${code}/fdi_correct.do"

	* 2.4: generate: new variables
	*   Requires: fdi_inter.dta
	*   Creates:  fdi_inter.dta
if (1) do "${code}/fdi_generate.do"

	* 2.5: aggregate: from projects to country-years
	*   Requires: fdi_inter.dta
	*   Creates:  fdi_final.dta
if (1) do "${code}/fdi_aggregate.do"
}

***********************************************************************
**# 	PART 3: 	Solar capacity (sol)
***********************************************************************
{
* Response to Question 4.4
	* 3.1: import the raw solar capacity file
	*   Requires: installed-solar-pv-capacity.csv
	*   Creates:  sol_raw.dta
if (1) do "${code}/sol_import.do"

	* 3.2: clean: rename variables
	*   Requires: sol_raw.dta
	*   Creates:  sol_inter.dta
if (1) do "${code}/sol_clean.do"

	* 3.3: correct: drop rows that are not countries
	*   Requires: sol_inter.dta
	*   Creates:  sol_inter.dta
if (1) do "${code}/sol_correct.do"

	* 3.4: generate: log of solar capacity
	*   Requires: sol_inter.dta
	*   Creates:  sol_final.dta
if (1) do "${code}/sol_generate.do"
}

***********************************************************************
**# 	PART 4: 	Analysis data set (an)
***********************************************************************
{
	* 4.1: merge solar capacity and FDI by country and year
	*   Requires: sol_final.dta, fdi_final.dta
	*   Creates:  an_final.dta
if (1) do "${code}/an_merge.do"

	* 4.2: visualise: one figure
	*   Requires: an_final.dta
	*   Creates:  solar_fdi_scatter.pdf and .png
if (1) do "${code}/an_visualise.do"

	* 4.3: regress: one regression table
	*   Requires: an_final.dta
	*   Creates:  reg_solar_fdi.rtf and reg_solar_fdi_stata.tex
if (1) do "${code}/an_regress.do"
}
