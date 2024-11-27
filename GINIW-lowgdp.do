
** Install additional modules
*findit ineqerr
*findit lorentz
ssc install ineqdeco
ssc install fedistr
ssc install lorenz

clear all
cd "C:\Users\wilai\OneDrive\Desktop\Master's Thesis"

**  Import dataset

clear all

import delimited "lowgdp-77.csv", clear
gen lngdppc = ln(gdppc)
gen lngdppc_squared = lngdppc^2
gen lngdppc_cubed = lngdppc^3
*gen lnconstruction_lengthpc = ln(allconstruction_lengthpc)
*gen lnedu_graduate = ln(edu_graduate +1)
gen lnurban_modis =ln(urban_modis)
gen lnpop_density =ln(pop_density)

*gen lnconstruction_share = ln(1000*construction_share)
*gen lnagri_share = ln(100000*agri_share)
*gen lnmanu_share = ln(100000*manu_share)
*gen lnknowledge_service_share = ln(100000*knowledge_service_share)

label  variable lngdppc "GDP per capita (log)"
label variable lngdppc_squared "GDP per capita$^2$ (log)"
label variable lngdppc_cubed "GDP per capita$^3$ (log)"
label variable construction_share "Share of construction GDP"
label variable allconstruction_lengthpc "Construction measured in length per capita"
label variable edu_graduate "Ratio of higher education graduates"
label variable agri_share "Share of agricultural GDP"
label variable manu_share "Share of manufacturing GDP"
label variable knowledge_service_share "Share of knowledge-intensive services GDP"
label variable lnurban_modis "Urban area (log)"
label variable lnpop_density "Population density (log)"


***Regressions***


* OLS with controls
eststo mod1: quietly reg giniw_province lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc edu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density,robust
quietly estadd local FE_region   "No", replace
quietly estadd local FE_year      "No", replace

*Set Panel Data
xtset province_id year

* Quietly estimate  regressions with two-way fixed effects
eststo mod2: quietly xtreg  giniw_province lngdppc i.year, fe robust
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod3: quietly xtreg  giniw_province lngdppc lngdppc_squared i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects with cubic terms
eststo mod4: quietly xtreg  giniw_province lngdppc lngdppc_squared lngdppc_cubed i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

*Quietly estimate  regressions with two-way fixed effects
*eststo mod4: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share lnconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year,fe robust 
*quietly estadd local FE_region   "Yes", replace
*quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
*eststo mod3: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share lnconstruction_lengthpc lnedu_graduate agri_share lnurban_modis lnpop_density i.year,fe robust 
*quietly estadd local FE_region   "Yes", replace
*quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
*eststo mod4: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share lnconstruction_lengthpc lnedu_graduate manu_share lnurban_modis lnpop_density i.year, fe robust 
*quietly estadd local FE_region   "Yes", replace
*quietly estadd local FE_year      "Yes", replace


* Quietly estimate  regressions with two-way fixed effects
*eststo mod5: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share lnconstruction_lengthpc lnedu_graduate knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 
*quietly estadd local FE_region   "Yes", replace
*quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
*eststo mod6: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share lnconstruction_lengthpc lnedu_graduate manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 
*quietly estadd local FE_region   "Yes", replace
*quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod5: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share allconstruction_lengthpc edu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod6: quietly xtreg  giniw_province lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc edu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

esttab mod1 mod2 mod3 mod4 mod5 mod6, ar2

* Compile professional regression table
#delimit;
    esttab mod1 mod2 mod3 mod4 mod5 mod6,
	keep(lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc edu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density)
    se
	ar2
    label 
    stats(N N_g ar2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "Number of province" "Adjusted R-squared" "Region FE" "Year FE"))
    mtitles("OLS" "2WFE" "2WFE" "2WFE" "2WFE" "2WFE" "2WFE") 
    nonotes
	title("Dependent Variable: Population-weighted Gini coefficient (GINIW)") 
    addnote("All models include a constant"
            "* p<0.10, ** p<0.05, *** p<0.01")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    compress
    replace;
#delimit cr

* Export regression table to Latex
#delimit;
    esttab mod1 mod2 mod3 mod4 mod5 mod6 using "ginilow.tex",
	keep(lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc edu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density)
    se
	ar2
    label 
    stats(N N_g ar2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "Number of province" "Adjusted R-squared" "Region FE" "Year FE"))
    mtitles("OLS" "2WFE" "2WFE" "2WFE" "2WFE" "2WFE" "2WFE") 
    nonotes
	title("Dependent Variable: Population-weighted Gini coefficient (GINIW)") 
    addnote("All models include a constant"
            "$* p<0.10, ** p<0.05, *** p<0.01$")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    replace;
#delimit cr

*Regression
xtreg giniw_province lngdppc lngdppc_squared construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 

* Step 3: Update scatterfit command
scatterfit giniw_province lngdppc, controls(lngdppc_squared construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density) vce(cluster province_id) regparameters(coef sig adjr2 nobs) parpos(750 0.4) plotscheme(white_tableau) opts(legend(off) subtitle("(b) Conditional relationship") graphregion(margin(zero)) name(fig2, replace))

*Plot the graph
twoway (scatter giniw_province lngdppc) (qfit giniw_province lngdppc, ytitle("GINIW"))



*Cubic term
*Regression
xtreg giniw_province lngdppc lngdppc_squared lnurban_modis lnedu_graduate agri_share manu_share knowledge_service_share i.yeari.year, fe robust

* Create a range of lngdppc values
summarize lngdppc, meanonly
scalar min_lngdppc = r(min)
scalar max_lngdppc = r(max)

* Define the multiplier for extending the range
scalar range_multiplier = 0.3

* Calculate the range difference with the multiplier
scalar range_diff = (max_lngdppc - min_lngdppc) * range_multiplier

* Generate the extended range of lngdppc values
gen lngdppc_range = min_lngdppc - range_diff + (_n-1)*(max_lngdppc - min_lngdppc + 2*range_diff)/99 if _n <= 100

* Generate the quadratic and cubic terms for the extended range
gen lngdppc_squared_range = lngdppc_range^2
gen lngdppc_cubed_range = lngdppc_range^3

* Get the regression coefficients
matrix list e(b)
scalar b_cons = _b[_cons]
scalar b_lngdppc = _b[lngdppc]
scalar b_lngdppc_squared = _b[lngdppc_squared]
scalar b_lngdppc_cubed = _b[lngdppc_cubed]

* Calculate the fitted values manually for the extended range
gen fitted_gini_range = b_cons + b_lngdppc*lngdppc_range + b_lngdppc_squared*lngdppc_squared_range + b_lngdppc_cubed*lngdppc_cubed_range

* Generate the scatterplot with the fitted curved line
twoway (scatter giniw_province lngdppc, ///
         title("") ///
         xtitle("Ln GDP per capita") ///
         ytitle("Provincial GINIW")) ///
       (line fitted_gini_range lngdppc_range, ///
         lcolor(red) lwidth(medium)), ///
         legend(order(1 "Observed Data" 2 "Fitted Curve"))