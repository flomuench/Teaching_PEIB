***********************************************************************
* 			sol: generate
***********************************************************************
*
*	PURPOSE: logarithm of installed solar capacity
*
*	Author:  	[your name]
*	ID variable: 	country year
*	Requires: 	sol_inter.dta
*	Creates:  	sol_final.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Log of solar capacity
***********************************************************************
{
use "${sol_inter}/sol_inter", clear

	* the log is only defined for positive values
* your_code_here (Question 4.5)
lab var log_solar_gw "Log installed solar PV capacity"

save "${sol_final}/sol_final", replace
}
