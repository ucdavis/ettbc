/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* Creation of the cohort, before cloning    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

/*libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";*/
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';


%macro cann07(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann07_logsANDlsts/cann07_cohort&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann07_logsANDlsts/cann07_cohort&agein..log" new;run;


/* THIS PART IS TO REMOVE IDS WITH INCONSISTENCIES BETWEEN bene_id AND ehic: happens in about 0.02% of the individuals */

%macro ids();
/*proc print data= anndata.box8_age80;
where bene_id='mmmmmmmJDsGaJsJ';
run;

proc contents data= anndata.box8_age80;run;
*/

%do i=70 %to 84;
data a&i; set anndata.box8_age&i (keep=bene_id ehic );agein=&i;run;
%end;

data b; 
set a: ; 
run;

proc sort data=b; by bene_id agein; run;
proc print data=b (obs=500);
where bene_id in ('mmmmmmmDUGWDmJU','mmmmmmmDUmWUWXf','mmmmmmmDXWaDJUa');
run;

data c; 
set b; 
by bene_id;
lagehic=lag(ehic);
removeme=0;
if first.bene_id=0 and ehic ne lagehic then removeme=1;
run;

proc freq data=c; table removeme / missing; run;

data idstoremove; set c; keep bene_id removeme; if removeme=1; run;

proc sort data=idstoremove nodupkey; by bene_id; run;

%mend;

%ids();




/* EXTRACTION OF BREAST CANCER AS A CAUSE OF DEATH */
/* First step is renaming the variables of the different files to do a merge with my cohort */

proc print data=anndata.box8_age&agein (obs=20);run;



%do yr=2000 %to 2008;

libname ndi&yr "/disk/aging/ndi/20pct/&yr";

data ndi&yr;
set ndi&yr..ndi&yr (keep=bene_id NDI_DEATH_DT RECORD_COND_1-RECORD_COND_8 ICD_CODE);
ICD_CODE_&yr=ICD_CODE; /* this is the underlying cause of death as extracted by the NDI algorithms */
NDI_DEATH_DT_&yr=NDI_DEATH_DT;
RECORD_COND_1_&yr=RECORD_COND_1; RECORD_COND_2_&yr=RECORD_COND_2;
RECORD_COND_3_&yr=RECORD_COND_3; RECORD_COND_4_&yr=RECORD_COND_4;
RECORD_COND_5_&yr=RECORD_COND_5; RECORD_COND_6_&yr=RECORD_COND_6;
RECORD_COND_7_&yr=RECORD_COND_7; RECORD_COND_8_&yr=RECORD_COND_8;
firstletter1_&yr=substr(RECORD_COND_1,1,1);
firstletter2_&yr=substr(RECORD_COND_2,1,1);
firstletter3_&yr=substr(RECORD_COND_3,1,1);
firstletter4_&yr=substr(RECORD_COND_4,1,1);
firstletter5_&yr=substr(RECORD_COND_5,1,1);
firstletter6_&yr=substr(RECORD_COND_6,1,1);
firstletter7_&yr=substr(RECORD_COND_7,1,1);
firstletter8_&yr=substr(RECORD_COND_8,1,1);
format NDI_DEATH_DT_&yr DATE9. ;
drop NDI_DEATH_DT RECORD_COND_1-RECORD_COND_8 ICD_CODE;
run;
/*proc print data=ndi&yr (obs=20); run;*/
proc sort data=ndi&yr; by bene_id; run;
%end;


/*proc freq data=ndi2005; 
table ICD_CODE_: / missing; 
run;
%return;*/


proc sort data=anndata.box8_age&agein; by bene_id; run;

data j&agein;
merge anndata.box8_age&agein (in=a) ndi2000-ndi2008;
by bene_id;
if a; 
run;

data k&agein;
set j&agein;
death_date=min(of NDI_DEATH_DT_2000-NDI_DEATH_DT_2008 );
/*dead=(death_date ne .);*/


array UCD{*} ICD_CODE_: ; 
array CDUCD{*} muertebcucd1-muertebcucd9;
do j=1 to 9; 
	if UCD[j] in ('C500','C501','C502','C503','C504','C505','C506','C508','C509') then CDUCD[j]=1;
end;
BCdeadUCD=(sum(of muertebcucd1-muertebcucd9)>0);

array RC{*} RECORD_COND: ;
array CD{*} muertebc1-muertebc72;
array FL{*} firstletter: ; 
array HD{*} muertehd1-muertehd72;
array CA{*} muerteca1-muerteca72;
do i=1 to 72;
	if RC[i] in ('C500','C501','C502','C503','C504','C505','C506','C508','C509') then CD[i]=1;
	if FL[i] = 'I' then HD[i]=1;
	if FL[i] = 'C' then CA[i]=1;
end;
BCdead=(sum(of muertebc1-muertebc72)>0);
CVdead=(sum(of muertehd1-muertehd72)>0);
OCdead=(sum(of muerteca1-muerteca72)>0);
if BCdead=1 then OCdead=0;
ORdead=0;
if death_date ne . then ORdead=1;
if BCdead=1 then ORdead=0;
if CVdead=1 then ORdead=0;
if OCdead=1 then ORdead=0;

year_&agein=year(startfup);
month_&agein=month(startfup);
cont_month_&agein=((year_&agein-1999)*12)+month_&agein;
format death_date DATE9.;
run;

/*proc print data=k&agein (obs=20);run;*/
proc freq data=k&agein;
table BCdead ICD_CODE_:/ missing;run;


/* extraction of the month when they stop fulfilling enrolment criteria */
%macro upto(agein= );

proc freq data=k&agein;
table cont_month_&agein / missing; run;

%macro vamos(year= ,one= , twelve= );
libname bsf&year "/disk/aging/medicare/data/20pct/bsf/&year./1";
data x&year;
set bsf&year..bsfab&year (keep= bene_id buyin01-buyin12 hmoind01-hmoind12 /*death_dt*/ );
array buyin{*} buyin01-buyin12;
array hmoin{*} hmoind01-hmoind12;
array buy{*} $1 buy&one-buy&twelve;
array hmo{*} $1 hmo&one-hmo&twelve;
do i=1 to 12;
buy[i]=buyin[i];
hmo[i]=hmoin[i];
end;
/*death_dt&year=death_dt;*/
drop buyin01-buyin12 hmoind01-hmoind12 i /*death_dt*/;
run;

proc sort data=x&year;by bene_id;run;
/*proc print data=x&year (obs=20);run;*/

%mend; /* vamos */

%vamos(year=2000,one=13,twelve=24);
%vamos(year=2001,one=25,twelve=36);
%vamos(year=2002,one=37,twelve=48);
%vamos(year=2003,one=49,twelve=60);
%vamos(year=2004,one=61,twelve=72);
%vamos(year=2005,one=73,twelve=84);
%vamos(year=2006,one=85,twelve=96);
%vamos(year=2007,one=97,twelve=108);
%vamos(year=2008,one=109,twelve=120);
/*%vamos(year=2009,one=121,twelve=132);
%vamos(year=2010,one=133,twelve=144);
%vamos(year=2011,one=145,twelve=156);
%vamos(year=2012,one=157,twelve=168);*/


data l&agein;
merge k&agein (in=a) x: ;
by bene_id;
if a;
run;

/*proc print data=l&agein (obs=1000);run;*/

data m&agein;
length death_date date_upto lastfup 4;
set l&agein;

array buy{*} buy13-buy120;
array hmo{*} hmo13-hmo120;
array elig{*} elig13-elig120;

do i=1 to 108;
	if buy[i] in ('3','C') and hmo[i]='0' then elig[i]=1;
end;

do k=(cont_month_&agein-/*60*/ 12) to 108;
	if elig[k]=. then do; 
	upto=k;
	leave;
	end;
end;

do m=0 to 8;
if (1+(12*m)) <= upto <= (12+(12*m)) then do;
	yearupto=/*2004*/ 2000+m;
	monthupto=upto - (12*m);
	end;
end;

date_upto=mdy(monthupto,1,yearupto);
/*date_death=min(of death_dt: );*/
adm_end=mdy(12,31,2008);
lastfup=min(date_upto, death_date, adm_end);

dead = (death_date=lastfup);

if dead=0 then BCdead=0;
if dead=0 then OCdead=0;
if dead=0 then CVdead=0;
if dead=0 then ORdead=0;

os=(lastfup-startfup)/30.4375;

format adm_end date_upto death_date lastfup DATE9. ;
drop buy: hmo: elig: i k m upto yearupto monthupto NDI_DEATH_DT_: RECORD_: muertebc: muertepancr: muertemelan: muertecolon: muerteova: muertecerv: muerteblad: muertelung: muertebra: muerteendo: year_&agein month_&agein adm_end date_upto;
if lastfup-date_&agein < 0 then delete ;  /* there are 13 patients (0.00%) like this */
run;

/*proc sort data= mydata.cohortnocovs&agein nodupkey;by bene_id;run;*/

proc print data=m&agein (obs=100);
*var /*date_death date_upto date_&agein*/ startfup /*lastfup*/ cont_month_&agein ;
*var bene_id cont_month_&agein elig: upto yearupto monthupto ;
run;

proc freq data=m&agein;
table /*dead*/ BCdead ORdead OCdead CVdead BCdeadUCD PANdeadUCD MELdeadUCD/ missing;run;


proc datasets lib=work; delete x: y ; run;

%mend; /* upto */

%upto(agein=&agein);


/* removing those ids with inconsistencies between bene_id and ehic -see first macro in this program- */

proc sort data=/*box8_baseline&agein*/ m&agein; by bene_id; 

data box8_baseline&agein; 
merge /*box8_baseline&agein*/ m&agein (in=a) idstoremove;
by bene_id;
if a; 
run;

data anndata.box8_baseline&agein; 
set box8_baseline&agein;
if removeme ne 1; 
drop removeme ICD_CODE_: firstletter: j muertehd: muerteca: ;
run;

proc freq data= anndata.box8_baseline&agein;
table /*dead*/ BCdead*BCdeadUCD / missing;run;

proc print data=anndata.box8_baseline&agein (obs=10); run;

proc datasets lib=work kill memtype=data;run;


%mend; /* cann07 */




/*
%cann07(agein=70);
%cann07(agein=71);
%cann07(agein=72);
%cann07(agein=73);
%cann07(agein=74);
%cann07(agein=75);
%cann07(agein=76);
%cann07(agein=77);
%cann07(agein=78);
%cann07(agein=79);
%cann07(agein=80);
%cann07(agein=81);
%cann07(agein=82);
%cann07(agein=83);
%cann07(agein=84);
*/