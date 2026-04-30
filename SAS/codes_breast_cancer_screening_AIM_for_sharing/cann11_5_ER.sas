/********************************************************************************(*******/
/* Code to extract visits to the ER in the previous 6 months				*/
/* 											*/
/*******************************************************************************(********/

options mprint notes compress=yes;




libname op1999 '/disk/aging/medicare/data/20pct/op/1999';libname op2000 '/disk/aging/medicare/data/20pct/op/2000';
libname op2001 '/disk/aging/medicare/data/20pct/op/2001';libname op2002 '/disk/aging/medicare/data/20pct/op/2002';
libname op2003 '/disk/aging/medicare/data/20pct/op/2003';libname op2004 '/disk/aging/medicare/data/20pct/op/2004';
libname op2005 '/disk/aging/medicare/data/20pct/op/2005';libname op2006 '/disk/aging/medicare/data/20pct/op/2006';
libname op2007 '/disk/aging/medicare/data/20pct/op/2007';libname op2008 '/disk/aging/medicare/data/20pct/op/2008';


%macro er3(year=);
data er&year;
length date_er 4 ; 
set op&year..opr&year (/*obs=100000*/ keep=bene_id rev_cntr thru_dt rename=(thru_dt=date_er) where=(rev_cntr in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981')));
keep bene_id date_er; 
run;
proc sort data=er&year nodupkey; by bene_id date_er; run;
%mend;

%er3(year=2006); %er3(year=2007); %er3(year=2008);


%macro er2(year=);
data er&year;
length date_er 4 ; 
set op&year..opr&year (/*obs=100000*/ keep=ehic rev_cntr srev_dt rename=(srev_dt=date_er) where=(rev_cntr in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981')));
keep ehic date_er; 
run;
proc sort data=er&year nodupkey; by ehic date_er; run;
%mend;

%er2(year=2001); %er2(year=2002); %er2(year=2003); %er2(year=2004); %er2(year=2005);


%macro er1(year=);
data er&year;
length date_er 4 ; 
set op&year..op&year (/*obs=100000*/ keep=ehic from_dt rvcntr1-rvcntr45 rename=(from_dt=date_er) where=(
rvcntr1 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr2 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr3 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr4 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr5 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr6 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr7 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr8 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr9 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr10 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr11 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr12 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr13 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr14 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr15 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr16 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr17 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr18 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr19 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr20 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr21 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr22 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr23 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr24 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr25 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr26 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr27 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr28 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr29 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr30 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr31 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr32 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr33 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr34 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr35 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr36 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr37 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr38 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr39 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr40 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr41 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr42 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr43 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr44 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981') OR
rvcntr45 in ('0450','0451','0452','0453','0454','0455','0456','0457','0548','0549','0981')
));
keep ehic date_er; 
run;
proc sort data=er&year nodupkey; by ehic date_er; run;
%mend; /* %er */

%er1(year=1999); %er1(year=2000);


%macro cann11_5(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_5_logsANDlsts/cann11_5_ER&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann11_5_logsANDlsts/cann11_5_ER&agein..log" new; run;

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

data ids; set anndata.box8_baseline&agein (keep = bene_id ehic); run;


data bunch1; set er1999-er2005; run;
proc sort data=bunch1; by ehic; run;
proc sort data=ids; by ehic; run;

data x1; merge ids (in=a) bunch1;  by ehic; if a; run;
data x1; set x1; if date_er ne . ; run;

/*proc print data=x1 (obs=100);run;*/

data bunch2; set er2006-er2008; run;
proc sort data=bunch2; by bene_id; run;
proc sort data=ids; by bene_id; run;

data x2; merge ids (in=a) bunch2; by bene_id; if a; run;

data x2; set x2; if date_er ne . ; run;

/*proc print data=x2 (obs=100);run;*/

data er&agein; set x1 x2; run;


%do i=1 %to 108;

data ervisit&i;

set er&agein ;

upbound=INTNX( 'MONTH', mdy(1,1,1999), &i+11, 'SAME' );
lowbound=INTNX( 'MONTH', mdy(1,1,1999), &i+5, 'SAME' );

if .<lowbound <= date_er < upbound;

ervisit=1;

format upbound lowbound date9. ;
run;

/*proc print data=ervisit&i; run;*/

proc sort data=ervisit&i; by bene_id; run;

proc transpose data=ervisit&i out=wide&i (drop=_name_) prefix=ervisit;
var ervisit;
by bene_id;

data wide&i; 
length ervisit6m&i 3 ; 
set wide&i;
ervisit6m&i=sum(of ervisit: );
keep bene_id ervisit6m&i;
run;


/*proc print data=wide&i; run;*/


%end;

data anndata.ervisits&agein;
merge ids (in=a) wide: ;
by bene_id; 
if a; 
drop ehic;
if sum(of ervisit6m:)> 0;
run;

proc print data=anndata.ervisits&agein (obs=100);
run;

proc datasets lib=work kill memtype=data;run;

%mend;

/*%c11_5(agein= 66);
%c11_5(agein= 67);
%c11_5(agein= 68);
%c11_5(agein= 69);
%c11_5(agein= 70);
%c11_5(agein= 71);
%c11_5(agein= 72);
%c11_5(agein= 73);
%c11_5(agein= 74);
%c11_5(agein= 75);
%c11_5(agein= 76);
%c11_5(agein= 77);
%c11_5(agein= 78);
%c11_5(agein= 79);
%c11_5(agein= 80);
%c11_5(agein= 81);
%c11_5(agein= 82);
%c11_5(agein= 83);
%cann11_5(agein= 84);*/

