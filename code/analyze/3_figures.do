*************************************************************************
* PROJECT: grs_federal_coal_reform
* SOURCE OF THE RAW DATA: GRS_data.xlsx
* AUTHORS: Hui Zhou and Todd Gerarden
* DATE: February 2019
* STATA VERSION: Stata/MP 15.1 for Mac (Revision 17 Dec 2018)
**************************************************************************

clear
set scheme s2color

*********************************************************************************
* FIGURE 1: US Coal Production by Region, 2001-2006 *
*********************************************************************************
use ./intermediate_data/EIA_Prod_Region,clear
destring P2017, replace
xpose, clear varname format
rename v1 US
rename v2 APP
rename v3 APN
rename v4 APC
rename v5 APS
rename v6 INT
rename v7 ILL
rename v8 INO
rename v9 WSB
rename v10 PRB
rename v11 UNT
rename v12 WBO
gen OtherWestern=UNT+WBO
keep PRB OtherWestern APP INT _varname
replace PRB=PRB/1000000
replace OtherWestern=OtherWestern/1000000
replace APP=APP/1000000
replace INT=INT/1000000

drop in 1/2
gen Year=.
forv i=2001(1)2016{
replace Year=`i' if strpos(_varname,"`i'")
}
gen Y2=PRB+OtherWestern
gen Y3=Y2+APP
gen Y4=Y3+INT

twoway (area Y4 Year, col(purple*0.5)) ///
       (area Y3 Year, col(midgreen*0.5)) ///
       (area Y2 Year, col(red*0.6)) ///
       (area PRB Year, col(midblue*0.5)), ///
	   xlabel(2001(1)2016,labsize(*0.8)) ///
	   ylabel(0(200)1400,labsize(*0.8) format(%9.0gc) angle(0) grid gmax) ///
       xtitle("") ///
	   ytitle("Million short tons") ///
	   legend(label(1 "Interior") label(2 "Appalachia") label(3 "Other Western") label(4 "Powder River Basin")) ///
	   legend(pos(6) col(4) region(lc(white)) symysize(*0.5) symxsize(*0.15)) /// 
	   graphregion(col(white))
graph export ./output/figures/Figure1.pdf, replace 
	  
	   
*********************************************************************************
* FIGURE 2: Federal lease renewal profile as of January 2016 *
*********************************************************************************
use ./intermediate_data/Lease_data.dta, clear
tab Yrs_to_adj, gen(year)
gen year20=0
forv i=1/20{
   gen ton_year`i'=Tons*year`i'
   egen Count`i'=sum(year`i')
   egen Count_wtd_ton`i'=sum(ton_year`i')
   replace Count_wtd_ton`i'=Count_wtd_ton`i'/1000000
   }
keep Count*
keep in 1
gen i=1
reshape long Count Count_wtd_ton, i(i) j(Yrs_to_exp)
drop i

