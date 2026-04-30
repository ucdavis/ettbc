/*********************************************************************/
/** Project: breast cancer screening 						 	    **/
/* Extraction of screening mammographies						    **/
/*********************************************************************/



libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/cohort_endoendo/data/';

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/macros/mammo_extraction0612.sas';
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/macros/mammo_extraction0205.sas';
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/macros/mammo_extraction01.sas';
%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/macros/mammo_extraction00.sas';

options compress=yes mprint notes;

libname op1999 '/disk/aging/medicare/data/20pct/op/1999';libname op2000 '/disk/aging/medicare/data/20pct/op/2000';
libname op2001 '/disk/aging/medicare/data/20pct/op/2001';libname op2002 '/disk/aging/medicare/data/20pct/op/2002';
libname op2003 '/disk/aging/medicare/data/20pct/op/2003';libname op2004 '/disk/aging/medicare/data/20pct/op/2004';
libname op2005 '/disk/aging/medicare/data/20pct/op/2005';libname op2006 '/disk/aging/medicare/data/20pct/op/2006';
libname op2007 '/disk/aging/medicare/data/20pct/op/2007';libname op2008 '/disk/aging/medicare/data/20pct/op/2008';
libname op2009 '/disk/aging/medicare/data/20pct/op/2009';libname op2010 '/disk/aging/medicare/data/20pct/op/2010';
libname op2011 '/disk/aging/medicare/data/20pct/op/2011';libname op2012 '/disk/aging/medicare/data/20pct/op/2012';

libname car1999 '/disk/aging/medicare/data/20pct/car/1999';
libname car2000 '/disk/aging/medicare/data/20pct/car/2000';libname car2001 '/disk/aging/medicare/data/20pct/car/2001';
libname car2002 '/disk/aging/medicare/data/20pct/car/2002';libname car2003 '/disk/aging/medicare/data/20pct/car/2003';
libname car2004 '/disk/aging/medicare/data/20pct/car/2004';libname car2005 '/disk/aging/medicare/data/20pct/car/2005';
libname car2006 '/disk/aging/medicare/data/20pct/car/2006';libname car2007 '/disk/aging/medicare/data/20pct/car/2007';
libname car2008 '/disk/aging/medicare/data/20pct/car/2008';libname car2009 '/disk/aging/medicare/data/20pct/car/2009';
libname car2010 '/disk/aging/medicare/data/20pct/car/2010';libname car2011 '/disk/aging/medicare/data/20pct/car/2011';
libname car2012 '/disk/aging/medicare/data/20pct/car/2012';


/*proc freq data=op2007.opr2007;
table hcpcs_cd;
run;
endsas;*/

/* YEAR 1999 */
%scrmammo00(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'),
margin=0,
datehcpcs=srev_dt,
id= ehic,
year=1999,
fileopc=op1999.op1999,
fileopr=op1999.op1999,
filecarl=car1999.cari1999,
fromdt= from_dt, 
thrudt= thru_dt,
cpt_right_end=HCPSCD45,
hcpcsfield= hcpcs_cd, 
claimid=CLM_CNTL,
claimid_car=CARRCNTL );  
run;


/* YEAR 2000 */
%scrmammo00(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'),  
margin=0,
datehcpcs=srev_dt, 
id= ehic,
year=2000,
fileopc=op2000.op2000,
fileopr=op2000.op2000,
filecarl=car2000.car2000,
fromdt= from_dt, 
thrudt= thru_dt,
cpt_right_end=HCPSCD45,
hcpcsfield= hcpcs_cd, 
claimid=CLM_CNTL,
claimid_car=CARRCNTL );  
run;



/* YEAR 2001 */
%scrmammo01(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'), 
margin=0,
datehcpcs=srev_dt, 
id= ehic,
year=2001,
fileopc=op2001.opc2001,
fileopr=op2001.opr2001,
filecarl=car2001.car2001,
fromdt= sfromdt, 
thrudt= sthrudt,
cpt_right_end=HCPSCD45,
hcpcsfield= hcpcs_cd, 
claimid=claimindex,
claimid_car=CARRCNTL );  
run;



/* YEAR 2002 */
%scrmammo0205(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'), 
margin=0,
datehcpcs=srev_dt, 
id= ehic,
year=2002,
fileopc=op2002.opc2002,
fileopr=op2002.opr2002,
filecarl=car2002.carl2002,
fromdt= sfromdt, 
thrudt= sthrudt,
hcpcsfield= hcpcs_cd, 
claimid=claimindex );  
run;


/* YEAR 2003 */
%scrmammo0205(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'),  
margin=0,
datehcpcs=srev_dt, 
id= ehic,
year=2003,
fileopc=op2003.opc2003,
fileopr=op2003.opr2003,
filecarl=car2003.carl2003,
fromdt= sfromdt, 
thrudt= sthrudt,
hcpcsfield= hcpcs_cd, 
claimid=claimindex );  
run;


/* YEAR 2004 */
%scrmammo0205(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'),  
margin=0,
datehcpcs=srev_dt, 
id= ehic,
year=2004,
fileopc=op2004.opc2004,
fileopr=op2004.opr2004,
filecarl=car2004.carl2004,
fromdt= sfromdt, 
thrudt= sthrudt,
hcpcsfield= hcpcs_cd, 
claimid=claimindex );  
run;



/* YEAR 2005 */
%scrmammo0205(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'), 
margin=0,
datehcpcs=srev_dt, 
id= ehic,
year=2005,
fileopc=op2005.opc2005,
fileopr=op2005.opr2005,
filecarl=car2005.carl2005,
fromdt= sfromdt, 
thrudt= sthrudt,
hcpcsfield= hcpcs_cd, 
claimid=claimindex );  
run;



/* YEAR 2006 */
%scrmammo0612(test=scrmammo , 
hcpcs=('76092','G0202','G0203','G0205'), 
margin=0,
datehcpcs=thru_dt, /* datehcpcs can be rev_dt or thru_dt */
id= bene_id,
year=2006,
fileopc=op2006.opc2006,
fileopr=op2006.opr2006,
filecarl=car2006.carl2006,
fromdt= from_dt, 
thrudt= thru_dt,
hcpcsfield= hcpcs_cd, 
claimid=clm_id );  
run;



/* YEAR 2007 */
%scrmammo0612(test=scrmammo , 
hcpcs=('77057','76092','G0202','G0203','G0205'),  
margin=0,
datehcpcs=thru_dt, /* datehcpcs can be rev_dt or thru_dt */
id= bene_id,
year=2007,
fileopc=op2007.opc2007,
fileopr=op2007.opr2007,
filecarl=car2007.carl2007,
fromdt= from_dt, 
thrudt= thru_dt,
hcpcsfield= hcpcs_cd, 
claimid=clm_id );  
run;



/* YEAR 2008 */
%scrmammo0612(test=scrmammo , 
hcpcs=('77057','76092','G0202','G0203','G0205'), 
margin=0,
datehcpcs=thru_dt, /* datehcpcs can be rev_dt or thru_dt */
id= bene_id,
year=2008,
fileopc=op2008.opc2008,
fileopr=op2008.opr2008,
filecarl=car2008.carl2008,
fromdt= from_dt, 
thrudt= thru_dt,
hcpcsfield= hcpcs_cd, 
claimid=clm_id );  
run;
