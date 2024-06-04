********************************************************************************
// DO FILE TO SHOW SOURCE OF CODELISTS AND GENERATE TIDY VERSIONS FOR SHARING
********************************************************************************
clear all
set more off

cd "D:\GitHub\Uncontrolled_COPD\codelists"

capture log close
log using codelists_primarycare, text replace

local aurum_build "202312"
local browser_dir "Z:\PCPH\CPRD_Research_Data\Code_Browsers\CPRD_CodeBrowser_`aurum_build'_Aurum"
local codelists_dir "D:\GitHub\code_lists"


//IMPORT BROWSERS...
//==================

//CPRD Aurum medical browser
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


//CPRD Aurum product browser
import delimited "`browser_dir'/CPRDAurumProduct.txt", ///
	bindquote(nobind) stringcols(1 2) favorstrfixed clear

//Remove drugissues (in case of issues with making public)
drop drugissues

//Save medical code browser to a tempfile
tempfile product
save `product'


//FIND AND FORMAT CODELISTS...
//============================

//COPD
use `codelists_dir'/10_Respiratory_System/COPD/Aurum/2023_12/copd, clear
drop observations

keep if prevalent == 1
drop if aecopd == 1

keep medcodeid incident prevalent

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order prevalent incident, last
rename prevalent copd_prevalent
rename incident copd_incident

compress
save medical/DTA/COPD_exAECOPD, replace
export delimited medical/CSV/COPD_exAECOPD, replace

//Compact version
keep medcodeid copd_prevalent copd_incident
save medical/compact/COPD_exAECOPD, replace


//SMOKING STATUS
use `codelists_dir'/21_Health_Status_and_Health_Services/Smoking/CPRD/Aurum/2023_12/smoking_status, clear
drop observations

keep if smoking_status != .

drop drugs passive vape smokeless_tobacco packyears gp_recorded_smoking

compress
save medical/DTA/smoking_status, replace
export delimited medical/CSV/smoking_status, replace

//Compact version
keep medcodeid smoking_status ever_smoker
save medical/compact/smoking_status, replace


//SPIROMETRY
use `codelists_dir'/18_Symptoms_Signs_Laboratory/Lung_function_spirometry_GOLDgrade/Aurum/2023_12/lungfunction_comprehensive_1s_gold_subflags_1s_jkq, clear

keep if forced_fev1_fvc == 1 ///
	| fev1 == 1 ///
	| fev1_predicted == 1 ///
	| fev1_percent_pred == 1 ///
	| fvc == 1 ///
	| fvc_predicted == 1 ///
	| fvc_percent_pred == 1 ///
	| fev1_fvc_ratio == 1 ///
	| fev1_fvc_ratio_predicted == 1 ///
	| fev1_fvc_ratio_percent_pred == 1 ///
	| reversibility_test_fev1_indic == 1

keep medcodeid forced_fev1_fvc fev1 fev1_predicted fev1_percent_pred fvc ///
	fvc_predicted fvc_percent_pred fev1_fvc_ratio fev1_fvc_ratio_predicted ///
	fev1_fvc_ratio_percent_pred reversibility_test_fev1_indic bronchdil

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order forced_fev1_fvc fev1 fev1_predicted fev1_percent_pred fvc ///
	fvc_predicted fvc_percent_pred fev1_fvc_ratio fev1_fvc_ratio_predicted ///
	fev1_fvc_ratio_percent_pred reversibility_test_fev1_indic bronchdil, last

encode bronchdil, generate(bronchodilator)
drop bronchdil

compress
save medical/DTA/spirometry, replace
export delimited medical/CSV/spirometry, replace

//Compact version
keep medcodeid forced_fev1_fvc fev1 fev1_predicted fev1_percent_pred fvc ///
	fvc_predicted fvc_percent_pred fev1_fvc_ratio fev1_fvc_ratio_predicted ///
	fev1_fvc_ratio_percent_pred reversibility_test_fev1_indic bronchodilator
save medical/compact/spirometry, replace


