*************************************************************************
* PROJECT: grs_federal_coal_reform
* SOURCE OF THE RAW DATA: GRS_data.xlsx
* AUTHORS: Hui Zhou and Todd Gerarden
* DATE: February 2019
* STATA VERSION: Stata/MP 15.1 for Mac (Revision 17 Dec 2018)
**************************************************************************

clear

********************************************************************************
*                         DATA FOR TABLE 1                                    *
********************************************************************************
* Annual Federal and Non-Federal Coal Production 2013-2014
import excel State=A P2013=B P2014=C Fed2014=D using ./input/GRS_data.xlsx, sheet("EIA - Coal Production 2013-2014") clear
save ./intermediate_data/Coal_Prod_2013_2014, replace

********************************************************************************
*                         DATA FOR TABLE 2                                    *
********************************************************************************
* Price Indexes
import excel year=A PCE=B infl_ann_PCE=C infl_cum_PCE=D CPI=F infl_ann_CPI=G infl_cum_CPI=H ///
using ./input/GRS_data.xlsx, sheet("Price Indexes") clear
keep if _n>=4 & _n<=12
destring PCE infl* CPI,replace
gen Year=.
forvalues i=2007(1)2015{
replace Year=`i' if strpos(year,"`i'")
}
order Year, first
drop year
save ./intermediate_data/Price_Indexes.dta,replace

* Per-ton surchage
import excel Year=A P2007_1=B P2007_2=C P2007_3=D P2007_4=E using ./input/GRS_data.xlsx, sheet("Social Cost of Carbon") clear
keep in 8/43
destring Year P*, replace
save ./intermediate_data/Per_ton_Surcharge.dta,replace

* CO2 to short tons
import excel factor=A using ./input/GRS_data.xlsx, sheet("MT CO2 per Short Ton Coal") clear
keep in 2
destring factor,replace
save ./intermediate_data/CO2_short_ton.dta, replace

* Ramp-in Factor
import excel Ramp_in_factor=A using ./input/GRS_data.xlsx, sheet("Ramp-in Factor") clear
drop in 1
destring Ramp_in_factor,replace
gen Year=_n+2014
save ./intermediate_data/Ramp_in_factor.dta, replace

********************************************************************************
*                         DATA FOR TABLE 3                                    *
********************************************************************************
* Primary case and secondary case

