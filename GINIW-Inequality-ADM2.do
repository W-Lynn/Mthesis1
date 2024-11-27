** Install additional modules
*findit ineqerr
*findit lorentz
ssc install ineqdeco
ssc install fedistr
ssc install lorenz

clear all

cd "C:\Users\wilai\OneDrive\Desktop\Master's Thesis"

**  Import district level dataset
import delimited "ADM2-MeanViirs-Pop.csv", clear

destring district_pop, force replace

replace district_pop = round(district_pop)

*Generate ln Mean NTL to make it normally distributed
*gen lndistrict_meansol = ln(1000000*district_meansol)
*label  variable lndistrict_meansol "District-level Mean NTL (Logs)"
label variable district_pop "District-level Population"

* Ensure the data is sorted by province and district
sort province district year

* Create a variable to count the number of districts in each province
bysort province: gen district_count = _N

* Identify provinces with only one district
gen single_district_province = (district_count == 1)
ta single_district_province
ta district_count

* List or browse the provinces with only one district
list province if single_district_province

** Calculate Provincial GINI index using District-level NTL
*GINIW
gen GINIW_province = .
egen group = group(province year)  

su group, meanonly
qui forval i = 1/`r(max)' {
  qui count if group == `i' & !missing(district_meansol)
  if r(N) > 0 {
    qui ineqdeco district_meansol [aw=district_pop] if group == `i' & !missing(district_meansol)
    replace GINIW_province = r(gini) if group == `i'
  }
}

drop group

*Generalized Entropy class -1 
gen GE_m1W=.
egen group = group(province year)
su group, meanonly
qui forval i = 1/`r(max)' {
  qui count if group == `i' & !missing(district_meansol)
  if r(N) > 0 {
  qui ineqdeco district_meansol [aw=district_pop]  if group == `i'
replace GE_m1W = r(gem1) if group == `i'	
}
}

drop group

*Generalized Entropy class 0 (mean logarithmic deviation)
gen GE_0W=.
egen group = group(province year)
su group, meanonly
qui forval i = 1/`r(max)' {
	qui count if group == `i' & !missing(district_meansol)
  if r(N) > 0 {
qui ineqdeco district_meansol [aw=district_pop]  if group == `i'
replace GE_0W = r(ge0) if group == `i'	
  }
} 

drop group

*Generalized Entropy class  1 (Theil index)
gen GE_1W=.
egen group = group(province year)
su group, meanonly
qui forval i = 1/`r(max)' {
	qui count if group == `i' & !missing(district_meansol)
  if r(N) > 0 {
qui ineqdeco district_meansol [aw=district_pop]  if group == `i'
replace GE_1W = r(ge1) if group == `i'	
  }
} 

drop group

*COVW GE(2) is half the square of the coefficient of variation.
gen GE_2w=.
egen group = group(province year)
su group, meanonly
qui forval i = 1/`r(max)' {
	qui count if group == `i' & !missing(district_meansol)
  if r(N) > 0 {
qui ineqdeco district_meansol [aw=district_pop]  if group == `i'
replace GE_2w = r(ge2) if group == `i'	
  }
} 

drop group
	
* Collapse the data to calculate the mean Gini index for each province and year combination
*preserve
	collapse (mean) GINIW_province, by(province year)

*restore


*Export to merge with Provincial GDPpc
export delimited using "C:\Users\wilai\OneDrive\Desktop\Master's Thesis/Giniw_province.csv"

clear all
import delimited "Gini_province2.csv", clear
gen lngdppc = ln(gdppc)
gen lngdppc_squared = lngdppc^2
gen lngdppc_cubed = lngdppc^3
gen lnurban_modis =ln(urban_modis)
gen lnedu_graduate = ln(edu_graduate)

label  variable lngdppc "Ln GDP per capita"
label variable lngdppc_squared "Square of Ln GDP per capita"
label variable lngdppc_cubed "Cube of Ln GDP per capita"
label variable lnurban_modis "Ln Urban Area"
label variable lnedu_graduate "Ln Higher Education Graduates"
label variable agri_share "Share of Agricultural GDP"
label variable manu_share "Share of Manufacturing GDP"
label variable knowledge_service_share "Share of Knowledge-intensive Serices GDP"

*Set Panel Data
xtset province_id year

