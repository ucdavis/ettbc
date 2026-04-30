/*************************************************************************/
/* Code to compute bootstrap variance 	 */
/*************************************************************************/

/*** DESCRIPTION OF THE NUMBERED DATASETS BELOW -- kind of hard to follow without this... ***
#1 ids&agegroup: contains just the ids of the agegroup.
#2 bootsample_pre&i: contains the bootstrap sample of #1: random and repeated ids.
#3 longcovs&agegroup: contains the unexpanded dataset with the TV covariates, long format.
	longcovs_all7084: contains the unexpanded dataset of all the single individuals, with the first and last month of follow-up, to compute the P(A).
#4 bootsample&i: random and repeated ids, merged with #3 to compute P(A) in the unexpanded dataset.
#5 pred_scrmammo_rcs&i: p(A) dataset, with duplicated ids removed.
#6 boot_singleid_&i: contains the random newbeneids without duplication. 
#7 bootids_CONTINUE&i: contains the CONTINUE arm (long format), with only the single random ids
#8 CONTINUE_1_&i: merge of #7 w with #3 and #5
#9 wCONTINUE&i: data step applied to #8: CONTINUE arm, long format, single random ids, with weights. 
#10 bootids_STOPBASE&i: same as #7, but with the STOPBASE arm.
#11 STOPBASE_1_&1: same as #8, but with the STOPBASE arm. 
#12 wSTOBASE&i: same as #9, but with the CONTINUE arm. 
#13 bootsample_base_&i: merge of #2 with plus the baseline variables. 
#14 boot_CONTINUE&i: merge of the continue arm, long format (CONTINUE&agegroup) with #13
#14b boot_STOPBASE&i: merge of the continue arm, long format (STOPBASE&agegroup) with #13
#15 CONTINUE&i: merge of #9 with #14.
#15b STOPBASE&i: merge of #9 with #14b.
#16 ANALYTIC&i: stacking of #15 and #15b.
***/


options mprint notes compress=yes varlenchk=nowarn;

/*libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";*/

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';
libname boots "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/bootsamples";

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';



%macro cann23(agein1= , agein2= , agein3= ,agein4= ,agein5=, agegroup= ,from= ,to= ,event= ,debugging= );
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann23_logsANDlsts/cann23_12m&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann23_logsANDlsts/cann23_12m&agegroup..log" new;run;
 
/* so the bootsample has to be from all the study population */
/* the database anndata.longcovs_all7084 has all the study population as single ids, with the first date of eligibility and last date of follow-up, with all the time-varying covariates */


data longcovs_all7084; set anndata.longcovs_all7084 (&debugging); run;
data long12m&agegroup; set anndata.long12m&agegroup (&debugging); run;

data studysingleids; set anndata.longcovs_all7084 (keep=bene_id &debugging); run;

proc sort data=studysingleids nodupkey; by bene_id; run;


data longcovs&agegroup; set anndata.longcovs&agegroup (&debugging); newbeneid=cats(of bene_id age); drop bene_id ; run;
proc sort data=longcovs&agegroup; by newbeneid month; run;



/* from the unexpanded dataset, I select baseline variables */
data basecovs&agegroup;
set anndata.longcovs&agegroup (where=(month2=0) keep= 
bene_id age month2 year_base race_c region 
ervisit6m_base2 daysin6m_base2 
 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base 
previsit_base 
AF_base CHF_base CKD_base COPD_base CRC_base HTA_base IHD_base LTC_base RA_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base
glaucoma_base hip12_base hypoth_base lipid_base lung_base osteo_base stroke12_base year_base


&debugging);
year_base_sq=year_base*year_base;
newbeneid=cats(of bene_id age);
drop bene_id month2;
run;

proc sort data=basecovs&agegroup; by newbeneid ; 


/* this macro c23a is called from the loop below. It merges random ids with the longcovs dataset and computes the weights */
  %macro c23a();

/* #4 */
  proc sql;
  create table bootsample&i as select * from /*bootsample_pre&i*/ bootstudysingleids&i full join longcovs_all7084 (rename=(bene_id=bene_id2)) on /*bootsample_pre&i*/bootstudysingleids&i..bene_id=longcovs_all7084.bene_id2;
  quit;
  /* watch out, delte this later */ data bootsample&i; set bootsample&i; if /*newbeneid*/bene_id ne '' ; run;

