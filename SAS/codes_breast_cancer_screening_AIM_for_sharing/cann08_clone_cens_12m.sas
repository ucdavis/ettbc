/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* Creation of the clones and censoring, WITH A 12 MONTHS strategy    **/
/*********************************************************************/
 

options mprint notes compress=yes varlenchk=nowarn;

libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

%macro cann08(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann08_logsANDlsts/cann08_12mcohort&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann08_logsANDlsts/cann08_12mcohort&agein..log" new;run;

/*proc print data=mydata.box8_baseline&agein (obs=20);run;*/

/* So, first step is generating arrays for screening mammography and diagnostic mammography. 
Arrays will go from 1 (Jan 2000) to 108 (Dec 2008) */

data ids&agein; 
set anndata.box8_baseline&agein (keep=bene_id ehic);
run;



/*****************************************************************/
/****   DIAGNOSTIC MAMMOGRAM   ************************************/
/*****************************************************************/

/*proc contents data=mydata.dxmammo2000; run;proc contents data=mydata.dxmammo2001; run;
proc contents data=mydata.dxmammo2002; run;proc contents data=mydata.dxmammo2003; run;
proc contents data=mydata.dxmammo2004; run;proc contents data=mydata.dxmammo2005; run;
proc contents data=mydata.dxmammo2006; run;proc contents data=mydata.dxmammo2007; run;
proc contents data=mydata.dxmammo2008; run;*/

data dxmammo2000; set mydata.dxmammo2000 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo1-cm_dxmammo6;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2000 (obs=10);run;*/

data dxmammo2001; set mydata.dxmammo2001 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo7-cm_dxmammo13;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2001 (obs=10);run;*/

data dxmammo2002; set mydata.dxmammo2002 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo14-cm_dxmammo20;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2002 (obs=10);run;*/

data dxmammo2003; set mydata.dxmammo2003 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo21-cm_dxmammo28;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2003 (obs=10);run;*/

data dxmammo2004; set mydata.dxmammo2004 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo29-cm_dxmammo35;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2004 (obs=10);run;*/

data dxmammo2005; set mydata.dxmammo2005 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo36-cm_dxmammo41;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2005 (obs=10);run;*/

data dxmammo2006; set mydata.dxmammo2006 (keep=bene_id date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo42-cm_dxmammo49;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ; run;
/*proc print data=dxmammo2006 (obs=10);run;*/

data dxmammo2007; set mydata.dxmammo2007 (keep=bene_id date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo50-cm_dxmammo56;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ; run;
/*proc print data=dxmammo2007 (obs=10);run;*/

data dxmammo2008; set mydata.dxmammo2008 (keep=bene_id date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo57-cm_dxmammo64;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ; run;
/*proc print data=dxmammo2008 (obs=10);run;*/


/*****************************************************************/
/****   SCREENING MAMMOGRAM   ************************************/
/*****************************************************************/

/*proc contents data=mydata.scrmammo2000; run;proc contents data=mydata.scrmammo2001; run;
proc contents data=mydata.scrmammo2002; run;proc contents data=mydata.scrmammo2003; run;
proc contents data=mydata.scrmammo2004; run;proc contents data=mydata.scrmammo2005; run;
proc contents data=mydata.scrmammo2006; run;proc contents data=mydata.scrmammo2007; run;
proc contents data=mydata.scrmammo2008; run;
%return;*/

data scrmammo2000; set mydata.scrmammo2000 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo1-cm_scrmammo4;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=scrmammo2000 (obs=10);run;*/

data scrmammo2001; set mydata.scrmammo2001 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo5-cm_scrmammo8;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2001 (obs=10);run;*/

data scrmammo2002; set mydata.scrmammo2002 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo9-cm_scrmammo12;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2002 (obs=10);run;*/

data scrmammo2003; set mydata.scrmammo2003 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo13-cm_scrmammo17;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2003 (obs=10);run;*/

data scrmammo2004; set mydata.scrmammo2004 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo18-cm_scrmammo20;
do i=1 to 3;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2004 (obs=10);run;*/

data scrmammo2005; set mydata.scrmammo2005 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo21-cm_scrmammo23;
do i=1 to 3;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2005 (obs=10);run;*/

data scrmammo2006; set mydata.scrmammo2006 (keep=bene_id date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo24-cm_scrmammo27;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=scrmammo2006 (obs=10);run;*/

data scrmammo2007; set mydata.scrmammo2007 (keep=bene_id date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo28-cm_scrmammo35;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=scrmammo2007 (obs=10);run;*/

data scrmammo2008; set mydata.scrmammo2008 (keep=bene_id date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo36-cm_scrmammo39;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=scrmammo2008 (obs=10);run;*/


/* differents ids, thus merging in two steps */

proc sort data=dxmammo2000; by ehic; run;
proc sort data=dxmammo2001; by ehic; run;
proc sort data=dxmammo2002; by ehic; run;
proc sort data=dxmammo2003; by ehic; run;
proc sort data=dxmammo2004; by ehic; run;
proc sort data=dxmammo2005; by ehic; run;

proc sort data=scrmammo2000; by ehic; run;
proc sort data=scrmammo2001; by ehic; run;
proc sort data=scrmammo2002; by ehic; run;
proc sort data=scrmammo2003; by ehic; run;
proc sort data=scrmammo2004; by ehic; run;
proc sort data=scrmammo2005; by ehic; run;

proc sort data= ids&agein; by ehic; run;

data k;
merge ids&agein (in=a) 
scrmammo2000 scrmammo2001 scrmammo2002 scrmammo2003 scrmammo2004 scrmammo2005
dxmammo2000 dxmammo2001 dxmammo2002 dxmammo2003 dxmammo2004 dxmammo2005;
by ehic;
if a; 
run;

proc sort data=dxmammo2006; by bene_id; run;
proc sort data=dxmammo2007; by bene_id; run;
proc sort data=dxmammo2008; by bene_id; run;
proc sort data=scrmammo2006; by bene_id; run;
proc sort data=scrmammo2007; by bene_id; run;
proc sort data=scrmammo2008; by bene_id; run;

proc sort data=k; by bene_id; run;

data k;
merge k (in=a) scrmammo2006 scrmammo2007 scrmammo2008 dxmammo2006 dxmammo2007 dxmammo2008;
by bene_id; if a; run;

/*proc print data=k (obs=10); where bene_id = 'mmmmmmmJDsGaJsJ'; title 'k'; run;*/


data mammos; 
set k;
array SM{*} scrmammo1 - scrmammo108; 
array CMSM{*} cm_scrmammo1-cm_scrmammo39 ;
do i=1 to 108;
	SM[i]=0;
	do j=1 to 39;
	if CMSM[j]=i then SM[i]=1;
	end;
end;
array DM{*} dxmammo1 - dxmammo108; 
array CMDM{*} cm_dxmammo1-cm_dxmammo64 ;
do i=1 to 108;
	DM[i]=0;
	do j=1 to 64;
	if CMDM[j]=i then DM[i]=1;
	end;
end;
keep bene_id scrmammo: dxmammo: ; 
run;


/* Diagnosis of breast cancer will be a reason for not being censored in all arms */

/*proc print data=myCCw.first&agein.breast (obs=10);run;*/
proc sort data=myCCw.first&agein.breast; by bene_id; run;
proc sort data=ids&agein; by bene_id; run;

data bc&agein;
merge ids&agein (in=a) myCCW.first&agein.breast; 
by bene_id; if a; 
monthBC= ((year(dfo_breast)-2000)*12)+month(dfo_breast);  
keep bene_id monthBC;  run;

/*proc print data=bc&agein (obs=10); run;*/




/****************************************************************************/
/***************** STOPENTR arm   *******************************************/
/** Stop at study entry *****************************************************/
/****************************************************************************/

/* merging eligible women with screening mamo, dx mammo and breast cancer */

proc sort data=anndata.box8_baseline&agein; by bene_id; run;

data stopentr;
merge anndata.box8_baseline&agein (in=a) bc&agein mammos;
by bene_id; if a ; run;

data stopentr;
length mstartfup mend monthcensor BCdead counteddeath countedBCdeath countedBCdeathUCD fup 4 ; 
set stopentr;
mstartfup=((year(startfup)-2000)*12)+month(startfup);
mlastfup=((year(lastfup)-2000)*12)+month(lastfup);
mdeath=((year(death_date)-2000)*12)+month(death_date);

array UCEN{*} uncensorable1-uncensorable108;

do i=1 to 108;			/* uncensorable due to breast cancer */
	UCEN[i]=0;
	if monthBC=i then UCEN[i]=1;
end;
do i=2 to 108;
	if UCEN[i-1]=1 then UCEN[i]=1;
end;


do i=mstartfup to (mstartfup+9); /* uncensorable the first 9 months after entering the trial -- scrmammos there are diagnostic */
	UCEN[i]=1;
end;

array SCRM{*} scrmammo1-scrmammo108;		/* censoring for receiving a screening mammo */
array CENSOR{*} c1-c108;
do i=(mstartfup+1) to 108;
	if SCRM[i]=1 AND UCEN[i]=0 then do; 
		CENSOR[i]=1;
		monthcensor=i;
		leave;
		end; 
end;
do i=2 to 108;
	if CENSOR[i-1]=1 then CENSOR[i]=1;
end;
mend=min(mdeath,mlastfup,monthcensor);
counteddeath=(mend=mdeath);
countedBCdeath=(counteddeath=1 AND BCdead=1);
countedBCdeathUCD=(counteddeath=1 AND BCdeadUCD=1);
fup=mend-mstartfup+1;
dummyend=1;
if .<monthBC<=mend then do;
  fupmonthBC=monthBC-mstartfup;
end;
arm='STOPBASE';

/* a check *
array DXM{*} dxmammo1-dxmammo108;	
array DXSCR dxsc1-dxsc108;
do a=(mstartfup+10) to mend;
if DXM[a] = 1 then DXSCR[a]=1;
end;

dxscrsum=sum(of dxsc1-dxsc108);
* end of the check */

keep bene_id ehic mstartfup mend monthcensor counteddeath BCdead countedBCdeath countedBCdeathUCD fupmonthBC monthBC fup arm ; 
run;



proc freq data=stopentr;
table /*monthcensor mend*/ counteddeath countedBCdeath countedBCdeathUCD BCdead /*fup*/ /*dxscrsum*// missing;
title 'arm=STOPBASE';run;

proc means data=stopentr mean median sum;
var fup ; 
title 'arm=STOPBASE';
run;



data stopentrBCincidence;
set stopentr;
keep fupmonthBC arm;
run;
PROC EXPORT DATA= stopentrBCincidence 
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/fupmonth12BC_STOPBASE&agein..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;



/****************************************************************************/
/***************** CONTINUE arm   *******************************************/
/* Continue regardless of age and comorbidities    **************************/
/****************************************************************************/

/* merging eligible women with screening mamo, dx mammo and breast cancer */

proc sort data=anndata.box8_baseline&agein; by bene_id; run;

data continue;
merge anndata.box8_baseline&agein (in=a) bc&agein mammos;
by bene_id; if a ; run;

data continue;
length mstartfup mend monthcensor BCdead counteddeath countedBCdeath countedBCdeathUCD fup 4 ; 
set continue;
mstartfup=((year(startfup)-2000)*12)+month(startfup);
mlastfup=((year(lastfup)-2000)*12)+month(lastfup);
mdeath=((year(death_date)-2000)*12)+month(death_date);

array UCEN{*} uncensorable1-uncensorable108; 	/* uncensorable because diagnosis of breast cancer */
do i=1 to 108;
	UCEN[i]=0;
	if monthBC=i then UCEN[i]=1;
end;
do i=2 to 108;
	if UCEN[i-1]=1 then UCEN[i]=1;
end;

do i=1 to 13;					/* uncensorable the first 14 months -months 12, 13 and 14 are the grace period */
	UCEN[i]=1;
end;

array DXM{*} dxmammo1-dxmammo108;
do i=1 to 108;
	if DXM[i]=1 then do;
		UCEN[i]=1;
		if i <108 then UCEN[i+1]=1;if i <107 then UCEN[i+2]=1;if i <106 then UCEN[i+3]=1;
		if i <105 then UCEN[i+4]=1;if i <104 then UCEN[i+5]=1;if i <103 then UCEN[i+6]=1;
		if i <102 then UCEN[i+7]=1;if i <101 then UCEN[i+8]=1;if i <100 then UCEN[i+9]=1;
		if i <99 then UCEN[i+10]=1;if i <98 then UCEN[i+11]=1;if i <97 then UCEN[i+12]=1;
		if i <96 then UCEN[i+13]=1;
	end;
end;
array SCRM{*} scrmammo1-scrmammo108;
do i=1 to 108;
	if SCRM[i]=1 then do;
		UCEN[i]=1;
		if i <108 then UCEN[i+1]=1;if i <107 then UCEN[i+2]=1;if i <106 then UCEN[i+3]=1;
		if i <105 then UCEN[i+4]=1;if i <104 then UCEN[i+5]=1;if i <103 then UCEN[i+6]=1;
		if i <102 then UCEN[i+7]=1;if i <101 then UCEN[i+8]=1;if i <100 then UCEN[i+9]=1;
		if i <99 then UCEN[i+10]=1;if i <98 then UCEN[i+11]=1;if i <97 then UCEN[i+12]=1;
		if i <96 then UCEN[i+13]=1;
	end;
end;
do i=mstartfup to 108;
	if UCEN[i]=0 then do;
	monthcensor=i/*-1*/;
	leave;	
	end;
end;

mend=min(mdeath,mlastfup,monthcensor);
counteddeath=(mend=mdeath);
countedBCdeath=(counteddeath=1 AND BCdead=1);
countedBCdeathUCD=(counteddeath=1 AND BCdeadUCD=1);
fup=mend-mstartfup+1;
dummyend=1;
arm='CONTINUE';
if .<monthBC<=mend then do; 
  fupmonthBC=monthBC-mstartfup;
end;
keep bene_id ehic mstartfup mend monthcensor BCdead counteddeath countedBCdeath countedBCdeathUCD fupmonthBC monthBC fup arm ; 
run;



proc freq data=continue;
table counteddeath countedBCdeath countedBCdeathUCD BCdead / missing;
title 'arm=CONTINUE'; run;

proc means data=continue mean median sum;
var fup ; 
title 'arm=CONTINUE';
run;


data continueBCincidence;
set continue;
keep fupmonthBC arm;
run;
PROC EXPORT DATA= continueBCincidence 
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/fupmonth12BC_CONTINUE&agein..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;






data anndata.cloned12m&agein;
set stopentr continue /*tillcoin*/ ; 
run;

PROC EXPORT DATA= ANNDATA.cloned12m&agein 
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/cloned12m&agein..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

proc datasets lib=work kill memtype=data;run;

%mend; /* cann08 */




/*%cann08(agein=84);*/