gen sum_c=.
gen sum_t=.
forv i=1/20{
     egen sum_c`i'=sum(Count) in 1/`i'
	 replace sum_c=sum_c`i' in `i'
	 drop sum_c`i'
	 egen sum_t`i'=sum(Count_wtd_ton) in 1/`i'
	 replace sum_t=sum_t`i' in `i'
	 drop sum_t`i'
} 

gen By_lease=sum_c/sum_c[20]
gen wtd_ton=sum_t/sum_t[20]
gen Model_appx=1
replace Model_appx=.1*_n in 1/9

twoway (line By_lease Yrs_to_exp, lcolor(emidblue) lwidth(medthick)) ///
       (line wtd_ton Yrs_to_exp, lcolor(black) lwidth(medthick) lp(dash)) ///
	   (line Model_appx Yrs_to_exp, lcolor(black) lw(medthick)), ///
	   xlabel(0(2)20) ///
	   ylabel(0(0.1)1, format(%02.1f) angle(0)) ///
	   xtitle("Years until readjustment") ///
	   legend(off) ///
	   text(0.35 7 "Lease count") ///
	   text(0.58 2.2 "Weighted by") ///
	   text(0.53 2.2 "tonnage") ///
	   text(0.87 6 "Linear modeling") ///
	   text(0.83 6 "approximation") ///
	   graphregion(col(white))
graph export ./output/figures/Figure2.pdf, replace 
	   
  
*********************************************************************************
* FIGURE 4: Wholesale Electricity Prices in 2030 (National Average) *
*********************************************************************************
* Y axis: Wholesale Electricity Price in 2030
use ./intermediate_data/Firm_Wholesale_Power_Prices_P.dta,clear
keep Scenario Year5
replace Scenario="Base" if strpos(Scenario,"Base Case")
replace Scenario="CPP_Mass" if strpos(Scenario,"CPP Mass Case")
replace Scenario="CPP_Rate" if strpos(Scenario,"CPP Rate Case")
bysort Scenario: gen scenario=_n
reshape wide Year5, i(Scenario) j(scenario)
xpose,clear 
rename v1 Base
rename v2 CPP_Mass
rename v3 CPP_Rate
drop in 1
gen scenario=_n
save ./intermediate_data/Figure4_y.dta, replace

* X axis: Per-ton surcharge under different scenarios
use ./intermediate_data/Table2_surcharge,clear
keep if Year==2016
keep SCC2012*
xpose, clear varname
gen scenario=. 
rename v1 surcharge
replace scenario=2 if strpos(_varname, "20")
replace scenario=3 if strpos(_varname, "50")
replace scenario=4 if strpos(_varname, "100")
expand 2 in 1
replace surcharge=0 in 4
replace scenario=1 in 4
drop _varname
save ./intermediate_data/surcharge_x.dta,replace
merge 1:1 scenario using ./intermediate_data/Figure4_y
drop _merge

twoway (line Base surcharge, lcolor(green) lwidth(medthick)) ///
       (line CPP_Mass surcharge, lcolor(blue) lwidth(medthick)) ///
	   (line CPP_Rate surcharge, lcolor(red) lwidth(medthick)), ///   
	   xlabel(0 "$0" 10 "$10" 20 "$20" 30 "$30" 40 "$40" 50 "$50" 60 "$60" 70 "$70" 80 "$80") ///
	   ylabel(53 "$53" 54 "$54" 55 "$55" 56 "$56" 57 "$57" 58 "$58" 59 "$59" 60 "$60" 61 "$61" 62 "$62" 63 "$63",angle(0)) ///  	   
	   xtitle("$/short ton royalty surcharge, 2016") ///
	   ytitle("$/MWh") ///
	   legend(off) ///
	   text(61.5 65 "No CPP", color(green)) ///
	   text(61.5 24 "Mass-based CPP", color(blue)) ///
	   text(55.6 13 "Rate-based CPP", color(red)) ///
	   graphregion(col(white))
graph export ./output/figures/Figure4.pdf, replace 
	   
*********************************************************************************
* FIGURE 5: Tradable Allowance Prices in 2030 *
*********************************************************************************
* Y axis: CO2 allowance prices in 2030
use ./intermediate_data/CO2_Allowance_Price_P.dta,clear
keep Region P2030*
keep in 1/6
xpose,clear varname
rename v1 EC_Mass
lab var EC_Mass "EC-Mass"
rename v2 NC_Mass
lab var NC_Mass "NC-Mass"
rename v3 NE_Mass
lab var NE_Mass "NE-Mass"
rename v4 SC_Mass
lab var SC_Mass "SC-Mass"
rename v5 SE_Mass
lab var SE_Mass "SE-Mass"
rename v6 WE_Mass
lab var WE_Mass "WE-Mass"
keep EC NC SC SE _varname
drop in 1
gen scenario=1 
replace scenario=2 if strpos(_varname, "SCC20")
replace scenario=3 if strpos(_varname, "SCC50")
replace scenario=4 if strpos(_varname, "SCC100")
drop _varname 
save ./intermediate_data/Figure5_y1.dta, replace

use ./intermediate_data/CO2_Allowance_Price_P.dta,clear
keep Region P2030*
keep in 7/12
xpose,clear varname
rename v1 EC_Rate
lab var EC_Rate "EC-Rate"
rename v2 NC_Rate
lab var NC_Rate "NC-Rate"
rename v3 NE_Rate
lab var NE_Rate "NE-Rate"
rename v4 SC_Rate
lab var SC_Rate "SC-Rate"
rename v5 SE_Rate
lab var SE_Rate "SE-Rate"
rename v6 WE_Rate
lab var WE_Rate "WE-Rate"
keep EC NC SC SE _varname
drop in 1
gen scenario=1 
replace scenario=2 if strpos(_varname, "SCC20")
replace scenario=3 if strpos(_varname, "SCC50")
replace scenario=4 if strpos(_varname, "SCC100")
drop _varname 
save ./intermediate_data/Figure5_y2.dta, replace

merge 1:1 scenario using ./intermediate_data/Figure5_y1
drop _merge
merge 1:1 scenario using ./intermediate_data/surcharge_x
drop _merge

twoway (line EC_Mass surcharge, lcolor(purple) lwidth(medthick)) ///
       (line NC_Mass surcharge, lcolor(blue) lwidth(medthick)) ///
	   (line SC_Mass surcharge, lcolor(red) lwidth(medthick)) ///
       (line SE_Mass surcharge, lcolor(green) lwidth(medthick)) ///
	   (line EC_Rate surcharge, lcolor(purple) lwidth(medthick) lpattern(dash)) ///
       (line NC_Rate surcharge, lcolor(blue) lwidth(medthick) lpattern(dash)) ///
	   (line SC_Rate surcharge, lcolor(red) lwidth(medthick) lpattern(dash)) ///
       (line SE_Rate surcharge, lcolor(green) lwidth(medthick) lpattern(dash)), ///	   
	   xlabel(0 "$0" 10 "$10" 20 "$20" 30 "$30" 40 "$40" 50 "$50" 60 "$60" 70 "$70" 80 "$80") ///
	   ylabel(0 "$0" 5 "$5" 10 "$10" 15 "$15" 20 "$20" 25 "$25",angle(0)) ///  	   
	   xtitle("$/short ton royalty surcharge, 2016") ///
	   ytitle("$/metric ton of CO{subscript:2}") ///
	   legend(region(lwidth(none) lcolor(white)) col(4) symxsize(*0.5)) ///
	   graphregion(col(white))
graph export ./output/figures/Figure5.pdf, replace 
   

*********************************************************************************
* FIGURE 6: National CO2 Emissions from the Power Sector in 2030 *
*********************************************************************************
use ./intermediate_data/Total_US_CO2_Emissions_P,clear
keep Scenario Emission5
replace Scenario="Base" if strpos(Scenario,"Base Case")
replace Scenario="CPP_Mass" if strpos(Scenario,"CPP Mass Case")
replace Scenario="CPP_Rate" if strpos(Scenario,"CPP Rate Case")
bysort Scenario: gen scenario=_n
reshape wide Emission5, i(Scenario) j(scenario)
xpose,clear 
rename v1 Base
rename v2 CPP_Mass
rename v3 CPP_Rate
drop in 1
gen scenario=_n
save ./intermediate_data/Figure6_y.dta, replace

merge 1:1 scenario using ./intermediate_data/surcharge_x.dta
drop _merge

twoway (line Base surcharge, lcolor(green) lwidth(medthick)) ///
       (line CPP_Mass surcharge, lcolor(blue) lwidth(medthick)) ///
	   (line CPP_Rate surcharge, lcolor(red) lwidth(medthick)), ///   
	   xlabel(0 "$0" 10 "$10" 20 "$20" 30 "$30" 40 "$40" 50 "$50" 60 "$60" 70 "$70" 80 "$80") ///
	   ylabel(1400(100)2100, format(%9.0fc) angle(0) gmax) ///  	   
	   xtitle("$/short ton royalty surcharge, 2016") ///
	   ytitle("Million metric tons of CO{subscript:2}") ///
	   legend(off) ///
	   text(1950 32 "No CPP", color(green)) ///
	   text(1650 50 "Mass-based CPP", color(blue)) ///
	   text(1550 20 "Rate-based CPP", color(red)) ///
	   graphregion(col(white))
graph export ./output/figures/Figure6.pdf, replace 


*********************************************************************************
* FIGURE 7: Cumulative Emissions Reductions *
*********************************************************************************
use ./intermediate_data/Cumul_emissions_reductions_P, clear
xpose,clear varname
rename v1 NoCPP
rename v2 NoCPP_SCC20
rename v3 NoCPP_SCC50
rename v4 NoCPP_SCC100
rename v5 MassCPP
rename v6 MassCPP_SCC20
rename v7 MassCPP_SCC50
rename v8 MassCPP_SCC100
rename v9 RateCPP
rename v10 RateCPP_SCC20
rename v11 RateCPP_SCC50
rename v12 RateCPP_SCC100
drop in 1
gen year=substr(_var,2,4)
destring year,replace
drop _varname

twoway (line NoCPP_SCC100 year, lcol(green) lwidth(medthick)) ///
       (line NoCPP_SCC20 year, lcol(green) lwidth(medthick) lpattern(dash)) ///
	   (line NoCPP_SCC50 year, lcol(green) lwidth(medthick) lpattern(dash)) ///
	   (line MassCPP year, lcol(blue) lwidth(medthick)) ///
	   (line RateCPP year, lcol(red) lwidth(medthick)), ///
	   ylabel(0(1)-7, angle(0)) ///
	   xlabel(2015(5)2040) ///
	   xscale(alt) xtitle("") legend(off) ///
	   ytitle("Metric gigatons of CO{subscript:2}") ///
	   text(-0.5 2035 "No CPP/20% SCC",color(green)) ///
	   text(-2.5 2037 "No CPP/50% SCC",color(green)) ///
	   text(-2.5 2022 "No CPP/100% SCC",color(green)) ///
	   text(-4.6 2040 "Rate-based CPP",color(red)) ///
	   text(-6.5 2036 "Mass-based CPP",color(blue)) ///
	   graphregion(col(white) margin(r+8))
graph export ./output/figures/Figure7.pdf, replace 

*********************************************************************************
* FIGURE 8: Generation Mix in 2030 *
*********************************************************************************
use ./intermediate_data/Generation_Mix_P,clear
keep Energy P2030*
xpose,clear varname
drop in 1
rename v1 Biomass
rename v2 CC_Existing
rename v3 CC_New
rename v4 Coal
rename v5 CT_Existing
rename v6 CT_New
rename v7 Geothermal
rename v8 Hydro
rename v9 Landfill
rename v10 Nuclear
rename v11 Oil_Gas
rename v12 Other
rename v13 Solar 
rename v14 Wind
rename v15 Total
rename v16 EE

gen NG=CC_Existing+CC_New+CT_Existing+CT_New
gen Oth=Total-Coal-NG
keep _varname Coal NG Oth
replace Coal=Coal/1000 
replace NG=NG/1000
replace Oth=Oth/1000
gen Scenario=""
replace Scenario="Base" if strpos(_varname,"Base")
replace Scenario="CPP_Mass" if strpos(_varname,"CPP_Mass")
replace Scenario="CPP_Rate" if strpos(_varname,"CPP_Rate")
bysort Scenario: gen scenario=_n
drop _varname Scenario

preserve
keep in 1/4
rename Coal NoCPP_Coal
rename NG NoCPP_NG
rename Oth NoCPP_Oth
tempfile NoCPP
save `NoCPP'
restore

preserve
keep in 5/8
rename Coal MassCPP_Coal
rename NG MassCPP_NG
rename Oth MassCPP_Oth
tempfile MassCPP
save `MassCPP'
restore

keep in 9/12
rename Coal RateCPP_Coal
rename NG RateCPP_NG
rename Oth RateCPP_Oth
tempfile RateCPP
save `RateCPP'

merge 1:1 scenario using `NoCPP'
drop _merge
merge 1:1 scenario using `MassCPP'
drop _merge
save ./intermediate_data/Figure7_y.dta, replace

merge 1:1 scenario using ./intermediate_data/surcharge_x.dta
drop _merge

twoway (line NoCPP_Coal surcharge, lcol(green) lwidth(medthick)) ///
       (line MassCPP_Coal surcharge, lcol(blue) lwidth(medthick)) ///
	   (line RateCPP_Coal surcharge, lcol(red) lwidth(medthick)) ///
	   (line NoCPP_NG surcharge, lcol(green) lwidth(medthick) lp(dash)) ///
       (line MassCPP_NG surcharge, lcol(blue) lwidth(medthick) lp(dash)) ///
	   (line RateCPP_NG surcharge, lcol(red) lwidth(medthick) lp(dash)) ///
	   (line NoCPP_Oth surcharge, lcol(green) lwidth(medthick) lp(".")) ///
       (line MassCPP_Oth surcharge, lcol(blue) lwidth(medthick) lp(".")) ///
	   (line RateCPP_Oth surcharge, lcol(red) lwidth(medthick) lp(".")), ///
	   xlabel(0 "$0" 10 "$10" 20 "$20" 30 "$30" 40 "$40" 50 "$50" 60 "$60" 70 "$70" 80 "$80") ///
	   ylabel(800(100)1800, angle(0)) ///  	   
	   xtitle("$/short ton royalty surcharge, 2016") ///
	   ytitle("Terawatt hours") ///
	   legend(off) ///
	   text(1150 47 "No CPP", color(green)) ///
	   text(1040 10 "Mass-based CPP", color(blue)) ///
	   text(1160 18 "Rate-based CPP", color(red)) ///
	   text(1050 81 "Coal (solid)", color(black)) ///
	   text(1440 78 "Natural Gas (dash)", color(black)) ///
	   text(1750 81 "Other (dot)", color(black)) ///	
	   graphregion(col(white) margin(r+7))
graph export ./output/figures/Figure8.pdf, replace 


*********************************************************************************
* FIGURE 9: Average Nonfederal-Federal Coal Substitution Ratio *
*********************************************************************************
* Coal production on Federal lands 
use ./intermediate_data/PRB_Coal_Production_P.dta,clear
keep in 13
keep P2030*
xpose, clear varname
gen scenario=_n
rename v1 Coal_Fed
tempfile Coal_Fed
save `Coal_Fed'

* Coal production on Non-federal lands
use ./intermediate_data/Coal_Prod_Basin_P.dta,clear
keep in 7
keep P2030*
xpose, clear varname
gen scenario=_n
rename v1 Coal_Total
merge 1:1 scenario using `Coal_Fed'
drop _merge
gen Coal_nonFed=Coal_Total-Coal_Fed

gen D_Fed=Coal_Fed-Coal_Fed[1] in 1/4
replace D_Fed=Coal_Fed-Coal_Fed[5] in 5/8
replace D_Fed=Coal_Fed-Coal_Fed[9] in 9/12

gen D_nonFed=Coal_nonFed-Coal_nonFed[1] in 1/4
replace D_nonFed=Coal_nonFed-Coal_nonFed[5] in 5/8
replace D_nonFed=Coal_nonFed-Coal_nonFed[9] in 9/12

gen Ratio=-D_nonFed/D_Fed
rename _varname Scenario
keep Scenario Ratio
replace Scenario="Base" if strpos(Scenario,"Base")
replace Scenario="CPP_Mass" if strpos(Scenario,"CPP_Mass")
replace Scenario="CPP_Rate" if strpos(Scenario,"CPP_Rate")
bysort Scenario: gen scenario=_n
reshape wide Ratio, i(Scenario) j(scenario)
xpose,clear 
rename v1 Base
rename v2 CPP_Mass
rename v3 CPP_Rate
drop in 1
gen scenario=_n

merge 1:1 scenario using ./intermediate_data/surcharge_x
drop _merge

twoway (line Base surcharge, lcolor(green) lwidth(medthick)) ///
       (line CPP_Mass surcharge, lcolor(blue) lwidth(medthick)) ///
	   (line CPP_Rate surcharge, lcolor(red) lwidth(medthick)), ///   
	   xlabel(0 "$0" 10 "$10" 20 "$20" 30 "$30" 40 "$40" 50 "$50" 60 "$60" 70 "$70" 80 "$80") ///
	   ylabel(0.00(0.10)1.00,format(%9.2f) angle(0) gmax) ///  	   
	   xtitle("$/short ton royalty surcharge, 2016") ///
	   ytitle("Substitution Ratio") legend(off) ///
	   text(0.15 40 "No CPP", color(green)) ///
	   text(0.65 35 "Mass-based CPP", color(blue)) ///
	   text(0.25 70 "Rate-based CPP", color(red)) ///
	   graphregion(col(white))
graph export ./output/figures/Figure9.pdf, replace 

*********************************************************************************
* FIGURE 10: Federal Royalties and Coal Production on Federal Lands *
*********************************************************************************
* Federal royalties
use ./intermediate_data/Table4_Royalty_State.dta,clear
keep if strpos(_varname,"Base_SCC20")
save ./intermediate_data/Figure10_Royalty.dta,replace

* Coal production on federal lands
use ./intermediate_data/Table4_Production_State.dta,clear
keep if strpos(_varname,"Base_SCC20")
save ./intermediate_data/Figure10_Prod.dta,replace

merge 1:1 Year using ./intermediate_data/Figure10_Royalty.dta
drop if Year==2050
drop _merge

twoway (line Royalty_CO Year, lcol(green) lwidth(medthick) yaxis(1)) ///
       (line Royalty_UT Year, lcol(orange) lwidth(medthick) yaxis(1)) ///
	   (line Royalty_MT Year, lcol(black) lwidth(medthick) yaxis(1)) ///
	   (line Royalty_WY Year, lcol(blue) lwidth(medthick) yaxis(1)) ///
	   (line Prod_CO Year, lcol(green) lwidth(medthick) lp(dash) yaxis(2)) ///
       (line Prod_UT Year, lcol(orange) lwidth(medthick) lp(dash) yaxis(2)) ///
	   (line Prod_MT Year, lcol(black) lwidth(medthick) lp(dash) yaxis(2)) ///
	   (line Prod_WY Year, lcol(blue) lwidth(medthick) lp(dash) yaxis(2)), ///
	   ylabel(0(500)2500, format(%9.0fc) angle(0) axis(1)) ///
	   ylabel(0(50)300, angle(0) axis(2)) ///
	   xlabel(2015(5)2040) ///
	   xtitle("") ///
	   ytitle("Federal royalty (millions 2012$)", axis(1) margin(-8 0 0 0)) ///
	   ytitle("Coal production (million short tons)", axis(2))  ///
	   legend(label(1 "CO royalty") label(2 "UT royalty") label(3 "MT royalty") label(4 "WY royalty") ///
		label(5 "CO production") label(6 "UT production") label(7 "MT production") label(8 "WY production") ///
		col(4) region(lwidth(none) lcolor(white) lstyle(none)) size(*.8) symxsize(*.4) bmargin(-8 -8 0 1)) ///
	   graphregion(col(white) margin(l+5)) xsize(6.5) ysize(5)
graph export ./output/figures/Figure10.pdf, replace 

graph close
