/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* exclusion of women with a previous diagnosis of breast cancer and mammogram for any cause    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';


%macro c05(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c05_logsANDlsts/c05_fourthbox&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c05_logsANDlsts/c05_fourthbox&agein..log" new;run;

proc sort data=mydata.box1_2age&agein; by bene_id; run;
proc sort data=myCCW.first&agein.breast; by bene_id; run;
data x&agein;
merge mydata.box1_2age&agein (in=a) myCCW.first&agein.breast;
by bene_id;
if a;
previousBC=0;
if .< dfo_breast< startfup  then previousBC=1; /* substracting 7 days to startfup does not change anything */
run;

proc freq data=x&agein;
table previousBC / missing; title 'number for the fourth box'; run;


/*proc freq data=x&agein;
table previousBC / missing; title 'number for the fourth box'; run;*/

data elig_box4age&agein;
set x&agein;
/*if previousBC=0;*/
yearstartfup=year(startfup);
keep bene_id ehic startfup date_&agein yearstartfup previousBC;
run;

proc freq data=elig_box4age&agein;
table yearstartfup / missing;
run;



/*proc print data=elig_box4age&agein (obs=100);run;*/

/* Exclusion of women that received a mammography (any type) in the nine months before inclusion */


/* need to rename the date_scrmammo variables to be able to merge files -- 8 is the max number of mammos per year -- */

%do yr=1999 %to 2007;
data anymammo&yr; set mydata.anymammo&yr;
array D1{*} date_anymammo:;
array D2{*} datey&yr._anymammo1-datey&yr._anymammo9;
do i=1 to dim(D1);
	D2[i]=D1[i];
end;
format datey&yr._anymammo: mmddyy10. ;
drop anymammo: date_anymammo: file_: i ;
run;
/*proc print data=anymammo&yr (obs=20); run;*/
%end;

/* women included in 2000 to 2004 */

%do year=2000 %to 2005;

data box5_age&agein.&year; set elig_box4age&agein; if yearstartfup=&year; run;
proc sort data=box5_age&agein.&year; by ehic; run;

%let yearmone=%eval(&year-1);

data a&agein.&year.mammo;
merge box5_age&agein.&year (in=a) anymammo&year anymammo&yearmone;
by ehic; if a;run;

/*proc print data=a&agein.&year.mammo (obs=1000);run;*/

data a&agein.&year.mammo; set a&agein.&year.mammo;
array DATEM{*} datey: ;
array FLAG{*} flag1-flag18;
do i=1 to dim(DATEM);
	if (startfup-270)<=DATEM[i]<(startfup) then FLAG[i]=1;
end;
sumflag=sum(of flag:); 
*if sumflag = . ; /* selection of women without mammograms in the 270 days before entering */
run;

/*proc print data=a&agein.&year.mammo (obs=1000); where sumflag ne . ; run;*/
%end;

/* women included in 2006 */

data box5_age&agein.2006; set elig_box4age&agein; if yearstartfup=2006; run;
proc sort data=box5_age&agein.2006; by ehic; run;

data a&agein.2006mammo;
merge box5_age&agein.2006 (in=a) anymammo2005;
by ehic; if a;run;

proc sort data=a&agein.2006mammo; by bene_id; run;

data a&agein.2006mammo;
merge a&agein.2006mammo (in=a) anymammo2006;
by bene_id; if a;run;


data  a&agein.2006mammo; set  a&agein.2006mammo;
array DATEM{*} datey: ;
array FLAG{*} flag1-flag18;
do i=1 to dim(DATEM);
	if (startfup-270)<=DATEM[i]<(startfup) then FLAG[i]=1;
end;
sumflag=sum(of flag:); 
*if sumflag = . ; /* selection of women without mammograms in the 270 days before entering */
run;


/* women included in 2007 */

data box5_age&agein.2007; set elig_box4age&agein; if yearstartfup=2007; run;
proc sort data=box5_age&agein.2007; by bene_id; run;

proc sort data=anymammo2007; by bene_id; run;

data a&agein.2007mammo;
merge box5_age&agein.2007 (in=a) anymammo2006 anymammo2007;
by bene_id; if a;run;


data  a&agein.2007mammo; set  a&agein.2007mammo;
array DATEM{*} datey: ;
array FLAG{*} flag1-flag18;
do i=1 to dim(DATEM);
	if (startfup-270)<=DATEM[i]<(startfup) then FLAG[i]=1;
end;
sumflag=sum(of flag:); 
*if sumflag = . ; /* selection of women without mammograms in the 270 days before entering */
run;

/************/
/* symptoms */
/************/

data breastsympt; set mydata.breastsympt; if bene_id ne ''; run;

proc transpose data=breastsympt out=breastsympt_wide (drop=_name_) prefix=date_breastsympt;
var date_breastsympt; by bene_id;

proc sort data=breastsympt_wide; by bene_id; run;

data box5_age&agein; set a&agein: ;
premammo270=(sumflag>.); run;

proc sort data=box5_age&agein; by bene_id; run;

data box5_age&agein;
merge box5_age&agein (in=a) breastsympt_wide;
by bene_id; 
if a; 
bsym6mprebase=0;
array CMS{*} date_breastsympt: ;
do i=1 to DIM(CMS);
	if (startfup-270)<=CMS[i]< (startfup-15) then bsym6mprebase=1;
	end; 
drop i date_breastsympt: ; 
run;



proc freq data=box5_age&agein;
table  previousBC premammo270 bsym6mprebase / missing; title 'number for the third, fourth and fifth boxes'; run;

data test; 
set box5_age&agein;
if premammo270=0;
if previousBC=0;
if bsym6mprebase=0;
run;

/*proc print data=box5_age&agein (obs=1000);run;*/

data mydata.box5_age&agein;
set box5_age&agein;
if premammo270=0;
if previousBC=0;
if bsym6mprebase=0;
keep bene_id ehic date_&agein startfup ;
run;

proc means data=mydata.box5_age&agein n ;
var startfup;
title "number for sixth box, women just screened for breast cancer, age=&agein";

%mend; /* c05 */

/*%c05(agein=70);*/



