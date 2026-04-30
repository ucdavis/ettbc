/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* Outcome model **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

/*libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";*/
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';
libname annboots "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/bootsamples";



%macro cann20_5y(agegroup= ,methodpa= ,outcome= ,label=, norobust=, upto= , pall=);
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann20_logsANDlsts/cann20_12m&outcome&methodpa&agegroup&upto.&pall..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann20_logsANDlsts/cann20_12m&outcome&methodpa&agegroup&upto.&pall..log" new;run;

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';

/* DESCRIPTION OF THE DATABASES:
		long&agegroup is the backbone dataset, already cloned
		longcovs&agegroup is the non-cloned dataset, with covariates 
        wCONTINUE&methodpa&agegroup: contains the weights for each arm*/


/* from the unexpanded dataset, I select baseline variables */
data basecovs&agegroup;
set anndata.longcovs&agegroup (keep= 
bene_id age month year_base race_c region 
ervisit6m_base2 daysin6m_base2 
 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base 
AF_base CHF_base CKD_base COPD_base CRC_base HTA_base IHD_base LTC_base RA_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base
glaucoma_base hip12_base hypoth_base lipid_base lung_base osteo_base stroke12_base year_base );
run;

proc sort data=basecovs&agegroup; by bene_id age month; 


/* the backbone, already cloned -- I select only the variables I need */

data backbone&agegroup; set anndata.long12m&agegroup (drop=bc_long monthBC);run; 

proc sort data=backbone&agegroup; by bene_id age month;



data x;
merge backbone&agegroup (in=a) basecovs&agegroup ;
by bene_id age month; 
if a; 
run;


proc sort data=x; by bene_id age month arm; run;

data y; 
merge x (in=a) anndata.wSTOPBASE&methodpa&agegroup.&pall anndata.wCONTINUE&methodpa&agegroup.&pall;
by bene_id age month arm;
if a; 
run;


%let thirdknot=%eval(&upto-23);

data y; 
set y; 
if 0<=month2<=&upto;
%RCSPLINE(month2,6,48,&thirdknot);
if arm='STOPBASE' then wunif=w;
if arm='STOPBASE' then wunifp99=wp99;
run;


/* this part here is for the point estimate for the CI using bootstrap. Will be called from cann24_bs_CI12m.sas */
proc logistic data=y outest=mainhr&agegroup;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0')  
race_c (ref='1') region (ref='3') / param=ref;
model &outcome (event='1') = arm
/* time */
month2 month21 
/* baseline */
age year_base year_base*year_base race_c region
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base  

LTC_base   

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base
;  
weight wp99;
title 'WEIGHT WP99';
run;

data annboots.&label.hr&upto.&agegroup.&pall.12m (keep=armCONTINUE); set mainhr&agegroup; run;


proc surveylogistic data=y;
&norobust cluster bene_id;
class arm (ref='STOPBASE')  / param=ref;
model &outcome (event='1') = arm
/* time */
month2 month21 ;  
title "outcome=&outcome, unadjusted, norobust=&norobust, methodpa=&methodpa";
run;


proc surveylogistic data=y;
&norobust cluster bene_id;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0') /*comcom_base (ref='0')*/ 
race_c (ref='1') region (ref='3') / param=ref;
model &outcome (event='1') = arm
/* time */
month2 month21 
/* baseline */
age year_base year_base*year_base race_c region
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base  

LTC_base   

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base
;  
title "outcome=&outcome, baseline adjusted, norobust=&norobust, methodpa=&methodpa";
run;



proc surveylogistic data=y;
&norobust cluster bene_id;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0') 
race_c (ref='1') region (ref='3') / param=ref;
model &outcome (event='1') = arm
/* time */
month2 month21 
/* baseline */
age year_base year_base*year_base race_c region
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base  

LTC_base   

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base 
;  
weight wp99;
title "outcome=&outcome, fully adjusted wp99, norobust=&norobust, methodpa=&methodpa, probs=&pall";
run;

%mend; /* c20 */



