* Response to Question 2.1 b): this whole script (created from fdi_correct.do in the student version)
***********************************************************************
* 			fdi: generate
***********************************************************************
*
*	PURPOSE: create new variables
*
*	Author:  	[your name]
*	ID variable: 	project_id
*	Requires: 	fdi_inter.dta
*	Creates:  	fdi_inter.dta
***********************************************************************

***********************************************************************
**# 	PART 1: 	New variables
***********************************************************************
{
use "${fdi_inter}/fdi_inter", clear

	* dummy: 1 if the investing firm is headquartered in China
* Response to Question 4.5 a)
gen china = home_country == "China"

	* investment in billion US dollars
* Response to Question 4.5 a)
gen invest_bn = invest_musd / 1000

save "${fdi_inter}/fdi_inter", replace
}