//MRC GRADE
use `codelists_dir'/18_Symptoms_Signs_Laboratory/Breathlessness_MRC/CPRD/Aurum/2023_12/mrc_dyspnoea_scale_raw, clear

keep if final_allmrc_JKQ_bro_2023_12 == 1

keep medcodeid mrc mrc_dyspnoea_scale mmrc mmrc_dyspnoea_scale emrc emrc_dyspnoea_scale

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order mrc mrc_dyspnoea_scale mmrc mmrc_dyspnoea_scale emrc emrc_dyspnoea_scale, last

compress
save medical/DTA/MRC_grade, replace
export delimited medical/CSV/MRC_grade, replace

//Compact version
keep medcodeid mrc mrc_dyspnoea_scale mmrc mmrc_dyspnoea_scale emrc emrc_dyspnoea_scale
save medical/compact/MRC_grade, replace


//CHRONIC BRONCHITIS/COUGH
use `codelists_dir'/18_Symptoms_Signs_Laboratory/Cough_and_sputum/CPRD/Aurum/2023_12/cough_raw, clear

keep if final_chroniccough_JKQ_bro202312 == 1
rename final_chroniccough_JKQ_bro202312 chronic_cough

keep medcodeid chronic_cough

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order chronic_cough, last

compress
save medical/DTA/chronic_cough, replace
export delimited medical/CSV/chronic_cough, replace

//Compact version
keep medcodeid chronic_cough
save medical/compact/chronic_cough, replace


//INHALED THERAPY (ICS/LABA/LAMA)
use `codelists_dir'/10_Respiratory_System/Medications/Inhalers/2023_12/0301_0302_COPDrx_inhalers_prodbrowsing_raw, clear

keep if final_COPDinh_JKQ_bro_2023_12 == 1

keep prodcodeid category

merge 1:1 prodcodeid using `product'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

//Dont need SABA/SAMA inhalers
list term category if strmatch(category, "*saba*") | strmatch(category, "*sama*")
drop if strmatch(category, "*saba*") | strmatch(category, "*sama*")

encode category, generate(inhaler)
drop category

compress
save product/DTA/inhaled_therapy, replace
export delimited product/CSV/inhaled_therapy, replace

//Compact version
keep prodcodeid inhaler
save product/compact/inhaled_therapy, replace


//EOSINOPHILS
use `codelists_dir'/03_Blood_and_Immune_Diseases/Eosinophils/CPRD/Aurum/2023_12/eosinophils, clear

drop observations

compress
save medical/DTA/eosinophils, replace
export delimited medical/CSV/eosinophils, replace

//Compact version
keep medcodeid eosinophils
save medical/compact/eosinophils, replace


//ASTHMA
use `codelists_dir'/10_Respiratory_System/Asthma/CPRD/Aurum/2023_12/asthma, clear

drop observations

compress
save medical/DTA/asthma, replace
export delimited medical/CSV/asthma, replace

//Compact version
keep medcodeid asthma
save medical/compact/asthma, replace


//LUNG FIBROSIS, SARCOIDOSIS, INTERSTITIAL LUNG DISEASE, CHURG-STRAUSS SYNDROME (EOSINOPHILIC GRANULOMATOSIS WITH POLYANGIITIS (EGPA)) (**Not a Dec 2023 build codelist**)
import delimited ///
"https://github.com/NHLI-Respiratory-Epi/Curation-Harmonisation/raw/txt_to_tsv/codelists/definite_ild_incidence_prevalence_classification-aurum_snomed_read.tsv", ///
	stringcols(1 2 3) clear

keep if prevalent == 1

keep medcodeid prevalent

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order prevalent, last
rename prevalent ild

compress
save medical/DTA/interstitial_lung_disease, replace
export delimited medical/CSV/interstitial_lung_disease, replace

//Compact version
keep medcodeid ild
save medical/compact/interstitial_lung_disease, replace


//PULMONARY HYPERTENSION, COR PULMONALE, EVIDENCE OF RIGHT CARDIAC FAILURE
use `codelists_dir'/09_Circulatory_System/Pulmonary_Vascular_Diseases/Pulmonary_Arterial_Hypertension/Aurum/2023_12/pulmonary_arterial_hypertension, clear

drop observations

compress
save medical/DTA/pulmonary_arterial_hypertension, replace
export delimited medical/CSV/pulmonary_arterial_hypertension, replace

//Compact version
keep medcodeid pah
save medical/compact/pulmonary_arterial_hypertension, replace


//BRONCHIECTASIS
use `codelists_dir'/10_Respiratory_System/Bronchiectasis/CPRD/Aurum/2023_12/bronchiectasis, clear

