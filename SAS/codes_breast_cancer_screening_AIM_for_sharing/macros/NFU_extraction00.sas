/********************************************************************/
/* This macro extracts the Nursing Facility Utilization in years 1999 and 2000 */
/* Some fields are flexible because the change from year to year,   */ 
/* e.g. how the icd9 codes fields are called. 			    */
/* this macro is called from:
/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c06_1NFU.sas
*/

%macro nfu00(test= ,hcpcs=, margin=, one=1, datehcpcs= ,id= , year= ,fileopc= , fileopr= , filecarl= , filecarh= , cpt_right_end= , fromdt= , thrudt= ,hcpcsfield= ,posfield= ,claimid= , claimid_car= ,pos= );

options mprint notes varlenchk=nowarn;

libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';

/* Outpatient file */


data test_opr_pre;
set &fileopr (keep= &id HCPSCD1-&CPT_RIGHT_END &claimid FROM_DT &thrudt /*obs=5000000*/);
&test=0;
array HCPCPS{*} HCPSCD1-&cpt_right_end;
do i=1 to DIM(HCPCPS);
if HCPCPS[i] in &hcpcs then do;
	&test=1;
	date_&test=FROM_DT;
	end;
end;
file_&test='out'; 
keep &id &test date_&test file_&test &claimid FROM_DT &thrudt; 
if &test=1;
run;


proc sort data=test_opr_pre nodupkey ;by &id &claimid;run;


/* Carrier file */

data test_car_pre;
set &filecarl (keep= &id &hcpcsfield /*&datehcpcs &thrudt*/ &claimid_CAR expnsdt1 expnsdt2 &posfield /*obs=5000000*/) ;

&test=0;
if &hcpcsfield  in &hcpcs then do;
	&test=1;
	date_&test= expnsdt1;
	end;
if &posfield  in &pos then do;
	&test=1;
	date_&test= expnsdt1;
	end;
file_&test='car'; 
format date_&test DATE9. ;
myclaimid=_N_; /* my own claim id for later manipulations */
keep &id &test date_&test file_&test myclaimid; 
if &test=1;
run;

proc sort data=test_car_pre nodupkey;by &id date_&test;run;



/* elimination of those car tests that happen during an outpatient */

data op_step;
set test_opr_pre (keep = &id &fromdt &thrudt);run;

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

/*proc print data=op_car (obs=1000);run;*/

/* because these are carrier claims that overlap with the dates of outpatient */

proc sort data=test_car_pre; by myclaimid; run;
proc sort data=op_car;by myclaimid; run;
data test_car;
merge test_car_pre (in=a) op_car;
if a;
by  myclaimid;
if flag=1 then delete;
run;



data b;
set test_opr_pre (keep=&id &test date_&test file_&test) test_car (keep=&id &test date_&test file_&test);
format date_&test mmddyy10.;
year_&test=year(date_&test);
month_&test=month(date_&test);
cont_month_&test=((year_&test-1999)*12)+month_&test;
drop month_&test year_&test;
run;

proc sort data=b nodupkey;
by &id /*date_&test*/ cont_month_&test ;
run;

proc print data=b (obs=100);
run;


/***** transposing of the data *****/

proc transpose data=b out=transtest (drop=_name_) prefix=&test;
var &test;
by &id;

proc transpose data=b out=transdate (drop=_name_) prefix=cont_month_&test;
var cont_month_&test;
by &id;

/***** merging the transposed  data *****/
data &test.&year;
merge transtest transdate  ;
by &id;
run;

%let one=%eval(((&year-1999)*12)+1);
%let twelve=%eval(((&year-1999)*12)+12);


data &test.&year;
set &test.&year;
array MONTHS{*} &test.month&one - &test.month&twelve;
array CONTMONTHS{*} cont_month_&test.: ;
do i=1 to 12;
	do j=1 to 12;
	if CONTMONTHS[j]=i+((&year-1999)*12) then MONTHS[i]=1;
	end;
end;
run;



proc print data=&test.&year (obs=100);
run;



data mydata.&test.&year;
length nfumonth: 4 ; 
set &test.&year;
keep &id nfumonth: ; 
run;

proc contents data=mydata.&test.&year;run;

proc datasets lib=work kill memtype=data;
quit;



%mend;






