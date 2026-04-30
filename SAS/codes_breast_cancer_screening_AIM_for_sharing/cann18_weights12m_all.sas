/*********************************************************************************************/
/** Project: BREAST cancer screening project 				                                **/
/* creates the weights for adjustment for compliance with the assigned screening strategy	**/
/*********************************************************************************************/

 
options mprint notes compress=yes varlenchk=nowarn;

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';




%macro cann18_5y(agegroup= ,methodpa=);
/* methodpa stands for how I modelled the P[A]. "combo" if using a combination of models for different times since last mammogram, and "rcs" if using just one model with restricted cubic splines */
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann18_logsANDlsts/cann18_12mweights_all_&methodpa&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann18_logsANDlsts/cann18_12mweights_all_&methodpa&agegroup..log" new;run;




/* DESCRIPTION OF THE DATABASES:
        long&agegroup is the backbone dataset, already cloned
        longcovs&agegroup is the non-cloned dataset, with covariates 
        pred_scrmammo&agegroup is the predicted probability of screening mammo, adjusted by TV vars (denominator)
*/


proc sort data=anndata.pred_scrmammo_rcs_all7084; by bene_id month ;run;

/******************/
/* arm = STOPBASE */
/******************/
data STOPBASE; set anndata.long12m&agegroup (/*obs=5000*/ where=(arm='STOPBASE')); run;

proc sort data=STOPBASE; by bene_id age month; run;

data STOPBASE1;
merge STOPBASE (in=a) anndata.longcovs&agegroup (keep=bene_id age month scrmammo dxmammo anymammo tslm tslm_lag);
by bene_id age month;
if a; 
run;

proc sort data=STOPBASE1; by bene_id month; run;


data STOPBASE1; 
merge STOPBASE1 (in=a) anndata.pred_scrmammo_rcs_all7084;
by bene_id month; 
if a; 
run;

proc sort data=STOPBASE1; by bene_id age month2; run;


data STOPBASE1;
set STOPBASE1;
if 0<=tslm_lag<=10 then p_scrmammo_&methodpa=0;
if 0<=month2<=11 then w=1;
if .<monthBC<=month then bc_long=1;
if bc_long=1 then den=1;
if bc_long=0 AND month2>11 then den=(1-p_scrmammo_&methodpa);

retain w sw;
if month2>11 then w=w/den;
run;


proc univariate data=STOPBASE1 ; var w; output out=dout pctlpts=99 pctlpre=w pctlname=p99; title 'STOPBASE'; run;
proc print data=dout; run;

data datap99; set dout (keep = wp99); run; 
proc transpose data = datap99 out = datap99;run;
proc print data = datap99;run;

proc sql noprint ; select col1 into : p99 separated by ' ' from datap99; quit;

%let p99=%sysevalf(&p99); %put &p99;


data anndata.wSTOPBASE&methodpa&agegroup._pall;
set STOPBASE1 (keep=bene_id arm month age w);
wp99=w;
if w >= &p99 then wp99=&p99;
run;


proc sort data=anndata.wSTOPBASE&methodpa&agegroup._pall; 
by bene_id age month;
run;


proc means data=anndata.wSTOPBASE&methodpa&agegroup._pall n nmiss mean std min max p25 p50 p75 p99 ; var w wp99 ; 

title '************************* STOPBASE ******************************'; run;




/******************/
/* arm = CONTINUE */
/******************/

data CONTINUE; set anndata.long12m&agegroup (/*obs=1000000*/ where=(arm='CONTINUE') ); run;

proc sort data=CONTINUE; by bene_id age month; run;

data CONTINUE1;
merge CONTINUE (in=a) anndata.longcovs&agegroup (keep=bene_id age month scrmammo anymammo tslm_lag tslm) ;
by bene_id age month;
if a; 
run;

proc sort data=CONTINUE1; by bene_id month; run;


data CONTINUE1; 
merge CONTINUE1 (in=a) anndata.pred_scrmammo_rcs_all7084;
by bene_id month; 
if a; 
run;

proc sort data=CONTINUE1; by bene_id age month2; 

data CONTINUE1;
set CONTINUE1;
if 0<=tslm_lag<=10 then p_scrmammo_&methodpa=0;
if anymammo=1 then mstartgp=month2;
if .<monthBC<=month then bc_long=1;
retain mstartgp;
mendgp=mstartgp+ 14;
lagmendgp=lag(mendgp);
if lagmendgp = month2 and scrmammo=1 then flag=1;
run;

proc sort data=CONTINUE1; by bene_id age month2; 


data CONTINUE1;
set CONTINUE1;
%do j=1 %to 3; 
if tslm_lag=10+&j and scrmammo=0 then unif=1-(1/( 3+1-&j));
%end;
%do j=1 %to 3; 
if tslm_lag=10+&j and scrmammo=1 then unif=(1/( 3+1-&j));
%end;
if tslm_lag<11 then unif=1;
if bc_long=1 then unif=1;
if month2=0 then w=1;
if month2=0 then wunif=1;
den=1;
num=1;
denunif=1;
numunif=1;
stab_unif=1;
if bc_long = 0 AND flag=1 then do; 
    den=p_scrmammo_&methodpa;
    end;