foreach x in "P" "S"{
* Firm Wholesale Power Prices 
import excel Scenario=B Year1=C Year2=D Year3=E Year4=F Year5=G Year6=H Year7=I ///
using ./input/GRS_data.xlsx, sheet("Firm Wholesale Power Prices (`x')") clear
keep in 5/18
drop in 5
drop in 9
gen scenario=_n
destring Year1,replace
save ./intermediate_data/Firm_Wholesale_Power_Prices_`x'.dta,replace

* CO2 Allowance Price 
import excel Region=B ///
P2016=C             P2018=D             P2020=E             P2025=F             P2030=G             P2040=H             P2050=I ///
P2016_SCC20=L       P2018_SCC20=M       P2020_SCC20=N       P2025_SCC20=O       P2030_SCC20=P       P2040_SCC20=Q       P2050_SCC20=R ///
P2016_SCC50=U       P2018_SCC50=V       P2020_SCC50=W       P2025_SCC50=X       P2030_SCC50=Y       P2040_SCC50=Z       P2050_SCC50=AA ///
P2016_SCC100=AD     P2018_SCC100=AE     P2020_SCC100=AF     P2025_SCC100=AG     P2030_SCC100=AH     P2040_SCC100=AI     P2050_SCC100=AJ ///
using ./input/GRS_data.xlsx, sheet("CO2 Allowance Prices (`x')") clear
keep in 5/19
drop in 7/9
gen Scenario="CPP_Mass" in 1/6
replace Scenario="CPP_Rate" in 7/12
save ./intermediate_data/CO2_Allowance_Price_`x'.dta,replace

* Total US CO2 Emissions 
import excel Scenario=B Year1=C Year2=D Year3=E Year4=F Year5=G Year6=H Year7=I ///
using ./input/GRS_data.xlsx, sheet("Total US CO2 Emissions (`x')") clear
keep in 5/18
drop in 5
drop in 9
destring Year1,replace

forvalues i=1(1)7{
gen Emission`i'=0.907185*Year`i'/1000
}
gen scenario=_n
preserve
keep scenario Scenario Emission*
save ./intermediate_data/Total_US_CO2_Emissions_`x'.dta,replace
restore

* Cumulative Emissions Reductions
forvalues i=1(1)7{
gen D`i'=0.907185*(Year`i'-Year`i'[1])/1000 in 1/4  //Mill metric tons Delta to Base Case
replace D`i'=0.907185*(Year`i'-Year`i'[1])/1000 if _n==5|_n==9 //Mill metric tons Delta to CPP Mass Case
replace D`i'=0.907185*(Year`i'-Year`i'[5])/1000 in 6/8 //Mill metric tons Delta to CPP Mass Case
replace D`i'=0.907185*(Year`i'-Year`i'[9])/1000 in 10/12  //Mill metric tons Delta to CPP Rate Case
}

// Generate cumulative emissions relative to Base Case (metric Gton)
gen R2016=D1/1000
gen R2017=R2016+(0.5*D1+0.5*D2)/1000
gen R2018=R2017+D2/1000
gen R2019=R2018+(0.5*D2+0.5*D3)/1000
gen R2020=R2019+D3/1000
forvalues i=2021(1)2024{
   local j=`i'-1
   gen R`i'=R`j'+((5-`i'+2020)*D3+(5-2025+`i')*D4)/(5*1000)
}
gen R2025=R2024+D4/1000
forvalues i=2026(1)2029{
   local j=`i'-1
   gen R`i'=R`j'+((5-`i'+2025)*D4+(5-2030+`i')*D5)/(5*1000)
}
gen R2030=R2029+D5/1000
forvalues i=2031(1)2039{
  local j=`i'-1
  gen R`i'=R`j'+((10-`i'+2030)*D5+(10-2040+`i')*D6)/(10*1000)
  }
gen R2040=R2039+D6/1000

keep Scenario R*
save ./intermediate_data/Cumul_emissions_reductions_`x'.dta,replace

* Total Production Cost  
import excel Scenario=B Year1=C Year2=D Year3=E Year4=F Year5=G Year6=H Year7=I ///
using ./input/GRS_data.xlsx, sheet("Total Production Costs (`x')") clear
keep in 5/18
drop in 5
drop in 9
gen scenario=_n
save ./intermediate_data/Total_Production_Costs_`x'.dta, replace
}
*******************************************************************************
*                         DATA FOR TABLE 4                                    *
********************************************************************************
* PRB Coal Production 
foreach x in "P" "S"{ 
import excel Region=B ///
P2016_Base=C             P2018_Base=D             P2020_Base=E             P2025_Base=F             P2030_Base=G             P2040_Base=H             P2050_Base=I ///
P2016_Base_SCC20=L       P2018_Base_SCC20=M       P2020_Base_SCC20=N       P2025_Base_SCC20=O       P2030_Base_SCC20=P       P2040_Base_SCC20=Q       P2050_Base_SCC20=R ///
P2016_Base_SCC50=U       P2018_Base_SCC50=V       P2020_Base_SCC50=W       P2025_Base_SCC50=X       P2030_Base_SCC50=Y       P2040_Base_SCC50=Z       P2050_Base_SCC50=AA ///
P2016_Base_SCC100=AD     P2018_Base_SCC100=AE     P2020_Base_SCC100=AF     P2025_Base_SCC100=AG     P2030_Base_SCC100=AH     P2040_Base_SCC100=AI     P2050_Base_SCC100=AJ ///
P2016_CPP_Mass=BN        P2018_CPP_Mass=BO        P2020_CPP_Mass=BP        P2025_CPP_Mass=BQ        P2030_CPP_Mass=BR        P2040_CPP_Mass=BS        P2050_CPP_Mass=BT ///
P2016_CPP_Mass_SCC20=BW  P2018_CPP_Mass_SCC20=BX  P2020_CPP_Mass_SCC20=BY  P2025_CPP_Mass_SCC20=BZ  P2030_CPP_Mass_SCC20=CA  P2040_CPP_Mass_SCC20=CB  P2050_CPP_Mass_SCC20=CC ///
P2016_CPP_Mass_SCC50=CF  P2018_CPP_Mass_SCC50=CG  P2020_CPP_Mass_SCC50=CH  P2025_CPP_Mass_SCC50=CI  P2030_CPP_Mass_SCC50=CJ  P2040_CPP_Mass_SCC50=CK  P2050_CPP_Mass_SCC50=CL ///
P2016_CPP_Mass_SCC100=CO P2018_CPP_Mass_SCC100=CP P2020_CPP_Mass_SCC100=CQ P2025_CPP_Mass_SCC100=CR P2030_CPP_Mass_SCC100=CS P2040_CPP_Mass_SCC100=CT P2050_CPP_Mass_SCC100=CU ///
P2016_CPP_Rate=DY        P2018_CPP_Rate=DZ        P2020_CPP_Rate=EA        P2025_CPP_Rate=EB        P2030_CPP_Rate=EC        P2040_CPP_Rate=ED        P2050_CPP_Rate=EE ///
P2016_CPP_Rate_SCC20=EH   P2018_CPP_Rate_SCC20=EI  P2020_CPP_Rate_SCC20=EJ  P2025_CPP_Rate_SCC20=EK  P2030_CPP_Rate_SCC20=EL  P2040_CPP_Rate_SCC20=EM  P2050_CPP_Rate_SCC20=EN ///
P2016_CPP_Rate_SCC50=EQ  P2018_CPP_Rate_SCC50=ER  P2020_CPP_Rate_SCC50=ES  P2025_CPP_Rate_SCC50=ET  P2030_CPP_Rate_SCC50=EU  P2040_CPP_Rate_SCC50=EV  P2050_CPP_Rate_SCC50=EW ///
P2016_CPP_Rate_SCC100=EZ P2018_CPP_Rate_SCC100=FA P2020_CPP_Rate_SCC100=FB P2025_CPP_Rate_SCC100=FC P2030_CPP_Rate_SCC100=FD P2040_CPP_Rate_SCC100=FE P2050_CPP_Rate_SCC100=FF ///
using ./input/GRS_data.xlsx, sheet("PRB Coal Production (`x')") clear

keep in 6/18

ds P*, has(type string)
foreach v in `r(varlist)' {
destring `v',replace
}
save ./intermediate_data/PRB_Coal_Production_`x'.dta,replace

* Mine mouth price
import excel Region=B ///
P2016_Base=C             P2018_Base=D             P2020_Base=E             P2025_Base=F             P2030_Base=G             P2040_Base=H             P2050_Base=I ///
P2016_Base_SCC20=L       P2018_Base_SCC20=M       P2020_Base_SCC20=N       P2025_Base_SCC20=O       P2030_Base_SCC20=P       P2040_Base_SCC20=Q       P2050_Base_SCC20=R ///
P2016_Base_SCC50=U       P2018_Base_SCC50=V       P2020_Base_SCC50=W       P2025_Base_SCC50=X       P2030_Base_SCC50=Y       P2040_Base_SCC50=Z       P2050_Base_SCC50=AA ///
P2016_Base_SCC100=AD     P2018_Base_SCC100=AE     P2020_Base_SCC100=AF     P2025_Base_SCC100=AG     P2030_Base_SCC100=AH     P2040_Base_SCC100=AI     P2050_Base_SCC100=AJ ///
P2016_CPP_Mass=BN        P2018_CPP_Mass=BO        P2020_CPP_Mass=BP        P2025_CPP_Mass=BQ        P2030_CPP_Mass=BR        P2040_CPP_Mass=BS        P2050_CPP_Mass=BT ///
P2016_CPP_Mass_SCC20=BW  P2018_CPP_Mass_SCC20=BX  P2020_CPP_Mass_SCC20=BY  P2025_CPP_Mass_SCC20=BZ  P2030_CPP_Mass_SCC20=CA  P2040_CPP_Mass_SCC20=CB  P2050_CPP_Mass_SCC20=CC ///
P2016_CPP_Mass_SCC50=CF  P2018_CPP_Mass_SCC50=CG  P2020_CPP_Mass_SCC50=CH  P2025_CPP_Mass_SCC50=CI  P2030_CPP_Mass_SCC50=CJ  P2040_CPP_Mass_SCC50=CK  P2050_CPP_Mass_SCC50=CL ///
P2016_CPP_Mass_SCC100=CO P2018_CPP_Mass_SCC100=CP P2020_CPP_Mass_SCC100=CQ P2025_CPP_Mass_SCC100=CR P2030_CPP_Mass_SCC100=CS P2040_CPP_Mass_SCC100=CT P2050_CPP_Mass_SCC100=CU ///
P2016_CPP_Rate=DY        P2018_CPP_Rate=DZ        P2020_CPP_Rate=EA        P2025_CPP_Rate=EB        P2030_CPP_Rate=EC        P2040_CPP_Rate=ED        P2050_CPP_Rate=EE ///
P2016_CPP_Rate_SCC20=EH  P2018_CPP_Rate_SCC20=EI  P2020_CPP_Rate_SCC20=EJ  P2025_CPP_Rate_SCC20=EK  P2030_CPP_Rate_SCC20=EL  P2040_CPP_Rate_SCC20=EM  P2050_CPP_Rate_SCC20=EN ///
P2016_CPP_Rate_SCC50=EQ  P2018_CPP_Rate_SCC50=ER  P2020_CPP_Rate_SCC50=ES  P2025_CPP_Rate_SCC50=ET  P2030_CPP_Rate_SCC50=EU  P2040_CPP_Rate_SCC50=EV  P2050_CPP_Rate_SCC50=EW ///
P2016_CPP_Rate_SCC100=EZ P2018_CPP_Rate_SCC100=FA P2020_CPP_Rate_SCC100=FB P2025_CPP_Rate_SCC100=FC P2030_CPP_Rate_SCC100=FD P2040_CPP_Rate_SCC100=FE P2050_CPP_Rate_SCC100=FF ///
using ./input/GRS_data.xlsx, sheet("Coal Prices (`x')") clear