/*proc sort data=bootsample_pre&i; by bene_id month; run;
proc sort data=longcovs_all7084; by bene_id month; run;*/

/*proc print data=bootsample_pre&i (obs=20); run;
proc print data=longcovs_all7084 (obs=100); var bene_id age month month2; run;
proc print data=bootsample&i (obs=300); var bene_id age month month2; run;*/
 %mend; 



/* this macro c23b is called from the loop below. It computes the p(A) */ 
  %macro c23b(); 

  proc hplogistic data=bootsample&i  ;
class ervisit6mlong2 (ref='0') daysin6mlong2 (ref='0') combinedscorelong (ref='0') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0') baseline_combinedscore (ref='0') 
race_c (ref='1') region (ref='3') lagnumberofdxmcat (ref='0') lagnumberofscrmcat (ref='1') / param=ref;
model scrmammo (descending) = 
/* time */
tslm_lagII tslm_lagII1 tslm_lagII2 month2 month2*month2 
/* baseline */
age age*age year_base year_base*year_base race_c region

ervisit6m_base2 daysin6m_base2 /*comcom_base*/ baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base     

AF_base CHF_base CKD_base COPD_base CRC_base LTC_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base stroke12_base RA_base /*bsym6m_base*/

/* tv */
ervisit6mlong2 daysin6mlong2 combinedscorelong 
cvd_prevlong crc_prevlong diabetes_prevlong pelvic_prevlong influenzalong bonemasslong previsitlong 
af_long alzheimer_long ami12_long anemia_long asthma_long cataract_long chf_long
ckd_long copd_long crc_long depre_long diabetes_long endometrial_long glaucoma_long hip12_long hta_long
hypoth_long ihd_long lipid_long lung_long osteo_long ra_long stroke12_long ltc_long 
bsym6m /*lastmammowasdx*/ lagnumberofdxmcat lagnumberofscrmcat;  
where tslm_lag >=11;
  output out = model_scrmammo_rcs copyvar=(bene_id /*age*/ month month2 scrmammo tslm tslm_lag /*newbeneid*/) p=p_scrmammo_rcs;
  title "model with just rcs";
  run;

  /* watch out, delte this later */ data pred_scrmammo_rcs&i; set model_scrmammo_rcs; keep bene_id month /*age*/ p_scrmammo_rcs /*newbeneid*/; run;

/*proc print data=pred_scrmammo_rcs&i (obs=2000); run;
proc print data=anndata.pred_scrmammo_rcs_all7084 (obs=2000); run;*/
  /* watch out, delte this later */ proc sort data=pred_scrmammo_rcs&i nodupkey; by /*newbeneid*/ bene_id month ;run;

  %mend;


/* this macro c23c is called from the loop below. It creates the weights for the CONTINUE arm */ 

%macro c23c();

/* #7 */
/* CONTINUE, long format */
data bootCONTINUE&i; set boot_long12m&i (where=(arm='CONTINUE')); newbeneid=cats(of bene_id age); drop bene_id2; run;

proc sort data=bootCONTINUE&i; by bene_id age month2; run;

data bootCONTINUEunique&i; set bootCONTINUE&i; run;

proc sort data=bootCONTINUEunique&i nodupkey; by newbeneid month2; run;

proc sort data=bootCONTINUEunique&i; by newbeneid month; 

data CONTINUE1_&i;
merge bootCONTINUEunique&i (in=a) longcovs&agegroup (keep=newbeneid /*age*/ month scrmammo anymammo tslm_lag tslm /*bene_id*/);
by newbeneid month; 
if a; 
run;

proc sort data=CONTINUE1_&i; by bene_id month; run;

data CONTINUE1_&i; merge CONTINUE1_&i (in=a) pred_scrmammo_rcs&i; by bene_id month; if a; run;

proc sort data=CONTINUE1_&i; by bene_id age month2; 

data CONTINUE1_&i;
set CONTINUE1_&i ;
if 0<=tslm_lag<=10 then p_scrmammo_rcs=0;
if anymammo=1 then mstartgp=month2;
if .<monthBC<=month then bc_long=1;
retain mstartgp;
mendgp=mstartgp + 14;
lagmendgp=lag(mendgp);
if lagmendgp = month2 and scrmammo=1 then flag=1;
run;

proc sort data=CONTINUE1_&i; by bene_id age month2; 

