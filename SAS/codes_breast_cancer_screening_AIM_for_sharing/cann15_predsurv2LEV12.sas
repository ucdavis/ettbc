/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* generate the long format					    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

/*libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";*/
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';

%macro cann15(agegroup= , data= );
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann15_logsANDlsts/ag15_12mpredsurv2LEV&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann15_logsANDlsts/ag15_12mpredsurv2LEV&agegroup..log" new;run;


%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';


/* some data steps before the analysis */ 

data longcovs&agegroup; 
set anndata.long12m7579 anndata.long12m8084;
run;




/***********************************/
/* macro for the UNadjusted curves */
/***********************************/

 %macro analysis1(
	y = ,
	event = ,
	treatment = , 
	final_model_time = ,
	data = 
    );

%let new_class_list = 	;

%let all_vars = &treatment &final_model_time &new_class_list;

/*	Create year variables and interactions	*/
data event_all;
set &data (keep=arm month2 &event);
/*if arm ne 'COLO';*/
	
	month3=month2;
	%RCSPLINE(MONTH3,6,48,72);
	month3sq=month31;

	STOPBASE=(arm='STOPBASE');

	month3STOPBASE=month3*STOPBASE;

	month3sqSTOPBASE=month3sq*STOPBASE;	
run;

/*	Regressions		*/	
proc logistic data=event_all descending outest=mle_est noprint;
	model &event = &all_vars;
	title "Unadjusted analysis";
	where 0<=month3<=95;
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

month3sqSTOPCOIN = 0;
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

	/* 	survival for STOPCOIN = 0 (CONTINUE)	*/
	/*STOPCOIN = 0 ;*/
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
var s_x1 s_x2;
class month3;
types month3;
output out = totalr (keep = month3 s_x1 s_x2)  mean(s_x1 s_x2)= ;


proc print data = totalr ;
var month3 s_x1 s_x2;
run;




/**************************************************************************/
PROC EXPORT DATA= WORK.TOTALR 
		OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/ps_ann_unadj12m_&event&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN; 

%mend; /* analysis1 */





 %analysis1(
	data= &data ,
	event =  bcucd_tplusone, 
	treatment = STOPBASE month3STOPBASE month3sqSTOPBASE , 
	final_model_time = month3 month3sq 
	);




%mend; /* cann15 */

%cann15(agegroup=7074, data=anndata.long12m7074);
%cann15(agegroup=7584, data=longcovs7584);