if bc_long = 0 then do;
    if 11<=tslm_lag<= 13 and scrmammo=0 then denunif=1-p_scrmammo_&methodpa;
    if 11<=tslm_lag<= 13 and scrmammo=1 then denunif=p_scrmammo_&methodpa;
    numunif=unif;
    end;

retain w wunif;
w=w/den;
wunif=wunif*numunif/denunif;
run; 


/****/proc univariate data=CONTINUE1 ; var w; output out=dout pctlpts=99 pctlpre=w pctlname=p99; title 'CONTINUE' ;run;
proc print data=dout; run;

data datap99; set dout (keep = wp99); run;
proc transpose data = datap99 out = datap99;run;
proc print data = datap99;run;

proc sql noprint ; select col1 into : p99 separated by ' ' from datap99; quit;

%let p99=%sysevalf(&p99); %put &p99;



/****/proc univariate data=CONTINUE1 ; var wunif; output out=doutwunif pctlpts=99 pctlpre=wunif pctlname=p99; title 'CONTINUE' ;run;
proc print data=doutwunif; run;

data datawunifp99; set doutwunif (keep = wunifp99); run;
proc transpose data = datawunifp99 out = datawunifp99;run;
proc print data = datawunifp99;run;

proc sql noprint ; select col1 into : wunif_p99 separated by ' ' from datawunifp99; quit;

%let wunif_p99=%sysevalf(&wunif_p99); %put &wunif_p99;




data anndata.wCONTINUE&methodpa&agegroup._pall;
set CONTINUE1 (keep=bene_id arm month age w wunif);
wp99=w;
wunifp99=wunif;
if w >= &p99 then wp99=&p99;
if wunif >= &wunif_p99 then wunifp99=&wunif_p99;
run;


proc sort data=anndata.wCONTINUE&methodpa&agegroup._pall; 
by bene_id age month;
run;



proc means data=anndata.wCONTINUE&methodpa&agegroup._pall n nmiss mean std min max p25 p50 p75 p99 ; var w wunif wp99 wunifp99; 

title '************************* CONTINUE1 ******************************'; run;


%mend; /* c18 */


%cann18_5y(agegroup=8084,methodpa=rcs);
%cann18_5y(agegroup=7074,methodpa=rcs);
%cann18_5y(agegroup=7579,methodpa=rcs);








%macro cann18_10y(agegroup= ,methodpa=);
/* methodpa stands for how I modelled the P[A]. "combo" if using a combination of models for different times since last mammogram, and "rcs" if using just one model with restricted cubic splines */
proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann18_logsANDlsts/cann18_12mweights_all_&methodpa&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann18_logsANDlsts/cann18_12mweights_all_&methodpa&agegroup..log" new;run;


/* DESCRIPTION OF THE DATABASES:
		long&agegroup is the backbone dataset, already cloned
		longcovs&agegroup is the non-cloned dataset, with covariates 
		pred_scrmammo&agegroup is the predicted probability of screening mammo, adjusted by TV vars (denominator)
*/


data long12m&agegroup;
set anndata.long12m7579 anndata.long12m8084;
run;

proc sort data=long12m&agegroup;
by bene_id age month; 
run;


data longcovs&agegroup; 
set anndata.longcovs7579 anndata.longcovs8084;
run;

proc sort data=longcovs&agegroup; 
by bene_id age month; 
run;




/******************/
/* arm = STOPBASE */
/******************/
data STOPBASE; set long12m&agegroup (/*obs=5000*/ where=(arm='STOPBASE') ); run;

proc sort data=STOPBASE; by bene_id age month; run;

data STOPBASE1;
merge STOPBASE (in=a) longcovs&agegroup (keep=bene_id age month scrmammo dxmammo anymammo tslm tslm_lag);
by bene_id age month;
if a; 
run;

proc sort data=STOPBASE1; by bene_id month; run;


data STOPBASE1; 
merge STOPBASE1 (in=a) anndata.pred_scrmammo_rcs_all7084;
by bene_id month; 
if a; 
run;

proc sort data=STOPBASE1; by bene_id month; run;

data STOPBASE1;
set STOPBASE1;
if 0<=tslm_lag<=10 then p_scrmammo_&methodpa=0;
if 0<=month2<=11 then w=1;
if .<monthBC<=month then bc_long=1;
if bc_long=1 then den=1;
if bc_long=0 AND month2>11 then den=(1-p_scrmammo_&methodpa);

retain w sw;
if month2>11 then w=w/den;
run;


proc univariate data=STOPBASE1 ; var w; output out=dout pctlpts=99 pctlpre=w pctlname=p99; title 'STOPBASE'; run;
proc print data=dout; run;

