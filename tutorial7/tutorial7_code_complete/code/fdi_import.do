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
import delimited "${fdi_raw}/cm-fdi-projects.csv", varnames(1) bindquote(strict) encoding(UTF-8) clear

save "${fdi_raw}/fdi_raw", replace
}
