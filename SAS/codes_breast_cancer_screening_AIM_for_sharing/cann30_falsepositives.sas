/**************************************************************************************************/
/* Code to extract breast cancer surgeries (mastectomy vs lumpectomy 				 	          */
/**************************************************************************************************/


options mprint notes compress=yes;
libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';


%macro cann30_fp(agein1=, agein2=, agein3=, agein4=, agein5=, agegroup= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann30_logsANDlsts/cann30_fp&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann30_logsANDlsts/cann30_fp&agegroup..log" new;run;


/*proc print data=mydata.long&agegroup (obs=10);run;
proc print data=mydata.longcovs&agegroup (obs=10);run;*/
/*data bcSTOPBASE ; 
set mydata.long&agegroup (where=(arm = "STOPBASE"));
bc=(monthBC=month);
run;
proc sort data=bcSTOPBASE; by bene_id age month; 
*/

data longcovs&agegroup;
set anndata.longcovs&agegroup (keep=bene_id scrmammo dxmammo age month race_c combinedscorelong alzheimer_long ami12_long
	chf_long ckd_long copd_long hip_long stroke12_long lung_long crc_long endometrial_long ltc_long);
anycomorb=(sum(of alzheimer_long ami12_long chf_long ckd_long copd_long hip_long stroke12_long lung_long 
	crc_long endometrial_long ltc_long)>0);
keep bene_id age month race_c anycomorb combinedscorelong scrmammo dxmammo; 
run;


/*proc sort data=longcovs&agegroup; by bene_id age month; run;

data bcSTOPBASE;
merge bcSTOPBASE (in=a) longcovs&agegroup;
by bene_id age month; 
if a; 
run;

data bcSTOPBASE;
set bcSTOPBASE;
by bene_id age;
lobs=last.age;
actualbc=bc;
if lobs=1 and scrmammo=1 then actualbc=0;
run;

proc freq data=bcSTOPBASE;
table bc*actualbc /missing; run;

proc print data=bcSTOPBASE (obs=50000);
var bene_id age month month2 monthBC bc actualbc scrmammo dxmammo lobs;
run;

%return;*/

data CONTINUE&agegroup; set anndata.long12m&agegroup (keep=arm bene_id age month monthBC month2); 
if arm='CONTINUE'; bc=(monthBC=month); run;

data STOPBASE&agegroup; set anndata.long12m&agegroup (keep=arm bene_id age month monthBC month2); 
if arm='STOPBASE'; bc=(monthBC=month); run;

proc sort data= CONTINUE&agegroup; by bene_id age month; run;

data CONTINUE&agegroup; merge CONTINUE&agegroup (in=a) longcovs&agegroup; 
by bene_id age month; 
if a;  run;


proc sort data= STOPBASE&agegroup; by bene_id age month; run;

data STOPBASE&agegroup; merge STOPBASE&agegroup (in=a) longcovs&agegroup; 
by bene_id age month; 
if a; run;

/* I won't count as BC those diagnosed the last month before censoring due to screening mammogram in the STOPBASE arm, althoug these are very few: less than 10 cases. Still. */
data STOPBASE&agegroup;
set STOPBASE&agegroup;
by bene_id age;
lobs=last.age;
/*actualbc=bc;*/
if lobs=1 and scrmammo=1 then /*actual*/bc=0;
run;

/*proc print data=STOPBASE&agegroup (obs=1000);
run;*/

data continuelastobs; set CONTINUE&agegroup;
by bene_id age;
lobs=last.age;
if lobs=1 then lastobs=month;
if lastobs ne .;
keep bene_id age lastobs; run;

proc sort data=continuelastobs; by bene_id age; run;

data stopbaselastobs; set STOPBASE&agegroup;
if lobs=1 then lastobs=month;
if lastobs ne .;
keep bene_id age lastobs; run;

/*proc print data=stopbaselastobs (obs=10000);run;*/

proc sort data=stopbaselastobs; by bene_id age; run;

data CONTINUE&agegroup; set CONTINUE&agegroup;
if monthBC=. OR month<=monthBC+6 ; run;

data STOPBASE&agegroup; set STOPBASE&agegroup;
if monthBC=. OR month<=monthBC+6 ; run;

proc freq data=CONTINUE&agegroup;
table bc scrmammo dxmammo / missing; 
where 0<=month2<=9;
title "BC and mammos, CONTINUE arm, first round of screening";
run;
proc freq data=STOPBASE&agegroup;
table bc scrmammo dxmammo / missing; 
where 0<=month2<=9;
title "BC and mammos, STOPBASE arm, first round of screening";
run;
proc freq data=CONTINUE&agegroup;
table bc scrmammo dxmammo / missing; 
where month2>9;
title "BC and mammos, CONTINUE arm, beyond first round of screening";
run;
proc freq data=STOPBASE&agegroup;
table bc scrmammo dxmammo / missing; 
where month2>9;
title "BC and mammos, STOPBASE arm, beyond first round of screening";
run;


/*proc print data=STOPBASE&agegroup (obs=50000);
var bene_id age month month2 monthBC bc actualbc scrmammo dxmammo lobs;
run;*/

data x&agein1; set anndata.box8_baseline&agein1 (keep= bene_id ehic  ); run;
data x&agein2; set anndata.box8_baseline&agein2 (keep= bene_id ehic  ); run;
data x&agein3; set anndata.box8_baseline&agein3 (keep= bene_id ehic  ); run;
data x&agein4; set anndata.box8_baseline&agein4 (keep= bene_id ehic  ); run;
data x&agein5; set anndata.box8_baseline&agein5 (keep= bene_id ehic  ); run;

/*proc print data=x&agein1 (obs=100);run;*/

data ids&agegroup; set x&agein1 x&agein2 x&agein3 x&agein4 x&agein5; run;

proc sort data=ids&agegroup nodupkey; by bene_id; run;


/***** BIOPSY *****/
/*proc contents data=mydata.biopsy2000; run;proc contents data=mydata.biopsy2001; run;
proc contents data=mydata.biopsy2002; run;proc contents data=mydata.biopsy2003; run;
proc contents data=mydata.biopsy2004; run;proc contents data=mydata.biopsy2005; run;
proc contents data=mydata.biopsy2006; run;proc contents data=mydata.biopsy2007; run;
proc contents data=mydata.biopsy2008; run;*/

data biopsy2000; set mydata.biopsy2000 (keep=ehic date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy1-cm_biopsy5;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=biopsy2000 (obs=10);run;*/

data biopsy2001; set mydata.biopsy2001 (keep=ehic date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy6-cm_biopsy15;
do i=1 to 10;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=biopsy2001 (obs=10);run;*/

data biopsy2002; set mydata.biopsy2002 (keep=ehic date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy16-cm_biopsy21;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=biopsy2002 (obs=10);run;*/

data biopsy2003; set mydata.biopsy2003 (keep=ehic date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy22-cm_biopsy25;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=biopsy2003 (obs=10);run;*/

data biopsy2004; set mydata.biopsy2004 (keep=ehic date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy26-cm_biopsy29;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=biopsy2004 (obs=10);run;*/

data biopsy2005; set mydata.biopsy2005 (keep=ehic date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy30-cm_biopsy33;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=biopsy2005 (obs=10);run;*/

data biopsy2006; set mydata.biopsy2006 (keep=bene_id date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy34-cm_biopsy38;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=biopsy2006 (obs=10);run;*/

data biopsy2007; set mydata.biopsy2007 (keep=bene_id date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy39-cm_biopsy43;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=biopsy2007 (obs=10);run;*/

data biopsy2008; set mydata.biopsy2008 (keep=bene_id date_biopsy:);
array DATE{*} date_biopsy: ; 
array CM{*} cm_biopsy44-cm_biopsy50;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=biopsy2008 (obs=10);run;*/


/***** LUMPECTOMY *****/
/*proc contents data=mydata.lumpect2000; run;proc contents data=mydata.lumpect2001; run;
proc contents data=mydata.lumpect2002; run;proc contents data=mydata.lumpect2003; run;
proc contents data=mydata.lumpect2004; run;proc contents data=mydata.lumpect2005; run;
proc contents data=mydata.lumpect2006; run;proc contents data=mydata.lumpect2007; run;
proc contents data=mydata.lumpect2008; run;*/

data lumpect2000; set mydata.lumpect2000 (keep=ehic date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect1-cm_lumpect6;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=lumpect2000 (obs=10);run;*/

data lumpect2001; set mydata.lumpect2001 (keep=ehic date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect7-cm_lumpect11;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=lumpect2001 (obs=10);run;*/

data lumpect2002; set mydata.lumpect2002 (keep=ehic date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect12-cm_lumpect15;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=lumpect2002 (obs=10);run;*/

data lumpect2003; set mydata.lumpect2003 (keep=ehic date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect16-cm_lumpect19;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=lumpect2003 (obs=10);run;*/

data lumpect2004; set mydata.lumpect2004 (keep=ehic date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect20-cm_lumpect28;
do i=1 to 9;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=lumpect2004 (obs=10);run;*/

data lumpect2005; set mydata.lumpect2005 (keep=ehic date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect29-cm_lumpect32;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=lumpect2005 (obs=10);run;*/

data lumpect2006; set mydata.lumpect2006 (keep=bene_id date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect33-cm_lumpect37;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=lumpect2006 (obs=10);run;*/

data lumpect2007; set mydata.lumpect2007 (keep=bene_id date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect38-cm_lumpect43;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=lumpect2007 (obs=10);run;*/

data lumpect2008; set mydata.lumpect2008 (keep=bene_id date_lumpect:);
array DATE{*} date_lumpect: ; 
array CM{*} cm_lumpect44-cm_lumpect48;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=lumpect2008 (obs=10);run;*/


/* differents ids, thus merging in two steps */

proc sort data=lumpect2000; by ehic; run;
proc sort data=lumpect2001; by ehic; run;
proc sort data=lumpect2002; by ehic; run;
proc sort data=lumpect2003; by ehic; run;
proc sort data=lumpect2004; by ehic; run;
proc sort data=lumpect2005; by ehic; run;

proc sort data=biopsy2000; by ehic; run;
proc sort data=biopsy2001; by ehic; run;
proc sort data=biopsy2002; by ehic; run;
proc sort data=biopsy2003; by ehic; run;
proc sort data=biopsy2004; by ehic; run;
proc sort data=biopsy2005; by ehic; run;

proc sort data=ids&agegroup; by ehic; run;

data k;
merge ids&agegroup (in=a) 
lumpect2000 lumpect2001 lumpect2002 lumpect2003 lumpect2004 lumpect2005 
biopsy2000 biopsy2001 biopsy2002 biopsy2003 biopsy2004 biopsy2005;
by ehic;
if a; 
run;

proc sort data=lumpect2006; by bene_id; run;
proc sort data=lumpect2007; by bene_id; run;
proc sort data=lumpect2008; by bene_id; run;

proc sort data=biopsy2006; by bene_id; run;
proc sort data=biopsy2007; by bene_id; run;
proc sort data=biopsy2008; by bene_id; run;

proc sort data=k ; by bene_id ; run;

data k;
merge k (in=a) lumpect2006 lumpect2007 lumpect2008 
biopsy2006 biopsy2007 biopsy2008 ;
by bene_id; if a; run;

proc sort data=CONTINUE&agegroup; by bene_id age month; run;

data CONTsurg&agegroup;
merge CONTINUE&agegroup (in=a) k;
by bene_id; 
if a; 
run;

proc sort data=STOPBASE&agegroup; by bene_id age month; run;


data STOPsurg&agegroup;
merge STOPBASE&agegroup (in=a) k;
by bene_id; 
if a; 
run;

proc sort data=STOPsurg&agegroup; by bene_id age; run;

data STOPsurg&agegroup;
merge STOPsurg&agegroup (in=a) stopbaselastobs;
by bene_id age; 
if a; 
run;

data STOPsurg&agegroup ; 
set  STOPsurg&agegroup  ;
if month2=0 then firstobs=month; 
if scrmammo=1 then monthmammo=month;
if dxmammo=1 then monthmammo=month;
array LUM {*} cm_lumpect:;
array RMAS {*} cm_biopsy:;
 lumpect=0;
do i=1 to dim(LUM);
	if month=LUM[i] then lumpect=1;
	if month=LUM[i] then monthhist=LUM[i];
end;
 biopsy=0;
do i=1 to dim(RMAS);
	if month=RMAS[i] then biopsy=1;
	if month=RMAS[i] then monthhist=RMAS[i];
end;

lagmonthhist=lag(monthhist);
difflags=monthhist-lagmonthhist;
if 0<=difflags<=6 then flag2=1;
if month2=0 then flag2=.;
if flag2 ne 1; 
positivehist=0;
if .<month<=monthBC<=(monthhist+6) then positivehist=1;
if monthhist ne . ; 
dxbeyondfirstround=0;
if month2>=10 then dxbeyondfirstround=1;
drop cm_: ehic i; 
run;

proc freq data=STOPsurg&agegroup;
table positivehist / missing; 
where dxbeyondfirstround=0;
title 'histological evaluations in the first round, STOPBASE- denominator is the total number of histological evaluations';run;

proc freq data=STOPsurg&agegroup;
table positivehist / missing; 
where dxbeyondfirstround=1;
title 'histological evaluations beyond the first round, STOPBASE- denominator is the total number of histological evaluations';run;


proc sort data=CONTsurg&agegroup; by bene_id age; run;

data CONTsurg&agegroup;
merge CONTsurg&agegroup (in=a) continuelastobs;
by bene_id age; 
if a; 
run;

data CONTsurg&agegroup ; 
set  CONTsurg&agegroup  ;
if month2=0 then firstobs=month; 
if scrmammo=1 then monthmammo=month;
if dxmammo=1 then monthmammo=month;
array LUM {*} cm_lumpect:;
array RMAS {*} cm_biopsy:;
 lumpect=0;
do i=1 to dim(LUM);
	if month=LUM[i] then lumpect=1;
	if month=LUM[i] then monthhist=LUM[i];
end;
 biopsy=0;
do i=1 to dim(RMAS);
	if month=RMAS[i] then biopsy=1;
	if month=RMAS[i] then monthhist=RMAS[i];
end;

lagmonthhist=lag(monthhist);
difflags=monthhist-lagmonthhist;
if 0<=difflags<=6 then flag2=1;
if month2=0 then flag2=.;
if flag2 ne 1; 
positivehist=0;
if .<month<=monthBC<=(monthhist+6) then positivehist=1;
if monthhist ne . ; 

dxbeyondfirstround=0;
if month2>=10 then dxbeyondfirstround=1;
drop cm_: ehic i; 
run;


proc freq data=CONTsurg&agegroup;
table positivehist / missing; 
where dxbeyondfirstround=0;
title 'histological evaluations in the first round, CONTINUE- denominator is the total number of histological evaluations';run;

proc freq data=CONTsurg&agegroup;
table positivehist / missing; 
where dxbeyondfirstround=1;
title 'histological evaluations beyond the first round, CONTINUE- denominator is the total number of histological evaluations';run;

%mend; 


%cann30_fp(agein1=70, agein2=71, agein3=72, agein4=73, agein5=74, agegroup=7074);
