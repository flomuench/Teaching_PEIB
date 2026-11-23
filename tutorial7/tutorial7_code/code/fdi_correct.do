***********************************************************************
* 			fdi: correct
***********************************************************************
*
*	PURPOSE: fix country names; drop projects that did not go ahead
*
*	Author:  	[your name]
*	ID variable: 	project_id
*	Requires: 	fdi_inter.dta
*	Creates:  	fdi_inter.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	Fix country names, drop projects that did not go ahead
***********************************************************************
{
use "${fdi_inter}/fdi_inter", clear

	* two destination countries are spelled differently from the solar data
* your_code_here (Question 3.5)

	* projects that were cancelled, paused or closed are not investments
drop if inlist(status, "Cancelled", "Paused", "Closed")

save "${fdi_inter}/fdi_inter", replace
}
