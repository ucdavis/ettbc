/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* identification of long term stay for baseline adjusting   **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';

libname snf2002 '/disk/aging/medicare/data/20pct/snf/2002/';libname snf2003 '/disk/aging/medicare/data/20pct/snf/2003/';
libname snf2004 '/disk/aging/medicare/data/20pct/snf/2004/';libname snf2005 '/disk/aging/medicare/data/20pct/snf/2005/';
libname snf2006 '/disk/aging/medicare/data/20pct/snf/2006/';libname snf2007 '/disk/aging/medicare/data/20pct/snf/2007/';
libname snf2008 '/disk/aging/medicare/data/20pct/snf/2008/';



%macro cann06_2(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann06_2_logsANDlsts/cann06_2_LSR&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann06_2_logsANDlsts/cann06_2_LSR&agein..log" new;run;


data s2002;set snf2002.snfc2002 (keep=ehic sfromdt rename=(sfromdt=date_snf)); run;
data s2003;set snf2003.snfc2003 (keep=ehic sfromdt rename=(sfromdt=date_snf)); run;
data s2004;set snf2004.snfc2004 (keep=ehic sfromdt rename=(sfromdt=date_snf)); run;
data s2005;set snf2005.snfc2005 (keep=ehic sfromdt rename=(sfromdt=date_snf)); run;
data s2006;set snf2006.snfc2006 (keep=bene_id from_dt rename=(from_dt=date_snf)); run;
data s2007;set snf2007.snfc2007 (keep=bene_id from_dt rename=(from_dt=date_snf)); run;
data s2008;set snf2008.snfc2008 (keep=bene_id from_dt rename=(from_dt=date_snf)); run;

proc print data=s2002 (obs=10);run;
proc print data=s2003 (obs=10);run;
proc print data=s2004 (obs=10);run;
proc print data=s2005 (obs=10);run;
proc print data=s2006 (obs=10);run;
proc print data=s2007 (obs=10);run;
proc print data=s2008 (obs=10);run;

proc print data=mydata.nfu1999 (obs=10);run;proc print data=mydata.nfu2000 (obs=10);run;proc print data=mydata.nfu2001 (obs=10);run;
proc print data=mydata.nfu2002 (obs=10);run;proc print data=mydata.nfu2003 (obs=10);run;proc print data=mydata.nfu2004 (obs=10);run;
proc print data=mydata.nfu2005 (obs=10);run;proc print data=mydata.nfu2006 (obs=10);run;proc print data=mydata.nfu2007 (obs=10);run;
proc print data=mydata.nfu2008 (obs=10);run;



data ids&agein;
set /*mydata.box5_age&agein*/ anndata.box8_age&agein (keep=ehic bene_id) ;
run;

proc print data=ids&agein (obs=20);run;

proc sort data=ids&agein; by ehic; run;

data s0205;set s2002-s2005;run;
proc sort data=s0205; by ehic; run;

data s0608; set s2006-s2008;run;
proc sort data=s0608; by bene_id; run;

data bat; 
merge ids&agein (in=a) s0205;
by ehic; 
if a; 
if date_snf ne .; 
run;

proc sort data=ids&agein; by bene_id; run;

data bi; 
merge ids&agein (in=a) s0608;
by bene_id; 
if a; 
if date_snf ne .;
run;


data hiru;
set bat bi; 
cont_month_snf=(((year(date_snf))-1999)*12)+month(date_snf);
run;


proc sort data=hiru nodupkey; 
by bene_id cont_month_snf; run;

proc sort data=hiru; by bene_id; run;

proc print data=hiru (obs=20); run;

proc transpose data=hiru out=lau (drop=_name_) prefix=cont_month_snf;
var cont_month_snf;
by bene_id;


data snf&agein; 
set lau;
array MONTHS{*} month_snf1 - month_snf120; /* yes, I know the first 36 will be empty */
array CONTMONTHS{*} cont_month_snf1-cont_month_snf120 ;
do i=1 to 120;
	do j=1 to 120;
	if CONTMONTHS[j]=i then MONTHS[i]=1;
	end;
end;
drop cont_month: i j ; 
run;

proc print data=snf&agein (obs=20); run;


/* up to here, SNF */

/* Now, NFU, from the files created in c06_1_NFU.sas */

proc sort data=mydata.nfu1999; by ehic; run; proc sort data=mydata.nfu2000; by ehic; run; proc sort data=mydata.nfu2001; by ehic; run;
proc sort data=mydata.nfu2002; by ehic; run;proc sort data=mydata.nfu2003; by ehic; run;proc sort data=mydata.nfu2004; by ehic; run;
proc sort data=mydata.nfu2005; by ehic; run;

proc sort data=ids&agein; by ehic; run;

data nfu&agein;
merge ids&agein (in=a) mydata.nfu1999 mydata.nfu2000 mydata.nfu2001 mydata.nfu2002 mydata.nfu2003 mydata.nfu2004 mydata.nfu2005;
by ehic;
if a; 
run;

proc sort data=nfu&agein; by bene_id; run;
proc sort data=mydata.nfu2006; by bene_id; run;proc sort data=mydata.nfu2007; by bene_id; run;proc sort data=mydata.nfu2008; by bene_id; run;

data nfu&agein;
merge nfu&agein (in=a) mydata.nfu2006 mydata.nfu2007 mydata.nfu2008;
by bene_id;
if a; 
run;

proc sort data=snf&agein; by bene_id; run;

data ltc&agein;
merge nfu&agein (in=a) snf&agein;
by bene_id; 
if a; 
run;

data ltc&agein;
set ltc&agein;
array NFU{*} nfumonth1-nfumonth120;
array SNF{*} month_snf1-month_snf120;
array LTC{*} month_ltc1-month_ltc120;
do i=1 to 120;
	if NFU[i]=1 and SNF[i]=. then LTC[i]=1;
end;
do i=2 to 120;
	if LTC[i-1]=1 then LTC[i]=1;
end;
do i=1 to 120;
	if LTC[i]=1 then do;
            firstmonthLTC=i;
            leave;
       end;
end;   /* I know there is redundant code, but helps me visualizing things */
run;


proc print data=ltc&agein (obs=20);run;


data anndata.ltc&agein;
length firstmonthLTC 4 ;
set ltc&agein;
keep bene_id ehic firstmonthLTC ;
if firstmonthLTC ne . ;
run;

proc print data=anndata.ltc&agein (obs=20);run;

proc datasets lib=work kill memtype=data;run;


%mend; /* c06_2 */


/*%cann06_2(agein=84 );*/


