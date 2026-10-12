**********************************************************************
* 			Master file: UCL PEIB
*			Purpose: Allocate Students into groups
***********************************************************************
*																	  
*	PURPOSE: Randomly allocate students into seminar small discussion groups & to presentation groups 
*																	  
*	OUTLINE: 	PART 1: Set standard settings & install packages	  
*				PART 2: Prepare dynamic folder paths & globals		  
*				PART 3: Allocate students into random seating order for weekly seminar 
*				PART 4: Allocate students into seminar group presentations
*				PART 5: Allocate students into groups for data and technical report 
*																	  
*																	  
*	Authors:  	Florian Muench
*	ID variable: student_number	  					  
*	Requires: 	 									  
***********************************************************************
**# 	PART 1: 	Set standard settings & install packages			  
***********************************************************************
{
	* set standard settings
version 18
clear all
graph drop _all
scalar drop _all
set varabbrev off // stops stata from referring to variables if only one part is the same
set graphics off /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c

	* install packages

/*	* visualisation
ssc install betterbar, replace
ssc install stripplot, replace
ssc install blindschemes, replace /* for plotplain --> scheme for graphic2al visualisations */
ssc install scheme-burd, replace

	* data transformation
ssc install winsor, replace
ssc install winsor2, replace
ssc install kdens
ssc install ihstrans

	* data analysis
ssc install ietoolkit, replace /* for iebaltab */
ssc install randtreat
ssc install mdesc , replace
net install http://www.stata.com/users/kcrow/tab2docx
ssc install asdoc, replace
net from https://www.sealedenvelope.com/
net install time.pkg
net install http://www.stata.com/users/kcrow/tab2docx
ssc install moremata
*/

	* define graph scheme for visual outputs
*set scheme plotplain
*set scheme burd
}

***********************************************************************
**# 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************
{
		* Mac & Windows root 
if `"`c(os)'"' == "MacOSX"    global  root   `"/Users"'
if `"`c(os)'"' == "Windows"   global  root   `"C:/Users"'

		* One Drive - data
	if  "`c(username)'" == "flori" {
	global onedrive =  "${root}/`c(username)'/OneDrive - University College London\UCL teaching\Political Economy of International Business/Students/26_27"
	} 

		* Github - code
global github = "${root}/`c(username)'/Documents/GitHub/Teaching_PEIB"

	
		* output
global output   = "${onedrive}"


			* set seeds for replication
set sortseed 10032025
}

***********************************************************************
**# 	PART 3: 	Data processing
***********************************************************************
{
import excel using "${onedrive}/tutorial_groups", clear firstrow

gen group_number = . 
	replace group_number = 1 if Group == "Tutor group 2"
	replace group_number = 2 if Group == "Tutor group 3"
	replace group_number = 3 if Group == "Tutor group 4"
	replace group_number = 4 if Group == "Tutor group 5"
	replace group_number = 5 if Group == "Tutor group 6"

tab group_number	

* Derek only sent me an Excel file group number but not date or time of the tutorial (or location); used timetable to find it out
gen group_time = ""
	replace group_time = "Fri, 11-12" if Group == "Tutor group 2"
	replace group_time = "Fri, 14-15" if Group == "Tutor group 3"
	replace group_time = "Fri, 15-16" if Group == "Tutor group 4"
	replace group_time = "Fri, 16-17" if Group == "Tutor group 5"
	replace group_time = "Fri, 12-13" if Group == "Tutor group 6"
	

/* 26/27:
In week 1, there is no student presentation.
In week 10, there is no student presentation of weekly content, cause all students present.
In weeks 6,7,8 there is no student presentation cause we will focus on scientific practices + academic writing.

So there are 10 - 5 = 5 weeks for presentations. 

There are 5 tutorial groups. 
	4 groups a 17 students. Here, one can have 4 groups with each 3 students and 1 group with 4 students. 5 groups in total.
	1 group with 15 students. Here, we have 5 groups with each 3 students.

*/
}
***********************************************************************
**# 	PART 4: 	Allocate students into random seating order for weekly seminar
***********************************************************************
{
* Loops: Loop over each week (10), use strata for student groups

* initial allocation
	* Loop 1: week 2 to week 10 (9 weeks)
gen week = 1
forvalues w = 2(1)10 {
	global wseed`w' "10032025`w'"
		
		* Content
			* divide each seminar group into 5 sub-groups with about min. 3 & max. 4 students
		randtreat, gen(group_seating_assignment) replace setseed($wseed`w') multiple(5) misfits(strata) strata(group_number)
		replace group_seating_assignment = 5 if group_seating_assignment == 0
		
		sort group_number group_seating_assignment
		
		replace week = week + 1
		export excel group_number group_time Lastname Firstname group_seating_assignment using "${output}/week`w'_seating_order", replace firstrow(var)
		
}

* allocation with updated student list
/*
drop week 
gen week = 4
forvalues w = 4(1)11 {
	global wseed`w' "10032025`w'"
		
		* Content
			* divide each seminar group into 6 sub-groups with about min. 3 & max. 4 students
		randtreat, gen(group_seating_assignment) replace setseed($wseed`w') multiple(6) misfits(strata) strata(group_number)
		replace group_seating_assignment = 6 if group_seating_assignment == 0
		
		sort group_number group_seating_assignment
		
		replace week = week + 1
		export excel group_tutorial group_room student_name group_seating_assignment using "${output}/week`w'_seating_order", replace firstrow(var)
*/		
}

}
***********************************************************************
**# 	PART 5: 	Allocate students into seminar group presentation
***********************************************************************
{
* initial allocation
randtreat, gen(group_presentation_assignment) replace setseed(10032025) multiple(5) misfits(strata) strata(group_number)
replace group_presentation_assignment = 5 if group_presentation_assignment == 0
by group_number: tab group_presentation_assignment
drop week
gen week = .
	replace week = 2 if group_presentation_assignment == 1
	replace week = 3 if group_presentation_assignment == 2
	replace week = 4 if group_presentation_assignment == 3
	replace week = 5 if group_presentation_assignment == 4
	replace week = 9 if group_presentation_assignment == 5
	
gen date = ""
replace date = "16/10/2026" if week == 2
replace date = "23/10/2026" if week == 3
replace date = "30/10/2026" if week == 4
replace date = "06/11/2026" if week == 5
replace date = "11/12/2026" if week == 9


sort group_number group_presentation_assignment
  
export excel group_number group_time Lastname Firstname group_presentation_assignment week date using "${output}/group_seminar_presentation", replace firstrow(var)

export excel group_number group_time Lastname Firstname PorticoStudentnumber Emailaddress group_presentation_assignment week date using "${output}/group_seminar_presentation_internal", replace firstrow(var)


* updated allocation with new student list 17.10.25
/*
randtreat if presented == 0, gen(group_presentation_assignment) replace setseed(10032025) multiple(6) misfits(strata) strata(group_number)
replace group_presentation_assignment = 6 if group_presentation_assignment == 0
bysort group_number: tab group_presentation_assignment
drop week
gen week = group_presentation_assignment + 4
gen date = ""
replace date = "16/10/2025" if inlist(student_number, 25114999, 25030635, 25116186, 25113680, 19031589, 25126427, 25115474)
replace week = 3 if date == "16/10/2025"
replace date = "23/10/2025" if inlist(student_number, 25144656, 25049563, 25116590, 25059492, 25111492, 25093545, 25136127)
replace week = 4 if date == "23/10/2025"
replace date = "30/10/2025" if week == 5
replace date = "13/11/2025" if week == 6
replace date = "20/11/2025" if week == 7
replace date = "27/11/2025" if week == 8
replace date = "04/12/2025" if week == 9
replace date = "11/12/2025" if week == 10

sort group_number group_presentation_assignment
  
export excel group_tutorial group_room student_name group_presentation_assignment week date using "${output}/group_seminar_presentation_1710", replace firstrow(var)
*/


}

