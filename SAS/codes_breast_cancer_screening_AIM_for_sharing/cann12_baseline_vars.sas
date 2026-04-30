/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* Arrangement of baseline variables			    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

/*libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";*/
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';

%macro cann12(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_logsANDlsts/cann12_base&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_logsANDlsts/cann12_base&agein..log" new;run;

proc print data=anndata.box8_baseline&agein (obs=20);run;

proc freq data=anndata.box8_baseline&agein; table baseline_combinedscore baseline_combinedscore2 / missing;
/* exploration of the preventive variables *


proc print data=mydata.tvpreventive&agein (obs=10);run;

proc means data=mydata.tvpreventive&agein sum;
var pneumococo1-pneumococo108 influenza1-influenza108 mammo_prev1-mammo_prev108 crc_prev1-crc_prev108 previsit1-previsit108 
bonemass1-bonemass108 obesity_prev1-obesity_prev108 pelvic_prev1-pelvic_prev108 cvd_prev1-cvd_prev108 tobacco1-tobacco108
diabetes_prev1-diabetes_prev108 glaucoma_prev1-glaucoma_prev108 ibt_cvd1-ibt_cvd108 AAA_prev1-AAA_prev108 alcohol_prev1-alcohol_prev108
depre_prev1-depre_prev108 mnt_prev1-mnt_prev108;
run;
%return; */

/* we can drop obesity_prev tobacco glaucoma_prev ibt_cvd AAA_prev alcohol_prev depre_prev mnt_prev */

proc sort data=anndata.box8_baseline&agein; by bene_id; run;
proc sort data=anndata.ervisits&agein; by bene_id; run;
proc sort data=anndata.daysadmitted&agein; by bene_id; run;
proc sort data=anndata.combinedcomorb&agein; by bene_id;run;



data base0;
merge anndata.box8_baseline&agein (in=a) anndata.tvpreventive&agein (drop=obesity_prev: tobacco: glaucoma_prev: ibt_cvd: 
AAA_prev: alcohol_prev: depre_prev: mnt_prev: ) anndata.ervisits&agein anndata.daysadmitted&agein /*anndata.combinedcomorb&agein*/;
by bene_id; if a; 
run;


data base0;
set base0;
mstartfup=((year(startfup)-2000)*12)+month(startfup);
pneumococo_base=0; influenza_base=0; crc_prev_base=0; previsit_base=0; bonemass_base=0; pelvic_prev_base=0;
cvd_prev_base=0; diabetes_prev_base=0; 
array PN{*} pneumococo1-pneumococo96;
array IN{*} influenza1-influenza96;
array CR{*} crc_prev1-crc_prev96;
array PV{*} previsit1-previsit96;
array BO{*} bonemass1-bonemass96;
array PE{*} pelvic_prev1-pelvic_prev96;
array CV{*} cvd_prev1-cvd_prev96;
array DI{*} diabetes_prev1-diabetes_prev96;
array ER{*} ervisit6m1-ervisit6m96;
array AD{*} daysin6m1-daysin6m96;
/*array CS{*} combinedscore1-combinedscore96;*/
do i=1 to 96;
	if i=mstartfup then do;
		if PN[i]=1 then pneumococo_base=1;
		if IN[i]=1 then influenza_base=1;
		if CR[i]=1 then crc_prev_base=1;
		if PV[i]=1 then previsit_base=1;
		if BO[i]=1 then bonemass_base=1;
		if PE[i]=1 then pelvic_prev_base=1;
		if CV[i]=1 then cvd_prev_base=1;
		if DI[i]=1 then diabetes_prev_base=1;
		ervisit6m_base=ER[i];
		daysin6m_base=AD[i];
		/*comcom_base=CS[i];*/
	end;
end;
if ervisit6m_base=. then ervisit6m_base=0 ;
if ervisit6m_base >1 then ervisit6m_base=2;
if daysin6m_base=. then daysin6m_base=0;
if 1<=daysin6m_base<=5 then daysin6m_base=1;
if 6<=daysin6m_base<=10 then daysin6m_base=2;
if daysin6m_base>10 then daysin6m_base=3;
/*if comcom_base=. then comcom_base=0;
if .<comcom_base<0 then comcom_base=-1;
if comcom_base>2 then comcom_base=2;*/
label ervisit6m_base='0=0, 1=1, 2=2+';
label daysin6m_base='0=0, 1=1-5, 2=6=10, 3=11+';
label baseline_combinedscore='-1=<0; 0=0'; 
year_base=year(startfup)-2000;
if baseline_combinedscore<-1 then baseline_combinedscore=-1; 
keep bene_id pneumococo_base influenza_base crc_prev_base previsit_base bonemass_base pelvic_prev_base cvd_prev_base 
diabetes_prev_base ervisit6m_base daysin6m_base /*comcom_base*/ baseline_combinedscore baseline_combinedscore2 year_base startfup; 
run;


/*proc freq data=base0;
table baseline_combinedscore pneumococo_base influenza_base crc_prev_base previsit_base bonemass_base pelvic_prev_base cvd_prev_base 
diabetes_prev_base ervisit6m_base daysin6m_base year_base/ missing;run;
%return;*/


proc print data=base0 (obs=10);run;

/* addition of CCW comorbidities. This was done in c07 step before the Annals review */

data base0;
merge base0 (in=a) myCCW.first&agein.alzheimer myCCW.first&agein.AMI myCCW.first&agein.asthma myCCW.first&agein.AF
 myCCW.first&agein.cataract myCCW.first&agein.chf myCCW.first&agein.ckd myCCW.first&agein.copd 
myCCW.first&agein.depre myCCW.first&agein.diabetes myCCW.first&agein.endometrial myCCW.first&agein.glaucoma
myCCW.first&agein.hip myCCW.first&agein.hta myCCW.first&agein.hypoth myCCW.first&agein.ihd myCCW.first&agein.lipid myCCW.first&agein.lung 
myCCW.first&agein.osteo myCCW.first&agein.ra myCCW.first&agein.stroke  myCCW.first&agein.crc myCCW.first&agein.anemia
;
by bene_id;
if a;
run;



data base1;
set base0;
array DFOCOM{*} dfo_alzheimer dfo_ami dfo_asthma dfo_AF dfo_cataract dfo_CHF dfo_CKD dfo_COPD dfo_depre
dfo_diabetes dfo_endometrial dfo_glaucoma dfo_hip dfo_HTA dfo_hypoth dfo_IHD dfo_lipid dfo_lung 
dfo_osteo dfo_RA dfo_stroke dfo_CRC dfo_anemia;

array COMORB{*} alzheimer_base ami_base asthma_base AF_base cataract_base CHF_base CKD_base COPD_base depre_base
diabetes_base endometrial_base glaucoma_base hip_base HTA_base hypoth_base IHD_base lipid_base lung_base osteo_base RA_base stroke_base CRC_base anemia_base;

do i=1 to dim(COMORB);
COMORB[i]=0;
if . < DFOCOM[i] < startfup then COMORB[i]=1;
end;

array DFOCOM12{*} dfo_ami dfo_hip dfo_stroke;
array COMORB12{*} ami12_base hip12_base stroke12_base;
do i=1 to dim(COMORB12);
COMORB12[i]=0;
if (startfup-365) < DFOCOM12[i] < startfup then COMORB12[i]=1;
end;

drop dfo_:        ;
ischemic_base=0; 
if AMI_base=1 OR IHD_base=1 then ischemic_base=1; 
run;


/* addition of LTC info  */
data base1;
merge base1 (in=a) anndata.ltc&agein; 
by bene_id;
if a; 
year_&agein=year(startfup);
month_&agein=month(startfup);
cont_month_&agein=((year_&agein-1999)*12)+month_&agein;
LTC_base = ( .<firstmonthLTC<=cont_month_&agein);
drop year_&agein month_&agein cont_month_&agein firstmonthLTC i; 
run;

proc print data=base1 (obs=15); run;


/*data base1; 
set anndata.box8_baseline&agein (keep=bene_id startfup asthma AF cataract depre diabetes glaucoma HTA hypoth IHD lipid osteo RA anemia
rename=(asthma=asthma_base) rename=(AF=AF_base) rename=(cataract=cataract_base) rename=(depre=depre_base) rename=(diabetes=diabetes_base) 
rename=(glaucoma=glaucoma_base) rename=(HTA=HTA_base) rename=(hypoth=hypoth_base) rename=(IHD=IHD_base) rename=(lipid=lipid_base)
rename=(osteo=osteo_base) rename=(RA=RA_base) rename=(anemia=anemia_base));
run;

proc print data=base1 (obs=20);run;
proc sort data=base1; by bene_id; run;
*/
/* addition of time-invariant baseline variables  ***/

%macro mevamata(agein= , year =);

libname bsf&year "/disk/aging/medicare/data/20pct/bsf/&year./1";

data baselig&year;set anndata.box8_baseline&agein; if year(startfup)=&year;run;

proc sort data=baselig&year;by bene_id;run;
data baselig&year;
merge baselig&year (in=a) bsf&year..bsfab&year (keep = bene_id race state_cd );
by bene_id;if a;run;

%mend; 

%macro loopmevamata(agein= );

%do i=2000 %to 2007; %mevamata(agein=&agein, year=&i); %end;

data timeinvariant&agein;set baselig: ;
keep bene_id race state_cd;run;

proc sort data= timeinvariant&agein;by bene_id;run;

%mend; 

%loopmevamata(agein=&agein);  

proc print data=timeinvariant&agein (obs=10);run;



data anndata.basevars&agein;
length state_cd race $ 3 alzheimer_base ami_base asthma_base AF_base cataract_base CHF_base CKD_base COPD_base depre_base
diabetes_base endometrial_base glaucoma_base hip_base HTA_base hypoth_base IHD_base lipid_base lung_base osteo_base RA_base stroke_base CRC_base anemia_base ami12_base hip12_base stroke12_base
/*comcom_base*/ crc_prev_base cvd_prev_base daysin6m_base depre_base diabetes_base diabetes_prev_base 
ervisit6m_base glaucoma_base hypoth_base influenza_base lipid_base osteo_base pelvic_prev_base pneumococo_base
previsit_base age year_base ischemic_base LTC_base 3  ; 
merge base1 (in=a) timeinvariant&agein /*base0*/; 
by bene_id; if a; 
age=&agein; 
drop startfup; run;

proc print data=anndata.basevars&agein (obs=25);run;

proc contents data=anndata.basevars&agein; run;

proc datasets lib=work kill memtype=data;run;

%mend; /* c12 */




*%cann12(agein=70);
*%cann12(agein=71);
*%cann12(agein=72);
*%cann12(agein=73);
*%cann12(agein=74);
*%cann12(agein=75);
*%cann12(agein=76);
*%cann12(agein=77);
*%cann12(agein=78);
*%cann12(agein=79);
*%cann12(agein=80);
*%cann12(agein=81);
*%cann12(agein=82);
*%cann12(agein=83);
*%cann12(agein=84);