data wCONTINUE&i;
set CONTINUE1_&i;
if month2=0 then w=1;
den=1;num=1;/*denunif=1;numunif=1;*/
if bc_long = 0 AND flag=1 then do; 
    den=p_scrmammo_rcs;
    end;
retain w /*wunif*/ ;
w=w/den;
keep newbeneid month w; 
run; 

%mend; /* %c23c */

/* this macro c23d is called from the loop below. It creates the weights for the STOPBASE arm */ 

%macro c23d();

data bootSTOPBASE&i; set boot_long12m&i (where=(arm='STOPBASE')); newbeneid=cats(of bene_id age); drop bene_id2; run;

proc sort data=bootSTOPBASE&i; by bene_id age month2; run;

data bootSTOPBASEunique&i; set bootSTOPBASE&i; run;

proc sort data=bootSTOPBASEunique&i nodupkey; by newbeneid month2; run;

proc sort data=bootSTOPBASEunique&i; by newbeneid month; 


data STOPBASE1_&i;
merge bootSTOPBASEunique&i (in=a) longcovs&agegroup (keep=newbeneid /*age*/ month scrmammo anymammo tslm_lag tslm /*bene_id*/);
by newbeneid month; 
if a; 
run;

proc sort data=STOPBASE1_&i; by bene_id month; run;

data STOPBASE1_&i; merge STOPBASE1_&i (in=a) pred_scrmammo_rcs&i; by bene_id month; if a; run;

proc sort data=STOPBASE1_&i; by bene_id age month2; 

data /*STOPBASE1_&i*/ wSTOPBASE&i;
set STOPBASE1_&i;
if 0<=tslm_lag<=10 then p_scrmammo_rcs=0;
if 0<=month2<=11 then w=1;
if .<monthBC<=month then bc_long=1;
if bc_long=1 then den=1;
if bc_long=0 AND month2>11 then den=(1-p_scrmammo_rcs);
retain w ;
if month2>11 then w=w/den;
keep newbeneid month w; 
run;

/*proc print data=wSTOPBASE&i (obs=500); run;
proc print data=anndata.wSTOPBASErcs8084_pall (obs=5000);
%return;*/
  %mend; /* %c23d */



/* this macro c23e is called from the loop below. It does the data steps necessary for the outcome analysis */
  %macro c23e();

/* addition of baseline variables */
proc sort data=bootSTOPBASE&i; by newbeneid; run;

data STOPBASE&i; 
merge bootSTOPBASE&i (in=a) basecovs&agegroup; 
by newbeneid; 
if a; 
run;

proc sort data=STOPBASE&i; by newbeneid month; run;
proc sort data=wSTOPBASE&i; by newbeneid month; run;

data STOPBASE&i;
merge STOPBASE&i (in=a) wSTOPBASE&i;
by newbeneid month;
if a; 
run;

proc univariate data=STOPBASE&i noprint; var w; output out=dout_&i pctlpts=99 pctlpre=w pctlname=p99; title 'STOPBASE'; run;

data datap99_&i; set dout_&i (keep = wp99); run; 
proc transpose data = datap99_&i out = datap99_&i;run;
proc sql noprint ; select col1 into : p99s_&i separated by ' ' from datap99_&i; quit;
%let p99=%sysevalf(&&p99s_&i); %put &p99;

data STOPBASE&i;
set STOPBASE&i;
wp99=w;
if w >= &p99 then wp99=&p99;
run;

%let p99=.; /* deleting the macro variable for further loops */


proc means data=STOPBASE&i n nmiss  mean std min max p25 p50 p75 p99; var w wp99; title 'STOPBASE'; run;




/* CONTINUE arm */

/* addition of baseline variables */
proc sort data=bootCONTINUE&i; by newbeneid; run;

data CONTINUE&i; 
merge bootCONTINUE&i (in=a) basecovs&agegroup; 
by newbeneid; 
if a; 
run;

proc sort data=CONTINUE&i; by newbeneid month; run;
proc sort data=wCONTINUE&i; by newbeneid month; run;


data CONTINUE&i;
merge CONTINUE&i (in=a) wCONTINUE&i;
by newbeneid month;
if a; 
run;

proc univariate data=CONTINUE&i noprint; var w ; output out=doutw_&i pctlpts=99 pctlpre=w pctlname=p99; title 'CONTINUE' ;run;

data datawp99_&i; set doutw_&i (keep = wp99); run;
proc transpose data = datawp99_&i out = datawp99_&i;run;