***********************************************************************
**# 	PART 6: 	Allocate students into group research project
***********************************************************************
/*
* Import & Save
import excel using "${onedrive}/Exam_Group/Preferences Technical or Data Report.xlsx", clear firstrow

* k19031589

replace Choice = "Data Report" if Username == "k25136127"


gen student_number = substr(Username,2,.)
destring student_number, replace


save "${onedrive}/Exam_Group/preferences_technical_data_report.dta", replace

* import full student list to identify those that did not submit their preference
import excel using "${onedrive}/student_list_with_seminar_group.xlsx", clear firstrow sheet(update_1710)


* 19031589
drop E
*tostring student_number, replace

gen group_number = . 
	replace group_number = 1 if group_tutorial == "2_3"
	replace group_number = 2 if group_tutorial == "4_5"
	replace group_number = 3 if group_tutorial == "5_6"

save "${onedrive}/Exam_Group/student_list_1710.dta", replace

* merge student list with preferences
merge 1:1 student_number using "${onedrive}/Exam_Group/preferences_technical_data_report.dta"


* necessary to drop inactive students? 
drop if inlist(student_number, 25139788, 25047960, 25155047, 25075723, 25044015, 24087720, 25095713, 25129213, 25141797)

* allocation students w/o submission to technical report
replace Choice = "Technical Report" if _merge == 1

encode Choice, gen(choice)

* Randomize students into groups of 3-4 stratifying by seminar group to be able to work on group assignments during seminar
	* data report
		* low number of students, allocate by hand
gen group_group_assignment = .
replace group_group_assignment = 1 if student_name == "CAI, REBECCA" | student_name == "LAI, ERIC"
replace group_group_assignment = 2 if inlist(student_name, "FRISCHMANN, SARAH", "JARUWAT, TAK", "LEE, HYUNSEUNG")

replace group_group_assignment = 3 if student_name == "WEI, LAI" | student_name == "BONSEY, HUGO"
replace group_group_assignment = 4 if inlist(student_name, "TAN, WEI TING", "LEE, MARVIN", "KHARMARBHA, TANMAY")


replace group_group_assignment = 5 if inlist(student_name, "LIN, HE-YA", "HASHIM, ENZO")
replace group_group_assignment = 6 if inlist(student_name, "SHI, QIANYE", "PODOVSOVNIK, VICTORIA")


	* technical report
		* do randomization by seminar group into groups of 3 students
tab Choice group_number // 15, 16, 12
	
randtreat if Choice == "Technical Report" & group_number == 1, gen(group_assignment1) replace setseed(10032025) multiple(5) misfits(global)
randtreat if Choice == "Technical Report" & group_number == 2, gen(group_assignment2) replace setseed(10032025) multiple(5) misfits(global)
randtreat if Choice == "Technical Report" & group_number == 3, gen(group_assignment3) replace setseed(10032025) multiple(4) misfits(global)

replace group_group_assignment = group_assignment1 + 7 if group_assignment1 != .
replace group_group_assignment = group_assignment2 + 14 if group_assignment2 != .
replace group_group_assignment = group_assignment3 + 21 if group_assignment3 != .

	

	* allocate misfits in technical report
sort group_tutorial group_group_assignment
br student_name Choice choice group_tutorial group_assignment? group_group_assignment if Choice == "Technical Report"
br student_name Choice choice group_tutorial group_assignment? group_group_assignment


drop group_assignment?


export excel group_tutorial Choice student_name group_group_assignment using "${onedrive}/Exam_Group/groups_group_assignment.xlsx", replace firstrow(variables)

*/