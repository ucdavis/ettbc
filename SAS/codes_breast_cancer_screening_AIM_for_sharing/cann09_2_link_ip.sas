/*********************************************************************/
/** Project: when to stop breast cancer screening	 	    **/
/* Linkage of claims to the included individuals. INPATIENT	    **/
/* Here I link the previous year of claims plus all the future claims*/
/* This will be used to extract baseline and time-varying variables **/
/* 								    **/
/*********************************************************************/

options mprint notes compress=yes;
/*libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';*/

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

libname ip1999 '/disk/aging/medicare/data/20pct/ip/1999';libname ip2000 '/disk/aging/medicare/data/20pct/ip/2000';
libname ip2001 '/disk/aging/medicare/data/20pct/ip/2001';libname ip2002 '/disk/aging/medicare/data/20pct/ip/2002';
libname ip2003 '/disk/aging/medicare/data/20pct/ip/2003';libname ip2004 '/disk/aging/medicare/data/20pct/ip/2004';
libname ip2005 '/disk/aging/medicare/data/20pct/ip/2005';libname ip2006 '/disk/aging/medicare/data/20pct/ip/2006';
libname ip2007 '/disk/aging/medicare/data/20pct/ip/2007';libname ip2008 '/disk/aging/medicare/data/20pct/ip/2008';

 
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


%macro bildu_ip(daysbeforeinclusion= ,agein=);


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





/* macro to create a long format "r" file from those years in a wide format: in ip these are 1999-2000 */
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


