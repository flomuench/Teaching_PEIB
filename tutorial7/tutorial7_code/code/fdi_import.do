***********************************************************************
* 			fdi: import
***********************************************************************
*
*	PURPOSE: import the raw project list
*
*	Author:  	[your name]
*	ID variable: 	projectid
*	Requires: 	cm-fdi-projects.csv
*	Creates:  	fdi_raw.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Import the raw project list
***********************************************************************
{
	* the raw csv is never edited: we read it and save an unchanged copy
* your_code_here (Question 3.3)

save "${fdi_raw}/fdi_raw", replace
}
