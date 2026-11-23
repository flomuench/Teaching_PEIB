***********************************************************************
* 			fdi: clean
***********************************************************************
*
*	PURPOSE: keep and rename variables; no value changes
*
*	Author:  	[your name]
*	ID variable: 	project_id
*	Requires: 	fdi_raw.dta
*	Creates:  	fdi_inter.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Keep and rename variables
***********************************************************************
{
use "${fdi_raw}/fdi_raw", clear

	* keep 8 of the 28 variables
keep projectid parentcompany companycountryhq projectstatus destinationcountry ///
	yearannounced technology capitalinvestmentusm

	* short names
rename (projectid parentcompany companycountryhq projectstatus destinationcountry ///
	yearannounced technology capitalinvestmentusm) ///
	(project_id parent home_country status country year technology invest_musd)

lab var invest_musd "Announced capital investment (million US dollars)"

save "${fdi_inter}/fdi_inter", replace
}