proc sql noprint ; select col1 into : p99_&i separated by ' ' from datawp99_&i; quit;

%let w_p99=%sysevalf(&&p99_&i); %put &w_p99;

data CONTINUE&i;
set CONTINUE&i;
wp99=w;
if w >= &w_p99 then wp99=&w_p99;
run;

%let w_p99=.; /* deleting the macro variable for further loops */

proc means data=CONTINUE&i n nmiss  mean std min max p25 p50 p75 p99; var w wp99; title 'CONTINUE'; run;


data analytic&i; 
set CONTINUE&i STOPBASE&i; 
if 0<=month2<=95;
%RCSPLINE(month2,6,48,72);
run;


  %mend;





%macro c23f();


%macro analysis1(
	y = ,
	event = ,
	weight= ,
	methodpa= ,
	treatment = , 
	final_model_time = ,
	data = 
    );	

%let new_class_list = 	race2 race3	
			region1 region2 region4
			/*er1 er2*/ ervisit6m_base2
			in1 in2 /*in3*/
			influenza_base
			bonemass_base
			cvd_prev_base
			diabetes_prev_base
			previsit_base
			crc_prev_base
			pelvic_prev_base

			LTC_base

			comcom_c0 /*comcom_c1 comcom_c2 comcom_c3*/
						
			alzheimer_base
			ami12_base
			AF_base
			anemia_base
			asthma_base
			cataract_base
			CHF_base
			CKD_base
			COPD_base
			CRC_base
			depre_base
			diabetes_base
			endometrial_base
			glaucoma_base
			hip12_base
			HTA_base
			hypoth_base
			IHD_base
			lipid_base
			lung_base
			osteo_base
			RA_base
			stroke12_base
			age 
			year_base year_base_sq;

%let all_vars = &treatment &final_model_time &new_class_list;

/*	Create year variables and interactions	*/
data event_all;
set &data (keep=arm month2 year_base year_base_sq &event race_c region ervisit6m_base2 daysin6m_base2 influenza_base bonemass_base
cvd_prev_base diabetes_prev_base previsit_base crc_prev_base pelvic_prev_base baseline_combinedscore LTC_base AF_base alzheimer_base anemia_base ami12_base asthma_base cataract_base
CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base lipid_base lung_base osteo_base RA_base stroke12_base age &weight);
/*if arm ne 'COLO';*/
	
	month3=month2;
	%RCSPLINE(MONTH3,6,48,72);
	month3sq=month31;

	STOPBASE=(arm='STOPBASE');

	month3STOPBASE=month3*STOPBASE;

	month3sqSTOPBASE=month3sq*STOPBASE;	

	race2=(race_c=2);
	race3=(race_c=3);

	region1=(region=1);region2=(region=2);region4=(region=4);

	in1=(daysin6m_base2=1);in2=(daysin6m_base2=2);

	comcom_c0=(baseline_combinedscore='0');

run;


/*	Regressions		*/	
proc logistic data=event_all descending outest=mle_est noprint;
	model &event = &all_vars;
	where 0<=month3<=95;
	weight &weight;
run;


/*	Generate predicted probability of survival	*/
data coefs (drop = _TYPE_) ;
set mle_est (where= ( _TYPE_='PARMS') keep = _TYPE_ Intercept &all_vars );
run;

proc transpose data = coefs out = coefs ;
/*proc print data = coefs ;*/
run;


     proc sql  noprint  ;                              
     select col1 format = 16.12                             
     into : coef_vars separated by ' '                              
     from coefs;                                             
     quit;

%macro numargs(arg);
     %let n = 1;
     %if %bquote(&arg)^= %then %do;
          %do %until (%qscan(&arg,%eval(&n),%str( ))=%str());
           
               %let word = %qscan(&arg,&n);
               %let n = %eval(&n+1);
          %end;
     %end;
     %eval(&n-1) /* there is no ; here since it will be used as %let a = %numargs(&b) ;
                      and the ; is included at the end of this line  */       
%mend  ; /* %numargs */

 %let nn = %numargs(&all_vars) ;
 %let nn = %eval(&nn + 1);

data surv_new (keep = month3 s_x1 s_x2) ;
set event_all (where = (month3 = 0)) ;
array vars Intercept &all_vars ;
array coefs {&nn}  _TEMPORARY_ ( &coef_vars ) ;

Intercept = 1.0 ;

