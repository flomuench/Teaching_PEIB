***********************************************************************
* 			fdi: aggregate
***********************************************************************
*
*	PURPOSE: collapse projects to destination country-years
*
*	Author:  	[your name]
*	ID variable: 	country year
*	Requires: 	fdi_inter.dta
*	Creates:  	fdi_final.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	From projects to country-years
***********************************************************************
{
use "${fdi_inter}/fdi_inter", clear

	* each row is one project
gen n_projects = 1

	* number of projects and total announced investment per country and year
* Response to Question 4.6 a)
collapse (sum) n_projects invest_bn, by(country year)

save "${fdi_final}/fdi_final", replace
}
