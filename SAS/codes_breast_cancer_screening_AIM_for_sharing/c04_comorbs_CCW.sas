/**************************************************************************************************/
/* Code to extract CCW comorbities, first date of occurence. To adjust baseline.	          */
/* To be merged with the expanded dataset						          */
/**************************************************************************************************/


options mprint notes compress=yes;
libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';


%macro c04(agein=);

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c04_logsANDlsts/c04_comorbs_CCW&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/c04_logsANDlsts/c04_comorbs_CCW&agein..log" new; run;


%macro ccw(agein= , year= , comorb= , dfo_comorb= );

libname cc&year "/disk/aging/medicare/data/20pct/bsf/&year/";

data &comorb&year;
set cc&year..bsfcc&year (keep=bene_id &dfo_comorb );
if &dfo_comorb ne . ;
run;

%mend; /* %ccw */

%macro loopcc(agein= ,comorb= , dfo_comorb= );

%do i=1999 %to 2008;
	%ccw(agein=&agein , year=&i , comorb=&comorb, dfo_comorb=&dfo_comorb);
%end;

data all&comorb;set &comorb.1999-&comorb.2008;run;

proc sort data=all&comorb nodupkey; by bene_id &dfo_comorb; run;

proc sort data=mydata.box1_2age&agein; by bene_id; run;

data first&agein.&comorb;
merge mydata.box1_2age&agein (in=a keep=bene_id) all&comorb;
by bene_id;if a;run;

data myCCW.first&agein.&comorb;
set first&agein.&comorb;
if &dfo_comorb ne . ;
dfo_&comorb=&dfo_comorb;drop &dfo_comorb;format dfo_&comorb DATE9. ;run;

proc datasets lib=work; delete &comorb.1999-&comorb.2008 all&comorb first&agein.&comorb; run;

proc print data=myCCW.first&agein.&comorb (obs=10);run;

%mend; /* %loopcc */

%loopcc(agein=&agein, comorb=alzheimer, dfo_comorb= alzhdmte);
%loopcc(agein=&agein, comorb=AMI, dfo_comorb= amie);
%loopcc(agein=&agein, comorb=asthma, dfo_comorb= asthma_ever);
%loopcc(agein=&agein, comorb=AF, dfo_comorb= atrialfe);
%loopcc(agein=&agein, comorb=cataract, dfo_comorb= catarcte);
%loopcc(agein=&agein, comorb=CHF, dfo_comorb= chfe);
%loopcc(agein=&agein, comorb=CKD, dfo_comorb= chrnkdne);
%loopcc(agein=&agein, comorb=endometrial, dfo_comorb= cncendme);
%loopcc(agein=&agein, comorb=breast, dfo_comorb= cncrbrse);
%loopcc(agein=&agein, comorb=CRC, dfo_comorb= cncrclre);
%loopcc(agein=&agein, comorb=anemia, dfo_comorb= anemia_ever);
%loopcc(agein=&agein, comorb=lung, dfo_comorb= cncrlnge);
%loopcc(agein=&agein, comorb=prostate, dfo_comorb= cncrprse);
%loopcc(agein=&agein, comorb=COPD, dfo_comorb= copde);
%loopcc(agein=&agein, comorb=depre, dfo_comorb= deprssne);
%loopcc(agein=&agein, comorb=diabetes, dfo_comorb= diabtese);
%loopcc(agein=&agein, comorb=glaucoma, dfo_comorb= glaucmae);
%loopcc(agein=&agein, comorb=hip, dfo_comorb= hipfrace);
%loopcc(agein=&agein, comorb=lipid, dfo_comorb= hyperl_ever);
%loopcc(agein=&agein, comorb=BPH, dfo_comorb= hyperp_ever);
%loopcc(agein=&agein, comorb=HTA, dfo_comorb= hypert_ever);
%loopcc(agein=&agein, comorb=hypoth, dfo_comorb= hypoth_ever);
%loopcc(agein=&agein, comorb=IHD, dfo_comorb= ischmche);
%loopcc(agein=&agein, comorb=osteo, dfo_comorb= osteopre);
%loopcc(agein=&agein, comorb=RA, dfo_comorb= ra_oa_e);
%loopcc(agein=&agein, comorb=stroke, dfo_comorb= strktiae);


%mend; 





