***********************************************************************
* 			an: regress
***********************************************************************
*
*	PURPOSE: log solar capacity on cumulative FDI projects
*
*	Author:  	[your name]
*	ID variable: 	country year
*	Requires: 	an_final.dta
*	Creates:  	output/tables/reg_solar_fdi.rtf and reg_solar_fdi_stata.tex
***********************************************************************

***********************************************************************
**# 	PART 1: 	Two regressions and the table
***********************************************************************
{
use "${an_final}/an_final", clear

	* declare the panel: Stata needs a numeric country identifier
encode country, gen(country_id)
xtset country_id year

	* r1: no fixed effects; r2: country and year fixed effects; clustered by country
regress log_solar_gw fdi_cum, vce(cluster country_id)
estimates store r1
* your_code_here (Question 4.9)
estimates store r2

	* export the table with esttab (package estout): Word (.rtf) and LaTeX (.tex)
esttab r1 r2 using "${out_tab}/reg_solar_fdi.rtf", replace ///
	keep(fdi_cum) label b(3) se(3) nostar ///
	mtitles("No fixed effects" "Country and year fixed effects") ///
	stats(N, labels("Observations") fmt(%9.0fc)) ///
	nonotes addnotes("Standard errors clustered by country in brackets.")
esttab r1 r2 using "${out_tab}/reg_solar_fdi_stata.tex", replace booktabs ///
	keep(fdi_cum) label b(3) se(3) nostar ///
	mtitles("No fixed effects" "Country and year fixed effects") ///
	stats(N, labels("Observations") fmt(%9.0fc)) ///
	nonotes addnotes("Standard errors clustered by country in brackets.")
}