%cann20_5y(agegroup=8084,methodpa=rcs, outcome=bcucd_tplusone, label=bcucd, norobust=, upto=95, pall=_pall);
%cann20_5y(agegroup=7074,methodpa=rcs, outcome=bcucd_tplusone, label=bcucd, norobust=, upto=95, pall=_pall);
%cann20_5y(agegroup=7579,methodpa=rcs, outcome=bcucd_tplusone, label=bcucd, norobust=, upto=95, pall=_pall);





%macro cann20_10y(agegroup= ,methodpa= ,outcome= ,label=, norobust=, upto= , pall= );
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann20_logsANDlsts/cann20_12m&outcome&methodpa&agegroup&upto.&pall..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann20_logsANDlsts/cann20_12m&outcome&methodpa&agegroup&upto.&pall..log" new;run;

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';



data longcovs&agegroup; 
set anndata.longcovs7579 anndata.longcovs8084;
run;

proc sort data=longcovs&agegroup; 
by bene_id age month; 
run;


data long12m&agegroup;
set anndata.long12m7579 anndata.long12m8084;
run;

proc sort data=long12m&agegroup;
by bene_id age month; 
run;




/* some data steps before the analysis */

/* from the unexpanded dataset, I select baseline variables */
data basecovs&agegroup;
set longcovs&agegroup (keep= 
bene_id age month year_base race_c region 
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base 
AF_base CHF_base CKD_base COPD_base CRC_base HTA_base IHD_base LTC_base RA_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base
glaucoma_base hip12_base hypoth_base lipid_base lung_base osteo_base stroke12_base year_base );
run;

proc sort data=basecovs&agegroup; by bene_id age month; 



data backbone&agegroup; set long12m&agegroup (where=(arm ne 'STOPCOIN') drop=bc_long monthBC);run; 

proc sort data=backbone&agegroup; by bene_id age month;


data x;
merge backbone&agegroup (in=a) basecovs&agegroup ;
by bene_id age month; 
if a; 
run;

proc sort data=x; by bene_id age month arm; run;

data y; 
merge x (in=a) anndata.wSTOPBASE&methodpa&agegroup.&pall anndata.wCONTINUE&methodpa&agegroup.&pall ;
by bene_id age month arm;
if a; 
run;

%let thirdknot=%eval(&upto-23);

data y; 
set y; 
if 0<=month2<=&upto;
%RCSPLINE(month2,6,48,&thirdknot);
if arm='STOPBASE' then wunif=w;
if arm='STOPBASE' then wunifp99=wp99;
run;



proc logistic data=y outest=mainhr&agegroup;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0')  
race_c (ref='1') region (ref='3') / param=ref;
model &outcome (event='1') = arm
/* time */
month2  month21 
/* baseline */
age year_base year_base*year_base race_c region
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base  

LTC_base   

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base
;  
weight wp99;
title 'WEIGHT WP99';
run;

data annboots.&label.hr&upto.&agegroup.&pall.12m (keep=armCONTINUE); set mainhr&agegroup; run;



proc surveylogistic data=y;
&norobust cluster bene_id;
class arm (ref='STOPBASE')  / param=ref;
model &outcome (event='1') = arm
/* time */
month2 month21 ;  
title "outcome=&outcome, unadjusted, norobust=&norobust, methodpa=&methodpa";
run;



proc surveylogistic data=y;
&norobust cluster bene_id;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0') /*comcom_base (ref='0')*/ 
race_c (ref='1') region (ref='3') / param=ref;
model &outcome (event='1') = arm
/* time */
month2  month21 
/* baseline */
age year_base year_base*year_base race_c region
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base  

LTC_base   

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base
;  
title "outcome=&outcome, baseline adjusted, norobust=&norobust, methodpa=&methodpa";
run;



proc surveylogistic data=y;
&norobust cluster bene_id;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0')  
race_c (ref='1') region (ref='3') / param=ref;
model &outcome (event='1') = arm
/* time */
month2 month21 
/* baseline */
age year_base year_base*year_base race_c region
ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base  

LTC_base   

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base 
;  
weight wp99;
title "outcome=&outcome, fully adjusted wp99, norobust=&norobust, methodpa=&methodpa, probs=&pall";
run;






%mend; /* c20 */


%cann20_10y(agegroup=7584,methodpa=rcs, outcome=bcucd_tplusone, label=bcucd, norobust=, upto=95, pall=_pall);



