***********************************************************************
* 			sol: correct
***********************************************************************
*
*	PURPOSE: give Kosovo a proper code; drop aggregates
*
*	Author:  	[your name]
*	ID variable: 	country year
*	Requires: 	sol_inter.dta
*	Creates:  	sol_inter.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Drop rows that are not countries
***********************************************************************
{
use "${sol_inter}/sol_inter", clear

	* Kosovo carries the code OWID_KOS; the usual code is XKX
replace iso3 = "XKX" if iso3 == "OWID_KOS"

	* rows without a country code, or with an OWID_ code, are aggregates
drop if iso3 == "" | strpos(iso3, "OWID") > 0

save "${sol_inter}/sol_inter", replace
}
