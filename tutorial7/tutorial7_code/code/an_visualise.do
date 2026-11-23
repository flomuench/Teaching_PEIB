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

* your_code_here (Question 4.8)

	* save the figure twice: pdf (sharp in LaTeX and Word) and png (for slides and web)
graph export "${out_fig}/solar_fdi_scatter.pdf", replace
graph export "${out_fig}/solar_fdi_scatter.png", width(2000) replace
}