drop observations

compress
save medical/DTA/bronchiectasis, replace
export delimited medical/CSV/bronchiectasis, replace

//Compact version
keep medcodeid bronchiectasis
save medical/compact/bronchiectasis, replace


//EOSINOPHILIC OESOPHAGITIS
use "`codelists_dir'/11_Digestive_System/Eosinophilic oesophagitis/CPRD/Aurum/2023_12/eosinophilic_oesophagitis", clear

drop observations

compress
save medical/DTA/eosinophilic_oesophagitis, replace
export delimited medical/CSV/eosinophilic_oesophagitis, replace

//Compact version
keep medcodeid eosinophilic_oesophagitis
save medical/compact/eosinophilic_oesophagitis, replace


//OXYGEN TREATMENT, LONG-TERM OXYGEN THERAPY
//medcodeid
use `codelists_dir'/10_Respiratory_System/Medications/Additional_Oxygen/CPRD/Aurum/2023_12/oxygen_medcode, clear

drop observations

compress
save medical/DTA/oxygen_medcode, replace
export delimited medical/CSV/oxygen_medcode, replace

//Compact version
keep medcodeid oxygen ltot
save medical/compact/oxygen_medcode, replace

//prodcodeid
use `codelists_dir'/10_Respiratory_System/Medications/Additional_Oxygen/CPRD/Aurum/2023_12/oxygen_prodcode, clear

drop drugissues jkq
rename JKQ_therapy_type oxygen_therapy_type

compress
save product/DTA/oxygen_prodcode, replace
export delimited product/CSV/oxygen_prodcode, replace

//Compact version
keep prodcodeid oxygen oxygen_therapy_type
save product/compact/oxygen_prodcode, replace


//HYPERCAPNIA REQUIRING BI-LEVEL VENTILATION
//Hypercapnia
use `codelists_dir'/18_Symptoms_Signs_Laboratory/Hypercapnia/CPRD/Aurum/2023_12/hypercapnia, clear

drop observations

compress
save medical/DTA/hypercapnia, replace
export delimited medical/CSV/hypercapnia, replace

//Compact version
keep medcodeid hypercapnia
save medical/compact/hypercapnia, replace

//NIV
use `codelists_dir'/21_Health_Status_and_Health_Services/Non_Invasive_Ventilation/CPRD/Aurum/2023_12/non_invasive_ventilation, clear

drop observations

compress
save medical/DTA/non_invasive_ventilation, replace
export delimited medical/CSV/non_invasive_ventilation, replace

//Compact version
keep medcodeid niv
save medical/compact/non_invasive_ventilation, replace


//MODERATE AECOPD
//AECOPD codes
use `codelists_dir'/10_Respiratory_System/COPD/AECOPD/Aurum/2023_12/AECOPD_raw, clear

keep if final_aecopddx_JKQ_bro_2023_12 == 1 | final_countaecopd_JKQ_bro_202312 == 1

rename final_aecopddx_JKQ_bro_2023_12 aecopd
rename final_countaecopd_JKQ_bro_202312 aecopd_count

keep medcodeid aecopd aecopd_count

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order aecopd aecopd_count, last

compress
save medical/DTA/AECOPD_moderate, replace
export delimited medical/CSV/AECOPD_moderate, replace
keep medcodeid aecopd aecopd_count
save medical/compact/AECOPD_moderate, replace

//AECOPD symptoms
use `codelists_dir'/10_Respiratory_System/COPD/AECOPD/Aurum/2023_12/AECOPD_symptoms_1s_qualdata, clear

keep if final_aecopd_bl_JKQ_bro202312 == 1 ///
	| final_cough_JKQ_bro_2023_12 == 1 ///
	| final_sput_JKQ_bro_2023_12 == 1

rename final_aecopd_bl_JKQ_bro202312 dyspnoea
rename final_cough_JKQ_bro_2023_12 cough
rename final_sput_JKQ_bro_2023_12 sputum

keep medcodeid dyspnoea cough sputum

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order dyspnoea cough sputum, last

compress
save medical/DTA/AECOPD_symptoms, replace
export delimited medical/CSV/AECOPD_symptoms, replace
keep medcodeid dyspnoea cough sputum
save medical/compact/AECOPD_symptoms, replace

