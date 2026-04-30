/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* Outcome model, predicted survival				    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';




 
%macro cann21_5y(agegroup= ,weight= ,methodpa= ,upto= , pall= );
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann21_logsANDlsts/cann21_12m&methodpa.&weight._adjps2LEV&upto.&agegroup.&pall..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann21_logsANDlsts/cann21_12m&methodpa.&weight._adjps2LEV&upto.&agegroup.&pall..log" new;run;

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';


/* from the unexpanded dataset, I select baseline variables */
data basecovs&agegroup;
set anndata.longcovs&agegroup (keep= 
bene_id age month year_base race_c region 
ervisit6m_base2 daysin6m_base2 
baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base 
AF_base CHF_base CKD_base COPD_base CRC_base HTA_base IHD_base LTC_base RA_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base
glaucoma_base hip12_base hypoth_base lipid_base lung_base osteo_base stroke12_base year_base );
year_base_sq=year_base*year_base;
run;

proc sort data=basecovs&agegroup; by bene_id age month; 


/* the backbone, already cloned -- I select only the variables I need */

data backbone&agegroup; set anndata.long12m&agegroup (drop=bc_long monthBC);run; 

proc sort data=backbone&agegroup; by bene_id age month;


data x&agegroup;
merge backbone&agegroup (in=a) basecovs&agegroup;
by bene_id age month; 
if a; 
run;

proc sort data=x&agegroup; by bene_id age month arm; run;

data y&agegroup; 
merge x&agegroup (in=a) anndata.wSTOPBASE&methodpa&agegroup.&pall anndata.wCONTINUE&methodpa&agegroup.&pall (rename=(wunifp99=wu99));
by bene_id age month arm;
if a; 
run;



%let thirdknot=%eval(&upto-23);

data y&agegroup; 
set y&agegroup; 
if 0<=month2<=&upto;
%RCSPLINE(month2,6,48,&thirdknot);

if arm='STOPBASE' then wunif=w;
if arm='STOPBASE' then wu99=wp99;

run;


%macro analysis1(
	y = ,
	event = ,
	weight= ,
	methodpa= ,
	treatment = , 
	final_model_time = ,
	data = 
    );

%let thirdknot=%eval(&upto-23);
%let new_class_list = 	 	race2 race3	
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
	title "Fully-adjusted analysis";
	where 0<=month3<=/*95*/ &upto;
	weight &weight;
run;


/*	Generate predicted probability of survival	*/
data coefs (drop = _TYPE_) ;
set mle_est (where= ( _TYPE_='PARMS') keep = _TYPE_ Intercept &all_vars );
run;

proc transpose data = coefs out = coefs ;
proc print data = coefs ;
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

do month3 = 0 to /*95*/ &upto  ;
%RCSPLINE(month3,6,48,/*72*//*84*/&thirdknot);
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
output out = a (keep = month3 s_x1 s_x2 )  mean(s_x1 s_x2 )= ;

data anndata.p12&weight.&event&agegroup.&pall;
set a; 
run;


proc print data = anndata.p12&weight.&event&agegroup.&pall ;
var month3 s_x1 s_x2 ;
title "&agegroup , &weight , &event ";
run;

/**************************************************************************/
PROC EXPORT DATA= WORK.a 
		OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/p12&upto&methodpa._&weight._&event&agegroup.&pall..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN; 

%mend; /* analysis1 */


 %analysis1(
	data= y&agegroup ,
	event = bcucd_tplusone, 
	weight= &weight ,
	methodpa = &methodpa ,
	treatment =  STOPBASE  month3STOPBASE  month3sqSTOPBASE , 
	final_model_time = month3 month3sq 
	);


%mend; /* cann21_5y */


%cann21_5y(agegroup=8084 ,weight=wp99 ,methodpa=rcs, upto=95, pall=_pall);
%cann21_5y(agegroup=7074 ,weight=wp99 ,methodpa=rcs, upto=95, pall=_pall);
%cann21_5y(agegroup=7579 ,weight=wp99 ,methodpa=rcs, upto=95, pall=_pall);


 
%macro cann21_10y(agegroup= ,weight= ,methodpa= ,upto= , pall= );
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann21_logsANDlsts/cann21_12m&methodpa.&weight._adjps2LEV&upto.&agegroup.&pall..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann21_logsANDlsts/cann21_12m&methodpa.&weight._adjps2LEV&upto.&agegroup.&pall..log" new;run;

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';


