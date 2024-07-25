********************************************************************************
//               DO FILE TO PRODUCE LIST OF EMIS MEDICAL CODES
//                     TO DEFINE HEALTHCARE UTILISATION
********************************************************************************
clear all
set more off

cd "D:\GitHub\Uncontrolled_COPD\codelists"

capture log close
log using healthcare_utilisation_medcode, text replace

//CPRD Aurum build
local aurum_build "202312"

//CPRD Aurum code browser location
local browser_dir "Z:\PCPH\CPRD_Research_Data\Code_Browsers\CPRD_CodeBrowser_`aurum_build'_Aurum"

//CPRD Aurum lookup files location
local lookup_dir "Z:/PCPH/CPRD_Research_Data/Lookup_Files/`aurum_build'_Lookups_CPRDAurum"


//Import with long COVID list
preserve
	import delimited "https://raw.githubusercontent.com/NHLI-Respiratory-Epi/Long_covid_codelists/main/HCU_medcodes_final.csv", stringcols(1) favorstrfixed clear
	rename term term_covid
	tempfile covidterms
	save `covidterms'
restore


//Import CPRD Aurum medical browser
import delimited "`browser_dir'/CPRDAurumMedical.txt", ///
	stringcols(1 6 7) favorstrfixed clear

//Drop useless variables
drop release emiscodecategoryid

//Remove observations (in case of issues with making public)
drop observations

order medcodeid originalreadcode cleansedreadcode ///
	snomedctconceptid snomedctdescriptionid term

//Save medical code browser to a tempfile
tempfile medical
save `medical'


//Merge in long COVID codes
merge 1:1 medcodeid using `covidterms'
keep if _merge == 3
drop _merge
compress

//Check terms are the same
count if lower(term) != lower(term_covid)
list if lower(term) != lower(term_covid)
drop term_covid


//Find SNOMED CT synonyms

//Check for missing SNOMED CT Concepts
codebook snomedctconceptid
assert !missing(snomedctconceptid)

count

//Make a note of current list
preserve
	keep medcodeid /**/primary ae op hospital/**/
	gen byte original = 1
	tempfile original
	save `original'
restore

//Merge SNOMED CT Concepts with medical dictionary
keep snomedctconceptid /**/primary ae op hospital/**/
collapse (max) /**/primary ae op hospital/**/, by(snomedctconceptid)

//Merge with original search results
merge 1:m snomedctconceptid using `medical', nogenerate keep(match)
compress
merge 1:1 medcodeid using `original', update
drop _merge
order snomedctconceptid, before(snomedctdescriptionid)
order /**/primary ae op hospital/**/, last
gsort /**/primary ae op hospital/**/ originalreadcode

//Label new codes
gen new_snomedct_synonym = (original != 1)
drop original

//Show new codes
foreach category of varlist /**/primary ae op hospital/**/ {
	
	display "New terms found for: `category'"
	list snomedctconceptid originalreadcode term if new_snomedct_synonym == 1 & `category' == 1
}

//Check new codes in the context of originally included SNOMED CT Concept ID codes
preserve
	keep if new_snomedct_synonym == 1
	keep snomedctconceptid
	bysort snomedctconceptid: keep if _n == 1

	count
	local obs = r(N)

	forvalues i = 1/`obs' {
		
		if `i' == 1 {
			
			local expanded_ids = snomedctconceptid in `i'
		}
		else {
			
			local expanded_ids = "`expanded_ids' " + snomedctconceptid in `i'
		}
	}
restore

foreach expanded_id of local expanded_ids {
	
	display "SNOMED CT Concept ID for which additional terms where found: `expanded_id'"
	
	list medcodeid originalreadcode term new_snomedct_synonym ///
		if snomedctconceptid == "`expanded_id'"
}


//This looks like a mistake to me - so remove
list if snomedctconceptid == "118613001"
drop if snomedctconceptid == "118613001"


//Save
compress
save healthcare_utilisation_medcode, replace
export delimited healthcare_utilisation_medcode, replace


log close
