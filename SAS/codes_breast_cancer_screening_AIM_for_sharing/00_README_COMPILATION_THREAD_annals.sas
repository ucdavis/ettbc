/************************************************************************************/
/* Code to call programs, with a brief description, BREAST cancer screening project */
/* The codes below were used to run the analysis of the manuscript "Continuation of 
Annyal Screening Mammography and Breast Cancer Mortality in Women Older Than 70 Years", 
Annals of Internal Medicine 2020 Mar 17;172(6):381-389. doi: 10.7326/M18-1199 */
/* Programs need to be called sequentially; each contains a brief description, as well
as a mention of the dataset it creates  */
/************************************************************************************/

options mprint notes compress=yes;
libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';



/******************************************************************/
/**** these programs here need to be run only once, not by age ****/
/******************************************************************/
/* b02_scrmammo.sas: extracts bilateral screening mammos, using hcpcs codes. Will have to be further refined
using the algorithm in Medical Care 52:e44
Generates the datasets mydata.scrmammo1999-mydata.scrmammo2008 */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/b02_scrmammo.sas'; 

/* b02_5_anymammo.sas: extracts any type of mammo (diagnostic or screening), using hcpcs codes. To be used in the algorithm in Medical Care 52:e44
Generates the datasets mydata.anymammo1999-mydata.anymammo2008 */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/b02_5_anymammo.sas'; 

/* b02_6_dxmammo.sas: extracts screening mammogram using hcpcs codes. 
Generates the datasets mydata.dxmammo1999-mydata.dxmammo2008 */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/b02_6_dxmammo.sas'; 

/* c06_1_NFU.sas: extracts the first date of Nursing Facility Utilization, the first step to identify LTC using
the algorithm in Health Serv Outcomes Res Method 10:100. 
This step is not cohort-specific. The next step IS cohort-specific and is run below 
Generates the datasets mydata.nfu1999-mydata.nfu2008 */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c06_1_NFU.sas'; 




/*******************************************************************/
/* These have to be run by age (70-84), for each of the 15 cohorts */
/*******************************************************************/

%macro age(agein= );

/* c01_eligibility.sas: applies the initial set of eligibility criteria: age and enrollment 
Note that the log and lst files are written in './c01_logsANDlsts/' 
Generates the dataset mydata.elig_box1_2age&agein 
Reading the end of the log file you can fill in the first two boxes of the flowchart in the publication*/
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c01_eligibility.sas';
%elig_over_years(agein=&agein); 

/* c04_comorbs_CCW.sas: extracts first CCW comorbidities  
Note that the log and lst files are written in './c04_logsANDlsts/' 
Generates several datasets myCCWdata.-- */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c04_comorbs_CCW.sas';
%c04(agein=&agein); 

/* c05_boxes34.sas: merges thirdbox with previous breast cancer and previous mammos to create the third exclusion box  
Note that the log and lst files are written in './c05_logsANDlsts/' 
Generates the dataset mydata.box5_age&agein
The lst file has the info for the 3rd and 4th boxes in the flowchart and the log file for the 5th box */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c05_boxes34.sas';
%c05(agein=&agein); 

/* up to here, the steps are the same as for the previous analysis. By the Annals review, we are changing the inclusion
criteria: now we will include women with a comorbidity score < 1 
This code merges the database created above with op, ip and car claims, computes the score using the 5 years before baseline, 
runs frequencies to fill in the flowchart, box 4, and applies the exclusion
Generates the dataset anndata.box5_age&agin*/
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann06_baseline_comorbidity_score.sas';
%cann06(agein=&agein, daysbeforeinclusion=1825, debugging= /*obs=100000*/);

/* cann07_cohort.sas: puts together the cohort, before cloning 
Creates the dataset anndata.box8_baseline&agein   */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann07_cohort.sas'; 
%cann07(agein=&agein);   

/* cann06_2_LSR.sas: identify SNF claims and perfomrs the second and last step of the algorithm Health Serv Outcomes Res Method 10:100. 
The first step is not cohort-specific and is run above 
Generates the dataset anndata.box8_age&agein, containing an array of 120 indicators for enrolment, one per month from Jan 1999 to Dec 2008 */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann06_2_LSR.sas'; 
%cann06_2(agein=&agein); 


/* cann08_clone_cens.sas: creates the arm by cloning and the censoring. Creates the dataset anndata.cloned&agein */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann08_clone_cens_12m.sas'; 
%cann08(agein=&agein);   

/* cann10_prevention.sas: extracts use of Medicare preventive services. 
Calls in the data merging programs cann09_* !!
Generates the dataset mydata.tvpreventive&agen */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann10_prevention.sas'; 
%cann10(agein=&agein);   

/* cann11_comorbidity_score.sas: extracts the comorbidity score. Takes frikin' forever 
Deletes the datasets "enrolled&agein._ : generated with programs c09_* !!
Generates the dataset mydata.combinedcomorb&agein */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_comorbidity_score.sas'; 
%cann11(agein=&agein);  