/* some data steps before the analysis */

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



/* from the unexpanded dataset, I select baseline variables */
data basecovs&agegroup;
set longcovs&agegroup (keep= 
bene_id age month year_base race_c region 
ervisit6m_base2 daysin6m_base2 
 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base 
AF_base CHF_base CKD_base COPD_base CRC_base HTA_base IHD_base LTC_base RA_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base
glaucoma_base hip12_base hypoth_base lipid_base lung_base osteo_base stroke12_base year_base );
year_base_sq=year_base*year_base;
run;

proc sort data=basecovs&agegroup; by bene_id age month; 


data backbone&agegroup; set long12m&agegroup (drop=bc_long monthBC);run; 

proc sort data=backbone&agegroup; by bene_id age month;


data x&agegroup;
merge backbone&agegroup (in=a) basecovs&agegroup;
by bene_id age month; 
if a; 
run;

proc sort data=x&agegroup; by bene_id age month arm; run;

data y&agegroup; 
merge x&agegroup (in=a) anndata.wSTOPBASE&methodpa&agegroup&pall anndata.wCONTINUE&methodpa&agegroup&pall (rename=(wunifp99=wu99));
by bene_id age month arm;
if a; 
run;

%let thirdknot=%eval(&upto-23);

data y&agegroup; 
set y&agegroup; 
if 0<=month2<=&upto;
%RCSPLINE(month2,6,48,&thirdknot);

if arm='STOPBASE' then wunif=w;
if arm='STOPBASE' then wu99=wp99;

run;


%macro analysis1(
	y = ,
	event = ,
	weight= ,
	methodpa= ,
	treatment = , 
	final_model_time = ,
	data = 
    );

%let thirdknot=%eval(&upto-23);
%let new_class_list = 	 	race2 race3	
			region1 region2 region4
			ervisit6m_base2
			in1 in2 
			influenza_base
			bonemass_base
			cvd_prev_base
			diabetes_prev_base
			previsit_base
			crc_prev_base
			pelvic_prev_base

			LTC_base

			comcom_c0 
						
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
	title "Fully-adjusted analysis";
	where 0<=month3<=/*95*/ &upto;
	weight &weight;
run;


/*	Generate predicted probability of survival	*/
data coefs (drop = _TYPE_) ;
set mle_est (where= ( _TYPE_='PARMS') keep = _TYPE_ Intercept &all_vars );
run;

proc transpose data = coefs out = coefs ;
proc print data = coefs ;
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

do month3 = 0 to &upto  ;
%RCSPLINE(month3,6,48,&thirdknot);
month3sq=month31;


    	xbeta_base2 = xbeta_base + coefs[5]*month3 + coefs[6]*month3sq ;	

	/* 	survival for  (CONTINUE)	*/
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
output out = a (keep = month3 s_x1 s_x2 )  mean(s_x1 s_x2 )= ;

data anndata.p12&weight.&event&agegroup.&pall;
set a; 
run;


proc print data = anndata.p12&weight.&event&agegroup.&pall ;
var month3 s_x1 s_x2 ;
title "&agegroup , &weight , &event ";
run;

/**************************************************************************/
PROC EXPORT DATA= WORK.a 
		OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/p12&upto&methodpa._&weight._&event&agegroup.&pall..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN; 

%mend; /* analysis1 */


 %analysis1(
	data= y&agegroup ,
	event = bcucd_tplusone, 
	weight= &weight ,
	methodpa = &methodpa ,
	treatment =  STOPBASE  month3STOPBASE  month3sqSTOPBASE , 
	final_model_time = month3 month3sq 
	);


%mend; /* cann21_10y */

%cann21_10y(agegroup=7584 ,weight=wp99 ,methodpa=rcs, upto=95, pall=_pall);

