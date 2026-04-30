/**************************************************************************************************/
/* Code to extract breast cancer surgeries (mastectomy vs lumpectomy) 				 	          */
/**************************************************************************************************/


options mprint notes compress=yes;
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';


%macro c26_bootstrap(agegroup= , fractions= ,beyondfirstround= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann26_6_logsANDlsts/cann26_6_btrp&agegroup.round&beyondfirstround..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann26_6_logsANDlsts/cann26_6_btrp&agegroup.round&beyondfirstround..log" new;run;



data beyondfirstround;set anndata.surg&agegroup (where=(dxbeyondfirstround=&beyondfirstround));run;

proc sql;
create table table_beyondfirstround as
select age, arm, combinedscorelong, anycomorb, sum(breastsurg12) as sum_breastsurg12, sum(lumpectomy12) as sum_lumpectomy12, sum(mastectomy12) as sum_mastectomy12,
sum(rmastectomy12) as sum_rmastectomy12,sum(bclymphsurg12) as sum_bclymphsurg12,
count(*) as total
from beyondfirstround
group by arm, age, combinedscorelong, anycomorb
order by arm, age, combinedscorelong, anycomorb;
quit;

%macro surgery_bar(surgery= , agegroup=);

ods exclude all; 
ods table STDRATE=STDRATE_&surgery;
proc stdrate data=table_beyondfirstround 
refdata=table_beyondfirstround
method=direct effect=diff
stat=rate(mult=100) ;
population group=arm event=sum_&surgery total=total  ;
reference total=total;strata age combinedscorelong anycomorb/ effect  ;
title "&agegroup,  &surgery";

data stdrate_&surgery (keep=arm stdrate lag);set stdrate_&surgery; lag=lag(stdrate);run;

data bar_&surgery._cont;set stdrate_&surgery;if arm='CONTINUE';drop arm lag;call symput("&surgery._bar_cont",stdrate);run;

data bar_&surgery._stop;set stdrate_&surgery;if arm='STOPBASE';drop arm lag;call symput("&surgery._bar_stop",stdrate);run;
%mend; /* surgery_bar */
/**** calls 1 ****/
%surgery_bar(surgery=breastsurg12, agegroup=&agegroup);
%surgery_bar(surgery=rmastectomy12, agegroup=&agegroup);
%surgery_bar(surgery=mastectomy12, agegroup=&agegroup);
%surgery_bar(surgery=lumpectomy12, agegroup=&agegroup);

/*****************/
%MACRO chunking;

%do i=1 %to &fractions;

proc surveyselect data=beyondfirstround out=bootsample&i
     seed = 1234&i method = urs
	 samprate = 1 outhits rep = 1;
run;

proc sql;
create table table_beyondfirstround&i as
select age, arm, combinedscorelong, anycomorb, sum(breastsurg12) as sum_breastsurg12, sum(lumpectomy12) as sum_lumpectomy12, sum(mastectomy12) as sum_mastectomy12,
sum(rmastectomy12) as sum_rmastectomy12,sum(bclymphsurg12) as sum_bclymphsurg12,
count(*) as total
from bootsample&i
group by arm, age, combinedscorelong, anycomorb 
order by arm, age, combinedscorelong, anycomorb;
quit;


%macro surgeries(surg= , agegroup= );

ods table STDRATE=STDRATE_&surg.&i;
proc stdrate data=table_beyondfirstround&i 
refdata=table_beyondfirstround&i
method=direct
effect=diff
stat=rate(mult=100);
population group=arm event=sum_&surg total=total ;
reference total=total;strata age combinedscorelong anycomorb/ order=data effect ;
title "&agegroup,  &surg";


data stdrate_&surg.&i (keep=arm stdrate lag);set stdrate_&surg.&i; lag=lag(stdrate);run;

data stdrate_&surg._cont&i;set stdrate_&surg.&i;if arm='CONTINUE';drop arm lag;run;
data stdrate_&surg._stop&i;set stdrate_&surg.&i;if arm='STOPBASE';drop arm lag;run;

%mend; /* surgeries */

/**** calls 2 ****/
%surgeries(surg=breastsurg12,agegroup=&agegroup);
%surgeries(surg=rmastectomy12,agegroup=&agegroup);
%surgeries(surg=mastectomy12,agegroup=&agegroup);
%surgeries(surg=lumpectomy12,agegroup=&agegroup);
/*****************/

proc datasets lib=work noprint; delete bootsample&i; run;

%end;

%macro srg(sg=);

data &sg._cont; set stdrate_&sg._cont: ; &sg._rate=stdrate + 0; run;  
data &sg._stop; set stdrate_&sg._stop: ; &sg._rate=stdrate + 0; run;  

%mend; /* srg */
/**** calls 3 ****/
%srg(sg=breastsurg12);
%srg(sg=rmastectomy12);
%srg(sg=mastectomy12);
%srg(sg=lumpectomy12);

%mend; /* chunking */

%chunking;

proc datasets lib=work noprint; delete stdrate_ : ; run;

%macro sg(s=);

data bar_&s._cont;set bar_&s._cont;call symput("bar_cont",stdrate);run;

data bar_&s._stop;set bar_&s._stop;call symput("bar_stop",stdrate);run;

 ods exclude none; 

/* Percentile confidence interval */
%let alphalev = .05;
%let a1 = %sysevalf(&alphalev/2*100);
%let a2 = %sysevalf((1 - &alphalev/2)*100);

proc univariate data = &s._cont alpha = .05 noprint; var &s._rate;
  output out=pmethod1 mean = betahat pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ; run;

data t2;   set pmethod1; bias = betahat - &bar_cont; CONTINUE = &bar_cont; run;
ods listing; proc print data  = t2; var CONTINUE bias p_lb p_ub; 
title "&s, &agegroup, beyondfirstround = &beyondfirstround";run;

proc univariate data = &s._stop alpha = .05 noprint; var &s._rate;
  output out=pmethod2 mean = betahat pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ; run;

data t3;   set pmethod2; bias = betahat - &bar_stop; STOPBASE = &bar_stop; run;
ods listing; proc print data  = t3; var STOPBASE bias p_lb p_ub; 
title "&s, &agegroup, beyondfirstround = &beyondfirstround";run;

%mend; /* comp */

/**** calls 4 ****/
%sg(s=breastsurg12);
%sg(s=rmastectomy12);
%sg(s=mastectomy12);
%sg(s=lumpectomy12);

%mend; 


%c26_bootstrap(agegroup=7074, fractions=500,beyondfirstround=1);
%c26_bootstrap(agegroup=7584, fractions=500,beyondfirstround=1);