/* cann11_5_ER.sas: extracts the number of visits to the emergency department in the 6m before baseline. 
Generates the dataset mydata.ervisits&agein */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_5_ER.sas'; 
%cann11_5(agein=&agein);   

/* cann11_6_Admissions.sas: extracts the number of days admitted to a hospital in the 6m before baseline. 
Generates the dataset mydata.daysadmitted&agein */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_6_Admissions.sas'; 
%cann11_6(agein=&agein);   


/* cann12_baseline_vars.sas: sets up baseline variables. 
Generates the datasets "mydata.basevars&agein"  */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_baseline_vars.sas'; 
%cann12(agein=&agein);   




proc datasets lib=work kill memtype=data;run;

%mend; /* %age */


/*%age(agein=70);
%age(agein=71);
%age(agein=72);
%age(agein=73);
%age(agein=74);
%age(agein=75);
%age(agein=76);
%age(agein=77);
%age(agein=78);
%age(agein=79);
%age(agein=80);
%age(agein=81);
%age(agein=82);
%age(agein=83);
%age(agein=84);*/


/* cann12_5_description_baseline.sas: frequency description for baseline variables by age groups */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_5_description_baseline.sas'; 

%cann12_5(agein1=70, agein2=71, agein3=72, agein4=73, agein5=74, agegroup=7074);
%cann12_5ag(agein1=75, agein2=76, agein3=77, agein4=78, agein5=79, agein6=80, agein7=81, agein8=82, agein9=83, agein10=84, agegroup=7584);


/* cann14_long.sas: creates, FROM THE CLONED DATA, the long datasets mydata.long&agegroup */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann14_long12m.sas'; 
%cann14(agein1=70, agein2=71, agein3=72, agein4=73, agein5=74, agegroup=7074);/*proc datasets lib=work kill memtype=data;run;*/
%cann14(agein1=75, agein2=76, agein3=77, agein4=78, agein5=79, agegroup=7579);/*proc datasets lib=work kill memtype=data;run;*/
%cann14(agein1=80, agein2=81, agein3=82, agein4=83, agein5=84, agegroup=8084);/*proc datasets lib=work kill memtype=data;run;*/


/* cann15_predsurv2LEV12m.sas: estimates the unadjusted parametric survival curves. Done to compare with Kaplan-Meier curves to see that the time function is properly chosen and for debugging */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann15_predsurv2LEV12m.sas'; 

%cann15(agegroup=7074);
%cann15(agegroup=7579);
%cann15(agegroup=8084);



/* cann16_predsurv_adjbaseline2LEV12m.sas: estimates the parametric survival curves adjusted for baseline variables */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann16_predsurv_adjbaseline2LEV12m.sas'; 
%cann16(agegroup=7074);
%cann16_7584(agegroup=7584);


/* cann17b_cpmf_all.sas: creates the long dataset in the unexpanded data, adds info on screening and covariates, and computes the conditional probability mass function for the weights */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann17b_cpmf_all.sas'; 
/*It has two calls: "%cann17b_all" creates the dataset and "%cann17b_all_model" computes the prob(scrmammo=1): */
%cann17b_all(frommagein=70, tomagein=84, agegroup=7084);
%cann17b_all_model(agegroup=7084);



/* cann17c_plot_cancerdiagnosis12m.sas: creates a csv dataset with the rate of cancer diagnosis per month */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann17c_plot_cancerdiagnosis12m.sas';


/* cann18_weights12m_all.sas: computes the weights 
Generates the datasets  mydata.wSTOPBASE&methodpa&agegroup._pall and mydata.wCONTINUE&methodpa&agegroup._pall */
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann18_weights12m_all.sas'; 

/* cann20_bcdead_model9612.sas: outcome model for HR */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann20_bcdead_model9612m.sas'; 


/* cann21_predsurv_fulladj_w_2lev12m.sas: outcome model for survival differences */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann21_predsurv_fulladj_w_2lev12m.sas'; 


/* cann23_bootsrap12m.sas: code to compute bootstrap variance in the 70-74 age group */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann23_bootsrap12m.sas'; 


/* cann23_bootsrap12m.sas: code to compute bootstrap variance in the 75-84 age group */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann23_bootsrap12m.sas'; 


/* cann24_bs_CI12m.sas: computes the 95% confidence interval with the results obtained in cann23 above */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann24_bs_CI12m.sas'; 


/* cann26_6_surgery_bootstrap.sas: extracts the type of surgery, standardizes it and estimates 95% CI */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann26_6_surgery_bootstrap.sas'; 


/* cann27_7_chemo_bootstrap.sas: extracts the use of chemotherapy, standardizes it and estimates 95% CI */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann27_7_chemo_bootstrap.sas'; 


/* cann28_7_radio_bootstrap.sas: extracts the use of radiotherapy, standardizes it and estimates 95% CI */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann28_7_radio_bootstrap.sas'; 


/* cann30_falsepositives.sas: computes the rate of false positives, one program for each age group */

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann30_falsepositives.sas'; 


