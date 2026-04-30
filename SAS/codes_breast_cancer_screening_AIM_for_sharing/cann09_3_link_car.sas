/*********************************************************************/
/** Project: colonoscopy and endocarditis		 	    **/
/* Linkage of claims to the included individuals. CARRIER FILE	    **/
/* Here I link the previous year of claims plus all the future claims*/
/* This will be used to extract baseline and time-varying variables **/
/*********************************************************************/

options mprint notes compress=yes;

libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';

libname car1999 '/disk/aging/medicare/data/20pct/car/1999' inencoding=any;libname car2000 '/disk/aging/medicare/data/20pct/car/2000' inencoding=any;
libname car2001 '/disk/aging/medicare/data/20pct/car/2001' inencoding=any;libname car2002 '/disk/aging/medicare/data/20pct/car/2002' inencoding=any;
libname car2003 '/disk/aging/medicare/data/20pct/car/2003' inencoding=any;libname car2004 '/disk/aging/medicare/data/20pct/car/2004' inencoding=any;
libname car2005 '/disk/aging/medicare/data/20pct/car/2005' inencoding=any;libname car2006 '/disk/aging/medicare/data/20pct/car/2006' inencoding=any;
libname car2007 '/disk/aging/medicare/data/20pct/car/2007' inencoding=any;libname car2008 '/disk/aging/medicare/data/20pct/car/2008' inencoding=any;



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

%macro bildu_car(daysbeforeinclusion= , agein = );


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



/* 1999: claims from 1999 link to inclusions from 2000 (contained in e1999) */
proc sort data=e1999; by ehic;run;

