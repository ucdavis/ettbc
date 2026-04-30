/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* application of enrolment eligibility criteria		    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/CRC_screening/macros/number_of_observations.sas';

libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";


%macro elig_over_years(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c01_logsANDlsts/c01_eligibility&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c01_logsANDlsts/c01_eligibility&agein..log" new;run;


%macro eligibility(year= ,agein= );

libname bsf&year "/disk/aging/medicare/data/20pct/bsf/&year./1";

proc contents data=bsf&year..bsfab&year;
run;



/***************************************************************************************************************/
/************************************** first box of the flowchart *********************************************/
/***************************************************************************************************************/

/********************/
/* selection by age */
/********************/

data a&year;
set bsf&year..bsfab&year ( /*obs=100000*/ keep=age bene_id /*ehic*/ bene_dob death_dt sex orec);
date_&agein = INTNX( 'YEAR', bene_dob, /*70*/ &agein, 'SAME' );
year_&agein=year(date_&agein);
month_&agein=month(date_&agein);
format date_&agein mmddyy10. ;
if year_&agein=&year;
cont_month_&agein=((year_&agein-1999)*12)+month_&agein;
if .< death_dt < date_&agein then delete ; /* you have to be alive in order to turn &agein */
if sex=2; /*selecting only women */
drop sex;
run;

/*proc contents data=a&year; run;
proc print data=a&year (obs=10);
proc freq data=a&year;
table cont_month_&agein sex orec / missing;run;
%return;*/

data ids_&year;
length cont_month_&agein date_&agein 4 ;
set a&year (keep=bene_id /*ehic*/ cont_month_&agein date_&agein orec);run;


/* adding ehic to the years 2004, 2005 and 2006 to allow its linking with claim files 2003 to 2005 */
proc sort data=ids_&year;by bene_id;run;


%if &year=2006 %then %do;
data ids_2006;merge ids_2006 (in=a) bsf2005.bsfab2005 /* yes, 2005 */ (keep=bene_id ehic);by bene_id;if a;run;
%end;

%if %eval(&year-2000) >=0 AND %eval(2005-&year)>=0 %then %do;
data ids_&year;merge ids_&year (in=a) bsf&year..bsfab&year (keep=bene_id ehic);by bene_id;if a;run;
%end;



%mend; /* macro eligibility */

%do n=2000 %to  /*2006*/ 2006;
%eligibility(year=&n, agein=&agein);
%end;

/***********************************/
/* linkage to screening mammograms */
/***********************************/
data a; 
set ids: ; 
year=year(date_&agein);
run;

proc freq data=a;
table year / missing; 
run;

proc sort data=a;
by bene_id;run;

proc print data=a (obs=10);run;

/* need to rename the date_scrmammo variables to be able to merge files -- 8 is the max number of mammos per year -- */

%do yr=2000 %to 2008;
data scrmammo&yr; set mydata.scrmammo&yr;
array D1{*} date_scrmammo:;
array D2{*} datey&yr._scrmammo1-datey&yr._scrmammo8;
do i=1 to dim(D1);
	D2[i]=D1[i];
end;
format datey&yr._scrmammo: mmddyy10. ;
drop scrmammo: date_scrmammo: file_: i ;
run;

proc print data=scrmammo&yr (obs=20); run;

%end;

/* women included in 2000 to 2004 */

%do year=2000 %to 2004;

data a&year; set a; if year=&year; run;
proc sort data=a&year; by ehic; run;

%let yearpone=%eval(&year+1);

data a&year.mammo;
merge a&year (in=a) scrmammo&year scrmammo&yearpone;
by ehic; if a;run;
/*proc print data=a&year.mammo (obs=100);run;*/

data a&year.mammo; set a&year.mammo;
array DATEM{*} datey: ;
array FLAG{*} flag1-flag16;
array stfup{*} stfup1-stfup16;
do i=1 to dim(DATEM);
	if date_&agein<=DATEM[i]<=(date_&agein+365) then do;
		FLAG[i]=1;
		stfup[i]=DATEM[i];
	end;
end;
sumflag=sum(of flag:); 
if sumflag ne . ; /* selection of women with at least one mammo in while age=&agein */
startfup=min(of stfup1-stfup16);
format stfup: startfup mmddyy10. ;
run;

proc sort data=a&year.mammo nodupkey; by ehic; run;
/*proc print data=a&year.mammo (obs=100); run;
proc freq data=a&year.mammo; table flag: sumflag/missing;title "year &year";run;*/
%end;


/* women included in 2005 */
data a2005; set a; if year=2005; run;
proc sort data=a2005; by ehic; run;

data a2005mammo;
merge a2005 (in=a) scrmammo2005 ;
by ehic; if a;run;

proc sort data=a2005mammo; by bene_id;run;
data a2005mammo;
merge a2005mammo (in=a) scrmammo2006;
by bene_id; if a;run;


data a2005mammo; set a2005mammo;
array DATEM{*} datey: ;
array FLAG{*} flag1-flag16;
array stfup{*} stfup1-stfup16;
do i=1 to dim(DATEM);
	if date_&agein<=DATEM[i]<=(date_&agein+365) then do;
		FLAG[i]=1;
		stfup[i]=DATEM[i];
	end;
end;
sumflag=sum(of flag:); 
if sumflag ne . ; /* selection of women with at least one mammo in while age=&agein */
startfup=min(of stfup1-stfup16);
format stfup: startfup mmddyy10. ;
run;

proc sort data=a2005mammo nodupkey; by ehic; run;
/*proc print data=a2005mammo (obs=100); run;
proc freq data=a2005mammo; table flag: sumflag/missing;title 'year 2005';run;*/


/* women included in 2006 */
data a2006; set a; if year=2006; run;
proc sort data=a2006; by bene_id; run;

data a2006mammo;
merge a2006 (in=a) scrmammo2006 scrmammo2007 ;
by bene_id; if a;run;


data a2006mammo; set a2006mammo;
array DATEM{*} datey: ;
array FLAG{*} flag1-flag16;
array stfup{*} stfup1-stfup16;
do i=1 to dim(DATEM);
	if date_&agein<=DATEM[i]<=(date_&agein+365) then do;
		FLAG[i]=1;
		stfup[i]=DATEM[i];
	end;
end;
sumflag=sum(of flag:); 
if sumflag ne . ; /* selection of women with at least one mammo in while age=&agein */
startfup=min(of stfup1-stfup16);
format stfup: startfup mmddyy10. ;
run;

proc sort data=a2006mammo nodupkey; by ehic; run;

/*proc print data=a2000mammo (obs=20);run;
proc print data=a2001mammo (obs=20);run;
proc print data=a2002mammo (obs=20);run;
proc print data=a2003mammo (obs=20);run;
proc print data=a2004mammo (obs=20);run;
proc print data=a2005mammo (obs=20);run;
proc print data=a2006mammo (obs=20);run;*/


data b&agein;
length startfup 4 ;
set a2000mammo a2001mammo a2002mammo a2003mammo a2004mammo a2005mammo a2006mammo;
year_&agein.sfup=year(startfup);
month_&agein.sfup=month(startfup);
cont_month_&agein.sfup=((year_&agein.sfup-1999)*12)+month_&agein.sfup;
keep cont_month_&agein bene_id orec ehic startfup cont_month_&agein.sfup date_&agein ;
run;

proc print data=b&agein (obs=10);run;
proc sort data=b&agein; by bene_id; run;

/***************************************************************************************************************/
/************************************* second box of the flowchart *********************************************/
/***************************************************************************************************************/

/* selection by complete enrollment in the previous 5 years of becoming "&agein" */

%macro vamos(yr= ,one= , twelve= );
libname bsf&yr "/disk/aging/medicare/data/20pct/bsf/&yr./1" ;
data x&yr;
set bsf&yr..bsfab&yr (keep= bene_id /*ehic*/ buyin01-buyin12 hmoind01-hmoind12 death_dt /*obs=100000*/);
array buyin{*} buyin01-buyin12;
array hmoin{*} hmoind01-hmoind12;
array buy{*} $1 buy&one-buy&twelve;
array hmo{*} $1 hmo&one-hmo&twelve;
do i=1 to 12;
buy[i]=buyin[i];
hmo[i]=hmoin[i];
end;
death_dt&yr=death_dt;
drop buyin01-buyin12 hmoind01-hmoind12 i death_dt;
run;

proc sort data=x&yr; by bene_id; run;
/*proc sort data=ids_&year; by bene_id;run;*/

/*data ep&yr;merge ids_&year (in=a) x&yr;by bene_id;if a;
run;*/
/*proc contents data=ep&yr;run;*/
%mend; /* macro vamos */

/*%let from=%eval(&year-1); * I need 12 months of previous enrollment */

%do j=/*&from*/1999 %to 2007 /*&year*/;
%let one=%eval(((&j-1999)*12)+1);
%let twelve=%eval(((&j-1999)*12)+12);
%vamos(yr=&j,one=&one,twelve=&twelve);
proc print data=x&j (obs=10);run;

%end;

data c&agein;
merge b&agein (in=a) x1999-x2007;
by bene_id;
if a;
run;


/*proc print data=c&agein (obs=500);run;*/


data d&agein;
length startfup 4 ; 
set c&agein;
array buy{*} buy1-buy108;
array hmo{*} hmo1-hmo108;
array elig{*} elig1-elig108;
array keep{*} keep1-keep108;

%let yr=year(cont_month_&agein.sfup);

do k=1 to 108;
	if buy[k] in ('3','C') and hmo[k]='0' then elig[k]=1;
end;



/*do m=(cont_month_&agein.sfup -( 11 +(&yr-2000)*12)) to (cont_month_&agein.sfup-((&yr-2000)*12));*/
do m= (cont_month_&agein.sfup - 11) to (cont_month_&agein.sfup - 0 );
	if elig[m]=1 then keep[m]=1;
	if elig[m]=. then keep[m]=0;
	end;

sumkeep=sum(of keep:);


keep bene_id ehic date_&agein startfup sumkeep orec;
run;

/*proc freq data=d&agein;
table cont_month_&agein.sfup / missing; run;


proc print data=d&agein (obs=1000);run;
*/
proc freq data=d&agein;
table sumkeep orec /missing; run;


/* first box flowchart: number of patients aged 70 */
%obsnvars(dataset=b&agein);
%put FIRSTBOX has &nvars variable(s) and &nobs observation(s).;



data mydata.box1_2age&agein;
set d&agein ;
if sumkeep=12;
if orec=0;
drop sumkeep orec;
run;

/* second box flowchart: enrolled A+B, not in HMO since startfup - 11 */
%obsnvars(dataset=mydata.box1_2age&agein);
%put SECONDBOX has &nvars variable(s) and &nobs observation(s).;

proc contents data=mydata.box1_2age&agein;run;

%mend; /* macro elig_over_years */

%elig_over_years(agein=80);



