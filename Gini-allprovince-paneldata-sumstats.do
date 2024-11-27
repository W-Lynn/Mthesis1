clear all
cd "C:\Users\wilai\OneDrive\Desktop\Master's Thesis"

**  Import dataset

clear all

import delimited "gini-allprovince-paneldata.csv", clear

drop provinceorg construction_gdp roadlength allconstruction_length total_gdp agri_gdpmillions manu_gdp knowledge_service_gdp total_area total_pop incomegroup allsectorshare totalshare



* generate new variables using natural log
gen lngdppc = ln(gdppc)
gen lngdppc_squared = lngdppc^2
gen lngdppc_cubed = lngdppc^3
gen lnedu_graduate = ln(edu_graduate + 1)
gen lnurban_modis =ln(urban_modis)
gen lnpop_density =ln(pop_density)

*label variables
label variable giniw_province "Provincial population-weighted coefficient"
label variable lngdppc "GDP per capita (log)"
label variable lngdppc_squared "GDP per capita$^2$ (log)"
label variable lngdppc_cubed "GDP per capita$^3$ (log)"
label variable construction_share "Share of construction GDP"
label variable allconstruction_lengthpc "Construction measured in length per capita"
label variable lnedu_graduate "Ratio of higher education graduates"
label variable agri_share "Share of agricultural GDP"
label variable manu_share "Share of manufacturing GDP"
label variable knowledge_service_share "Share of knowledge-intensive services GDP"
label variable lnurban_modis "Urban area (log)"
label variable lnpop_density "Population density (log)"

histogram lnedu_graduate

summarize

* Post summary statistics to esttab
estpost summarize  province_id giniw_province lngdppc construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density

* Export to LaTeX format
esttab using "descriptive_statistics.tex", ///
    cells(mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))) ///
    label replace tex varlabels("Mean" "Standard Deviation" "Minimum" "Maximum")

	
***Regressions***


* OLS with controls
eststo mod1: quietly reg giniw_province lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density,robust
quietly estadd local FE_region   "No", replace
quietly estadd local FE_year      "No", replace

*Set Panel Data
xtset province_id year

* Quietly estimate  regressions with two-way fixed effects
eststo mod2: quietly xtreg giniw_province lngdppc i.year, fe robust
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
*eststo mod4: quietly xtreg  giniw_province lngdppc construction_share lnconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share *lnurban_modis lnpop_density i.year,fe robust 
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
eststo mod5: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod6: quietly xtreg  giniw_province lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

esttab mod1 mod2 mod3 mod4 mod5 mod6, ar2

* Compile professional regression table
#delimit;
    esttab mod1 mod2 mod3 mod4 mod5 mod6,
	keep(lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density)
    se
	ar2
    label 
    stats(N N_g ar2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "Number of province" "Adjusted R-squared" "Region FE" "Year FE"))
    mtitles("P-OLS" "TWFE" "TWFE" "TWFE" "TWFE" "TWFE" "TWFE")  
    nonotes
	title("Dependent Variable: Population-weighted Gini coefficient (GINIW)") 
    addnote("Notes: All models include a constant."
			"Standard robust errors in parenthesis."
            "* p<0.10, ** p<0.05, *** p<0.01")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    compress
    replace;
#delimit cr

* Export regression table to Latex
#delimit;
    esttab mod1 mod2 mod3 mod4 mod5 mod6 using "giniallprovinces1.tex",
	keep(lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc edu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density)
    se
	ar2
    label 
    stats(N N_g ar2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "Number of province" "Adjusted R-squared" "Region FE" "Year FE"))
    mtitles("P-OLS" "TWFE" "TWFE" "TWFE" "TWFE" "TWFE" "TWFE") 
    nonotes
	title("Dependent Variable: Population-weighted Gini coefficient (GINIW)") 
    addnote("Notes: All models include a constant."
			"Standard errors in parenthesis."
            "* p<0.10, ** p<0.05, *** p<0.01")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    replace;
#delimit cr


*** Plotting graphs***

*Regression
xtreg giniw_province lngdppc lngdppc_squared construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 

*Plot the graph
twoway (scatter giniw_province lngdppc) (qfit giniw_province lngdppc, ytitle("GINIW"))

	 
*Cubic term

*2. Regression
xtreg giniw_province lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust 

* Plot the scatter plot and the fitted cubic polynomial line
twoway (scatter giniw_province lngdppc) ///
       (lpoly giniw_province lngdppc, degree(3)) ///
       , ytitle("GINIW")


* Run fixed-effects regression with cubic polynomial terms
xtreg giniw_province lngdppc lngdppc_squared lngdppc_cubed ///
       construction_share allconstruction_lengthpc lnedu_graduate ///
       agri_share manu_share knowledge_service_share lnurban_modis ///
       lnpop_density i.year, fe robust

* Generate residuals
predict giniw_residual, residuals

* Determine the range and density of lngdppc values
summarize lngdppc, meanonly
scalar min_lngdppc = r(min)
scalar max_lngdppc = r(max)
scalar range_diff = (max_lngdppc - min_lngdppc) / 100

* Generate a denser range of lngdppc values
gen lngdppc_dense = min_lngdppc + (_n - 1) * range_diff if _n <= 100

* Fit a higher-degree polynomial, e.g., degree(4)
lpoly giniw_province lngdppc_dense, degree(4)

* Smooth the fitted curve using lowess for comparison
lowess giniw_province lngdppc_dense, lcolor(red)

* Plot the scatter plot, fitted polynomial, and smoothed curve
twoway (scatter giniw_province lngdppc) ///
       (lpoly giniw_province lngdppc_dense, degree(4) lcolor(blue)) ///
       (lowess giniw_province lngdppc_dense, lcolor(red)), ///
       legend(label(1 "Observed Data") label(2 "Fitted Polynomial") label(3 "Smoothed Curve")) ///
       ytitle("GINIW")
	   
* 3.Fit the fixed-effects regression with robust standard errors
xtreg giniw_province lngdppc lngdppc_squared lngdppc_cubed construction_share allconstruction_lengthpc lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis lnpop_density i.year, fe robust

* Use margins to get the predicted values over a range of lngdppc
margins, at(lngdppc=(1(5)15))

* Plot the scatter plot and the fitted cubic line
twoway (scatter giniw_province lngdppc) ///
       (line _margin lngdppc, sort) ///
       , ytitle("GINIW")



* 4. Create a range of lngdppc values
summarize lngdppc, meanonly
scalar min_lngdppc = r(min)
scalar max_lngdppc = r(max)

* Define the multiplier for extending the range
scalar range_multiplier = 2

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
		 


 