data C_e04_ipc1999 (rename=(pdgns_cd=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 pdgns_cd $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e1999 (in=a) ip1999.ip1999  
(keep=ehic CLM_CNTL pdgns_cd dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt /* obs=100000 */ );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;


data R_e04_ipr1999_pre; merge e1999 (in=a) ip1999.ip1999 	 
(keep=ehic CLM_CNTL FROM_DT THRU_DT hcpscd1-hcpscd58  /* obs=100000 */ );	
by ehic ;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;
run;

data R_e04_ipr1999 (keep=ehic bene_id hcpcs_cd i CLM_CNTL FROM_DT THRU_DT);
set R_e04_ipr1999_pre (keep=ehic bene_id hcpscd1-hcpscd58 CLM_CNTL FROM_DT THRU_DT );
array h{58} hcpscd1-hcpscd58;
do i=1 to 58;
	hcpcs_cd=h[i];
output  R_e04_ipr1999;
end;
run;

proc datasets lib=work; delete R_e04_ipr1999_pre; run;

data R_e04_ipr1999;set R_e04_ipr1999;
if hcpcs_cd ne '';
drop i; run;

proc sort data=R_e04_ipr1999 nodupkey; by ehic THRU_DT hcpcs_cd;

proc print data=R_e04_ipr1999 (obs=100);run;

/* 2000: claims from 2000 link to inclusions from 2000-2001 (contained in e2000) */
proc sort data=e2000; by ehic;run;


data C_e0405_ipc2000 (rename=(pdgns_cd=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 from_dt thru_dt 5 ;
merge e2000 (in=a) ip2000.ip2000  
(keep=ehic link_num pdgns_cd dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdr_dt1-prcdr_dt6 from_dt thru_dt /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;



data R_e0405_ipr2000_pre; merge e2000 (in=a) ip2000.ip2000 	
(keep=ehic LINK_NUM FROM_DT THRU_DT  hcpscd1-hcpscd45  /* obs=100000 */ );		
by ehic ;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;
run;

%runpostillarun(varout=hcpcs_cd, varin=hcpscd, data=R_e0405_ipr2000);

proc datasets lib=work;
delete R_e0405_ipr2000_pre;
run;

proc print data=R_e0405_ipr2000 (obs=100);run;



/* 2001: claims from 2001 link to inclusions from 2000-2002 (contained in e2001) */
proc sort data=e2001; by ehic;run;

data C_e0406_ipc2001 (rename=(pdgns_cd=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 pdgns_cd $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2001 (in=a) ip2001.ip2001  
(keep=ehic link_num pdgns_cd dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt  /* obs=100000 */ );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0406_ipr2001_pre; merge e2001 (in=a) ip2001.ip2001 	
(keep=ehic LINK_NUM FROM_DT THRU_DT hcpscd1-hcpscd45  /* obs=100000 */ );		
by ehic ;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;
run;

%runpostillarun(varout=hcpcs_cd, varin=hcpscd, data=R_e0406_ipr2001);

proc datasets lib=work;
delete R_e0406_ipr2001_pre;
run;

proc print data=R_e0406_ipr2001 (obs=100);run;



/* 2002: claims from 2002 link to inclusions from 2000-2003 (contained in e2002) */
proc sort data=e2002; by ehic;run;

data C_e0407_ipc2002 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2002 (in=a) ip2002.ipc2002  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /* obs=100000 */ );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0407_ipr2002 (rename=(srev_dt=thru_dt)); 
merge e2002 (in=a) ip2002.ipr2002
(keep=ehic claimindex hcpcs_cd srev_dt  /* obs=100000 */ );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;

proc print data=R_e0407_ipr2002 (obs=100);run;


/* 2003: claims from 2003 link to inclusions from 2000 - 2004 (contained in e2003) */
proc sort data=e2003; by ehic;run;

data C_e0304_ipc2003 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2003 (in=a) ip2003.ipc2003  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /* obs=100000 */ );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0304_ipr2003 (rename=(srev_dt=thru_dt)); 
merge e2003 (in=a) ip2003.ipr2003
(keep=ehic claimindex hcpcs_cd srev_dt  /* obs=100000 */ );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;

proc print data=R_e0304_ipr2003 (obs=100);run;

/* 2004: claims from 2004 link to inclusions from 2000 - 2005 (contained in e2004) */
proc sort data=e2004; by ehic;run;

data C_e0405_ipc2004 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2004 (in=a) ip2004.ipc2004  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /* obs=100000 */ );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0405_ipr2004 (rename=(srev_dt=thru_dt)); 
merge e2004 (in=a) ip2004.ipr2004
(keep=ehic claimindex hcpcs_cd srev_dt  /* obs=100000 */ );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;

proc print data=R_e0405_ipr2004 (obs=100);run;


/* 2005: claims from 2005 link to inclusions from 2000 - 2006 (contained in e2005) */
proc sort data=e2005; by ehic;run;

data C_e0506_ipc2005 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd10=icd_dgns_cd1-icd_dgns_cd10 prcdr_cd1-prcdr_cd6=icd_prcdr_cd1-icd_prcdr_cd6 prcdr_dt1-prcdr_dt6=prcdr_dt1-prcdr_dt6 sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 pdgns_cd $7 prcdr_dt1-prcdr_dt6 sfromdt sthrudt 5 ;
merge e2005 (in=a) ip2005.ipc2005  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd10 prcdr_cd1-prcdr_cd6 prcdr_dt1-prcdr_dt6 sfromdt sthrudt  /* obs=100000 */ );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0506_ipr2005 (rename=(srev_dt=thru_dt)); 
merge e2005 (in=a) ip2005.ipr2005
(keep=ehic claimindex hcpcs_cd srev_dt  /* obs=100000 */ );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < srev_dt  ; run;

proc print data=R_e0506_ipr2005 (obs=100);run;


/* 2006: claims from 2006 link to inclusions from 2000 - 2007 (contained in e2006) */
proc sort data=e2006; by bene_id;run;

data C_e0607_ipc2006 (rename=(ad_dgns=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6
prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 ad_dgns $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2006 (in=a) ip2006.ipc2006  
(keep=bene_id clm_id ad_dgns dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt  /* obs=100000 */ );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0607_ipr2006; 
merge e2006 (in=a) ip2006.ipr2006
(keep=bene_id clm_id hcpcs_cd thru_dt  /* obs=100000 */ );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;

proc print data=R_e0607_ipr2006 (obs=100);run;


/* 2007: claims from 2007 link to inclusions from 2000 - 2007 (contained in e2007) */
proc sort data=e2007; by bene_id;run;

data C_e0708_ipc2007 (rename=(ad_dgns=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6
prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 ad_dgns $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2007 (in=a) ip2007.ipc2007  
(keep=bene_id clm_id ad_dgns dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt  /* obs=100000 */ );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0708_ipr2007; 
merge e2007 (in=a) ip2007.ipr2007
(keep=bene_id clm_id hcpcs_cd thru_dt  /* obs=100000 */ );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;

proc print data=R_e0708_ipr2007 (obs=100);run;


/* 2008: claims from 2008 link to inclusions from 2000 - 2007 (contained in e2008) */
proc sort data=e2008; by bene_id;run;

data C_e0809_ipc2008 (rename=(ad_dgns=prncpal_dgns_cd dgnscd1-dgnscd10=icd_dgns_cd1-icd_dgns_cd10 prcdrcd1-prcdrcd6=icd_prcdr_cd1-icd_prcdr_cd6
prcdrdt1-prcdrdt6=prcdr_dt1-prcdr_dt6)); 
length dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 ad_dgns $7 prcdrdt1-prcdrdt6 from_dt thru_dt 5 ;
merge e2008 (in=a) ip2008.ipc2008  
(keep=bene_id clm_id ad_dgns dgnscd1-dgnscd10 prcdrcd1-prcdrcd6 prcdrdt1-prcdrdt6 from_dt thru_dt  /* obs=100000 */ );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0809_ipr2008; 
merge e2008 (in=a) ip2008.ipr2008
(keep=bene_id clm_id hcpcs_cd thru_dt  /* obs=100000 */ );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;

proc print data=R_e0809_ipr2008 (obs=100);run;
 


/* FINAL POOLING OF ALL THE DATASETS */

data anndata.enrolled&agein._C_ip_d&daysbeforeinclusion; set C_: ;
drop from_dt year claimindex link_num clm_cntl clm_id inclusion_date; run;
data anndata.enrolled&agein._R_ip_d&daysbeforeinclusion; set R_: ;
drop claimindex from_dt year link_num clm_id clm_cntl inclusion_date; run;

/* deleting all the temporay datasets because this program will be called from another */
proc datasets lib=work;
delete C_e04_ipc1999 C_e0405_ipc2000 C_e0406_ipc2001 C_e0407_ipc2002 C_E0304_ipC2003 C_E0405_ipC2004 
C_E0506_ipC2005 C_E0607_ipC2006 C_E0708_ipC2007 C_E0809_ipC2008 
E1999 E2000 E2001 E2002 E2003 E2004 E2005 E2006 E2007 E2008  
R_e04_ipr1999_pre R_e04_ipr1999 R_e0405_ipr2000 R_e0406_ipr2001 R_e0407_ipr2002 R_E0304_ipR2003 R_E0405_ipR2004 
R_E0506_ipR2005 R_E0607_ipR2006 R_E0708_ipR2007 R_E0809_ipR2008 
X;
run;

proc contents data=anndata.enrolled&agein._C_ip_d&daysbeforeinclusion;
proc contents data=anndata.enrolled&agein._R_ip_d&daysbeforeinclusion;
run;

proc sort data=anndata.enrolled&agein._C_ip_d&daysbeforeinclusion; by bene_id thru_dt  ; run;
proc sort data=anndata.enrolled&agein._R_ip_d&daysbeforeinclusion; by bene_id thru_dt  ; run;

proc print data=anndata.enrolled&agein._C_ip_d&daysbeforeinclusion (obs=1000); run;
proc print data=anndata.enrolled&agein._R_ip_d&daysbeforeinclusion (obs=1000);run;

%mend; /* %bildu_op2 */

/*%bildu_ip (daysbeforeinclusion=366 ,agein=84);*/

