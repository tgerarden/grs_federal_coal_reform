*************************************************************************
* PROJECT: grs_federal_coal_reform
* SOURCE OF THE RAW DATA: GRS_data.xlsx
* AUTHORS: Hui Zhou and Todd Gerarden
* DATE: February 2019
* STATA VERSION: Stata/MP 15.1 for Mac (Revision 17 Dec 2018)
**************************************************************************

clear

*********************************************************************************
* TABLE 1: Annual Federal and Non-Federal Coal Production *
*********************************************************************************
use ./intermediate_data/Coal_Prod_2013_2014, clear
keep in 7/11
destring P* Fed2014, replace
xpose, clear varname
gen v6=v5-(v1+v2+v3+v4)
order v6, before(v5)
xpose, clear 
tostring State,replace
replace State="WY" in 1
replace State="MT" in 2
replace State="CC" in 3
replace State="UT" in 4
replace State="Oth" in 5
replace State="Total" in 6
replace P2013=round(P2013/1000,1)
replace P2014=round(P2014/1000,1)
gen Fed_per=Fed2014/(P2013*1/4+P2014*3/4)
save ./output/tables/Table1.dta,replace

*********************************************************************************
* TABLE 2: Simulated Phased-In Royalty Surcharges for Federal Coal INdexed to SCC with 10-year linera phase-in *
*********************************************************************************
use ./intermediate_data/Price_Indexes.dta,clear
keep Year PCE
xpose, clear varname
forvalues i = 1(1)9{
local year = v`i' in 1
rename v`i' Year`year'
}
keep in 2
gen Infl2007_2015=Year2015/Year2007
gen Infl2015_2012=Year2012/Year2015
gen Infl2007_2012=Year2012/Year2007
local Infl07_15=Infl2007_2015  // Inflation factor from 2007 to 2015
local Infl15_12=Infl2015_2012  // Deflation factor from 2015 to 2012
local Infl07_12=Infl2007_2012  // Inflation factor from 2007 to 2012

use ./intermediate_data/CO2_short_ton.dta,clear
local Factor=factor

use ./intermediate_data/Per_ton_Surcharge,clear
gen P2015_1=P2007_1*`Infl07_15'
gen P2015_2=P2007_2*`Infl07_15'
gen P2015_3=P2007_3*`Infl07_15'
gen P2015_4=P2007_4*`Infl07_15'

gen P2012_1=P2015_1*`Infl15_12'
gen P2012_2=P2015_2*`Infl15_12'
gen P2012_3=P2015_3*`Infl15_12'
gen P2012_4=P2015_4*`Infl15_12'

gen SCC2015_100=P2015_2*`Factor'
gen SCC2015_50=SCC2015_100*0.5
gen SCC2015_20=SCC2015_100*0.2

gen SCC2012_100=P2012_2*`Factor'
gen SCC2012_50=SCC2012_100*0.5
gen SCC2012_20=SCC2012_100*0.2

merge 1:1 Year using ./intermediate_data/Ramp_in_factor.dta
drop _merge

gen RSCC2015_100=SCC2015_100*Ramp_in_factor
gen RSCC2015_50=SCC2015_50*Ramp_in_factor
gen RSCC2015_20=SCC2015_20*Ramp_in_factor

gen RSCC2012_100=SCC2012_100*Ramp_in_factor
gen RSCC2012_50=SCC2012_50*Ramp_in_factor
gen RSCC2012_20=SCC2012_20*Ramp_in_factor
save ./intermediate_data/Table2_surcharge.dta,replace

keep if Year==2016|Year==2018|Year==2020|Year==2025|Year==2030
keep Year RSCC2012_20 RSCC2012_50 RSCC2012_100
order RSCC2012_20, before(RSCC2012_50)
order RSCC2012_100, after(RSCC2012_50)
save ./output/tables/Table2.dta,replace


*********************************************************************************
************ TABLE 3: IPM Results: Electricity and Allowance Prices *********
*********************************************************************************
use ./intermediate_data/Firm_Wholesale_Power_Prices_P,clear
keep Scenario scenario Year5
tempfile Firm_Wholesale
save `Firm_Wholesale'

use ./intermediate_data/CO2_Allowance_Price_P,clear
keep Region P2030*
preserve
keep in 1/6
xpose, clear varname 
tempfile CO2_Allowance_CPP_Mass
save `CO2_Allowance_CPP_Mass'
restore

keep in 7/12
xpose, clear varname
tempfile CO2_Allowance_CPP_Rate
save `CO2_Allowance_CPP_Rate' 

use `CO2_Allowance_CPP_Mass',clear
append using `CO2_Allowance_CPP_Rate'
drop in 1
drop in 5
gen scenario =  5 in 1
forvalues i=6(1)12{
local j=`i'-4
replace scenario = `i' in `j'
}
drop _varname
tempfile CO2_Allowance
save `CO2_Allowance'

use `Firm_Wholesale',clear
merge 1:1 scenario using `CO2_Allowance'
drop _merge scenario
rename Year5 Electricity_price
format Electricity_price %9.2f
forvalues i=1(1)6{
format v`i' %9.2f if v`i'!=0
}
rename v1 East_Central
rename v2 North_Central
rename v3 Northeast
rename v4 South_Central
rename v5 Southeast
rename v6 West
save ./output/tables/Table3.dta,replace


*********************************************************************************
* TABLE 4: IPM Results: Emissions and Abatement Costs of Royalty Surcharge *********
*********************************************************************************
use ./intermediate_data/Total_US_CO2_Emissions_P,clear
keep Scenario scenario Emission5
gen Delta = Emission5-Emission5[1]
gen percent = Delta/Emission5[1]
save ./intermediate_data/Table4_col1to3.dta,replace

* Coal Production
use ./intermediate_data/PRB_Coal_Production_P.dta, clear
drop if _n==1|_n==5|_n==7|_n==9|_n==13
xpose,clear format varname
rename v1 Prod_CO_Raton
rename v2 Prod_CO_SanJuan
rename v3 Prod_CO_Uinta
rename v4 Prod_UT
rename v5 Prod_MT
rename v6 Prod_WY_Green
rename v7 Prod_WY_Low
rename v8 Prod_WY_Powder

gen Year=2016 if strpos(_varname,"2016")
replace Year=2018 if strpos(_varname,"2018")
replace Year=2020 if strpos(_varname,"2020")
replace Year=2025 if strpos(_varname,"2025")
replace Year=2030 if strpos(_varname,"2030")
replace Year=2040 if strpos(_varname,"2040")
replace Year=2050 if strpos(_varname,"2050")
gen scenario=1 if strpos(_varname,"Base")
replace scenario=2 if strpos(_varname,"Base_SCC20")
replace scenario=3 if strpos(_varname,"Base_SCC50")
replace scenario=4 if strpos(_varname,"Base_SCC100")
replace scenario=5 if strpos(_varname,"CPP_Mass")
replace scenario=6 if strpos(_varname,"CPP_Mass_SCC20")
replace scenario=7 if strpos(_varname,"CPP_Mass_SCC50")
replace scenario=8 if strpos(_varname,"CPP_Mass_SCC100")
replace scenario=9 if strpos(_varname,"CPP_Rate")
replace scenario=10 if strpos(_varname,"CPP_Rate_SCC20")
replace scenario=11 if strpos(_varname,"CPP_Rate_SCC50")
replace scenario=12 if strpos(_varname,"CPP_Rate_SCC100")
drop in 1
save ./intermediate_data/Table4_Production.dta,replace

* Mine mouth price
use ./intermediate_data/Mine_mouth_price_P.dta,clear
xpose,clear format varname
rename v1 Price_CO
rename v2 Price_UT
rename v3 Price_MT
rename v4 Price_WY_8400
rename v5 Price_WY_8800

