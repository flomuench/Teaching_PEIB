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
import delimited "${sol_raw}/installed-solar-pv-capacity.csv", varnames(1) clear

save "${sol_raw}/sol_raw", replace
}
