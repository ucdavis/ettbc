/********************************************************************/
/* This macro extracts all the mammograms done in years 2006-2012 */
/* Some fields are flexible because the change from year to year,   */ 
/* e.g. how the icd9 codes fields are called. 			    */
/* this macro is called from:
/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/b02_scrmammo.sas */


%macro scrmammo0612(test= ,hcpcs=, margin=, one=1, datehcpcs= ,id= , year= ,fileopc= ,fileipc=, fileopr= ,filecarl= ,fromdt= , thrudt= ,hcpcsfield= ,claimid= );

options mprint notes varlenchk=nowarn;

libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';

/* Outpatient file */

data test_op;
length &fromdt 4;
set &fileopr (keep= &id &hcpcsfield &datehcpcs &thrudt &claimid /*obs=5000000*/);
&test=0;
if &hcpcsfield in &hcpcs then do;
	&test=1;
	date_&test=&datehcpcs;
	end;
file_&test='out'; 
&fromdt=&datehcpcs;
format &fromdt DATE9. ;
keep &id &test date_&test file_&test &fromdt &thrudt &claimid; 
if &test=1;run;


proc sort data=test_op nodupkey; by &id &claimid ;
proc sort data=test_op nodupkey; by &id date_&test ;





/* Carrier file */

data test_car_pre;
set &filecarl (keep= &id &hcpcsfield &datehcpcs &thrudt &claimid expnsdt1 expnsdt2 /*obs=5000000*/ ) ;

&test=0;
if &hcpcsfield  in &hcpcs then do;
	&test=1;
	date_&test=&datehcpcs;
	end;

myclaimid=_N_; /* my own claim id for later manipulations */
file_&test='car'; 
format date_&test DATE9. ;
keep &id &test date_&test file_&test  myclaimid ; 
if &test=1;
run;

proc sort data=test_car_pre nodupkey;by bene_id date_&test;run;




/* elimination of those car tests that happen during an outpatient or inpatient claim */

data op_step;
set test_op (keep = &id &fromdt &thrudt);run;

proc sql;
create table op_car as
select *
from op_step full join test_car_pre (rename=(&id=bene_id2))
on op_step.&id=test_car_pre.bene_id2;
quit;

data op_car;set op_car;
if &id='' then &id=bene_id2;
drop bene_id2;
if .<&fromdt AND &fromdt <= date_&test <= (&thrudt+&margin) then flag=1;
if flag=1;
format date_&test DATE9. ;
keep myclaimid flag;run;



/* because these are carrier claims that overlap with the dates of outpatient and inpatient */


proc sort data=test_car_pre; by myclaimid; run;
proc sort data=op_car;by myclaimid; run;
data test_car;
merge test_car_pre (in=a) op_car;
if a;
by  myclaimid;
if flag=1 then delete;
run;


data b;
set test_op (keep=&id &test date_&test file_&test) test_car (keep=&id &test date_&test file_&test);
format date_&test mmddyy10.;
run;

proc sort data=b nodupkey;
by bene_id date_&test ;
run;



/***** transposing of the data *****/

proc sort data=b; by &id date_&test; run;

proc transpose data=b out=transtest (drop=_name_) prefix=&test;
var &test;
by &id;

proc transpose data=b out=transdate (drop=_name_) prefix=date_&test;
var date_&test;
by &id;

proc transpose data=b out=transfile (drop=_name_) prefix=file_&test;
var file_&test;
by &id;


/***** merging the transposed  data *****/

data &test.&year;
merge transtest transdate transfile ;
by &id;
run;


proc freq data=b noprint;
table &id / out=testcount;
run;
proc means data=testcount max;
var count;
output out=mcount (keep=mcount) max=mcount;
run;
data mcount;
set mcount;
call symput('mcount',compress(mcount));
run;

data &test.&year;
set &test.&year;
&test._count=sum(of &test&one-&test&mcount);
run;

proc means data=&test.&year n nmiss sum;
var &test._count;
title "N=number of individuals with &test done, Sum=total mumber of &test done";
run;

proc means data=&test.&year n nmiss;
var &test&one-&test&mcount;
run;



data mydata.&test.&year;
length &test&one-&test&mcount date_&test.1-date_&test&mcount &test._count 3 ;
set &test.&year;
run;

proc contents data=mydata.&test.&year;run;


proc datasets lib=work kill memtype=data;
quit;

%mend;