data datap99; set dout (keep = wp99); run; 
proc transpose data = datap99 out = datap99;run;
proc print data = datap99;run;

proc sql noprint ; select col1 into : p99 separated by ' ' from datap99; quit;

%let p99=%sysevalf(&p99); %put &p99;


data anndata.wSTOPBASE&methodpa&agegroup._pall;
set STOPBASE1 (keep=bene_id arm month age w /*sw*/);
wp99=w;
if w >= &p99 then wp99=&p99;
run;


proc sort data=anndata.wSTOPBASE&methodpa&agegroup._pall; 
by bene_id age month;
run;

proc means data=anndata.wSTOPBASE&methodpa&agegroup._pall n nmiss mean std min max p25 p50 p75 p99 ; var w wp99 ; 

title '************************* STOPBASE ******************************'; run;




/******************/
/* arm = CONTINUE */
/******************/

data CONTINUE; set long12m&agegroup (/*obs=1000000*/ where=(arm='CONTINUE') ); run;

proc sort data=CONTINUE; by bene_id age month; run;

data CONTINUE1;
merge CONTINUE (in=a) longcovs&agegroup (keep=bene_id age month scrmammo anymammo tslm_lag tslm) ;
by bene_id age month;
if a; 
run;

proc sort data=CONTINUE1; by bene_id month; run;


data CONTINUE1; 
merge CONTINUE1 (in=a) anndata.pred_scrmammo_rcs_all7084;
by bene_id month; 
if a; 
run;

proc sort data=CONTINUE1; by bene_id age month2; run;

data CONTINUE1;
set CONTINUE1;
if 0<=tslm_lag<=10 then p_scrmammo_&methodpa=0;
if anymammo=1 then mstartgp=month2;
if .<monthBC<=month then bc_long=1;
retain mstartgp;
mendgp=mstartgp+14;
lagmendgp=lag(mendgp);
if lagmendgp = month2 and scrmammo=1 then flag=1;
run;


proc sort data=CONTINUE1; by bene_id age month2; 

data CONTINUE1;
set CONTINUE1;
%do j=1 %to 3; 
if tslm_lag=10+&j and scrmammo=0 then unif=1-(1/( 3+1-&j));
%end;
%do j=1 %to 3; 
if tslm_lag=10+&j and scrmammo=1 then unif=(1/( 3+1-&j));
%end;
if tslm_lag<11 then unif=1;
if bc_long=1 then unif=1;
if month2=0 then w=1;
if month2=0 then wunif=1;
den=1;
num=1;
denunif=1;
numunif=1;
stab_unif=1;
if bc_long = 0 AND flag=1 then do; 
    den=p_scrmammo_&methodpa;
    end;
if bc_long = 0 then do;
    if 11<=tslm_lag<= 13 and scrmammo=0 then denunif=1-p_scrmammo_&methodpa;
    if 11<=tslm_lag<= 13 and scrmammo=1 then denunif=p_scrmammo_&methodpa;
    numunif=unif;
    end;

retain w wunif;
w=w/den;
wunif=wunif*numunif/denunif;
run; 


/****/proc univariate data=CONTINUE1 ; var w; output out=dout pctlpts=99 pctlpre=w pctlname=p99; title 'CONTINUE' ;run;
proc print data=dout; run;

data datap99; set dout (keep = wp99); run;
proc transpose data = datap99 out = datap99;run;
proc print data = datap99;run;

proc sql noprint ; select col1 into : p99 separated by ' ' from datap99; quit;

%let p99=%sysevalf(&p99); %put &p99;


/****/proc univariate data=CONTINUE1 ; var wunif; output out=doutwunif pctlpts=99 pctlpre=wunif pctlname=p99; title 'CONTINUE' ;run;
proc print data=doutwunif; run;

data datawunifp99; set doutwunif (keep = wunifp99); run;
proc transpose data = datawunifp99 out = datawunifp99;run;
proc print data = datawunifp99;run;

proc sql noprint ; select col1 into : wunif_p99 separated by ' ' from datawunifp99; quit;

%let wunif_p99=%sysevalf(&wunif_p99); %put &wunif_p99;



data anndata.wCONTINUE&methodpa&agegroup._pall;
set CONTINUE1 (keep=bene_id arm month age w wunif );
wp99=w;
wunifp99=wunif;
if w >= &p99 then wp99=&p99;
if wunif >= &wunif_p99 then wunifp99=&wunif_p99;
run;


proc sort data=anndata.wCONTINUE&methodpa&agegroup._pall; 
by bene_id age month;
run;



proc means data=anndata.wCONTINUE&methodpa&agegroup._pall n nmiss mean std min max p25 p50 p75 p99 ; var w  wunif  wp99 wunifp99; 

title '************************* CONTINUE1 ******************************'; run;


%mend; /* c18 */

%cann18_10y(agegroup=7584,methodpa=rcs);