keep in 5/9

* Replace all "N/A" to 0
ds P*, has(type string)
foreach v in `r(varlist)' {
replace `v' ="0" if `v'=="N/A"
destring `v',replace
}
save ./intermediate_data/Mine_mouth_price_`x'.dta, replace

* Social Cost of Carbon
import excel Year=A SCC=C using ./input/GRS_data.xlsx, sheet("Social Cost of Carbon") clear
drop in 1/7
destring Year SCC,replace
save ./intermediate_data/SCC.dta,replace



*******************************************************************************
*                         DATA FOR TABLE 5                                    *
********************************************************************************
* Generation Mix
import excel Energy=B ///
P2016_Base=C             P2018_Base=D             P2020_Base=E             P2025_Base=F             P2030_Base=G             P2040_Base=H             P2050_Base=I ///
P2016_Base_SCC20=L       P2018_Base_SCC20=M       P2020_Base_SCC20=N       P2025_Base_SCC20=O       P2030_Base_SCC20=P       P2040_Base_SCC20=Q       P2050_Base_SCC20=R ///
P2016_Base_SCC50=U       P2018_Base_SCC50=V       P2020_Base_SCC50=W       P2025_Base_SCC50=X       P2030_Base_SCC50=Y       P2040_Base_SCC50=Z       P2050_Base_SCC50=AA ///
P2016_Base_SCC100=AD     P2018_Base_SCC100=AE     P2020_Base_SCC100=AF     P2025_Base_SCC100=AG     P2030_Base_SCC100=AH     P2040_Base_SCC100=AI     P2050_Base_SCC100=AJ ///
P2016_CPP_Mass=BN        P2018_CPP_Mass=BO        P2020_CPP_Mass=BP        P2025_CPP_Mass=BQ        P2030_CPP_Mass=BR        P2040_CPP_Mass=BS        P2050_CPP_Mass=BT ///
P2016_CPP_Mass_SCC20=BW  P2018_CPP_Mass_SCC20=BX  P2020_CPP_Mass_SCC20=BY  P2025_CPP_Mass_SCC20=BZ  P2030_CPP_Mass_SCC20=CA  P2040_CPP_Mass_SCC20=CB  P2050_CPP_Mass_SCC20=CC ///
P2016_CPP_Mass_SCC50=CF  P2018_CPP_Mass_SCC50=CG  P2020_CPP_Mass_SCC50=CH  P2025_CPP_Mass_SCC50=CI  P2030_CPP_Mass_SCC50=CJ  P2040_CPP_Mass_SCC50=CK  P2050_CPP_Mass_SCC50=CL ///
P2016_CPP_Mass_SCC100=CO P2018_CPP_Mass_SCC100=CP P2020_CPP_Mass_SCC100=CQ P2025_CPP_Mass_SCC100=CR P2030_CPP_Mass_SCC100=CS P2040_CPP_Mass_SCC100=CT P2050_CPP_Mass_SCC100=CU ///
P2016_CPP_Rate=DY        P2018_CPP_Rate=DZ        P2020_CPP_Rate=EA        P2025_CPP_Rate=EB        P2030_CPP_Rate=EC        P2040_CPP_Rate=ED        P2050_CPP_Rate=EE ///
P2016_CPP_Rate_SCC20=EH  P2018_CPP_Rate_SCC20=EI  P2020_CPP_Rate_SCC20=EJ  P2025_CPP_Rate_SCC20=EK  P2030_CPP_Rate_SCC20=EL  P2040_CPP_Rate_SCC20=EM  P2050_CPP_Rate_SCC20=EN ///
P2016_CPP_Rate_SCC50=EQ  P2018_CPP_Rate_SCC50=ER  P2020_CPP_Rate_SCC50=ES  P2025_CPP_Rate_SCC50=ET  P2030_CPP_Rate_SCC50=EU  P2040_CPP_Rate_SCC50=EV  P2050_CPP_Rate_SCC50=EW ///
P2016_CPP_Rate_SCC100=EZ P2018_CPP_Rate_SCC100=FA P2020_CPP_Rate_SCC100=FB P2025_CPP_Rate_SCC100=FC P2030_CPP_Rate_SCC100=FD P2040_CPP_Rate_SCC100=FE P2050_CPP_Rate_SCC100=FF ///
using ./input/GRS_data.xlsx, sheet("Generation Mix (`x')") clear
keep in 5/20
save ./intermediate_data/Generation_Mix_`x'.dta,replace

* Coal Production by Basin
import excel Basin=B ///
P2016_Base=C             P2018_Base=D             P2020_Base=E             P2025_Base=F             P2030_Base=G             P2040_Base=H             P2050_Base=I ///
P2016_Base_SCC20=L       P2018_Base_SCC20=M       P2020_Base_SCC20=N       P2025_Base_SCC20=O       P2030_Base_SCC20=P       P2040_Base_SCC20=Q       P2050_Base_SCC20=R ///
P2016_Base_SCC50=U       P2018_Base_SCC50=V       P2020_Base_SCC50=W       P2025_Base_SCC50=X       P2030_Base_SCC50=Y       P2040_Base_SCC50=Z       P2050_Base_SCC50=AA ///
P2016_Base_SCC100=AD     P2018_Base_SCC100=AE     P2020_Base_SCC100=AF     P2025_Base_SCC100=AG     P2030_Base_SCC100=AH     P2040_Base_SCC100=AI     P2050_Base_SCC100=AJ ///
P2016_CPP_Mass=BN        P2018_CPP_Mass=BO        P2020_CPP_Mass=BP        P2025_CPP_Mass=BQ        P2030_CPP_Mass=BR        P2040_CPP_Mass=BS        P2050_CPP_Mass=BT ///
P2016_CPP_Mass_SCC20=BW  P2018_CPP_Mass_SCC20=BX  P2020_CPP_Mass_SCC20=BY  P2025_CPP_Mass_SCC20=BZ  P2030_CPP_Mass_SCC20=CA  P2040_CPP_Mass_SCC20=CB  P2050_CPP_Mass_SCC20=CC ///
P2016_CPP_Mass_SCC50=CF  P2018_CPP_Mass_SCC50=CG  P2020_CPP_Mass_SCC50=CH  P2025_CPP_Mass_SCC50=CI  P2030_CPP_Mass_SCC50=CJ  P2040_CPP_Mass_SCC50=CK  P2050_CPP_Mass_SCC50=CL ///
P2016_CPP_Mass_SCC100=CO P2018_CPP_Mass_SCC100=CP P2020_CPP_Mass_SCC100=CQ P2025_CPP_Mass_SCC100=CR P2030_CPP_Mass_SCC100=CS P2040_CPP_Mass_SCC100=CT P2050_CPP_Mass_SCC100=CU ///
P2016_CPP_Rate=DY        P2018_CPP_Rate=DZ        P2020_CPP_Rate=EA        P2025_CPP_Rate=EB        P2030_CPP_Rate=EC        P2040_CPP_Rate=ED        P2050_CPP_Rate=EE ///
P2016_CPP_Rate_SCC20=EH  P2018_CPP_Rate_SCC20=EI  P2020_CPP_Rate_SCC20=EJ  P2025_CPP_Rate_SCC20=EK  P2030_CPP_Rate_SCC20=EL  P2040_CPP_Rate_SCC20=EM  P2050_CPP_Rate_SCC20=EN ///
P2016_CPP_Rate_SCC50=EQ  P2018_CPP_Rate_SCC50=ER  P2020_CPP_Rate_SCC50=ES  P2025_CPP_Rate_SCC50=ET  P2030_CPP_Rate_SCC50=EU  P2040_CPP_Rate_SCC50=EV  P2050_CPP_Rate_SCC50=EW ///
P2016_CPP_Rate_SCC100=EZ P2018_CPP_Rate_SCC100=FA P2020_CPP_Rate_SCC100=FB P2025_CPP_Rate_SCC100=FC P2030_CPP_Rate_SCC100=FD P2040_CPP_Rate_SCC100=FE P2050_CPP_Rate_SCC100=FF ///
using ./input/GRS_data.xlsx, sheet("Coal Production by Basin (`x')") clear
keep in 6/12
ds P*, has(type string)
foreach v in `r(varlist)' {
destring `v',replace
}
save ./intermediate_data/Coal_Prod_Basin_`x'.dta,replace
}

*******************************************************************************
*                         DATA FOR TABLE 6                                    *
********************************************************************************
* Total US CO2 Emissions (L)
import excel Scenario=B Year1=C Year2=D Year3=E Year4=F Year5=G Year6=H Year7=I ///
using ./input/GRS_data.xlsx, sheet("Total US CO2 Emissions (L)") clear
keep in 3/8
destring Year1,replace

forvalues i=1(1)7{
gen Emission`i'=0.907185*Year`i'/1000
}
gen scenario=_n
keep scenario Scenario Emission*
save ./intermediate_data/Total_US_CO2_Emissions_L.dta,replace