//Systemic corticosteroids (intramuscular, intrvenous, oral)
use `codelists_dir'/10_Respiratory_System/Medications/Oral_corticosteroids/CPRD/Aurum/2023_12/ocs, clear

keep if jkq_202312 == 1

keep prodcodeid jkq_202312
rename jkq_202312 ocs

merge 1:1 prodcodeid using `product'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order ocs, last

compress
save product/DTA/oral_corticosteroids, replace
export delimited product/CSV/oral_corticosteroids, replace
keep prodcodeid ocs
save product/compact/oral_corticosteroids, replace

//Antibiotics
use `codelists_dir'/10_Respiratory_System/Medications/Antibiotics/CPRD/Aurum/2023_12/antibiotics, clear

keep if abx_jkq_202312 == 1

keep prodcodeid abx_jkq_202312
rename abx_jkq_202312 abx

merge 1:1 prodcodeid using `product'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order abx, last

compress
save product/DTA/antibiotics, replace
export delimited product/CSV/antibiotics, replace
keep prodcodeid abx
save product/compact/antibiotics, replace

//Lower respiratory tract infection
use `codelists_dir'/10_Respiratory_System/Lower_Respiratory_Tract_Infection/CPRD/Aurum/2023_12/lrti, clear

keep if jkq_202312 == 1

keep medcodeid jkq_202312
rename jkq_202312 lrti

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order lrti, last

compress
save medical/DTA/LRTI, replace
export delimited medical/CSV/LRTI, replace
keep medcodeid lrti
save medical/compact/LRTI, replace

//COPD annual review
use `codelists_dir'/10_Respiratory_System/COPD/AECOPD/Aurum/2023_12/COPD_annual_review, clear

keep medcodeid
generate byte copd_annual_review = 1

merge 1:1 medcodeid using `medical'
drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order copd_annual_review, last

compress
save medical/DTA/COPD_annual_review, replace
export delimited medical/CSV/COPD_annual_review, replace
keep medcodeid copd_annual_review
save medical/compact/COPD_annual_review, replace


//PNEUMONECTOMY, LUNG VOLUME REDUCTION SURGERY
use `codelists_dir'/21_Health_Status_and_Health_Services/Lung_Volume_Reduction_Surgery/CPRD/Aurum/2023_12/lung_volume_reduction_surgery, clear

drop observations

compress
save medical/DTA/lung_volume_reduction_surgery, replace
export delimited medical/CSV/lung_volume_reduction_surgery, replace
keep medcodeid lvrs
save medical/compact/lung_volume_reduction_surgery, replace


//PULMONARY REHABILITATION
use `codelists_dir'/21_Health_Status_and_Health_Services/Pulmonary_Rehabilitation/CPRD/Aurum/2023_12/pulmonary_rehabilitation, clear

drop observations

//Don't want anyone that wasn't at least referred
list term if considered == 1 & referred == . & commenced == . & completed == .
drop if considered == 1 & referred == . & commenced == . & completed == .
drop considered

compress
save medical/DTA/pulmonary_rehabilitation, replace
export delimited medical/CSV/pulmonary_rehabilitation, replace
keep medcodeid pulmonary_rehab referred commenced completed
save medical/compact/pulmonary_rehabilitation, replace


//ALPHA-1 ANTI-TRYPSIN DEFICIENCY
use `codelists_dir'/10_Respiratory_System/Alpha_1_Antitrypsin/CPRD/Aurum/2023_12/alpha1_antitrypsin, clear

drop observations

compress
save medical/DTA/alpha1_antitrypsin, replace
export delimited medical/CSV/alpha1_antitrypsin, replace
keep medcodeid alpha1
save medical/compact/alpha1_antitrypsin, replace


//HEALTHCARE UTILISATION
//todo?