STOPBASE = 0;

month3  = 0;
month3sq = 0;

month3STOPBASE = 0;

month3sqSTOPBASE = 0;

n = dim(vars) ;
xbeta_base = 0;
do i=1 to n ;
	xbeta_base = xbeta_base + coefs[i] * vars[i] ;
end;

s_x1 = 1.0 ;
s_x2 = 1.0 ;

do month3 = 0 to 95  ;
%RCSPLINE(MONTH3,6,48,72);
month3sq=month31;


    	xbeta_base2 = xbeta_base + coefs[5]*month3 + coefs[6]*month3sq ;	

	/* 	survival for CONTINUE	*/
	STOPBASE = 0 ;
	xbeta = coefs[2]*STOPBASE + coefs[3]*STOPBASE*month3 + coefs[4]*STOPBASE*month3sq + xbeta_base2 ;
	p_x1 = 1.0/(1.0 + exp(-1 * xbeta)) ;

	/* 	survival for STOPBASE = 1 	*/
	STOPBASE = 1 ;
	xbeta = coefs[2]*STOPBASE + coefs[3]*STOPBASE*month3 + coefs[4]*STOPBASE*month3sq + xbeta_base2 ;
	p_x2 = 1.0/(1.0 + exp(-1 * xbeta)) ;

	s_x1 = s_x1 * (1-p_x1) ;
	s_x2 = s_x2 * (1-p_x2) ;
	output;
end; 
run;

proc means data = surv_new  noprint ;
var s_x1 s_x2 ;
class month3;
types month3;
output out = boots.&event&agegroup._wp99_&i (keep = month3 s_x1 s_x2 )  mean(s_x1 s_x2 )= ;


%mend; /* analysis1 */


 %analysis1(
	data=  analytic&i ,
	event =  &event, 
	weight=  wp99 ,
	methodpa = rcs ,
	treatment =  STOPBASE  month3STOPBASE month3sqSTOPBASE , 
	final_model_time = month3 month3sq 
	);



%mend; /* %c23f */


%macro c23g();



proc logistic data=analytic&i outest=hr&i;
class arm (ref='STOPBASE') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0')  
race_c (ref='1') region (ref='3') / param=ref;
model &event (event='1') = arm
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
run;


data boots.hr&event&agegroup._wp99_&i (keep=armCONTINUE); set hr&i; run;


%mend; /* %c23g() */

%do i=&from %to &to;

%let seed=1234&i;
proc surveyselect data=  studysingleids out= bootstudysingleids&i /* #2 */
     seed = &seed method = urs
   samprate = 1 outhits rep = 1;
run;

proc sort data= bootstudysingleids&i; by bene_id; run;

data  bootstudysingleids&i; set  bootstudysingleids&i (keep=bene_id ); run;


/* the database anndata.long12m&agegroup has the cloned strategies in long format. Here I merge it to the ids selected in the bootsample */
  proc sql;
  create table boot_long12m&i as select * from  bootstudysingleids&i full join long12m&agegroup (rename=(bene_id=bene_id2)) on bootstudysingleids&i..bene_id=long12m&agegroup..bene_id2;
  quit;
  /* watch out, delte this later */ data boot_long12m&i; set boot_long12m&i; if /*newbeneid*/bene_id ne '' ; run;

%c23a();
%c23b();
%c23c();
%c23d();
%c23e();
%c23f();
%c23g();

proc datasets lib=work memtype=data ;
delete 
hr&i
bootsample&i

ANALYTIC&i
BOOTCONTINUE&i
BOOTCONTINUEUNIQUE&i

BOOTSTOPBASE&i
BOOTSTOPBASEUNIQUE&i
BOOTSTUDYSINGLEIDS&i
BOOT_LONG12M&i

COEFS

CONTINUE&i   
CONTINUE1_&i             
DATAP99_&i
DATAWP99_&i    
DOUTW_&i   
DOUT_&i  

EVENT_ALL                   

PRED_SCRMAMMO_RCS&i
STOPBASE&i
STOPBASE1_&i  


WCONTINUE&i
WSTOPBASE&i

surv_new

mle_est
model_scrmammo_rcs;
quit;

%end;


%mend;

%cann23(agein1=70, agein2=71, agein3=72, agein4=73, agein5=74, agegroup=7074 ,from=1 ,to=500 ,event=bcucd_tplusone, debugging= /*obs=1000000*/);