* PRB Coal Production (L)
import excel Region=B ///
P2016_Base1=C       P2018_Base1=D       P2020_Base1=E       P2025_Base1=F       P2030_Base1=G       P2040_Base1=H       P2050_Base1=I ///
P2016_Base2=L       P2018_Base2=M       P2020_Base2=N       P2025_Base2=O       P2030_Base2=P       P2040_Base2=Q       P2050_Base2=R ///
P2016_Base3=U       P2018_Base3=V       P2020_Base3=W       P2025_Base3=X       P2030_Base3=Y       P2040_Base3=Z       P2050_Base3=AA ///
P2016_CPP_Mass1=AV        P2018_CPP_Mass1=AW        P2020_CPP_Mass1=AX        P2025_CPP_Mass1=AY        P2030_CPP_Mass1=AZ        P2040_CPP_Mass1=BA        P2050_CPP_Mass1=BB ///
P2016_CPP_Mass2=BE        P2018_CPP_Mass2=BF        P2020_CPP_Mass2=BG        P2025_CPP_Mass2=BH        P2030_CPP_Mass2=BI        P2040_CPP_Mass2=BJ        P2050_CPP_Mass2=BK ///
P2016_CPP_Mass3=BN        P2018_CPP_Mass3=BO        P2020_CPP_Mass3=BP        P2025_CPP_Mass3=BQ        P2030_CPP_Mass3=BR        P2040_CPP_Mass3=BS        P2050_CPP_Mass3=BT ///
using ./input/GRS_data.xlsx, sheet("PRB Coal Production (L)") clear
keep in 6/18
ds P*, has(type string)
foreach v in `r(varlist)' {
destring `v',replace
}
save ./intermediate_data/PRB_Coal_Production_L.dta,replace