data C_e04_carc1999 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 from_dt thru_dt 5 ;
merge e1999 (in=a) car1999.cari1999  
(keep=ehic CARRCNTL pdgns_cd dgns_cd1-dgns_cd4 from_dt thru_dt /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e04_carr1999 ; 
merge e1999 (in=a) car1999.cari1999
(keep=ehic CARRCNTL hcpcs_cd from_dt thru_dt /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;


/* 2000: claims from 2000 link to inclusions from 2000-2001 (contained in e2000) */
proc sort data=e2000; by ehic;run;

data C_e0405_carc2000 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 from_dt thru_dt 5 ;
merge e2000 (in=a) car2000.car2000  
(keep=ehic CARRCNTL pdgns_cd dgns_cd1-dgns_cd4 from_dt thru_dt  /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0405_carr2000 ; 
merge e2000 (in=a) car2000.car2000
(keep=ehic CARRCNTL hcpcs_cd from_dt thru_dt /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;





/* 2001: claims from 2001 link to inclusions from 2000-2002 (contained in e2001) */
proc sort data=e2001; by ehic;run;

data C_e0406_carc2001 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 from_dt thru_dt 5 ;
merge e2001 (in=a) car2001.car2001  
(keep=ehic CARRCNTL pdgns_cd dgns_cd1-dgns_cd4 from_dt thru_dt  /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0406_carr2001 ; 
merge e2001 (in=a) car2001.car2001
(keep=ehic CARRCNTL hcpcs_cd from_dt thru_dt /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;




/* 2002: claims from 2002 link to inclusions from 2000-2003 (contained in e2002) */
proc sort data=e2002; by ehic;run;

data C_e0407_carc2002 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4
sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 sfromdt sthrudt 5 ;
merge e2002 (in=a) car2002.carc2002  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd4 sfromdt sthrudt /* obs=100000 */   );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0407_carr2002 (rename=(sexpndt1=thru_dt)); 
merge e2002 (in=a) car2002.carl2002
(keep=ehic claimindex hcpcs_cd sexpndt1  /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < sexpndt1  ; run;



/* 2003: claims from 2003 link to inclusions from 2000 - 2004 (contained in e2003) */
proc sort data=e2003; by ehic;run;

data C_e0304_carc2003 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4
sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 sfromdt sthrudt 5 ;
merge e2003 (in=a) car2003.carc2003  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd4 sfromdt sthrudt  /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0304_carr2003 (rename=(sexpndt1=thru_dt)); 
merge e2003 (in=a) car2003.carl2003
(keep=ehic claimindex hcpcs_cd sexpndt1  /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < sexpndt1  ; run;




/* 2004: claims from 2004 link to inclusions from 2000 - 2005 (contained in e2004) */
proc sort data=e2004; by ehic;run;

data C_e0405_carc2004 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4
sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 sfromdt sthrudt 5 ;
merge e2004 (in=a) car2004.carc2004  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd4 sfromdt sthrudt  /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0405_carr2004 (rename=(sexpndt1=thru_dt)); 
merge e2004 (in=a) car2004.carl2004
(keep=ehic claimindex hcpcs_cd sexpndt1  /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < sexpndt1  ; run;


/* 2005: claims from 2005 link to inclusions from 2000 - 2006 (contained in e2005) */
proc sort data=e2005; by ehic;run;

data C_e0506_carc2005 (rename=(pdgns_cd=prncpal_dgns_cd dgns_cd1-dgns_cd4=icd_dgns_cd1-icd_dgns_cd4
sfromdt=from_dt sthrudt=thru_dt)); 
length dgns_cd1-dgns_cd4 pdgns_cd $7 sfromdt sthrudt 5 ;
merge e2005 (in=a) car2005.carc2005  
(keep=ehic claimindex pdgns_cd dgns_cd1-dgns_cd4 sfromdt sthrudt  /* obs=100000 */  );
by ehic;
if a;
if (inclusion_date-&daysbeforeinclusion) < sfromdt  ; run;

data R_e0506_carr2005 (rename=(sexpndt1=thru_dt)); 
merge e2005 (in=a) car2005.carl2005
(keep=ehic claimindex hcpcs_cd sexpndt1  /* obs=100000 */  );
by ehic;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < sexpndt1  ; run;



/* 2006: claims from 2006 link to inclusions from 2000 - 2007 (contained in e2006) */
proc sort data=e2006; by bene_id;run;

data C_e0607_carc2006 (rename=(dgns_cd1-dgns_cd8=icd_dgns_cd1-icd_dgns_cd8)); 
length dgns_cd1-dgns_cd8 $7 from_dt thru_dt 5 ;
merge e2006 (in=a) car2006.carc2006  
(keep=bene_id clm_id dgns_cd1-dgns_cd8 from_dt thru_dt  /* obs=100000 */  );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0607_carr2006; 
merge e2006 (in=a) car2006.carl2006
(keep=bene_id clm_id hcpcs_cd thru_dt  /* obs=100000 */  );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;


/* 2007: claims from 2007 link to inclusions from 2000 - 2007 (contained in e2007) */
proc sort data=e2007; by bene_id;run;

data C_e0708_carc2007 (rename=(dgns_cd1-dgns_cd8=icd_dgns_cd1-icd_dgns_cd8)); 
length dgns_cd1-dgns_cd8 $7 from_dt thru_dt 5 ;
merge e2007 (in=a) car2007.carc2007  
(keep=bene_id clm_id dgns_cd1-dgns_cd8 from_dt thru_dt  /* obs=100000 */  );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0708_carr2007; 
merge e2007 (in=a) car2007.carl2007
(keep=bene_id clm_id hcpcs_cd thru_dt  /* obs=100000 */  );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;



/* 2008: claims from 2008 link to inclusions from 2000 - 2007 (contained in e2008) */
proc sort data=e2008; by bene_id;run;

data C_e0809_carc2008 (rename=(dgns_cd1-dgns_cd8=icd_dgns_cd1-icd_dgns_cd8)); 
length dgns_cd1-dgns_cd8 $7 from_dt thru_dt 5 ;
merge e2008 (in=a) car2008.carc2008  
(keep=bene_id clm_id dgns_cd1-dgns_cd8 from_dt thru_dt  /* obs=100000 */  );
by bene_id;
if a;
if (inclusion_date-&daysbeforeinclusion) < from_dt  ; run;

data R_e0809_carr2008; 
merge e2008 (in=a) car2008.carl2008
(keep=bene_id clm_id hcpcs_cd thru_dt  /* obs=100000 */  );
by bene_id;
if a;
if hcpcs_cd ne '';
if (inclusion_date-&daysbeforeinclusion) < thru_dt  ; run;





/* FINAL POOLING OF ALL THE DATASETS */

data anndata.enrolled&agein._C_car_d&daysbeforeinclusion; set C_: ;
drop from_dt year claimindex clm_id inclusion_date carrcntl ; run;
data anndata.enrolled&agein._R_car_d&daysbeforeinclusion; set R_: ;
drop year inclusion_date claimindex carrcntl from_dt clm_id; run;

/* deleting all the temporay datasets because this program will be called from another */
proc datasets lib=work;
delete C_E04_CARC1999 C_E0405_CARC2000 C_E0406_CARC2001 C_E0407_CARC2002 C_E0304_carC2003 C_E0405_carC2004 
C_E0506_carC2005 C_E0607_carC2006 C_E0708_carC2007 C_E0809_carC2008 
E1999 E2000 E2001 E2002 E2003 E2004 E2005 E2006 E2007 E2008 
R_E04_CARR1999 R_E0405_CARR2000 R_E0406_CARR2001 R_E0407_CARR2002 R_E0304_carR2003 R_E0405_carR2004 
R_E0506_carR2005 R_E0607_carR2006 R_E0708_carR2007 R_E0809_carR2008 
X;
run;


proc contents data=anndata.enrolled&agein._C_car_d&daysbeforeinclusion;
proc contents data=anndata.enrolled&agein._R_car_d&daysbeforeinclusion;
run;

proc sort data=anndata.enrolled&agein._C_car_d&daysbeforeinclusion; by bene_id thru_dt  ; run;
proc sort data=anndata.enrolled&agein._R_car_d&daysbeforeinclusion; by bene_id thru_dt  ; run;

proc print data=anndata.enrolled&agein._C_car_d&daysbeforeinclusion (obs=1000); run;
proc print data=anndata.enrolled&agein._R_car_d&daysbeforeinclusion (obs=1000);run;


%mend; /* %bildu_car */

/*%bildu_car(daysbeforeinclusion=366 ,agein=66);*/

