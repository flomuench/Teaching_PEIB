***********************************************************************
* 			sol: import
***********************************************************************
*
*	PURPOSE: import the raw solar capacity file
*
*	Author:  	[your name]
*	ID variable: 	entity year
*	Requires: 	installed-solar-pv-capacity.csv
*	Creates:  	sol_raw.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Import the raw solar capacity file
***********************************************************************
{
	* the raw csv is never edited: we read it and save an unchanged copy
* your_code_here (Question 4.1)

save "${sol_raw}/sol_raw", replace
}
