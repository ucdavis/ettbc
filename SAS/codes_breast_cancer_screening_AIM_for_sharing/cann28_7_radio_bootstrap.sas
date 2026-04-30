/**************************************************************************************************/
/* Code to extract radiotherapy 				 	          */
/**************************************************************************************************/


options mprint notes compress=yes;
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';


%macro c28_bootstrap(agegroup= , fractions= ,beyondfirstround= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann28_logsANDlsts/cann28_7_btrp&agegroup.round&beyondfirstround..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann28_logsANDlsts/cann28_7_btrp&agegroup.round&beyondfirstround..log" new;run;



data beyondfirstround;set anndata.rad&agegroup (where=(dxbeyondfirstround=&beyondfirstround));run;

proc sql;
create table table_beyondfirstround as
select age, arm, combinedscorelong, anycomorb, sum(radio12) as sum_radio12,
count(*) as total
from beyondfirstround
group by arm, age, combinedscorelong, anycomorb
order by arm, age, combinedscorelong, anycomorb;
quit;

%macro radio_bar(radio= , agegroup=);

ods exclude all; 
ods table STDRATE=STDRATE_&radio;
proc stdrate data=table_beyondfirstround 
refdata=table_beyondfirstround
method=direct effect=diff
stat=rate(mult=100) ;
population group=arm event=sum_&radio total=total  ;
reference total=total;strata age combinedscorelong anycomorb/ effect  ;
title "&agegroup,  &radio";

data stdrate_&radio (keep=arm stdrate lag);set stdrate_&radio; lag=lag(stdrate);run;

data bar_&radio._cont;set stdrate_&radio;if arm='CONTINUE';drop arm lag;call symput("&radio._bar_cont",stdrate);run;

data bar_&radio._stop;set stdrate_&radio;if arm='STOPBASE';drop arm lag;call symput("&radio._bar_stop",stdrate);run;
%mend; /* radio_bar */
/**** calls 1 ****/
%radio_bar(radio=radio12, agegroup=&agegroup);



/*****************/
%MACRO chunking;

%do i=1 %to &fractions;

proc surveyselect data=beyondfirstround out=bootsample&i
     seed = 1234&i method = urs
	 samprate = 1 outhits rep = 1;
run;

proc sql;
create table table_beyondfirstround&i as
select age, arm, combinedscorelong, anycomorb, sum(radio12) as sum_radio12,
count(*) as total
from bootsample&i
group by arm, age, combinedscorelong, anycomorb 
order by arm, age, combinedscorelong, anycomorb;
quit;


%macro radiotherapies(rad= , agegroup= );

ods table STDRATE=STDRATE_&rad.&i;
proc stdrate data=table_beyondfirstround&i 
refdata=table_beyondfirstround&i
method=direct
effect=diff
stat=rate(mult=100);
population group=arm event=sum_&rad total=total ;
reference total=total;strata age combinedscorelong anycomorb/ order=data effect ;
title "&agegroup,  &rad";


data stdrate_&rad.&i (keep=arm stdrate lag);set stdrate_&rad.&i; lag=lag(stdrate);run;

data stdrate_&rad._cont&i;set stdrate_&rad.&i;if arm='CONTINUE';drop arm lag;run;
data stdrate_&rad._stop&i;set stdrate_&rad.&i;if arm='STOPBASE';drop arm lag;run;

%mend; 

/**** calls 2 ****/
%radiotherapies(rad=radio12,agegroup=&agegroup);

/*****************/

proc datasets lib=work noprint; delete bootsample&i; run;

%end;

%macro rad(ra=);

data &ra._cont; set stdrate_&ra._cont: ; &ra._rate=stdrate + 0; run;  
data &ra._stop; set stdrate_&ra._stop: ; &ra._rate=stdrate + 0; run;  

%mend; /* srg */
/**** calls 3 ****/
%rad(ra=radio12);

%mend; /* chunking */

%chunking;

proc datasets lib=work noprint; delete stdrate_ : ; run;

%macro ra(r=);

data bar_&r._cont;set bar_&r._cont;call symput("bar_cont",stdrate);run;

data bar_&r._stop;set bar_&r._stop;call symput("bar_stop",stdrate);run;

 ods exclude none; 

/* Percentile confidence interval */
%let alphalev = .05;
%let a1 = %sysevalf(&alphalev/2*100);
%let a2 = %sysevalf((1 - &alphalev/2)*100);

proc univariate data = &r._cont alpha = .05 noprint; var &r._rate;
  output out=pmethod1 mean = betahat pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ; run;

data t2;   set pmethod1; bias = betahat - &bar_cont; CONTINUE = &bar_cont; run;
ods listing; proc print data  = t2; var CONTINUE bias p_lb p_ub; 
title "&r, &agegroup, beyondfirstround = &beyondfirstround";run;

proc univariate data = &r._stop alpha = .05 noprint; var &r._rate;
  output out=pmethod2 mean = betahat pctlpts=&a1 &a2 pctlpre = p pctlname = _lb _ub ; run;

data t3;   set pmethod2; bias = betahat - &bar_stop; STOPBASE = &bar_stop; run;
ods listing; proc print data  = t3; var STOPBASE bias p_lb p_ub; 
title "&r, &agegroup, beyondfirstround = &beyondfirstround";run;

%mend; /* comp */

/**** calls 4 ****/
%ra(r=radio12);






%mend; 


%c28_bootstrap(agegroup=7074, fractions=500,beyondfirstround=1);
%c28_bootstrap(agegroup=7584, fractions=500,beyondfirstround=1);