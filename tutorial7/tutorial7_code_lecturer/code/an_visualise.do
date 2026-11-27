***********************************************************************
* 			an: visualise
***********************************************************************
*
*	PURPOSE: solar capacity against cumulative FDI projects
*
*	Author:  	[your name]
*	ID variable: 	country
*	Requires: 	an_final.dta
*	Creates:  	output/figures/solar_fdi_scatter.pdf and .png
***********************************************************************

***********************************************************************
**# 	PART 1: 	Scatter plot, saved as pdf and png
***********************************************************************
{
use "${an_final}/an_final", clear

* Response to Question 4.8 a)
twoway scatter solar_gw fdi_cum if year == 2024 & solar_gw > 0, yscale(log) ///
	ylabel(0.00001 "0.00001" 0.001 "0.001" 0.1 "0.1" 10 "10" 1000 "1,000", angle(0)) ///
	xtitle("Cleantech FDI projects announced since 2000") ///
	ytitle("Installed solar capacity in 2024 (GW, log scale)")

	* save the figure twice: pdf (sharp in LaTeX and Word) and png (for slides and web)
graph export "${out_fig}/solar_fdi_scatter.pdf", replace
graph export "${out_fig}/solar_fdi_scatter.png", width(2000) replace
}
