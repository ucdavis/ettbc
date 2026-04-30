/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* generate the long format					    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';

%macro cann14(agein1= ,agein2= ,agein3=, agein4=, agein5=, agegroup= );
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann14_logsANDlsts/cann14_12mlong&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann14_logsANDlsts/cann14_12mlong&agegroup..log" new;run;

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';


data x&agein1; set anndata.cloned12m&agein1; age=&agein1; run;
data x&agein2; set anndata.cloned12m&agein2; age=&agein2; run;
data x&agein3; set anndata.cloned12m&agein3; age=&agein3; run;
data x&agein4; set anndata.cloned12m&agein4; age=&agein4; run;
data x&agein5; set anndata.cloned12m&agein5; age=&agein5; run;

/*proc print data=x&agein1 (obs=100);run;*/

data x&agegroup; set x&agein1 x&agein2 x&agein3 x&agein4 x&agein5; run;

/*proc print data=x&agegroup (obs=100);where countedBCdeath=1; run;*/

/* so this will be Yt+1, Ct, Lt+1, At */
/* I'll use Lt+1 because how I extracted time-varying variables, it corresponds to Lt, i.e.
if tv1=1 at month 3 it means it was measured up to the end of month 2 */

/*proc print data=mydata.cloned&agein (obs=20);
where mstartfup=mend;
run;*/


proc freq data=x&agegroup; table counteddeath*arm / missing; run;

proc freq data=x&agegroup;
table (counteddeath countedBCdeath countedBCdeathUCD)*arm / missing; 
title "breast cancer deaths happening the first month, agegroup=&agegroup";
where mstartfup=mend;run;



data long;
set x&agegroup ;
retain newid;
if _n_ = 1 then newid=0;
newid=newid+1;
dead_tplusone=0;
  do month=mstartfup to mend;
  if month= mend then do;
    if month= mstartfup then dead_tplusone=.;
    else if month > mstartfup then do;
      if counteddeath=1 then dead_tplusone=1;
      else dead_tplusone=.;
    end;
  end;
output;
end;
drop ehic; 
run;

data anndata.long12m&agegroup; 
length month2 dead_tplusone bcdead_tplusone bcucd_tplusone age month bc_long 3 ;
set long (keep=bene_id arm month dead_tplusone mstartfup mend counteddeath countedBCdeath countedBCdeathUCD age monthBC); 
month2=month-mstartfup;

if month=mend-1 and counteddeath=1 then dead_tplusone=1;
if mend=month and counteddeath=1 then delete; 
bcdead_tplusone=dead_tplusone;
if dead_tplusone=1 AND countedBCdeath=0 then bcdead_tplusone=0;
bcucd_tplusone=dead_tplusone;
if dead_tplusone=1 AND countedBCdeathUCD=0 then bcucd_tplusone=0;
bc_long=0;
if monthBC=month then bc_long=1;
drop mstartfup mend counteddeath countedBCdeath countedBCdeathUCD ;
run;

proc sort data=anndata.long12m&agegroup; by bene_id age month; run;  

/*proc print data= mydata.long&agegroup (obs=100000);  where arm ='STOPBASE' and age=66;run;*/

proc freq data= anndata.long12m&agegroup;
table (dead_tplusone bcdead_tplusone bcucd_tplusone)*arm / missing;
run;

%mend; /* c14 */



*%cann14(agein1=80, agein2=81, agein3=82, agein4=83, agein5=84, agegroup=8084);
*%cann14(agein1=70, agein2=71, agein3=72, agein4=73, agein5=74, agegroup=7074);
*%cann14(agein1=75, agein2=76, agein3=77, agein4=78, agein5=79, agegroup=7579);




