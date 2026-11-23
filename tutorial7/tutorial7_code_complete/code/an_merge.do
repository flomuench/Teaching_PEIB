***********************************************************************
* 			an: merge
***********************************************************************
*
*	PURPOSE: merge solar capacity with FDI projects
*
*	Author:  	[your name]
*	ID variable: 	country year
*	Requires: 	sol_final.dta, fdi_final.dta
*	Creates:  	an_final.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Merge solar capacity and FDI
***********************************************************************
{
use "${sol_final}/sol_final", clear

merge 1:1 country year using "${fdi_final}/fdi_final"
	* paste the merge table that Stata shows here as a comment

	* FDI country-years without solar data (_merge == 2) are dropped
drop if _merge == 2
drop _merge

	* country-years without a project have no FDI
replace n_projects = 0 if n_projects == .
replace invest_bn  = 0 if invest_bn == .

	* running total of projects announced in each country since 2000
bysort country (year): gen fdi_cum = sum(n_projects)
lab var fdi_cum "Cumulative FDI projects"

save "${an_final}/an_final", replace
}