//BODY MASS INDEX (BMI)
//Pre-calculated BMI
use `codelists_dir'/21_Health_Status_and_Health_Services/Body_Mass_Index/Aurum/adult_and_paeds/2023_12/bmi_raw, clear

keep if final_adultBMI_JKQ_bro_202312 == 1
drop if flag_centile == 1  //don't need centile codes

keep medcodeid final_adultBMI_JKQ_bro_202312
rename final_adultBMI_JKQ_bro_202312 bmi

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order bmi, last

//Genrate BMI categories using WHO categorisation
label define bmi_4_WHO -1 "Underweight" 0 "Normal" 1 "Overweight" 2 "Obese"
generate byte bmi_4_WHO = .
label values bmi_4_WHO bmi_4_WHO

replace bmi_4_WHO = -1 if strmatch(lower(term), "*less*16.5*")
replace bmi_4_WHO = 0 if strmatch(lower(term), "*normal*") | strmatch(lower(term), "*18.5-24.9*")
replace bmi_4_WHO = 1 if strmatch(lower(term), "*overweight*")
replace bmi_4_WHO = 2 if strmatch(lower(term), "*obes*")

//Another categorisation using less than 20 as underweight because of presence of these codes
generate byte bmi_4_u20 = .
label values bmi_4_u20 bmi_4_WHO

replace bmi_4_u20 = -1 if strmatch(lower(term), "*less*")
replace bmi_4_u20 = 0 if strmatch(lower(term), "*normal*") | strmatch(lower(term), "*18.5-24.9*")
replace bmi_4_u20 = 1 if strmatch(lower(term), "*overweight*")
replace bmi_4_u20 = 2 if strmatch(lower(term), "*obes*")

compress
save medical/DTA/BMI, replace
export delimited medical/CSV/BMI, replace
keep medcodeid bmi bmi_4_WHO bmi_4_u20
save medical/compact/BMI, replace

//Height
use `codelists_dir'/21_Health_Status_and_Health_Services/Height/adult_and_paediatric/2023_12/height_raw, clear

keep if final_adultheight_JKQ_bro_202312 == 1

keep medcodeid final_adultheight_JKQ_bro_202312
rename final_adultheight_JKQ_bro_202312 height

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order height, last

compress
save medical/DTA/height, replace
export delimited medical/CSV/height, replace
keep medcodeid height
save medical/compact/height, replace

//Weight
use `codelists_dir'/21_Health_Status_and_Health_Services/Weight/adult_and_paeds/CPRD/Aurum/2023_12/weight_raw, clear

keep if final_adultweight_JKQ_bro_202312 == 1

keep medcodeid final_adultweight_JKQ_bro_202312
rename final_adultweight_JKQ_bro_202312 weight

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order weight, last

//Categorise weight using WHO 4 categories
label define weight_4cat -1 "Underweight" 0 "Normal" 1 "Overweight" 2 "Obese"
generate byte weight_4cat = .
label values weight_4cat weight_4cat

replace weight_4cat = -1 if strmatch(lower(term), "*underweight")
replace weight_4cat = 0 if strmatch(lower(term), "normal*")
replace weight_4cat = 1 if strmatch(lower(term), "*overweight*")
replace weight_4cat = 2 if strmatch(lower(term), "*obes*")

compress
save medical/DTA/weight, replace
export delimited medical/CSV/weight, replace
keep medcodeid weight weight_4cat
save medical/compact/weight, replace


//FRACTIONAL EXHALED NITRIC OXIDE (FeNO)
use `codelists_dir'/18_Symptoms_Signs_Laboratory/Fractional_exhaled_nitric_oxide/CPRD/Aurum/2023_12/fractional_exhaled_nitric_oxide, clear

drop observations

compress
save medical/DTA/FeNO, replace
export delimited medical/CSV/FeNO, replace
keep medcodeid feno
save medical/compact/FeNO, replace


//DEPRESSION
use `codelists_dir'/05_Mental_Behavioural/Depression/Aurum/2023_12/depression_1s, clear

rename final_dep_JKQ_bro_2023_12 depression

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order depression, last

compress
save medical/DTA/depression, replace
export delimited medical/CSV/depression, replace
keep medcodeid depression
save medical/compact/depression, replace


//ANXIETY
use `codelists_dir'/05_Mental_Behavioural/Anxiety/Aurum/2023_12/anxiety_1s, clear

rename final_anx_JKQ_bro_2023_12 anxiety

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order anxiety, last

compress
save medical/DTA/anxiety, replace
export delimited medical/CSV/anxiety, replace
keep medcodeid anxiety
save medical/compact/anxiety, replace


