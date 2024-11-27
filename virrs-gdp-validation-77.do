
clear all
* Setting directory
cd "C:\Users\wilai\OneDrive\Desktop\Master's Thesis"

* Import the dataset and set up the spatial id
import delimited "Viirs-gdp-77.csv", clear
order id, first
sort id

* Declare panel data
xtset id year

* Generate log values of variables
gen ln_NTL = ln(1000000*total_sol)
gen ln_GDP = ln(1000000*gdp)
gen ln_meanNTL = ln(1000000*mean_sol)
gen ln_GDPpc = ln(1000000*gdppc)


* Label new variables
label variable ln_meanNTL "Mean NTL (log)"
label variable ln_GDPpc "GDP per capita (log)"

* Summarize panel data variables
*xtsum  ln_NTL ln_GDP
xtsum ln_meanNTL ln_GDPpc

* Pooled OLS 
*reg ln_GDP ln_NTL, vce(cluster id) 
reg ln_GDPpc ln_meanNTL, vce(cluster id)
quietly estadd local FE_region   "No", replace
quietly estadd local FE_year      "No", replace
estimates store pooled_ols

* Time-demeaning fixed effects (within estimator)
*xtreg ln_GDP ln_NTL i.year, fe vce(cluster id)
xtreg ln_GDPpc ln_meanNTL i.year, fe vce(cluster id)
quietly estadd local FE_region   "Yes", replace
quietly estadd local FE_year      "Yes", replace
estimates store fe

* Between estimator
*xtreg ln_GDP ln_NTL, be 
xtreg ln_GDPpc ln_meanNTL, be
quietly estadd local FE_region   "No", replace
quietly estadd local FE_year      "No", replace
estimates store be

* Compile professional regression table
#delimit;
    esttab pooled_ols be fe,
	keep(ln_meanNTL)
    se
    label 
    stats(N N_g r2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "Number of Provinces" "R-squared" "Region FE" "Year FE"))
    mtitles("Pooled OLS" "Between Estimator" "Within Estimator (TWFE)") 
    nonotes
    title("Dependent Variable: Provincial GDP per capita (log)")
    addnote("Notes: All models include a constant."
			"Standard errors in parenthesis."
            "* p<0.10, ** p<0.05, *** p<0.01")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    compress
    replace;
#delimit cr

* Export regression table to Latex
#delimit;
    esttab pooled_ols be fe using "gdpntl_validation.tex",
	keep(ln_meanNTL)
    se
    label 
    stats(N N_g r2 FE_region FE_year, 
        fmt(0 0 2)
        label("Observations" "Number of Provinces" "R-squared" "Region FE" "Year FE"))
    mtitles("Pooled OLS" "Between Estimator" "Within Estimator (TWFE)") 
    nonotes
	title("Dependent Variable: Provincial GDP per capita (log)")
    addnote("Notes: All models include a constant."
			"Standard errors in parenthesis."
            "$* p<0.10, ** p<0.05, *** p<0.01$")
    star(* 0.10 ** 0.05 *** 0.01)  
    b(%7.3f)
    replace;
#delimit cr


**Scatter plots

*Pooled OLS
reg ln_GDPpc ln_meanNTL
*Store the beta coefficient and number of observations in local macros
local coef = _b[ln_meanNTL]
local nobs = e(N)
test ln_meanNTL = 0
local sig = r(p)

scatterfit ln_GDPpc ln_meanNTL, regparameters(coef sig nobs) vce(cluster id) parpos(25 16) plotscheme(white_tableau) opts(legend(off) subtitle("(a) Pooled OLS") graphregion(margin(2 2 2 2)) scale(0.7) name(fig1, replace))


* Between estimator
preserve
  sort id year
  
  collapse (mean) ln_GDPpc ln_meanNTL, by(id)
  
  label variable ln_meanNTL "Log of Mean NTL (over-time mean)"
  label variable ln_GDPpc "Log of GDP per capita (over-time mean)"
  
  scatterfit ln_GDPpc ln_meanNTL, regparameters(coef sig nobs) vce(cluster id) parpos(25 16) plotscheme(white_tableau) opts(legend(off) subtitle("(b) Between Estimator") graphregion(margin(2 2 2 2)) scale(0.7) name(fig2, replace))
  reg ln_GDPpc ln_meanNTL, robust
restore

* Within estimator
scatterfit ln_GDPpc ln_meanNTL, fcontrols(id  year) regparameters(coef sig nobs) vce(cluster id) parpos(24.8 13.6)  plotscheme(white_tableau) opts(legend(off) subtitle("(c) Within Estimator") graphregion(margin(2 2 2 2)) scale(0.7) name(fig3, replace))
xtreg ln_GDP ln_NTL i.year, fe vce(cluster id)

* Create combined graph
graph combine fig2 fig3, col(2) scale(0.5.0.5) ysize(2) xsize(5) ycommon xcommon  name(combined1, replace)