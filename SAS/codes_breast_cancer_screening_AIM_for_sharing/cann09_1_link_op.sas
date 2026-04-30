/*********************************************************************/
/** Project: when to stop breast cancer screening	 	    **/
/* Linkage of claims to the included individuals. OUTPATIENT	    **/
/* Here I link the previous year of claims plus all the future claims*/
/* This will be used to extract baseline and time-varying variables **/
/* 								   									 **/
/*********************************************************************/

options mprint notes compress=yes;

/*libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';*/

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

libname op1999 '/disk/aging/medicare/data/20pct/op/1999';libname op2000 '/disk/aging/medicare/data/20pct/op/2000';
libname op2001 '/disk/aging/medicare/data/20pct/op/2001';libname op2002 '/disk/aging/medicare/data/20pct/op/2002';
libname op2003 '/disk/aging/medicare/data/20pct/op/2003';libname op2004 '/disk/aging/medicare/data/20pct/op/2004';
libname op2005 '/disk/aging/medicare/data/20pct/op/2005';libname op2006 '/disk/aging/medicare/data/20pct/op/2006';
libname op2007 '/disk/aging/medicare/data/20pct/op/2007';libname op2008 '/disk/aging/medicare/data/20pct/op/2008';



/* 
How years/claims are linked:

year inclusion /year claim ->	1999	2000	2001	2002	2003	2004	2005	2006	2007	2008

2000							x		x		x		x		x		x		x		x		x		x
2001									x		x		x		x		x		x		x		x		x
2002											x		x		x		x		x		x		x		x
2003													x		x		x		x		x		x		x
2004															x		x		x		x		x		x
2005																	x		x		x		x		x
2006																			x		x		x		x		
2007																					x		x		x

*/

/*proc print data=mydata.box8_baseline66 (obs=10);run;
endsas;*/

%macro bildu_op(daysbeforeinclusion= ,agein=);


/* minimacro to extract the inclusions corresponding to specific years -see above- that will have to be linked to the claims */
data x; 
length year 3; 
set anndata.box8_baseline&agein;  /* x */ ;
inclusion_date=startfup; 
year=year(inclusion_date); 
keep bene_id ehic inclusion_date year;run;
proc freq data=x; table year /missing; run;


%macro yearendoc();
%do j=1999 %to 2008; /* range of claims years which the included individuals will be linked to */
data e&j; set x; 
%let ub=min(2008,&j+1); 
if 2000<=year<=&ub; run;
proc freq data=e&j; table year /missing;
title "claims from &j are linked patients included in these years"; %end; run;
%mend;
%yearendoc();


/* macro to create a long format "r" file from those years in a wide format: in op these are 1999-2000 */
%macro runpostillarun(varout= ,varin=, data= );
data &data (keep=ehic bene_id &varout i LINK_NUM FROM_DT THRU_DT);
set &data._pre (keep=ehic bene_id &varin.1-&varin.45 LINK_NUM FROM_DT THRU_DT);
array h{45} &varin.1-&varin.45;
do i=1 to 45;
	&varout=h[i];
output &data;
end;
run;
data &data;set &data;
if &varout ne '';
drop i; run;
proc sort data=&data nodupkey; by ehic THRU_DT hcpcs_cd;
%mend;


/* 1999: claims from 1999 link to inclusions from 2000 (contained in e1999) */
proc sort data=e1999; by ehic;run;

data C_e04_opc1999 (rename=(pdgns_cd=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 pdgns_cd $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e1999 (in=a) op1999.op1999  
(keep=ehic link_num pdgns_cd dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt  /*obs=100000*/    );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;


data R_e04_opr1999_pre; merge e1999 (in=a) op1999.op1999
(keep=ehic LINK_NUM FROM_DT THRU_DT hcpscd1-hcpscd45  /*obs=100000*/     );	/* the structure of hcpcs in 2000 and 1999 is in "wide" format, thus the pain */
by ehic ;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;
run;

%runpostillarun(varout=hcpcs_cd, varin=hcpscd, data=R_e04_opr1999);

proc datasets lib=work;
delete R_e04_opr1999_pre;
run;



/* 2000: claims from 2000 link to inclusions from 2000-2001 (contained in e2000) */
proc sort data=e2000; by ehic;run;


data C_e0405_opc2000 (rename=(pdgns_cd=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 pdgns_cd $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2000 (in=a) op2000.op2000  
(keep=ehic link_num pdgns_cd dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt  /*obs=100000*/     );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;



data R_e0405_opr2000_pre; merge e2000 (in=a) op2000.op2000 	/* linkage 2000 dx-2000 claims */ 
(keep=ehic LINK_NUM FROM_DT THRU_DT hcpscd1-hcpscd45   /*obs=100000*/    );	/* the structure of hcpcs in 2000 and 1999 is in "wide" format, thus the pain */
by ehic ;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;
run;

%runpostillarun(varout=hcpcs_cd, varin=hcpscd, data=R_e0405_opr2000);

proc datasets lib=work;
delete R_e0405_opr2000_pre;
run;


/* 2001: claims from 2001 link to inclusions from 2000-2002 (contained in e2001) */
proc sort data=e2001; by ehic;run;

data C_e0406_opc2001 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2001 (in=a) op2001.opc2001  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt /*obs=100000*/     );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt ; run;

data R_e0406_opr2001 (rename=(srev_dt=thru_dt)); 
merge e2001 (in=a) op2001.opr2001
(keep=ehic claimindex hcpcs_cd srev_dt  /*obs=100000*/    );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;



/* 2002: claims from 2002 link to inclusions from 2000-2003 (contained in e2002) */
proc sort data=e2002; by ehic;run;

data C_e0407_opc2002 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2002 (in=a) op2002.opc2002  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /*obs=100000*/    );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0407_opr2002 (rename=(srev_dt=thru_dt)); 
merge e2002 (in=a) op2002.opr2002
(keep=ehic claimindex hcpcs_cd srev_dt  /*obs=100000*/    );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt ; run;



/* 2003: claims from 2003 link to inclusions from 2000 - 2004 (contained in e2003) */
proc sort data=e2003; by ehic;run;

data C_e0304_opc2003 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2003 (in=a) op2003.opc2003  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /*obs=100000*/    );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0304_opr2003 (rename=(srev_dt=thru_dt)); 
merge e2003 (in=a) op2003.opr2003
(keep=ehic claimindex hcpcs_cd srev_dt  /*obs=100000*/    );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;



/* 2004: claims from 2004 link to inclusions from 2000 - 2005 (contained in e2004) */
proc sort data=e2004; by ehic;run;

data C_e0405_opc2004 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2004 (in=a) op2004.opc2004  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /*obs=100000*/    );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0405_opr2004 (rename=(srev_dt=thru_dt)); 
merge e2004 (in=a) op2004.opr2004
(keep=ehic claimindex hcpcs_cd srev_dt  /*obs=100000*/    );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;