gen Year=2016 if strpos(_varname,"2016")
replace Year=2018 if strpos(_varname,"2018")
replace Year=2020 if strpos(_varname,"2020")
replace Year=2025 if strpos(_varname,"2025")
replace Year=2030 if strpos(_varname,"2030")
replace Year=2040 if strpos(_varname,"2040")
replace Year=2050 if strpos(_varname,"2050")
gen scenario=1 if strpos(_varname,"Base")
replace scenario=2 if strpos(_varname,"Base_SCC20")
replace scenario=3 if strpos(_varname,"Base_SCC50")
replace scenario=4 if strpos(_varname,"Base_SCC100")
replace scenario=5 if strpos(_varname,"CPP_Mass")
replace scenario=6 if strpos(_varname,"CPP_Mass_SCC20")
replace scenario=7 if strpos(_varname,"CPP_Mass_SCC50")
replace scenario=8 if strpos(_varname,"CPP_Mass_SCC100")
replace scenario=9 if strpos(_varname,"CPP_Rate")
replace scenario=10 if strpos(_varname,"CPP_Rate_SCC20")
replace scenario=11 if strpos(_varname,"CPP_Rate_SCC50")
replace scenario=12 if strpos(_varname,"CPP_Rate_SCC100")
drop in 1
save ./intermediate_data/Table4_minemouth_price.dta,replace

* Coal royalty payments on Federal lands, minemouth price portion
use ./intermediate_data/Table4_Production.dta,clear
merge 1:1 Year scenario using ./intermediate_data/Table4_minemouth_price.dta
drop _merge

gen Pmnts_CO_Raton=0.08*Prod_CO_Raton*Price_CO
gen Pmnts_CO_SanJuan=0.08*Prod_CO_SanJuan*Price_CO
gen Pmnts_CO_Uinta=0.08*Prod_CO_Uinta*Price_CO
gen Pmnts_UT=0.08*Prod_UT*Price_UT
gen Pmnts_MT=0.125*Prod_MT*Price_MT
gen Pmnts_WY_Green=0.125*Prod_WY_Green*Price_WY_8800
gen Pmnts_WY_Low=0.125*Prod_WY_Low*Price_WY_8400
gen Pmnts_WY_Powder=0.125*Prod_WY_Powder*Price_WY_8800
keep Pmnts* _varname

gen Year=2016 if strpos(_varname,"2016")
replace Year=2018 if strpos(_varname,"2018")
replace Year=2020 if strpos(_varname,"2020")
replace Year=2025 if strpos(_varname,"2025")
replace Year=2030 if strpos(_varname,"2030")
replace Year=2040 if strpos(_varname,"2040")
replace Year=2050 if strpos(_varname,"2050")
gen scenario=1 if strpos(_varname,"Base")
replace scenario=2 if strpos(_varname,"Base_SCC20")
replace scenario=3 if strpos(_varname,"Base_SCC50")
replace scenario=4 if strpos(_varname,"Base_SCC100")
replace scenario=5 if strpos(_varname,"CPP_Mass")
replace scenario=6 if strpos(_varname,"CPP_Mass_SCC20")
replace scenario=7 if strpos(_varname,"CPP_Mass_SCC50")
replace scenario=8 if strpos(_varname,"CPP_Mass_SCC100")
replace scenario=9 if strpos(_varname,"CPP_Rate")
replace scenario=10 if strpos(_varname,"CPP_Rate_SCC20")
replace scenario=11 if strpos(_varname,"CPP_Rate_SCC50")
replace scenario=12 if strpos(_varname,"CPP_Rate_SCC100")

save ./intermediate_data/Table4_Pmnts_minemouth.dta,replace

