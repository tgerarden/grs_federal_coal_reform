*************************************************************************
* PROJECT: grs_federal_coal_reform
* SOURCE OF THE RAW DATA: GRS_data.xlsx
* AUTHORS: Hui Zhou and Todd Gerarden
* DATE: February 2019
* STATA VERSION: Stata/MP 15.1 for Mac (Revision 17 Dec 2018)
**************************************************************************

clear
macro drop _all
set more off, permanently
capture log close
capture graph drop _all

* set directory
cd "../"

* create log file
local c_time_date = "`c(current_date)'"+"_" +"`c(current_time)'"
local time_string = subinstr("`c_time_date'", ":", "_", .)
local time_string = subinstr("`time_string'", " ", "_", .)
log using "output/logs/grs_federal_coal_reform_`time_string'.log", text

* run scripts
do "code/build/1_import_raw_data.do"
do "code/analyze/2_tables.do"
do "code/analyze/3_figures.do"

log close

clear

exit