//GASTRO-OESOPHAGEAL REFLUX DISEASE (GORD)
use `codelists_dir'/11_Digestive_System/Gastroesophageal_Reflux_Disease/Aurum/2023_12/gord_raw, clear

keep if final_gord_JKQ_bro_2023_12 == 1

keep medcodeid final_gord_JKQ_bro_2023_12
rename final_gord_JKQ_bro_2023_12 gord

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order gord, last

compress
save medical/DTA/GORD, replace
export delimited medical/CSV/GORD, replace
keep medcodeid gord
save medical/compact/GORD, replace


//ISCHAEMIC HEART DISEASE (acute coronary syndrome codelist) (**Not a Dec 2023 build codelist**)
use "`codelists_dir'/09_Circulatory_System/Acute Coronary Syndrome - MI, unstable angina/CPRD/Aurum/2023_09/acs_all", clear

keep if jkq == 1

keep medcodeid acs_all
rename acs_all acs

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order acs, last

compress
save medical/DTA/acute_coronary_syndrome, replace
export delimited medical/CSV/acute_coronary_syndrome, replace
keep medcodeid acs
save medical/compact/acute_coronary_syndrome, replace


//HEART FAILURE (**Not a Dec 2023 build codelist**)
use `codelists_dir'/09_Circulatory_System/Heart_Failure/CPRD/Aurum/2023_09/heart_failure, clear

keep if jkq == 1

keep medcodeid heart_failure

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order heart_failure, last

compress
save medical/DTA/heart_failure, replace
export delimited medical/CSV/heart_failure, replace
keep medcodeid heart_failure
save medical/compact/heart_failure, replace


//STROKE (**Not a Dec 2023 build codelist**)
use `codelists_dir'/09_Circulatory_System/Ischaemic_stroke/CPRD/Aurum/2023_09/stroke_ischemic, clear

keep if jkq == 1

keep medcodeid stroke_all
rename stroke_all stroke

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1  //old terms (not in Dec 2023 build)
drop _merge

order stroke, last

compress
save medical/DTA/stroke, replace
export delimited medical/CSV/stroke, replace
keep medcodeid stroke
save medical/compact/stroke, replace


//ATOPIC DERMATITIS (atopy codelist)
use `codelists_dir'/03_Blood_and_Immune_Diseases/Allergy/Atopy/CPRD/Aurum/2023_12/atopy, clear

drop observations

compress
save medical/DTA/atopy, replace
export delimited medical/CSV/atopy, replace
keep medcodeid atopy
save medical/compact/atopy, replace


//NASAL POLYPS
use `codelists_dir'/10_Respiratory_System/Nasal_polyps/CPRD/Aurum/2023_12/nasal_polyps, clear

drop observations

compress
save medical/DTA/nasal_polyps, replace
export delimited medical/CSV/nasal_polyps, replace
keep medcodeid nasal_polyps
save medical/compact/nasal_polyps, replace


//CHRONIC URTICARIA
use `codelists_dir'/12_Skin_and_Tissue/Chronic_Urticaria/CPRD/Aurum/2023_12/chronic_urticaria, clear

drop observations

keep if chronic_urticaria == 1
drop urticaria

compress
save medical/DTA/chronic_urticaria, replace
export delimited medical/CSV/chronic_urticaria, replace
keep medcodeid chronic_urticaria
save medical/compact/chronic_urticaria, replace


//PULMONARY EMBOLISM (venous thromboembolism codelist)
use `codelists_dir'/09_Circulatory_System/Venousthromboembolism/CPRD/Aurum/2023_12/venous_thromboembolism, clear

drop observations

compress
save medical/DTA/venous_thromboembolism, replace
export delimited medical/CSV/venous_thromboembolism, replace
keep medcodeid vte
save medical/compact/venous_thromboembolism, replace


//COPD ASESSMENT TEST (CAT) SCORE
use `codelists_dir'/10_Respiratory_System/COPD/CAT_score/2023_12/cat_score_copd, clear

keep if final_catscore_JKQ_bro_2023_12 == 1

keep medcodeid final_catscore_JKQ_bro_2023_12
rename final_catscore_JKQ_bro_2023_12 cat_score

merge 1:1 medcodeid using `medical'

drop if _merge == 2
drop if _merge == 1
drop _merge

order cat_score, last

compress
save medical/DTA/COPD_assessment_test, replace
export delimited medical/CSV/COPD_assessment_test, replace
keep medcodeid cat_score
save medical/compact/COPD_assessment_test, replace


log close