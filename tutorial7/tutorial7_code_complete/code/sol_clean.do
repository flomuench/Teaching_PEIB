***********************************************************************
* 			sol: clean
***********************************************************************
*
*	PURPOSE: rename variables; no value changes
*
*	Author:  	[your name]
*	ID variable: 	country year
*	Requires: 	sol_raw.dta
*	Creates:  	sol_inter.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Rename variables
***********************************************************************
{
use "${sol_raw}/sol_raw", clear

	* short names: country, iso3, year, solar_gw
rename (entity code solar__total_gw) (country iso3 solar_gw)
lab var solar_gw "Installed solar PV capacity (GW)"

save "${sol_inter}/sol_inter", replace
}