* Firm Wholesale Power Prices (L)
import excel Scenario=B Year1=C Year2=D Year3=E Year4=F Year5=G Year6=H Year7=I ///
using ./input/GRS_data.xlsx, sheet("Firm Wholesale Power Prices (L)") clear
keep in 3/8
gen scenario=_n
destring Year1,replace
save ./intermediate_data/Firm_Wholesale_Power_Prices_L.dta,replace

* CO2 Allowance Price (L)
import excel Region=B ///
P2016_Base1=C       P2018_Base1=D       P2020_Base1=E       P2025_Base1=F       P2030_Base1=G       P2040_Base1=H       P2050_Base1=I ///
P2016_Base2=L       P2018_Base2=M       P2020_Base2=N       P2025_Base2=O       P2030_Base2=P       P2040_Base2=Q       P2050_Base2=R ///
P2016_Base3=U       P2018_Base3=V       P2020_Base3=W       P2025_Base3=X       P2030_Base3=Y       P2040_Base3=Z       P2050_Base3=AA ///
using ./input/GRS_data.xlsx, sheet("CO2 Allowance Prices (L)") clear
keep in 3/8
save ./intermediate_data/CO2_Allowance_Price_L.dta,replace

* Generation Mix (L)
import excel Energy=B ///
P2016_Base1=C       P2018_Base1=D       P2020_Base1=E       P2025_Base1=F       P2030_Base1=G       P2040_Base1=H       P2050_Base1=I ///
P2016_Base2=L       P2018_Base2=M       P2020_Base2=N       P2025_Base2=O       P2030_Base2=P       P2040_Base2=Q       P2050_Base2=R ///
P2016_Base3=U       P2018_Base3=V       P2020_Base3=W       P2025_Base3=X       P2030_Base3=Y       P2040_Base3=Z       P2050_Base3=AA ///
P2016_CPP_Mass1=AV        P2018_CPP_Mass1=AW        P2020_CPP_Mass1=AX        P2025_CPP_Mass1=AY        P2030_CPP_Mass1=AZ        P2040_CPP_Mass1=BA        P2050_CPP_Mass1=BB ///
P2016_CPP_Mass2=BE        P2018_CPP_Mass2=BF        P2020_CPP_Mass2=BG        P2025_CPP_Mass2=BH        P2030_CPP_Mass2=BI        P2040_CPP_Mass2=BJ        P2050_CPP_Mass2=BK ///
P2016_CPP_Mass3=BN        P2018_CPP_Mass3=BO        P2020_CPP_Mass3=BP        P2025_CPP_Mass3=BQ        P2030_CPP_Mass3=BR        P2040_CPP_Mass3=BS        P2050_CPP_Mass3=BT ///
using ./input/GRS_data.xlsx, sheet("Generation Mix (L)") clear
keep in 5/20
save ./intermediate_data/Generation_Mix_L.dta,replace