* Coal roylaty payments on federal lands, adder portion
use ./intermediate_data/Table2_surcharge.dta,clear 
keep if Year==2016|Year==2018|Year==2020|Year==2025|Year==2030|Year==2040|Year==2050
keep Year RSCC2012_100
forvalues i = 1/12{
gen SCC_surcharge`i'=RSCC2012_100
}
reshape long SCC_surcharge, i(Year) j(scenario)
sort scenario Year

gen sur_rate = 0
replace sur_rate = 0.2 if scenario==2 | scenario==6 | scenario==10
replace sur_rate = 0.5 if scenario==3 | scenario==7 | scenario==11
replace sur_rate = 1.0 if scenario==4 | scenario==8 | scenario==12

gen Ramped_surcharge = SCC_surcharge*sur_rate
keep Year scenario Ramped_surcharge
merge 1:1 Year scenario using ./intermediate_data/Table4_Production.dta
drop _merge

gen Pmnts_CO_Raton_adder = Prod_CO_Raton*Ramped
gen Pmnts_CO_SanJuan_adder=Prod_CO_SanJuan*Ramped
gen Pmnts_CO_Uinta_adder=Prod_CO_Uinta*Ramped
gen Pmnts_UT_adder=Prod_UT*Ramped
gen Pmnts_MT_adder=Prod_MT*Ramped
gen Pmnts_WY_Green_adder=Prod_WY_Green*Ramped
gen Pmnts_WY_Low_adder=Prod_WY_Low*Ramped
gen Pmnts_WY_Powder_adder=Prod_WY_Powder*Ramped

keep _varname Year scenario Pmnts*
save ./intermediate_data/Table4_Pmnts_adder.dta,replace

* Total Royalty
use ./intermediate_data/Table4_Pmnts_minemouth.dta,clear
merge 1:1 Year scenario using ./intermediate_data/Table4_Pmnts_adder.dta
drop _merge

foreach x in "CO_Raton" "CO_SanJuan" "CO_Uinta" "UT" "MT" "WY_Green" "WY_Low" "WY_Powder" {
gen Royalty_`x'=Pmnts_`x'+Pmnts_`x'_adder
}

keep _varname Year scenario Royalty*
save ./intermediate_data/Table4_Total_royalty.dta,replace

* State subtotals
use ./intermediate_data/Table4_Production.dta,replace
gen Prod_CO = Prod_CO_Raton+Prod_CO_SanJuan+Prod_CO_Uinta
gen Prod_WY = Prod_WY_Green+Prod_WY_Low+Prod_WY_Powder
keep _varname Year scenario Prod_CO Prod_UT Prod_MT Prod_WY
save ./intermediate_data/Table4_Production_State.dta,replace

use ./intermediate_data/Table4_Total_royalty.dta,clear
gen Royalty_CO = Royalty_CO_Raton+Royalty_CO_SanJuan+Royalty_CO_Uinta
gen Royalty_WY = Royalty_WY_Green+Royalty_WY_Low+Royalty_WY_Powder
keep _varname Year scenario Royalty_CO Royalty_UT Royalty_MT Royalty_WY
gen Total = Royalty_CO+Royalty_UT+Royalty_MT+Royalty_WY
save ./intermediate_data/Table4_Royalty_State.dta,replace

* Total Royalty in different scenarios
use ./intermediate_data/Table4_Royalty_State.dta,clear
keep Year scenario Total
replace Year=1 if Year==2016
replace Year=2 if Year==2018
replace Year=3 if Year==2020
replace Year=4 if Year==2025
replace Year=5 if Year==2030
replace Year=6 if Year==2040
replace Year=7 if Year==2050
reshape wide Total, i(scenario) j(Year)
save ./intermediate_data/Table4_Total_royalty_wide.dta,replace

* Abatement cost calculation
use ./intermediate_data/Total_Production_Costs_P.dta,clear
rename Year1 PC1
rename Year2 PC2
rename Year3 PC3
rename Year4 PC4
rename Year5 PC5
rename Year6 PC6
rename Year7 PC7
merge 1:1 scenario using ./intermediate_data/Table4_Total_royalty_wide.dta
drop _merge
* Net production cost = Total production costs-Total Royalties
gen NC1=PC1-Total1
gen NC2=PC2-Total2
gen NC3=PC3-Total3
gen NC4=PC4-Total4
gen NC5=PC5-Total5
gen NC6=PC6-Total6
gen NC7=PC7-Total7
* Delta net production costs relative to CPP base case
forvalues i=1(1)7{
gen D_NC`i'=NC`i'-NC`i'[1] in 1/4
replace D_NC`i'=NC`i'-NC`i'[5] in 5/8
replace D_NC`i'=NC`i'-NC`i'[9] in 9/12
}
keep scenario Scenario D*
save ./intermediate_data/Table4_Delta_Net_Costs.dta,replace
* Delta emissions relative to CPP base case
use ./intermediate_data/Total_US_CO2_Emissions_P.dta,clear
forvalues i=1(1)7{
gen D_Emission`i'=Emission`i'-Emission`i'[1] in 1/4
replace D_Emission`i'=Emission`i'-Emission`i'[5] in 5/8
replace D_Emission`i'=Emission`i'-Emission`i'[9] in 9/12
}
keep scenario Scenario D*
save ./intermediate_data/Table4_Delta_Emissions.dta,replace
* Abatement cost (2012$/metric ton CO2)
use ./intermediate_data/Table4_Delta_Net_Costs.dta, clear
merge 1:1 Scenario using ./intermediate_data/Table4_Delta_Emissions.dta
drop _merge
forvalues i=1(1)7{
gen Abmnt_Cost`i'=-D_NC`i'/D_Emission`i' in 2/4
replace Abmnt_Cost`i'=-D_NC`i'/D_Emission`i' in 6/8
replace Abmnt_Cost`i'=-D_NC`i'/D_Emission`i' in 10/12
}
sort scenario
keep Scenario scenario Abmnt*
save ./intermediate_data/Table4_Abatement_Costs.dta,replace

use ./intermediate_data/SCC, clear
gen SCC_in2012=SCC*`Infl07_12'
keep if Year==2025 | Year==2030
keep Year SCC_in2012
xpose, clear varname
save ./intermediate_data/Table4_Memo.dta,replace

* Table 4 datafile
use ./intermediate_data/Table4_col1to3, clear
merge 1:1 scenario using ./intermediate_data/Table4_Abatement_Costs
drop _merge
keep Scenario Emission5 Delta percent Abmnt_Cost4 Abmnt_Cost5
format Emission5 %9.3gc
format Abmnt* %9.0f
replace Delta=. if Delta==0
replace percent=. if percent==0
save ./output/tables/Table4.dta, replace

*********************************************************************************
* TABLE 5: IPM Results: Generation Mix and PRB Coal Production                  *
*********************************************************************************
* Generation Mix
use ./intermediate_data/Generation_Mix_P, clear
xpose,clear varname

gen Year=2016 if strpos(_varname,"2016")
replace Year=2018 if strpos(_varname,"2018")
replace Year=2020 if strpos(_varname,"2020")
replace Year=2025 if strpos(_varname,"2025")
replace Year=2030 if strpos(_varname,"2030")
replace Year=2040 if strpos(_varname,"2040")
replace Year=2050 if strpos(_varname,"2050")
gen scenario=1 if strpos(_varname,"Base")
replace scenario=2 if strpos(_varname,"Base_SCC20")
replace scenario=3 if strpos(_varname,"Base_SCC50")
replace scenario=4 if strpos(_varname,"Base_SCC100")
replace scenario=5 if strpos(_varname,"CPP_Mass")
replace scenario=6 if strpos(_varname,"CPP_Mass_SCC20")
replace scenario=7 if strpos(_varname,"CPP_Mass_SCC50")
replace scenario=8 if strpos(_varname,"CPP_Mass_SCC100")
replace scenario=9 if strpos(_varname,"CPP_Rate")
replace scenario=10 if strpos(_varname,"CPP_Rate_SCC20")
replace scenario=11 if strpos(_varname,"CPP_Rate_SCC50")
replace scenario=12 if strpos(_varname,"CPP_Rate_SCC100")
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

gen Gas=CC_Existing+CC_New+CT_Existing+CT_New
gen Solar_Wind=Solar+Wind
gen New_Gas=CC_New+CT_New

keep if Year==2030
keep _varname Coal Gas Solar_Wind New_Gas 
rename _varname Scenario
order Scenario, first
replace Coal = Coal/1000
replace Gas = Gas/1000
replace Solar_Wind = Solar_Wind/1000
replace New_Gas = New_Gas/1000
format Coal Gas Solar_Wind New_Gas %12.3gc
generate scenario=_n
save ./intermediate_data/Table5_Generation_Mix.dta, replace

* Coal Production by Basin
use ./intermediate_data/Coal_Prod_Basin_P, clear
keep in 4
keep Basin P2030* 
xpose, clear varname
drop in 1
rename _varname Scenario
rename v1 PRB_Coal_Prod
order Scenario, first

gen Change_PRB=PRB-PRB[1] in 2/4
replace Change_PRB=PRB-PRB[5] in 6/8
replace Change_PRB=PRB-PRB[9] in 10/12

gen Change_PRB_percent=PRB/PRB[1]-1 in 2/4
replace Change_PRB_percent=PRB/PRB[5]-1 in 6/8
replace Change_PRB_percent=PRB/PRB[9]-1 in 10/12
format PRB Change_PRB %9.0f
save ./intermediate_data/Table5_PRB.dta,replace

use ./intermediate_data/Table5_Generation_Mix
merge 1:1 Scenario using ./intermediate_data/Table5_PRB
drop _merge
sort scenario
drop scenario
save ./output/tables/Table5.dta,replace

*********************************************************************************
*TABLE 6: IPM Results: Comparison of Royalty Surcharge and Quantity Limit Cases *
*********************************************************************************
use ./intermediate_data/Total_US_CO2_Emissions_S, clear
drop if strpos(Scenario,"50%")
keep Scenario Emission6
replace Emission6=round(Emission6,1)
drop if strpos(Scenario,"CPP Rate")
xpose,clear varname
rename v1 CPP1 
rename v2 CPP2
rename v3 CPP3
rename v4 CPP_Mass1
rename v5 CPP_Mass2
rename v6 CPP_Mass3
drop in 1
replace _varname="Emissions" in 1
tempfile Table6_Emissions_S
save `Table6_Emissions_S'

use ./intermediate_data/Total_US_CO2_Emissions_L, clear
keep Scenario Emission6
replace Emission6=round(Emission6,1)
drop if Scenario=="Base Case"
drop if Scenario=="CPP Base Case"
xpose,clear varname
drop in 1
rename v1 CPP_NoLimit 
rename v2 CPP_Cap50
rename v3 CPP_Mass_NoLimit
rename v4 CPP_Mass_Cap50
order CPP_NoLimit, after(CPP_Cap50)
order CPP_Mass_NoLimit, after(CPP_Mass_Cap50)
replace _varname="Emissions" in 1
tempfile Table6_Emissions_L
save `Table6_Emissions_L'

use ./intermediate_data/Coal_Prod_Basin_S, clear
keep if strpos(Basin,"PRB") | strpos(Basin,"Total")
keep Basin P2040* 
drop P2040_*SCC50 P2040*Rate*
rename P2040_Base CPP1
rename P2040_Base_SCC20 CPP2
rename P2040_Base_SCC100 CPP3
rename P2040_CPP_Mass CPP_Mass1
rename P2040_CPP_Mass_SCC20 CPP_Mass2
rename P2040_CPP_Mass_SCC100 CPP_Mass3
rename Basin _varname
tempfile Table6_Productions_S
save `Table6_Productions_S'

use ./intermediate_data/Coal_Prod_Basin_L, clear
keep if strpos(Basin,"PRB") | strpos(Basin,"Total")
keep Basin P2040* 
drop P2040*1
rename P2040_Base2 CPP_NoLimit 
rename P2040_Base3 CPP_Cap50
rename P2040_CPP_Mass2 CPP_Mass_NoLimit
rename P2040_CPP_Mass3 CPP_Mass_Cap50
order CPP_NoLimit, after(CPP_Cap50)
order CPP_Mass_NoLimit, after(CPP_Mass_Cap50)
rename Basin _varname
tempfile Table6_Productions_L
save `Table6_Productions_L'

use ./intermediate_data/Firm_Wholesale_Power_Prices_S, clear
drop if strpos(Scenario,"50%")
keep Scenario Year6
drop if strpos(Scenario,"CPP Rate")
xpose,clear varname
rename v1 CPP1 
rename v2 CPP2
rename v3 CPP3
rename v4 CPP_Mass1
rename v5 CPP_Mass2
rename v6 CPP_Mass3
drop in 1
local new=_N+1
set obs `new'
replace _varname="Wholesale_electricity_price" in 1
replace _varname="Allowance price" in 2
tempfile Table6_Wholesale_prices_S
save `Table6_Wholesale_prices_S'

use ./intermediate_data/Firm_Wholesale_Power_Prices_L, clear
keep Scenario Year6
drop if Scenario=="Base Case"
drop if Scenario=="CPP Base Case"
xpose,clear varname
drop in 1
rename v1 CPP_NoLimit 
rename v2 CPP_Cap50
rename v3 CPP_Mass_NoLimit
rename v4 CPP_Mass_Cap50
order CPP_NoLimit, after(CPP_Cap50)
order CPP_Mass_NoLimit, after(CPP_Mass_Cap50)
local new=_N+1
set obs `new'
replace _varname="Wholesale_electricity_price" in 1
replace _varname="Allowance price" in 2
tempfile Table6_Wholesale_prices_L
save `Table6_Wholesale_prices_L'

use ./intermediate_data/CO2_Allowance_Price_S, clear
keep Region Scenario P2040*
keep if strpos(Region,"North Central")|strpos(Region,"South Central")|strpos(Region,"Southeast")
keep if strpos(Scenario,"CPP_Mass")
drop P2040_SCC50
rename P2040 CPP_Mass1
rename P2040_SCC20 CPP_Mass2
rename P2040_SCC100 CPP_Mass3
gen CPP1=.
gen CPP2=.
gen CPP3=.
drop Scenario
rename Region _varname
order CPP1, after(_varname)
order CPP2, after(CPP1)
order CPP3, after(CPP2)
local new=_N+1
set obs `new'
replace _varname="North Central" in 1
replace _varname="South Central" in 2
replace _varname="Southeast" in 3
replace _varname="Generation (TWh)" in 4
tempfile Table6_Allowance_prices_S
save `Table6_Allowance_prices_S'

use ./intermediate_data/CO2_Allowance_Price_L, clear
keep Region P2040*
keep if strpos(Region,"North Central")|strpos(Region,"South Central")|strpos(Region,"Southeast")
drop P2040_Base1
rename P2040_Base2 CPP_Mass_NoLimit 
rename P2040_Base3 CPP_Mass_Cap50
order CPP_Mass_NoLimit, after(CPP_Mass_Cap50)
rename Region _varname
replace CPP_Mass_Cap50=round(CPP_Mass_Cap50,0.01)
replace CPP_Mass_NoLimit=round(CPP_Mass_NoLimit,0.01)
local new=_N+1
set obs `new'
replace _varname="North Central" in 1
replace _varname="South Central" in 2
replace _varname="Southeast" in 3
replace _varname="Generation (TWh)" in 4
tempfile Table6_Allowance_prices_L
save `Table6_Allowance_prices_L'

use ./intermediate_data/Generation_Mix_S, clear
keep Energy P2040*
drop P2040_*SCC50 P2040*Rate*
keep if strpos(Energy,"CC - New")| strpos(Energy,"Solar")| strpos(Energy,"Wind")
xpose,clear varname
rename v1 CC_New
rename v2 Solar
rename v3 Wind
drop in 1
gen Solar_Wind=Solar+Wind
replace Solar_Wind=Solar_Wind/1000
replace CC_New=CC_New/1000
keep CC_New Solar_Wind _varname 
xpose,clear varname
rename P2040_Base CPP1
rename P2040_Base_SCC20 CPP2
rename P2040_Base_SCC100 CPP3
rename P2040_CPP_Mass CPP_Mass1
rename P2040_CPP_Mass_SCC20 CPP_Mass2
rename P2040_CPP_Mass_SCC100 CPP_Mass3
gsort -_varname
tempfile Table6_Generation_S
save `Table6_Generation_S'

use ./intermediate_data/Generation_Mix_L, clear
keep Energy P2040*
drop P2040*1
keep if strpos(Energy,"CC - New")| strpos(Energy,"Solar")| strpos(Energy,"Wind")
xpose,clear varname
rename v1 CC_New
rename v2 Solar
rename v3 Wind
drop in 1
gen Solar_Wind=Solar+Wind
replace Solar_Wind=Solar_Wind/1000
replace CC_New=CC_New/1000
keep CC_New Solar_Wind _varname 
xpose,clear varname
rename P2040_Base2 CPP_NoLimit 
rename P2040_Base3 CPP_Cap50
rename P2040_CPP_Mass2 CPP_Mass_NoLimit
rename P2040_CPP_Mass3 CPP_Mass_Cap50
order CPP_NoLimit, after(CPP_Cap50)
order CPP_Mass_NoLimit, after(CPP_Mass_Cap50)
gsort -_varname
tempfile Table6_Generation_L
save `Table6_Generation_L'

foreach x in "S" "L"{
use `Table6_Emissions_`x'',clear
append using `Table6_Productions_`x''
append using `Table6_Wholesale_prices_`x''
append using `Table6_Allowance_prices_`x''
append using `Table6_Generation_`x''
rename _varname Case
order Case, first
save ./intermediate_data/Table6_`x'.dta,replace
}

use ./intermediate_data/Table6_S,clear
keep Case CPP_Mass*
rename CPP_Mass1 CPP1
rename CPP_Mass2 CPP2
rename CPP_Mass3 CPP3
tempfile Table6_Mass_S
save `Table6_Mass_S'
use ./intermediate_data/Table6_S,clear
keep Case CPP1 CPP2 CPP3
append using `Table6_Mass_S'
gen n=_n
tempfile Table6_S
save `Table6_S'

use ./intermediate_data/Table6_L,clear
keep Case CPP_Mass*
rename CPP_Mass_Cap50 CPP_Cap50
rename CPP_Mass_NoLimit CPP_NoLimit
tempfile Table6_Mass_L
save `Table6_Mass_L'
use ./intermediate_data/Table6_L,clear
keep Case CPP_Cap50 CPP_NoLimit
append using `Table6_Mass_L'
gen n=_n
tempfile Table6_L
save `Table6_L'

use `Table6_S',clear
merge 1:1 n using `Table6_L'
drop _merge n
rename CPP1 Primary_No_surcharge
rename CPP2 Primary_SCC20
rename CPP3 Primary_SCC100
save ./output/tables/Table6.dta,replace

*********************************************************************************
*TABLE B.1: IPM Results: Comparison of the Primary and Secondary Base Case *
*********************************************************************************
foreach x in "P" "S"{
use ./intermediate_data/Total_US_CO2_Emissions_`x'.dta, clear
drop if strpos(Scenario,"50%")
keep Scenario Emission5
replace Emission5=round(Emission5,1)
format Emission5 %9.0fc
gen Delta=(Emission5-Emission5[1])/Emission5[1]
replace Delta=. in 1
xpose,clear varname
rename v1 CPP1 
rename v2 CPP2
rename v3 CPP3
rename v4 CPP_Mass1
rename v5 CPP_Mass2
rename v6 CPP_Mass3
rename v7 CPP_Rate1
rename v8 CPP_Rate2
rename v9 CPP_Rate3
drop in 1
replace _varname="Emissions(MMT)" in 1
replace _varname="Relative to No CPP, no surcharge (within base case)" in 2
tempfile TableB1_Emissions_`x'
save `TableB1_Emissions_`x''

use ./intermediate_data/Coal_Prod_Basin_`x'.dta, clear
keep if strpos(Basin,"PRB") | strpos(Basin,"Total")
keep Basin P2030* 
drop P2030_*SCC50
rename P2030_Base CPP1
rename P2030_Base_SCC20 CPP2
rename P2030_Base_SCC100 CPP3
rename P2030_CPP_Mass CPP_Mass1
rename P2030_CPP_Mass_SCC20 CPP_Mass2
rename P2030_CPP_Mass_SCC100 CPP_Mass3
rename P2030_CPP_Rate CPP_Rate1
rename P2030_CPP_Rate_SCC20 CPP_Rate2
rename P2030_CPP_Rate_SCC100 CPP_Rate3
rename Basin _varname
replace _varname="PRB production (MST)" in 1
replace _varname="Total coal production (MST)" in 2
foreach y in "CPP" "CPP_Mass" "CPP_Rate"{
forvalues j = 1(1)3{
replace `y'`j'=round(`y'`j',1)
}
}
tempfile TableB1_Productions_`x'
save `TableB1_Productions_`x''

use ./intermediate_data/Firm_Wholesale_Power_Prices_`x',clear
drop if strpos(Scenario,"50% SCC")
keep Scenario Year5
xpose,clear varname 
rename v1 CPP1 
rename v2 CPP2
rename v3 CPP3
rename v4 CPP_Mass1
rename v5 CPP_Mass2
rename v6 CPP_Mass3
rename v7 CPP_Rate1
rename v8 CPP_Rate2
rename v9 CPP_Rate3
drop in 1
local new=_N+1
set obs `new'
replace _varname="Wholesale_electricity_price" in 1
replace _varname="Allowance price" in 2
foreach y in "CPP" "CPP_Mass" "CPP_Rate"{
forvalues j = 1(1)3{
replace `y'`j'=round(`y'`j',0.01)
}
}
tempfile TableB1_Wholesale_price_`x'
save `TableB1_Wholesale_price_`x''

use ./intermediate_data/CO2_Allowance_Price_`x',clear
keep Region P2030*
keep if strpos(Region,"North Central")|strpos(Region,"South Central")|strpos(Region,"Southeast")
drop P2030_SCC50
gen scenario=1 in 1/3
replace scenario=2 in 4/6
reshape wide P2030 P2030_SCC20 P2030_SCC100, i(Region) j(scenario)
rename P20301 CPP_Mass1
rename P2030_SCC201 CPP_Mass2
rename P2030_SCC1001 CPP_Mass3
rename P20302 CPP_Rate1
rename P2030_SCC202 CPP_Rate2
rename P2030_SCC1002 CPP_Rate3
gen CPP1=.
gen CPP2=.
gen CPP3=.
rename Region _varname
order CPP1, after(_varname)
order CPP2, after(CPP1)
order CPP3, after(CPP2)
local new=_N+1
set obs `new'
replace _varname="North Central" in 1
replace _varname="South Central" in 2
replace _varname="Southeast" in 3
replace _varname="Generation (TWh)" in 4
foreach y in "CPP" "CPP_Mass" "CPP_Rate"{
forvalues j = 1(1)3{
replace `y'`j'=round(`y'`j',0.01)
}
}
tempfile TableB1_Allowance_price_`x'
save `TableB1_Allowance_price_`x''

use ./intermediate_data/Generation_Mix_`x',clear
keep Energy P2030*
drop P2030_*SCC50
keep if strpos(Energy,"CC - New")| strpos(Energy,"Solar")| strpos(Energy,"Wind")
xpose,clear varname
rename v1 CC_New
rename v2 Solar
rename v3 Wind
drop in 1
gen Solar_Wind=Solar+Wind
replace Solar_Wind=Solar_Wind/1000
replace CC_New=CC_New/1000
keep CC_New Solar_Wind _varname 
xpose,clear varname
rename P2030_Base CPP1
rename P2030_Base_SCC20 CPP2
rename P2030_Base_SCC100 CPP3
rename P2030_CPP_Mass CPP_Mass1
rename P2030_CPP_Mass_SCC20 CPP_Mass2
rename P2030_CPP_Mass_SCC100 CPP_Mass3
rename P2030_CPP_Rate CPP_Rate1
rename P2030_CPP_Rate_SCC20 CPP_Rate2
rename P2030_CPP_Rate_SCC100 CPP_Rate3
foreach y in "CPP" "CPP_Mass" "CPP_Rate"{
forvalues j = 1(1)3{
replace `y'`j'=round(`y'`j',1)
}
}
gsort -_varname
tempfile TableB1_Generation_`x'
save `TableB1_Generation_`x''

use `TableB1_Emissions_`x'',clear
append using `TableB1_Productions_`x''
append using `TableB1_Wholesale_price_`x''
append using `TableB1_Allowance_price_`x''
append using `TableB1_Generation_`x''
rename _varname Case
order Case, first
tempfile TableB1_`x'
save `TableB1_`x''
preserve
keep Case CPP_Mass*
rename CPP_Mass1 CPP1
rename CPP_Mass2 CPP2
rename CPP_Mass3 CPP3
tempfile TableB1_Mass_`x'
save `TableB1_Mass_`x''
restore

preserve
keep Case CPP_Rate*
rename CPP_Rate1 CPP1
rename CPP_Rate2 CPP2
rename CPP_Rate3 CPP3
tempfile TableB1_Rate_`x'
save `TableB1_Rate_`x''
restore

keep Case CPP1 CPP2 CPP3
append using `TableB1_Mass_`x''
append using `TableB1_Rate_`x''
gen n=_n
save ./intermediate_data/TableB1_`x'.dta,replace
}

use ./intermediate_data/TableB1_P, clear
rename CPP1 Primary_No_surcharge
rename CPP2 Primary_SCC20
rename CPP3 Primary_SCC100
merge 1:1 n using ./intermediate_data/TableB1_S
drop _merge
rename CPP1 Secondary_No_surcharge
rename CPP2 Secondary_SCC20
rename CPP3 Secondary_SCC100
sort n
drop n
save ./output/tables/TableB1.dta, replace


*********************** Write Tables into Excel **********************************
* Table set up
local Tables ./output/tables/Tables.xlsx
capture rm `Tables'
* Table 1
use ./output/tables/Table1.dta,clear
mkmat P2013 P2014 Fed2014 Fed_per, mat(X)
mata: b=xl()
mata: b.create_book("`Tables'","Table 1", "xlsx")
mata: b.set_sheet_gridlines("Table 1","off")
mata: b.set_column_width(1,1,10)
mata: b.set_column_width(2,3,7.5)
mata: b.set_column_width(4,4,13.5)
mata: b.set_column_width(5,5,10.5)
mata: rows=(4,10)
mata: b.set_number_format(rows,(2,4),"number")
mata: b.set_number_format(rows,5,"percent")
mata: b.set_horizontal_align(rows,1,"left")
mata: b.set_font((3,9),(1,5), "Calibri", 9)
mata: b.set_row_height(3,9,13)
mata: b.set_row_height(10,12,10)

putexcel set `Tables', sheet("Table 1") modify
putexcel A1:E1="Table 1: Annual Federal and Non-Federal Coal Production",merge hcenter font(timesnewroman,12,black) bold
putexcel A2:E2="(millions of short tons)",merge hcenter font(timesnewroman,12,black) bold 
putexcel A3="State",left bold border(top)
putexcel B3="Total, 2013" C3="Total, 2014" D3="Federal only, FY2014" E3="Federal percent", bold hcenter border(top)
putexcel A3:E3, border(bottom)
putexcel A4="Wyoming"
putexcel A5="Montana"
putexcel A6="Colorado"
putexcel A7="Utah"
putexcel A8="Other"
putexcel A9="Total"
putexcel B4=matrix(X),hcenter
putexcel A9:E9, border(bottom)
putexcel A10:E10="Sources: EIA (2015b, 2016). Federal percent is computed as the ratio of FY production to the", merge font(Calibri,8)
putexcel A11:E11="weighted average of calendar year 2013 and 2014 production, weighted by the fraction of the", merge font(Calibri,8)
putexcel A12:E12="calendar year in the fiscal year. Excludes refuse recovery.", merge font(Calibri,8)

* Table 2
use ./output/tables/Table2,clear
mkmat Year RSCC2012_20 RSCC2012_50 RSCC2012_100, mat(X)
mata: b=xl()
mata: b.load_book("`Tables'")
mata: b.add_sheet("Table 2")
mata: b.set_sheet("Table 2")
mata: b.set_sheet_gridlines("Table 2","off")
mata: b.set_column_width(2,2,12)
mata: b.set_column_width(3,5,10)
mata: rows=(3,8)
mata: cols=(3,5)
mata: b.set_number_format(rows,cols,"currency_d2_negbra")
mata: b.set_font((2,8),(2,5), "Calibri", 9)
mata: b.set_horizontal_align(rows,2,"center")
mata: b.set_horizontal_align(rows,cols,"right")
mata: b.set_row_height(3,8,13)
mata: b.set_row_height(9,10,12)

putexcel set `Tables', sheet("Table 2") modify
putexcel A1:F1="Table 2: Simulated Phased-In Royalty Surcharges for Federal Coal",merge hcenter font(timesnewroman,12,black) bold
putexcel A2:F2="Indexed to SCC with 10-year linear phase-in (2012$)",merge hcenter font(timesnewroman,12,black) bold 
putexcel B3="Year" C3="20% SCC" D3="50% SCC" E3="100% SCC", hcenter border(top)
putexcel B3:E3, border(bottom)
putexcel B4=matrix(X)
putexcel B8:E8, border(bottom)
putexcel B9:E9="Note: Computed for sub-bituminous coal (heat content 9130 Btu/lb).", merge font(Calibri,9)
putexcel B10:E10="The SCC is the 2013 U.S. Government estimate (OMB 2013).", merge font(Calibri,9)

* Table 3
use ./output/tables/Table3,clear
mata: b=xl()
mata: b.load_book("`Tables'")
mata: b.add_sheet("Table 3")
mata: b.set_sheet("Table 3")
mata: b.set_sheet_gridlines("Table 3","off")
mata: b.set_column_width(1,1,25)
mata: b.set_column_width(2,8,10)
mata: rows=(4,18)
mata: cols=(2,8) 
mata: b.set_number_format(rows,cols,"0.00;(#.##);0;@")
mata: b.set_horizontal_align(rows,cols,"right")
mata: b.set_horizontal_align(rows,1,"left")
mata: b.set_font((2,18),(1,8), "Calibri", 11)
mata: b.set_row_height(2,18,15)
mata: b.set_row_height(19,19,15)

putexcel set `Tables', sheet("Table 3") modify
putexcel A1:H1="Table 3: IPM Results: Electricity and Allowance Prices",merge hcenter font(timesnewroman,12) bold border(bottom)
putexcel B2="Electricity", bold hcenter 
putexcel C2:H2="CO2 Allowance Prices ($/MT CO2)",merge hcenter bold border(bottom)
putexcel A3="Case" B3="price", bold hcenter
putexcel B4="($/MWh)" C4="East Central" D4="North Central" E4="Northeast" F4="South Central" G4="Southeast" H4="West", bold hcenter
putexcel A1:H1, border(bottom)
putexcel C2:H2, border(bottom)
putexcel A4:H4, border(bottom)
putexcel A18:H18, border(bottom)
putexcel A5="No CPP, no royalty surcharge", bold
putexcel A6="No CPP, 20% SCC", bold
putexcel A7="No CPP, 50% SCC", bold
putexcel A8="No CPP, 100% SCC", bold
putexcel A10="CPP mass case, no surcharge", bold
putexcel A11="CPP mass case with 20% SCC", bold
putexcel A12="CPP mass case with 50% SCC", bold
putexcel A13="CPP mass case with 100% SCC", bold
putexcel A15="CPP rate case, no surcharge", bold
putexcel A16="CPP rate case with 20% SCC", bold
putexcel A17="CPP rate case with 50% SCC", bold
putexcel A18="CPP rate case with 100% SCC", bold

mkmat Electricity East North_Central Northeast South_Central Southeast West in 1/4, mat(X1)
mkmat Electricity East North_Central Northeast South_Central Southeast West in 5/8, mat(X2)
mkmat Electricity East North_Central Northeast South_Central Southeast West in 9/12, mat(X3)
putexcel B5=matrix(X1)
putexcel B10=matrix(X2)
putexcel B15=matrix(X3)
putexcel A19:H19="Notes: Prices are 2012 dollars and are generation-weighted averages. Source: IPM simulations by ICF and authors calculations.",merge font(Calibri,11)

* Table 4
use ./output/tables/Table4,clear
mata: b=xl()
mata: b.load_book("`Tables'","xlsx")
mata: b.add_sheet("Table 4")
mata: b.set_sheet("Table 4")
mata: b.set_sheet_gridlines("Table 4","off")
mata: b.set_column_width(1,1,25)
mata: b.set_column_width(2,4,12)
mata: b.set_column_width(5,6,14)
mata: rows=(6,21)
mata: cols=(2,6)
mata: b.set_number_format(rows,2,"account")
mata: b.set_number_format(rows,3,"number")
mata: b.set_number_format(rows,4,"0.0%;-0.0%;0;@")
mata: b.set_number_format(rows,(5,6),"currency_negbra")
mata: b.set_horizontal_align(rows,cols,"right")
mata: b.set_horizontal_align(rows,1,"left")
mata: b.set_font((2,21),(1,6), "Calibri", 11)
mata: b.set_row_height(2,24,15)

putexcel set `Tables', sheet("Table 4") modify
putexcel A1:F1="Table 4: IPM Results: Emissions and Abatement Costs of Royalty Surcharge",merge hcenter font(timesnewroman,12) bold border(bottom)
putexcel B3="CO2 Emissions", bold hcenter 
putexcel B4="in 2030 (MMT)", bold hcenter
putexcel C2:D2="Emissions in 2030 relative to",merge hcenter bold 
putexcel C3:D3="no CPP/no surcharge case", merge hcenter bold
putexcel E2:F2="Cost per ton CO2 avoided,", merge hcenter bold
putexcel E3:F3="relative to no-surcharge case within", merge hcenter bold
putexcel E4:F4="CPP implementation (2012$/MT)", merge hcenter bold
putexcel C5="MMT", hcenter bold
putexcel D5="percent", hcenter bold
putexcel E5="2025", hcenter bold
putexcel F5="2030", hcenter bold
putexcel C4:F4, border(bottom)
putexcel A5:F5, border(bottom)
putexcel A21:F21, border(bottom)

putexcel A6="No CPP, no royalty surcharge", bold
putexcel A7="No CPP, 20% SCC", bold
putexcel A8="No CPP, 50% SCC", bold
putexcel A9="No CPP, 100% SCC", bold
putexcel A11="CPP mass case, no surcharge", bold
putexcel A12="CPP mass case with 20% SCC", bold
putexcel A13="CPP mass case with 50% SCC", bold
putexcel A14="CPP mass case with 100% SCC", bold
putexcel A16="CPP rate case, no surcharge", bold
putexcel A17="CPP rate case with 20% SCC", bold
putexcel A18="CPP rate case with 50% SCC", bold
putexcel A19="CPP rate case with 100% SCC", bold
putexcel A21="Memo: SCC (2012$)"

mkmat Emission Delta percent Abmnt_Cost4 Abmnt_Cost5 in 1/4, mat(X1)
mkmat Emission Delta percent Abmnt_Cost4 Abmnt_Cost5 in 5/8, mat(X2)
mkmat Emission Delta percent Abmnt_Cost4 Abmnt_Cost5 in 9/12, mat(X3)
putexcel B6=matrix(X1)
putexcel B11=matrix(X2)
putexcel B16=matrix(X3)
use ./intermediate_data/Table4_Memo,clear
mkmat v1 v2 in 2, mat(X4)
putexcel E21=matrix(X4)
putexcel A22:F22="Notes: Abatement cost is the increase in the total cost of power production, net of the federal royalty, relative to the zero-",merge font(Calibri,11)
putexcel A23:F23="surcharge CPP case, as a ratio to emissions reductions. Prices are 2012 dollars. The SCC values in the Memo line are the",merge font(Calibri,11)
putexcel A24:F24="values for emissions in 2025 and 2030 in 2012$. Source: IPM simulations by ICF and authors' calculations.",merge font(Calibri,11)

* Table 5
use ./output/tables/Table5,clear
mata: b=xl()
mata: b.load_book("`Tables'","xlsx")
mata: b.add_sheet("Table 5")
mata: b.set_sheet("Table 5")
mata: b.set_sheet_gridlines("Table 5","off")
mata: b.set_column_width(1,1,23)
mata: b.set_column_width(2,3,8.5)
mata: b.set_column_width(4,4,10.5)
mata: b.set_column_width(5,5,9)
mata: b.set_column_width(6,6,11)
mata: b.set_column_width(7,8,16)
mata: rows=(5,18)
mata: cols=(2,8)
mata: b.set_number_format(rows,(2,5),"#,###,###;-#,###,###;0;@")
mata: b.set_number_format(rows,(6,7),"number")
mata: b.set_number_format(rows,8,"0.0%;-0.0%;0;@")
mata: b.set_horizontal_align(rows,cols,"right")
mata: b.set_horizontal_align(rows,1,"left")
mata: b.set_font((2,18),(1,8), "Calibri", 11)
mata: b.set_row_height(2,19,15)

putexcel set `Tables', sheet("Table 5") modify
putexcel A1:H1="Table 5: IPM Results: Generation Mix and PRB Coal Production",merge hcenter font(timesnewroman,12) bold border(bottom)
putexcel B2:D2="Generation (TWh)", merge bold hcenter 
putexcel B3:B4="Coal",merge vcenter hcenter bold
putexcel C3:C4="Gas", merge vcenter hcenter bold
putexcel D3:D4="Solar & Wind", merge vcenter hcenter bold
putexcel E2="New gas", bold hcenter
putexcel E3="generation", hcenter bold
putexcel E4="(TWh)", hcenter bold
putexcel F2="PRB Coal",hcenter bold 
putexcel F3="Production", hcenter bold
putexcel F4="(m short tons)", hcenter bold
putexcel G2:H2="Change, PRB Coal, relative to no-surcharge", merge hcenter bold
putexcel G3:H3="case within CPP implementation", merge hcenter bold
putexcel G4="(m short tons)", hcenter bold
putexcel H4="(%)", hcenter bold

putexcel A1:H1, border(bottom)
putexcel B2:D2, border(bottom)
putexcel A4:H4, border(bottom)
putexcel A18:H18, border(bottom)

putexcel A5="No CPP, no royalty surcharge", bold
putexcel A6="No CPP, 20% SCC", bold
putexcel A7="No CPP, 50% SCC", bold
putexcel A8="No CPP, 100% SCC", bold
putexcel A10="CPP mass case, no surcharge", bold
putexcel A11="CPP mass case with 20% SCC", bold
putexcel A12="CPP mass case with 50% SCC", bold
putexcel A13="CPP mass case with 100% SCC", bold
putexcel A15="CPP rate case, no surcharge", bold
putexcel A16="CPP rate case with 20% SCC", bold
putexcel A17="CPP rate case with 50% SCC", bold
putexcel A18="CPP rate case with 100% SCC", bold

mkmat Coal Gas Solar_Wind New_Gas PRB_Coal_Prod Change_PRB Change_PRB_percent in 1/4, mat(X1)
mkmat Coal Gas Solar_Wind New_Gas PRB_Coal_Prod Change_PRB Change_PRB_percent in 5/8, mat(X2)
mkmat Coal Gas Solar_Wind New_Gas PRB_Coal_Prod Change_PRB Change_PRB_percent in 9/12, mat(X3)
putexcel B5=matrix(X1)
putexcel B10=matrix(X2)
putexcel B15=matrix(X3)
putexcel A19:H19="Notes: Results are for 2030. Source: IPM simulations by ICF and authors' calculations.",merge font(Calibri,11)

* Table 6
use ./output/tables/Table6,clear
mata: b=xl()
mata: b.load_book("`Tables'","xlsx")
mata: b.add_sheet("Table 6")
mata: b.set_sheet("Table 6")
mata: b.set_sheet_gridlines("Table 6","off")
mata: b.set_column_width(1,1,33)
mata: b.set_column_width(2,2,11)
mata: b.set_column_width(3,5,8.5)
mata: b.set_column_width(6,6,11.5)
mata: cols=(2,6)
mata: b.set_number_format(6,cols,"account")
mata: b.set_number_format((7,8),cols,"number")
mata: b.set_number_format(9,cols,"currency_d2_negbra")
mata: b.set_number_format((15,16),cols,"account")
mata: b.set_number_format(18,cols,"account")
mata: b.set_number_format((19,20),cols,"number")
mata: b.set_number_format((21,25),cols,"currency_d2_negbra")
mata: b.set_number_format((27,28),cols,"account")
mata: b.set_horizontal_align((6,28),cols,"right")
mata: b.set_font((2,28),(1,6), "Calibri", 11)
mata: b.set_row_height(2,30,15)

putexcel set `Tables', sheet("Table 6") modify
putexcel A1:F1="Table 6: IPM Results: Comparison of Royalty Surcharge and Quantity Limit Cases",merge hcenter font(timesnewroman,12) bold border(bottom)
putexcel B3="No surcharge", hcenter bold
putexcel C2:D2="Royalty surcharge", merge hcenter bold
putexcel E2:F2="Tonnage production cap", merge hcenter bold
putexcel C3:C4="20% SCC", merge hcenter vcenter bold
putexcel D3:D4="100% SCC", merge hcenter vcenter bold
putexcel E3:E4="50% cap", merge hcenter vcenter bold
putexcel F3="No new leases", hcenter bold
putexcel F4="or renewals", hcenter bold
putexcel C2:F2, border(bottom)
putexcel A4:F4, border(bottom)
putexcel A5:F5, border(bottom)
putexcel A28:F28, border(bottom)

putexcel B5:F5="Panel A. No CPP", merge hcenter bold
putexcel A6="Emissions (MMT)", bold left
putexcel A7="PRB production (MST)",bold left
putexcel A8="Total coal production (MST)", bold left
putexcel A9="Wholesale electricity price ($/MWh)",bold left
putexcel A10="Allowance price",bold left
putexcel A11="North Central", bold right
putexcel A12="South Central",bold right
putexcel A13="Southeast",bold right
putexcel A14="Generation (TWh)", bold left
putexcel A15="Solar+Wind", bold right
putexcel A16="New NGCC", bold right

putexcel B17:F17="Panel B. Mass-based CPP", merge hcenter bold
putexcel A17:F17,border(top)
putexcel A17:F17,border(bottom)
putexcel A18="Emissions (MMT)", bold left
putexcel A19="PRB production (MST)",bold left
putexcel A20="Total coal production (MST)", bold left
putexcel A21="Wholesale electricity price ($/MWh)",bold left
putexcel A22="Allowance price",bold left
putexcel A23="North Central", bold right
putexcel A24="South Central",bold right
putexcel A25="Southeast",bold right
putexcel A26="Generation (TWh)", bold left
putexcel A27="Solar+Wind", bold right
putexcel A28="New NGCC", bold right

mkmat Primary_No_surcharge Primary_SCC20 Primary_SCC100 CPP_Cap50 CPP_NoLimit in 1/11, mat(X1)
mkmat Primary_No_surcharge Primary_SCC20 Primary_SCC100 CPP_Cap50 CPP_NoLimit in 12/22, mat(X2)
putexcel B6=matrix(X1)
putexcel B18=matrix(X2)
putexcel A29:F29="Notes: All results are for 2040, computed under the secondary base case. The tonnage production caps assume a",merge font(Calibri,11)
putexcel A30:F30="20 year linear phase-in. Source: IPM simulations by ICF.",merge font(Calibri,11)

* Table B.1
use ./output/tables/TableB1,clear
mata: b=xl()
mata: b.load_book("`Tables'","xlsx")
mata: b.add_sheet("Table B1")
mata: b.set_sheet("Table B1")
mata: b.set_sheet_gridlines("Table B1","off")
mata: b.set_column_width(1,1,40)
mata: b.set_column_width(2,2,10)
mata: b.set_column_width(3,4,8)
mata: b.set_column_width(5,5,10)
mata: b.set_column_width(6,7,8)
mata: cols=(2,7)
mata: b.set_number_format(5,cols,"account")
mata: b.set_number_format(6,cols,"0.0%;-0.0%;0;@")
mata: b.set_number_format((7,8),cols,"number")
mata: b.set_number_format(9,cols,"currency_d2_negbra")
mata: b.set_number_format((15,16),cols,"number")

mata: b.set_number_format(18,cols,"account")
mata: b.set_number_format(19,cols,"0.0%;-0.0%;0;@")
mata: b.set_number_format((20,21),cols,"number")
mata: b.set_number_format((22,26),cols,"currency_d2_negbra")
mata: b.set_number_format((28,29),cols,"number")

mata: b.set_number_format(31,cols,"account")
mata: b.set_number_format(32,cols,"0.0%;-0.0%;0;@")
mata: b.set_number_format((33,34),cols,"number")
mata: b.set_number_format((35,39),cols,"currency_d2_negbra")
mata: b.set_number_format((41,42),cols,"number")
mata: b.set_horizontal_align((5,42),cols,"right")
mata: b.set_font((2,42),(1,7), "Calibri", 11)
mata: b.set_row_height(2,42,15)

putexcel set `Tables', sheet("Table B1") modify
putexcel A1:G1="Table B.1: IPM Results: Comparison of the Primary and Secondary Base Cases",merge hcenter font(timesnewroman,12) bold border(bottom)
putexcel B2:D2="Primary Base Case", merge hcenter bold
putexcel E2:G2="Secondary Base Case", merge hcenter bold
putexcel B3="No surcharge", hcenter bold
putexcel C3="20% SCC", hcenter bold
putexcel D3="100% SCC", hcenter bold
putexcel E3="No surcharge", hcenter bold
putexcel F3="20% SCC", hcenter bold
putexcel G3="100% SCC", hcenter bold
putexcel B4:D4="A. No CPP", merge hcenter bold
putexcel E4:G4="A. No CPP", merge hcenter bold

putexcel B2:G2, border(bottom)
putexcel B3:G3, border(bottom)
putexcel A4:G4, border(bottom)
putexcel A2:A4, border(right)
putexcel D2:D4, border(right)
putexcel A42:G42, border(bottom)

putexcel A5="Emissions (MMT)", bold left
putexcel A6="Relative to No CPP, no surcharge (within base case)", bold right
putexcel A7="PRB production (MST)",bold left
putexcel A8="Total coal production (MST)", bold left
putexcel A9="Wholesale electricity price ($/MWh)",bold left
putexcel A10="Allowance price",bold left
putexcel A11="North Central", bold right
putexcel A12="South Central",bold right
putexcel A13="Southeast",bold right
putexcel A14="Generation (TWh)", bold left
putexcel A15="Solar+Wind", bold right
putexcel A16="New NGCC", bold right

putexcel B17:D17="B. CPP mass-based", merge hcenter bold
putexcel E17:G17="B. CPP mass-based", merge hcenter bold
putexcel A17:G17,border(top)
putexcel A17:G17,border(bottom)
putexcel B17,border(left)
putexcel B17,border(right)
putexcel A18="Emissions (MMT)", bold left
putexcel A19="Relative to No CPP, no surcharge (within base case)", bold right
putexcel A20="PRB production (MST)",bold left
putexcel A21="Total coal production (MST)", bold left
putexcel A22="Wholesale electricity price ($/MWh)",bold left
putexcel A23="Allowance price",bold left
putexcel A24="North Central", bold right
putexcel A25="South Central",bold right
putexcel A26="Southeast",bold right
putexcel A27="Generation (TWh)", bold left
putexcel A28="Solar+Wind", bold right
putexcel A29="New NGCC", bold right

putexcel B30:D30="C. CPP rate-based", merge hcenter bold
putexcel E30:G30="B. CPP rate-based", merge hcenter bold
putexcel A30:G30,border(top)
putexcel A30:G30,border(bottom)
putexcel B30,border(left)
putexcel B30,border(right)
putexcel A31="Emissions (MMT)", bold left
putexcel A32="Relative to No CPP, no surcharge (within base case)", bold right
putexcel A33="PRB production (MST)",bold left
putexcel A34="Total coal production (MST)", bold left
putexcel A35="Wholesale electricity price ($/MWh)",bold left
putexcel A36="Allowance price",bold left
putexcel A37="North Central", bold right
putexcel A38="South Central",bold right
putexcel A39="Southeast",bold right
putexcel A40="Generation (TWh)", bold left
putexcel A41="Solar+Wind", bold right
putexcel A42="New NGCC", bold right

mkmat Primary_No_surcharge Primary_SCC20 Primary_SCC100 Secondary_No_surcharge Secondary_SCC20 Secondary_SCC100 in 1/12, mat(X1)
mkmat Primary_No_surcharge Primary_SCC20 Primary_SCC100 Secondary_No_surcharge Secondary_SCC20 Secondary_SCC100 in 13/24, mat(X2)
mkmat Primary_No_surcharge Primary_SCC20 Primary_SCC100 Secondary_No_surcharge Secondary_SCC20 Secondary_SCC100 in 25/36, mat(X3)

putexcel B5=matrix(X1)
putexcel B18=matrix(X2)
putexcel B31=matrix(X3)
putexcel A43:G43="Notes: All results are for 2030. Source: IPM simulations by ICF. See Section 4 for a discussion of the assumptions used in each base case.",merge font(Calibri,10)