/* 2005: claims from 2005 link to inclusions from 2000 - 2006 (contained in e2005) */
proc sort data=e2005; by ehic;run;

data C_e0506_opc2005 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2005 (in=a) op2005.opc2005  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /*obs=100000*/    );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0506_opr2005 (rename=(srev_dt=thru_dt)); 
merge e2005 (in=a) op2005.opr2005
(keep=ehic claimindex hcpcs_cd srev_dt  /*obs=100000*/    );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;



/* 2006: claims from 2006 link to inclusions from 2000 - 2007 (contained in e2006) */
proc sort data=e2006; by bene_id;run;

data C_e0607_opc2006 (rename=(ad_dgns=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6
prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 ad_dgns $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2006 (in=a) op2006.opc2006  
(keep=bene_id clm_id ad_dgns dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 
from_dt thru_dt  /*obs=100000*/    );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0607_opr2006; 
merge e2006 (in=a) op2006.opr2006
(keep=bene_id clm_id hcpcs_cd thru_dt  /*obs=100000*/    );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;



/* 2007: claims from 2007 link to inclusions from 2000 - 2007 (contained in e2007) */
proc sort data=e2007; by bene_id;run;

data C_e0708_opc2007 (rename=(ad_dgns=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6
prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 ad_dgns $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2007 (in=a) op2007.opc2007  
(keep=bene_id clm_id ad_dgns dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 
from_dt thru_dt  /*obs=100000*/    );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0708_opr2007; 
merge e2007 (in=a) op2007.opr2007
(keep=bene_id clm_id hcpcs_cd thru_dt  /*obs=100000*/    );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;



/* 2008: claims from 2008 link to inclusions from 2000 - 2007 (contained in e2008) */
proc sort data=e2008; by bene_id;run;

data C_e0809_opc2008 (rename=(ad_dgns=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6
prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 ad_dgns $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2008 (in=a) op2008.opc2008  
(keep=bene_id clm_id ad_dgns dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 
from_dt thru_dt  /*obs=100000*/    );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0809_opr2008; 
merge e2008 (in=a) op2008.opr2008
(keep=bene_id clm_id hcpcs_cd thru_dt  /*obs=100000*/    );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;







/* FINAL POOLING OF ALL THE DATASETS */

data anndata.enrolled&agein._C_op_d&daysbeforeinclusion; set C_: ;
drop from_dt year claimindex link_num clm_id inclusion_date ;run;
data anndata.enrolled&agein._R_op_d&daysbeforeinclusion; set R_: ;
drop claimindex from_dt year link_num clm_id inclusion_date ;run;

/* deleting all the temporay datasets because this program will be called from another */
proc datasets lib=work;
delete C_e04_opc1999 C_e0405_opc2000 C_e0406_opc2001 C_e0407_opc2002 C_E0304_OPC2003 C_E0405_OPC2004 
C_E0506_OPC2005 C_E0607_OPC2006 C_E0708_OPC2007 C_E0809_OPC2008 
E1999 E2000 E2001 E2002 E2003 E2004 E2005 E2006 E2007 E2008  
R_e04_opr1999_pre R_e04_opr1999 R_e0405_opr2000 R_e0406_opr2001 R_e0407_opr2002 R_E0304_OPR2003 R_E0405_OPR2004 
R_E0506_OPR2005 R_E0607_OPR2006 R_E0708_OPR2007 R_E0809_OPR2008 
X;
run;

proc contents data=anndata.enrolled&agein._C_op_d&daysbeforeinclusion;
proc contents data=anndata.enrolled&agein._R_op_d&daysbeforeinclusion;
run;

proc sort data=anndata.enrolled&agein._C_op_d&daysbeforeinclusion; by bene_id thru_dt ; run;
proc sort data=anndata.enrolled&agein._R_op_d&daysbeforeinclusion; by bene_id thru_dt ; run;

proc print data=anndata.enrolled&agein._C_op_d&daysbeforeinclusion (obs=1000); run;
proc print data=anndata.enrolled&agein._R_op_d&daysbeforeinclusion (obs=1000);run;

%mend;

/*%bildu_op(daysbeforeinclusion=366 ,agein=66);*/

