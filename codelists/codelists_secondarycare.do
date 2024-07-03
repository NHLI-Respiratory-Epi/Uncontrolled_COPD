********************************************************************************
// DO FILE TO SHOW SOURCE OF CODELISTS AND GENERATE TIDY VERSIONS FOR SHARING
********************************************************************************
clear all
set more off

cd "D:\GitHub\Uncontrolled_COPD\codelists"

capture log close
log using codelists_secondarycare, text replace

local browser_dir "Z:\Database guidelines and info\NHS TRUD\NHS ICD-10 5th Edition data files\icd_df_10.5.0_20151102000001"
local codelists_dir "D:\GitHub\code_lists"
local EXACOS_dir "D:\GitHub\EXACOS-CV--internal--\Codelists"


//IMPORT BROWSERS...
//==================

//ICD-10 browser
use "`browser_dir'/ICD-10_codes_descriptions", clear

//Add modifiers to description
assert modifier_4 == "" | modifier_5 == ""  //check at leasst one is blank
replace description = description + ": " + modifier_4 if modifier_4 != ""
replace description = description + ": " + modifier_5 if modifier_5 != ""

//Drop useless variables
keep code description

//give same var name as HES data
rename code icd

//Save medical code browser to a tempfile
tempfile icd10
save `icd10'


//FIND AND FORMAT CODELISTS...
//============================

//MAJOR ADVERSE CARDIOVASCULAR EVENT (MACE)

//Myocardial infarction (MI)
use `EXACOS_dir'/2_icd10_acs_FINAL_1s, clear

keep if acs_acutemi == 1

rename icd10 icd

keep icd acs_acutemi

merge 1:1 icd using `icd10'
drop if _merge == 2
drop _merge

order acs_acutemi, last

compress
save ICD-10/DTA/MI, replace
export delimited ICD-10/CSV/MI, replace

//Compact version
keep icd acs_acutemi
save ICD-10/compact/MI, replace

//Combined master codelist
save ICD-10/ICD-10_master, replace


//Heart failure
use `EXACOS_dir'/2_icd10_hf_FINAL_1s, clear

keep if hf_overall == 1

rename icd10 icd

keep icd hf_overall

merge 1:1 icd using `icd10'
drop if _merge == 2
drop _merge

order hf_overall, last

compress
save ICD-10/DTA/heart_failure, replace
export delimited ICD-10/CSV/heart_failure, replace

//Compact version
keep icd hf_overall
save ICD-10/compact/heart_failure, replace

//Combined master codelist
merge 1:1 icd using ICD-10/ICD-10_master, nogenerate
save ICD-10/ICD-10_master, replace


//Stroke
use `EXACOS_dir'/2_icd10_stroke_anne, clear

keep if stroke == 1

rename icd10 icd

keep icd stroke

merge 1:1 icd using `icd10'
drop if _merge == 2
drop _merge

order stroke, last

compress
save ICD-10/DTA/stroke, replace
export delimited ICD-10/CSV/stroke, replace

//Compact version
keep icd stroke
save ICD-10/compact/stroke, replace

//Combined master codelist
merge 1:1 icd using ICD-10/ICD-10_master, nogenerate
save ICD-10/ICD-10_master, replace


//Cardiovascular death
use `icd10', clear

generate byte cv_death = (strmatch(icd, "I*"))

keep if cv_death == 1

compress
save ICD-10/DTA/cardiovascular_death, replace
export delimited ICD-10/CSV/cardiovascular_death, replace

//Compact version
keep icd cv_death
save ICD-10/compact/cardiovascular_death, replace

//Combined master codelist
merge 1:1 icd using ICD-10/ICD-10_master, nogenerate
save ICD-10/ICD-10_master, replace


//SEVERE AECOPD

/*hospitalization with a code for acute respiratory event including COPD or bronchitis as a primary diagnosis or a secondary diagnosis of COPD following previously validation in HES, observation > 24hrs in emergency dept/urgent care facility*/

use `codelists_dir'/10_Respiratory_System/icd10_respiratory_master_flagged, clear

keep if aecopd == 1

rename icd10 icd

keep icd aecopd

merge 1:1 icd using `icd10'
drop if _merge == 2
drop _merge

order aecopd, last

compress
save ICD-10/DTA/AECOPD_severe, replace
export delimited ICD-10/CSV/AECOPD_severe, replace

//Compact version
keep icd aecopd
save ICD-10/compact/AECOPD_severe, replace

//Combined master codelist
merge 1:1 icd using ICD-10/ICD-10_master, nogenerate
save ICD-10/ICD-10_master, replace



log close