* Coal Production by Basin (L)
import excel Basin=B ///
P2016_Base1=C       P2018_Base1=D       P2020_Base1=E       P2025_Base1=F       P2030_Base1=G       P2040_Base1=H       P2050_Base1=I ///
P2016_Base2=L       P2018_Base2=M       P2020_Base2=N       P2025_Base2=O       P2030_Base2=P       P2040_Base2=Q       P2050_Base2=R ///
P2016_Base3=U       P2018_Base3=V       P2020_Base3=W       P2025_Base3=X       P2030_Base3=Y       P2040_Base3=Z       P2050_Base3=AA ///
P2016_CPP_Mass1=AV        P2018_CPP_Mass1=AW        P2020_CPP_Mass1=AX        P2025_CPP_Mass1=AY        P2030_CPP_Mass1=AZ        P2040_CPP_Mass1=BA        P2050_CPP_Mass1=BB ///
P2016_CPP_Mass2=BE        P2018_CPP_Mass2=BF        P2020_CPP_Mass2=BG        P2025_CPP_Mass2=BH        P2030_CPP_Mass2=BI        P2040_CPP_Mass2=BJ        P2050_CPP_Mass2=BK ///
P2016_CPP_Mass3=BN        P2018_CPP_Mass3=BO        P2020_CPP_Mass3=BP        P2025_CPP_Mass3=BQ        P2030_CPP_Mass3=BR        P2040_CPP_Mass3=BS        P2050_CPP_Mass3=BT ///
using ./input/GRS_data.xlsx, sheet("Coal Production by Basin (L)") clear
keep in 4/10
ds P*, has(type string)
foreach v in `r(varlist)' {
destring `v',replace
}
save ./intermediate_data/Coal_Prod_Basin_L.dta,replace


*******************************************************************************
*                         DATA FOR FIGURE 1                                    *
********************************************************************************
import excel Region=A P2017=B P2016=C P2015=D P2014=E P2013=F P2012=G P2011=H P2010=I P2009=J P2008=K ///
P2007=L P2006=M P2005=N P2004=O P2003=P P2002=Q P2001=R using ./input/GRS_data.xlsx, sheet("EIA - Past Production by Region") clear
keep in 6/17
save ./intermediate_data/EIA_Prod_Region.dta,replace

*******************************************************************************
*                         DATA FOR FIGURE 2                                    *
********************************************************************************
* Lease data
import excel Yrs_to_adj=I Tons=W using ./input/GRS_data.xlsx, sheet("Lease Data") clear
drop in 1/2
destring Yrs_to_adj, replace
replace Tons="." if Tons=="-"
destring Tons, replace
keep in 1/330
save ./intermediate_data/Lease_data.dta, replace
