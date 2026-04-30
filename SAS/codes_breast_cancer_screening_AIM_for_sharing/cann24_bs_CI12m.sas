/*************************************************************************/
/* Code to use the bootstrap samples to compute the variance 	 */
/*************************************************************************/




options mprint notes compress=yes varlenchk=nowarn;

libname boots "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/bootsamples";
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

%macro cann24(agegroup= , weight= , event=  , eventlabel=);
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann24_logsANDlsts/cann24_12m&weight&agegroup&event..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann24_logsANDlsts/cann24_12m&weight&agegroup&event..log" new;run;
 


data a;
set boots.bcucdhr95&agegroup._pall12m;
obs=1;
if obs=1 then call symput('hr_bar',armCONTINUE);
drop obs; 
run;

%put &hr_bar;


data b;
set boots.hrbcucd_tplusone&agegroup._wp99_: ; 
run;


data b;
  set b;
  hr = armCONTINUE + 0; 
run;


proc print data=b; run;


/* Percentile confidence interval */
%let alphalev = .05;
%let a1 = %sysevalf(&alphalev/2*100);
%let a2 = %sysevalf((1 - &alphalev/2)*100);

/* CONTINUE arm */
proc univariate data = b alpha = .05 noprint;
  var hr;
  output out=hr_pmethod mean = hr_betahat pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ;
run;

data hr_ci;
  set hr_pmethod;
  bias = hr_betahat - &hr_bar;
  beta_point_estimate = &hr_bar;
  hr_point_estimate=exp(&hr_bar);
  hr_lb=exp(p_lb);
  hr_ub=exp(p_ub);
run;
ods listing;
proc print data  = hr_ci;
  var hr_point_estimate bias hr_lb hr_ub;
title1 "95% bootstrap CI (percentile method) CONTINUE arm HAZARD RATIO age &agegroup";
run;



%do i=0 %to 95;
data _null_;
 set anndata.p12&weight.&event&agegroup._pall;
 diff2minus1 = s_x1-s_x2;
 if month3 =  "&i" then call symput('s_x1_bar', s_x1);
 if month3 =  "&i" then call symput('s_x2_bar', s_x2);
 if month3 =  "&i" then call symput('diff_bar', diff2minus1);
run;

%put &s_x1_bar;
%put &s_x2_bar;
%put &diff_bar;


data surv&i;
set boots.&event&agegroup._wp99_: (where=(month3=&i)); 
diff2minus1 = s_x1-s_x2;
run;


/* converting character type to numeric type*/
data pred&i;
  set surv&i;
  s_x1_&i = s_x1 + 0;  s_x2_&i = s_x2 + 0;
  diff2minus1_&i = diff2minus1 + 0;
run;



/* Percentile confidence interval */
%let alphalev = .05;
%let a1 = %sysevalf(&alphalev/2*100);
%let a2 = %sysevalf((1 - &alphalev/2)*100);

/* CONTINUE arm */
proc univariate data = pred&i alpha = .05 noprint;
  var s_x1_&i;
  output out=pmethodC&i mean = betahat&i pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ;
run;
data continue_ci&i;
  set pmethodC&i;
  bias = betahat&i - &s_x1_bar;
  s_x1 = &s_x1_bar;
  month3=&i;  drop betahat&i;
run;
ods listing;
proc print data  = continue_ci&i;
  var s_x1 bias p_lb p_ub;
title1 "95% bootstrap CI (percentile method) for &i months, CONTINUE arm";
run;

/* STOPBASE arm */
proc univariate data = pred&i alpha = .05 noprint;
  var s_x2_&i;
  output out=pmethodS&i mean = betahat&i pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ;
run;
data stopbase_ci&i;
  set pmethodS&i;
  bias = betahat&i - &s_x2_bar;
  s_x2 = &s_x2_bar;
  month3=&i;
  drop betahat&i;
run;
ods listing;
proc print data  = stopbase_ci&i;
  var s_x2 bias p_lb p_ub;
title1 "95% bootstrap CI (percentile method) for &i months, STOPBASE arm";
run;

/* STOPBASE-CONTINUE */
proc univariate data = pred&i alpha = .05 noprint;
  var diff2minus1_&i;
  output out=pmethodD&i mean = betahat&i pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ;
run;
data difference_ci&i;
  set pmethodD&i;
  bias = betahat&i - &diff_bar;
  diff2m1 = &diff_bar;
  month3=&i;
  drop betahat&i;
run;
ods listing;
proc print data  = difference_ci&i;
 var diff2m1 bias p_lb p_ub;
title1 "95% bootstrap CI (percentile method) for &i months, STOPBASE-CONTINUE";
run;


%end;

/* export datasets for plotting */

data continue;
set continue_ci: ;
drop bias ;
run;

PROC EXPORT DATA= WORK.continue
		OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/CIp_CONT_&weight._&eventlabel&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN; 



data stopbase;
set stopbase_ci: ;
drop bias ;
run;

PROC EXPORT DATA= WORK.stopbase
		OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/CIp_STOP_&weight._&eventlabel&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN; 



data difference;
set difference_ci: ;
drop bias ;
run;

PROC EXPORT DATA= WORK.difference
		OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/CIp_diff_&weight._&eventlabel&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN; 


%mend; /* c24 */


%cann24(agegroup=7074, weight=wp99, event=bcucd_tplusone, eventlabel=bcucd);
%cann24(agegroup=7584, weight=wp99, event=bcucd_tplusone, eventlabel=bcucd);