* Quietly estimate  regressions with two-way fixed effects
eststo mod1: quietly xtreg  giniw_province lngdppc i.year, fe robust
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod2: quietly xtreg  giniw_province lngdppc lngdppc_squared i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod3: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share allconstruction_length lnedu_graduate agri_share lnurban_modis pop_density i.year,fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod4: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share allconstruction_length lnedu_graduate manu_share lnurban_modis pop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace


* Quietly estimate  regressions with two-way fixed effects
eststo mod5: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share allconstruction_length lnedu_graduate knowledge_service_share lnurban_modis pop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Quietly estimate  regressions with two-way fixed effects
eststo mod6: quietly xtreg  giniw_province lngdppc lngdppc_squared construction_share allconstruction_length lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis pop_density i.year, fe robust 
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace

* Compile professional regression table
#delimit;
    esttab mod1 mod2 mod3 mod4 mod5 mod6,
	keep(lngdppc lngdppc_squared construction_share allconstruction_length lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis pop_density)
    se
    label 
    stats(N N_g r2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "N Countries" "R-squared" "Region FE" "Year FE"))
    mtitles("GINIW" "GINIW" "GINIW" "GINIW" "GINIW" "GINIW") 
    nonotes
    addnote("Notes: The dependent variable is the Provincial Gini index." 
            "All models include a constant"
            "* p<0.10, ** p<0.05, *** p<0.01")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    compress
    replace;
#delimit cr

*Regression
xtreg giniw_province lngdppc lngdppc_squared construction_share allconstruction_length lnedu_graduate agri_share manu_share knowledge_service_share lnurban_modis pop_density i.year, fe robust

*Square Term 
twoway (scatter giniw_province lngdppc) (qfit giniw_province lngdppc)

*square term another approach
* Create a range of lngdppc values
summarize lngdppc, meanonly
scalar min_lngdppc = r(min)
scalar max_lngdppc = r(max)
gen lngdppc_range = min_lngdppc + (_n-1)*(max_lngdppc - min_lngdppc)/99 if _n <= 100

* Generate the quadratic term for the range
gen lngdppc_squared_range = lngdppc_range^2

* Get the regression coefficients
matrix list e(b)
scalar b_cons = _b[_cons]
scalar b_lngdppc = _b[lngdppc]
scalar b_lngdppc_squared = _b[lngdppc_squared]

* Calculate the fitted values manually
gen fitted_gini_range = b_cons + b_lngdppc*lngdppc_range + b_lngdppc_squared*lngdppc_squared_range

* Generate the scatterplot with the fitted curved line
twoway (scatter giniw_province lngdppc, ///
         title("") ///
         xtitle("Ln GDP per capita") ///
         ytitle("Provincial GINIW")) ///
       (line fitted_gini_range lngdppc_range, ///
         lcolor(red) lwidth(medium)), ///
         legend(order(1 "Observed Data" 2 "Fitted Curve"))
		 
		 
		 
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



		 
*******Sensei's Codes******

*Sort data
sort province district year

** Compute gini over time
ineqdeco lndistrict_meansol [w=district_pop], by(year)
*ineqdeco viirs_mean_mask_km2 [w= area_km2], by(year)
*ineqdeco dmsp_ext_km2        [w= area_km2], by(year)

** Colapse data by taking the mean over the years
*preserve

    *collapse (mean) rgdpo_km2 viirs_mean_km2 viirs_mean_mask_km2 dmsp_ext_km2 dmsp_like_km2 area_km2, by(poly_id)
    *summarize

    ** Simplify labels
    label variable lndistrict_meansol            "NTL(VIIRS masked)"
    *label variable viirs_mean_mask_km2  "NTL(VIIRS masked)"
    *label variable dmsp_ext_km2         "NTL (DMSP extended)"

    ** Compute inequality measures
    ineqerr lndistrict_meansol [w=district_pop] 
    *ineqerr viirs_mean_mask_km2 [w= area_km2] 
    *ineqerr dmsp_ext_km2 [w= area_km2]

    ** Compare lorentz curves
    lorenz estimate lndistrict_meansol [iw= district_pop], gini 
    lorenz graph,  overlay proportion  ytitle("Cumulative share of GDP or NTL") xtitle("Cumulative share of population") subtitle("Provincial Inequality") legend(pos(11) ring(0)) ysize(5) xsize(5) name(developing, replace)
    *graph export "../results/developing_country_gini.png", replace as(png)
  
restore









	








