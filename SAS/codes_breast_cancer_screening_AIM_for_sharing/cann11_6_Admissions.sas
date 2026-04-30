/********************************************************************************(*******/
/* Code to extract number of days admitted in the previous 6 months			*/
/* Note that this code calls the linkages c09_* 					*/
/*******************************************************************************(********/

options mprint notes compress=yes;

libname ip1999 '/disk/aging/medicare/data/20pct/ip/1999';libname ip2000 '/disk/aging/medicare/data/20pct/ip/2000';
libname ip2001 '/disk/aging/medicare/data/20pct/ip/2001';libname ip2002 '/disk/aging/medicare/data/20pct/ip/2002';
libname ip2003 '/disk/aging/medicare/data/20pct/ip/2003';libname ip2004 '/disk/aging/medicare/data/20pct/ip/2004';
libname ip2005 '/disk/aging/medicare/data/20pct/ip/2005';libname ip2006 '/disk/aging/medicare/data/20pct/ip/2006';
libname ip2007 '/disk/aging/medicare/data/20pct/ip/2007';libname ip2008 '/disk/aging/medicare/data/20pct/ip/2008';


%macro ad1(year=);
data ad&year;
length date_in date_out 4;
set ip&year..ip&year (/*obs=1000000*/ keep=ehic admsn_dt dschrgdt rename=(admsn_dt=date_in dschrgdt=date_out));
keep ehic date_in date_out; 
run;
proc sort data=ad&year nodupkey; by ehic date_in; run;
%mend;

%ad1(year=2001); %ad1(year=2000); %ad1(year=1999); 


%macro ad2(year=);
data ad&year;
length date_in date_out 4;
set ip&year..ipc&year (/*obs=1000000*/ keep=ehic sadmsndt sdschrgdt rename=(sadmsndt=date_in sdschrgdt=date_out));
keep ehic date_in date_out; 
run;
proc sort data=ad&year nodupkey; by ehic date_in; run;
%mend;

%ad2(year=2002); %ad2(year=2003); %ad2(year=2004); %ad2(year=2005);


%macro ad3(year=);
data ad&year;
length date_in date_out 4;
set ip&year..ipc&year (/*obs=1000000*/ keep=bene_id admsn_dt dschrgdt rename=(admsn_dt=date_in dschrgdt=date_out));
keep bene_id date_in date_out; 
run;

proc sort data=ad&year nodupkey; by bene_id date_in; run;

%mend;

%ad3(year=2006);%ad3(year=2007); %ad3(year=2008);



%macro cann11_6(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_6_logsANDlsts/c11_6_Admissions&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_6_logsANDlsts/c11_6_Admissions&agein..log" new; run;

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

data ids; set anndata.box8_baseline&agein (keep = bene_id ehic); run;


data bunch1; set ad1999-ad2005; run;
proc sort data=bunch1; by ehic; run;
proc sort data=ids; by ehic; run;

data x1; merge ids (in=a) bunch1;  by ehic; if a; run;
data x1; set x1; if date_in ne . ; run;

/*proc print data=x1 (obs=100);run;*/


data bunch2; set ad2006-ad2008; run;
proc sort data=bunch2; by bene_id; run;
proc sort data=ids; by bene_id; run;

data x2; merge ids (in=a) bunch2; by bene_id; if a; run;

data x2; set x2; if date_in ne . ; run;

/*proc print data=x2 (obs=100);run;*/

data ad&agein; set x1 x2; run;



%do i=1 %to 108;

data admission&i;

set ad&agein ;

upbound=INTNX( 'MONTH', mdy(1,1,1999), &i+11, 'SAME' );
lowbound=INTNX( 'MONTH', mdy(1,1,1999), &i+5, 'SAME' );

if .<date_in<lowbound AND (lowbound<date_out<=upbound) then daysin=date_out-lowbound;
if (lowbound<date_in<=upbound) AND (lowbound<date_out<=upbound) then daysin=date_out-date_in;
if (lowbound<=date_in<upbound) AND .<upbound<date_out then daysin=upbound-date_in;

if daysin > . ; 

format upbound lowbound date_in date_out date9. ;
run;

proc sort data=admission&i; by bene_id; run;

proc transpose data=admission&i out=wide&i (drop=_name_) prefix=daysin;
var daysin;
by bene_id;

data wide&i; 
length daysin6m&i 3 ; 
set wide&i;
daysin6m&i=sum(of daysin: );
keep bene_id daysin6m&i;
run;

%end;


data anndata.daysadmitted&agein;
merge ids (in=a) wide: ;
by bene_id; 
if a; 
drop ehic;
if sum(of daysin6m:)> 0;
run;

proc print data=anndata.daysadmitted&agein (obs=100);
run;

proc datasets lib=work kill memtype=data;run;

%mend;

/*
%cann11_6(agein= 70);
%cann11_6(agein= 71);
%cann11_6(agein= 72);
%cann11_6(agein= 73);
%cann11_6(agein= 74);
%cann11_6(agein= 75);
%cann11_6(agein= 76);
%cann11_6(agein= 77);
%cann11_6(agein= 78);
%cann11_6(agein= 79);
%cann11_6(agein= 80);
%cann11_6(agein= 81);
%cann11_6(agein= 82);
%cann11_6(agein= 83);
*%cann11_6(agein= 84);
*/
