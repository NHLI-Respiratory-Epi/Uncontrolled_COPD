********************************************************************************
//             DO FILE TO PRODUCE LIST OF EMIS CONSULTATION CODES
//                     TO DEFINE HEALTHCARE UTILISATION
********************************************************************************
clear all
set more off

cd "D:\GitHub\Uncontrolled_COPD\codelists"

capture log close
log using healthcare_utilisation, text replace

//CPRD Aurum build
local aurum_build "202312"

//CPRD lookup files location
local lookup_dir "Z:/PCPH/CPRD_Research_Data/Lookup_Files/`aurum_build'_Lookups_CPRDAurum"


//Import with long COVID list
preserve
	import delimited "https://raw.githubusercontent.com/NHLI-Respiratory-Epi/Long_covid_codelists/main/HCU_consultations_final.csv", clear
	bysort description: keep if _n == 1
	drop conssourceid
	tempfile covidcons
	save `covidcons'
restore


//Import ConsSource lookup
import delimited "`lookup_dir'/ConsSource.txt", favorstrfixed

//Rename ID to be consistent with Aurum Consultation file
rename id conssourceid


//Merge with long COVID ConsSource codes
merge m:1 description using `covidcons'

keep if _merge == 3
drop _merge

order conssourceid description
gsort conssourceid


//Save
compress
save healthcare_utilisation, replace
export delimited healthcare_utilisation, replace


log close
