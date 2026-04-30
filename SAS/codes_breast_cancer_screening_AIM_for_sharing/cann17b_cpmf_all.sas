/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* generate the long format in the unexpanded dataset to compute the 
conditional probability mass function for the weights		    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';


/*proc print data=anndata.cloned12m70 (obs=10); run;
endsas;*/

/* macro with the models */

%macro cann17b_all(frommagein= , tomagein= , agegroup=);



%do i=&frommagein %to &tomagein; /* loop 1 */

/*proc print data=mydata.censored5pct&i (obs=10); run;*/

data x&i; 
length age 8 ; 
set anndata.cloned12m&i (keep=  bene_id ehic /*arm*/ mstartfup mend /*countedPCdeathUCD*/ counteddeath /*base_previsit base_fobt base_influenza base_diab_scr base_cv_scr*/ /*obs=10000*/) ;
age=&i; run;


data ltc&i; set anndata.ltc&i; monthLTC=firstmonthLTC-12; run;



/* transformation to long format of the time-varying covariates */

%macro ccw(comorb=);

data ccw&comorb&i;
set myCCW.first&i.&comorb;
month&comorb=((year(dfo_&comorb)-2000)*12)+month(dfo_&comorb);
run;
/*proc print data=ccw&comorb&i (obs=100);run;*/
/*proc print data=ccw&comorb (obs=10);run;*/
%mend; /* ccw */

%ccw(comorb=af);
%ccw(comorb=alzheimer);
%ccw(comorb=ami);
%ccw(comorb=anemia);
%ccw(comorb=asthma);
%ccw(comorb=cataract);
%ccw(comorb=chf);
%ccw(comorb=ckd);
%ccw(comorb=copd);
%ccw(comorb=crc);
%ccw(comorb=depre);
%ccw(comorb=diabetes);
%ccw(comorb=endometrial);
%ccw(comorb=glaucoma);
%ccw(comorb=hip);
%ccw(comorb=hta);
%ccw(comorb=hypoth);
%ccw(comorb=ihd);
%ccw(comorb=lipid);
%ccw(comorb=lung);
%ccw(comorb=osteo);
%ccw(comorb=ra);
%ccw(comorb=stroke);
%ccw(comorb=breast);


/* ER visits and hospital admissions in the previous 6m */
%macro longtransf(file=, var=);

data &var.long&i; 
length month &var.long 3 ; 
set &file&i ;
array &var.array{*} &var.1-&var.108 ;
do month=1 to 108;
	&var.long=&var.array[month];
output &var.long&i;
end;
keep bene_id month &var.long;
run;
data &var.long&i; set &var.long&i;
if &var.long ne . ; run;
/*proc print data=&var.long&i (obs=500); title "age=&i"; run;*/

%mend; /* longtransf */
%longtransf(file=anndata.ervisits , var=ervisit6m );
%longtransf(file=anndata.daysadmitted , var=daysin6m );
%longtransf(file=anndata.combinedcomorb , var=combinedscore );


/* Use of preventive services in the previous 12 months */
%macro prevtransf(var=);
/*proc print data=anndata.tvpreventive66 (obs=10);run;*/
data &var.long&i;
length month &var.long 3 ; 
set anndata.tvpreventive&i;
array &var.array{*} &var.1-&var.108 ;
do month=1 to 108;
	&var.long=&var.array[month];
output &var.long&i;
end;
keep bene_id month &var.long;
run;
data &var.long&i; set &var.long&i;
if &var.long ne . ; run;
%mend; /* prevtransf */
%prevtransf(var=crc_prev);
%prevtransf(var=cvd_prev);
%prevtransf(var=diabetes_prev);
%prevtransf(var=pelvic_prev);
%prevtransf(var=influenza);
%prevtransf(var=bonemass);
%prevtransf(var=previsit);

%end; /* loop 1 */


data x&agegroup; set x: ; run;


/* transformation to long format of the variable long term care facility */
data ltc; set ltc&frommagein-ltc&tomagein; drop firstmonthLTC ehic; run;
proc sort data=ltc nodupkey; by bene_id; run;
/*proc print data=ltc (obs=10);run;*/

%macro ccw2(comorb=); 
data ccw&comorb; set ccw&comorb&frommagein-ccw&comorb&tomagein ; drop dfo_&comorb; run;
proc sort data=ccw&comorb nodupkey; by bene_id; run;
%mend; /* ccw2 */
%ccw2(comorb=af);
%ccw2(comorb=alzheimer);
%ccw2(comorb=ami);
%ccw2(comorb=anemia);
%ccw2(comorb=asthma);
%ccw2(comorb=cataract);
%ccw2(comorb=chf);
%ccw2(comorb=ckd);
%ccw2(comorb=copd);
%ccw2(comorb=crc);
%ccw2(comorb=depre);
%ccw2(comorb=diabetes);
%ccw2(comorb=endometrial);
%ccw2(comorb=glaucoma);
%ccw2(comorb=hip);
%ccw2(comorb=hta);
%ccw2(comorb=hypoth);
%ccw2(comorb=ihd);
%ccw2(comorb=lipid);
%ccw2(comorb=lung);
%ccw2(comorb=osteo);
%ccw2(comorb=ra);
%ccw2(comorb=stroke);
%ccw2(comorb=breast);

%macro longtransf2(file= , var= );
data &var.long; set &var.long&frommagein-&var.long&tomagein; run;
proc sort data=&var.long nodupkey; by bene_id month;run;
%mend; /* longtransf2 */
%longtransf2(file=anndata.ervisits , var=ervisit6m );
%longtransf2(file=anndata.daysadmitted , var=daysin6m );
%longtransf2(file=anndata.combinedcomorb , var=combinedscore );

%macro prevtransf2(var=);
data &var.long; set &var.long&frommagein-&var.long&tomagein; run;
proc sort data=&var.long nodupkey; by bene_id month;run;
/*proc print data=&var.long (obs=10); title "&var"; run;*/
%mend; /* prevtransf2 */

%prevtransf2(var=crc_prev);
%prevtransf2(var=cvd_prev);
%prevtransf2(var=diabetes_prev);
%prevtransf2(var=pelvic_prev);
%prevtransf2(var=influenza);
%prevtransf2(var=bonemass);
%prevtransf2(var=previsit);


/*************************************************************************************************/
/* identification of the earliest eligibility date and the last month of fup for each individual */
/*************************************************************************************************/

proc sort data=x&agegroup; by bene_id descending mend; run;


data lastelig&agegroup; 
set x&agegroup; 
by bene_id; 
fobs=(first.bene_id);
if fobs=1; 
lastelig=mend;
keep bene_id lastelig;
run;

proc print data=lastelig&agegroup (obs=10); run;


proc sort data=x&agegroup; by bene_id mend; run;

data firstelig&agegroup; 
set x&agegroup; 
by bene_id; 
fobs=(first.bene_id);
if fobs=1; 
firstelig=mstartfup; 
drop fobs mstartfup mend;
run;

proc print data=firstelig&agegroup (obs=10); run;

data wholetime&agegroup; 
merge firstelig&agegroup (in=a) lastelig&agegroup; 
by bene_id; 
if a; 
run;


proc print data=wholetime&agegroup (obs=100); run;

data ids&agegroup; set wholetime&agegroup (keep=bene_id ehic) ; run;

proc sort data=ids&agegroup nodupkey; by bene_id; run; 




/* breast symptoms */

data breastsympt; set mydata.breastsympt; /* see c35_breast_symptoms.sas */
if bene_id ne ''; 
cmsym=((year(date_breastsympt)-2000)*12)+month(date_breastsympt);
run;

/*proc print data=breastsympt (obs=100);run;*/

proc transpose data=breastsympt out=breastsympt_wide (drop=_name_) prefix=cmsym;
var cmsym;
by bene_id;

proc sort data=breastsympt_wide; by bene_id; run;

data breastsympt_wide;
merge ids&agegroup (in=a) breastsympt_wide;
by bene_id; 
if a; 
run;

/*****************************************************************/
/****   DIAGNOSTIC MAMMOGRAM   ***********************************/
/*****************************************************************/

/*proc contents data=mydata.dxmammo2000; run;proc contents data=mydata.dxmammo2001; run;
proc contents data=mydata.dxmammo2002; run;proc contents data=mydata.dxmammo2003; run;
proc contents data=mydata.dxmammo2004; run;proc contents data=mydata.dxmammo2005; run;
proc contents data=mydata.dxmammo2006; run;proc contents data=mydata.dxmammo2007; run;
proc contents data=mydata.dxmammo2008; run;*/

data dxmammo2000; set mydata.dxmammo2000 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo1-cm_dxmammo6;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=dxmammo2000 (obs=10);run;*/

data dxmammo2001; set mydata.dxmammo2001 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo7-cm_dxmammo13;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=dxmammo2001 (obs=10);run;*/

data dxmammo2002; set mydata.dxmammo2002 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo14-cm_dxmammo20;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=dxmammo2002 (obs=10);run;*/

data dxmammo2003; set mydata.dxmammo2003 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo21-cm_dxmammo28;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=dxmammo2003 (obs=10);run;*/

data dxmammo2004; set mydata.dxmammo2004 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo29-cm_dxmammo35;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=dxmammo2004 (obs=10);run;*/

data dxmammo2005; set mydata.dxmammo2005 (keep=ehic date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo36-cm_dxmammo41;
do i=1 to 6;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=dxmammo2005 (obs=10);run;*/

data dxmammo2006; set mydata.dxmammo2006 (keep=bene_id date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo42-cm_dxmammo49;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=dxmammo2006 (obs=10);run;*/

data dxmammo2007; set mydata.dxmammo2007 (keep=bene_id date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo50-cm_dxmammo56;
do i=1 to 7;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=dxmammo2007 (obs=10);run;*/

data dxmammo2008; set mydata.dxmammo2008 (keep=bene_id date_dxmammo:);
array DATE{*} date_dxmammo: ; 
array CM{*} cm_dxmammo57-cm_dxmammo64;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=dxmammo2008 (obs=10);run;*/

/* differents ids, thus merging in two steps */

proc sort data=dxmammo2000; by ehic; run;
proc sort data=dxmammo2001; by ehic; run;
proc sort data=dxmammo2002; by ehic; run;
proc sort data=dxmammo2003; by ehic; run;
proc sort data=dxmammo2004; by ehic; run;
proc sort data=dxmammo2005; by ehic; run;

proc sort data= ids&agegroup; by ehic; run;

data k;
merge ids&agegroup (in=a) 
dxmammo2000 dxmammo2001 dxmammo2002 dxmammo2003 dxmammo2004 dxmammo2005 ;
by ehic;
if a; 
run;


proc sort data=dxmammo2006; by bene_id; run;
proc sort data=dxmammo2007; by bene_id; run;
proc sort data=dxmammo2008; by bene_id; run;

proc sort data=k ; by bene_id ; run;

data k;
merge k (in=a) dxmammo2006 dxmammo2007 dxmammo2008 ;
by bene_id; if a; run;

/*proc print data=k (obs=10); run;*/


data dxmammolong ;
length month 3 ; 
set k ;
array CMSM{*} cm_dxmammo1-cm_dxmammo64 ;
do i=1 to 64;
	month=CMSM[i];
output dxmammolong;
end;
run;
data dxmammolong;set dxmammolong;
if month ne '';
dxmammo=1;
keep bene_id month dxmammo; run;

proc sort data=dxmammolong nodupkey; by bene_id month; run;



/*****************************************************************/
/****   SCREENING MAMMOGRAM   ************************************/
/*****************************************************************/

/*proc contents data=mydata.scrmammo2000; run;proc contents data=mydata.scrmammo2001; run;
proc contents data=mydata.scrmammo2002; run;proc contents data=mydata.scrmammo2003; run;
proc contents data=mydata.scrmammo2004; run;proc contents data=mydata.scrmammo2005; run;
proc contents data=mydata.scrmammo2006; run;proc contents data=mydata.scrmammo2007; run;
proc contents data=mydata.scrmammo2008; run;*/

data scrmammo2000; set mydata.scrmammo2000 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo1-cm_scrmammo4;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ; run;
/*proc print data=scrmammo2000 (obs=10);run;*/

data scrmammo2001; set mydata.scrmammo2001 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo5-cm_scrmammo8;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2001 (obs=10);run;*/

data scrmammo2002; set mydata.scrmammo2002 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo9-cm_scrmammo12;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2002 (obs=10);run;*/

data scrmammo2003; set mydata.scrmammo2003 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo13-cm_scrmammo17;
do i=1 to 5;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2003 (obs=10);run;*/

data scrmammo2004; set mydata.scrmammo2004 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo18-cm_scrmammo20;
do i=1 to 3;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2004 (obs=10);run;*/

data scrmammo2005; set mydata.scrmammo2005 (keep=ehic date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo21-cm_scrmammo23;
do i=1 to 3;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep ehic cm: ;run;
/*proc print data=scrmammo2005 (obs=10);run;*/

data scrmammo2006; set mydata.scrmammo2006 (keep=bene_id date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo24-cm_scrmammo27;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=scrmammo2006 (obs=10);run;*/

data scrmammo2007; set mydata.scrmammo2007 (keep=bene_id date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo28-cm_scrmammo35;
do i=1 to 8;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=scrmammo2007 (obs=10);run;*/

data scrmammo2008; set mydata.scrmammo2008 (keep=bene_id date_scrmammo:);
array DATE{*} date_scrmammo: ; 
array CM{*} cm_scrmammo36-cm_scrmammo39;
do i=1 to 4;
	CM[i]=((year(DATE[i])-2000)*12)+month(DATE[i]);
end; keep bene_id cm: ;run;
/*proc print data=scrmammo2008 (obs=10);run;*/


/* differents ids, thus merging in two steps */

proc sort data=scrmammo2000; by ehic; run;
proc sort data=scrmammo2001; by ehic; run;
proc sort data=scrmammo2002; by ehic; run;
proc sort data=scrmammo2003; by ehic; run;
proc sort data=scrmammo2004; by ehic; run;
proc sort data=scrmammo2005; by ehic; run;

proc sort data= ids&agegroup; by ehic; run;

data k;
merge ids&agegroup (in=a) 
scrmammo2000 scrmammo2001 scrmammo2002 scrmammo2003 scrmammo2004 scrmammo2005 ;
by ehic;
if a; 
run;

proc sort data=scrmammo2006; by bene_id; run;
proc sort data=scrmammo2007; by bene_id; run;
proc sort data=scrmammo2008; by bene_id; run;

proc sort data=k ; by bene_id ; run;

data k;
merge k (in=a) scrmammo2006 scrmammo2007 scrmammo2008 ;
by bene_id; if a; run;

/*proc print data=k (obs=10); where bene_id = 'mmmmmmmJDsGaJsJ'; run;*/


data scrmammolong ;
length month 3 ; 
set k ;
array CMSM{*} cm_scrmammo1-cm_scrmammo39 ;
do i=1 to 39;
	month=CMSM[i];
output scrmammolong;
end;
run;
data scrmammolong;set scrmammolong;
if month ne '';
scrmammo=1;
keep bene_id month scrmammo; run;

proc sort data=scrmammolong nodupkey; by bene_id month; run;

/*proc print data=scrmammolong (obs=1000);
where bene_id = 'mmmmmmmJDsGaJsJ'; run;

%RETURN;*/


/* so this will be Yt+1, Ct, Lt+1, At */
/* I'll use Lt+1 because how I extracted time-varying variables, it corresponds to Lt, i.e.
if tv1=1 at month 3 it means it was measured up to the end of month 2 */


data long;
set wholetime&agegroup ;
/*mstartfup=((year(startfup)-2000)*12)+month(startfup);
mend=((year(lastfup)-2000)*12)+month(lastfup);*/
retain newid;
if _n_ = 1 then newid=0;
newid=newid+1;
dead_tplusone=0;
  do month=/*mstartfup*/ firstelig to /*mend*/ lastelig;
  if month= /*mend*/ lastelig then do;
    if month= /*mstartfup*/ firstelig then dead_tplusone=.;
    else if month > /*mstartfup*/ firstelig then do;
      if /*dead*/counteddeath=1 then dead_tplusone=1;
      else dead_tplusone=.;
    end;
  end;
output;
end;
run;


data long; 
length month2 dead_tplusone age month 3 ;
set long (keep=dead_tplusone bene_id ehic age month /*mstartfup*/ firstelig); 
month2=month-/*mstartfup*/ firstelig;
drop /*mstartfup*/ firstelig;
run;

proc sort data=long; by bene_id month; run;

data long; 
merge long (in=a) breastsympt_wide;
by bene_id; 
if a; 
bsym6m=0;
array CMS{*} cmsym: ;
do i=1 to DIM(CMS);
	if month-5<=CMS[i]< month then bsym6m=1;
	end; 
drop i cmsym: ; 
run;



data longccw;
length af_long alzheimer_long ami_long ami12_long anemia_long asthma_long cataract_long chf_long 
ckd_long copd_long crc_long depre_long diabetes_long endometrial_long glaucoma_long
hip_long hip12_long hta_long hypoth_long ihd_long lipid_long lung_long osteo_long ra_long stroke_long 
stroke12_long 3 ;
merge long (in=a) ccwbreast ccwaf ccwalzheimer ccwami ccwanemia ccwasthma ccwcataract ccwchf ccwckd
ccwcopd ccwcrc ccwdepre ccwdiabetes ccwendometrial ccwglaucoma ccwhip ccwhta ccwhypoth ccwihd
ccwlipid ccwlung ccwosteo ccwra ccwstroke ltc;
by bene_id; 
if a; 
breast_long=0;if .<monthbreast<=month then breast_long=1;
af_long=0;if .<monthaf<=month then af_long=1;
alzheimer_long=0;if .<monthalzheimer<=month then alzheimer_long=1;
ami_long=0;if .<monthami<=month then ami_long=1;
ami12_long=0;if .<monthami<=month<=(monthami+11) then ami12_long=1;
anemia_long=0;if .<monthanemia<=month then anemia_long=1;
asthma_long=0;if .<monthasthma<=month then asthma_long=1;
cataract_long=0;if .<monthcataract<=month then cataract_long=1;
chf_long=0;if .<monthchf<=month then chf_long=1;
ckd_long=0;if .<monthckd<=month then ckd_long=1;
copd_long=0;if .<monthcopd<=month then copd_long=1;
crc_long=0;if .<monthcrc<=month then crc_long=1;
depre_long=0;if .<monthdepre<=month then depre_long=1;
diabetes_long=0;if .<monthdiabetes<=month then diabetes_long=1;
endometrial_long=0;if .<monthendometrial<=month then endometrial_long=1;
glaucoma_long=0;if .<monthglaucoma<=month then glaucoma_long=1;
hip_long=0;if .<monthhip<=month then hip_long=1;
hip12_long=0;if .<monthhip<=month<=(monthhip+11) then hip12_long=1;
hta_long=0;if .<monthhta<=month then hta_long=1;
hypoth_long=0;if .<monthhypoth<=month then hypoth_long=1;
ihd_long=0;if .<monthihd<=month then ihd_long=1;
lipid_long=0;if .<monthlipid<=month then lipid_long=1;
lung_long=0;if .<monthlung<=month then lung_long=1;
osteo_long=0;if .<monthosteo<=month then osteo_long=1;
ra_long=0;if .<monthra<=month then ra_long=1;
stroke_long=0;if .<monthstroke<=month then stroke_long=1;
stroke12_long=0;if .<monthstroke<=month<=(monthstroke+11) then stroke12_long=1;
ltc_long=0;if .<monthLTC<=month then ltc_long=1;

drop monthbreast monthaf monthalzheimer monthami monthanemia monthasthma monthcataract monthchf monthckd monthcopd monthcrc
monthdepre monthdiabetes monthendometrial monthglaucoma monthhip monthhta monthhypoth monthihd monthlipid
monthlung monthosteo monthra monthstroke monthLTC;
run;


data longcovs&agegroup;
merge longccw (in=a) 
scrmammolong 
dxmammolong
ervisit6mlong 
daysin6mlong
cvd_prevlong
crc_prevlong
diabetes_prevlong
pelvic_prevlong
influenzalong
bonemasslong
previsitlong
combinedscorelong ;

by bene_id month;
if a;
if scrmammo=. then scrmammo=0;
if dxmammo=. then dxmammo=0;
/*if ervisit6mlong=. then ervisit6mlong=0;
if daysin6mlong=. then daysin6mlong=0;*/
if cvd_prevlong=. then cvd_prevlong=0;
if crc_prevlong=. then crc_prevlong=0;
if diabetes_prevlong=. then diabetes_prevlong=0;
if pelvic_prevlong=. then pelvic_prevlong=0;
if influenzalong=. then influenzalong=0;
if bonemasslong=. then bonemasslong=0;
if previsitlong=. then previsitlong=0;
/*if combinedscorelong=. then combinedscorelong=0;*/

if ervisit6mlong=. then ervisit6mlong=0 ;
if ervisit6mlong >1 then ervisit6mlong=2;

ervisit6mlong2=ervisit6mlong;
if ervisit6mlong=2 then ervisit6mlong2=1;

if daysin6mlong=. then daysin6mlong=0;
if 1<=daysin6mlong<=5 then daysin6mlong=1;
if 6<=daysin6mlong<=10 then daysin6mlong=2;
if daysin6mlong>10 then daysin6mlong=3;

daysin6mlong2=daysin6mlong;
if daysin6mlong=3 then daysin6mlong2=2;

if combinedscorelong=. then combinedscorelong=0;
if .<combinedscorelong<0 then combinedscorelong=-1;
if combinedscorelong>2 then combinedscorelong=2;
label ervisit6mlong='0=0, 1=1, 2=2+';
label ervisit6mlong2='0=0, 1=1+';
label daysin6mlong='0=0, 1=1-5, 2=6=10, 3=11+';
label daysin6mlong2='0=0, 1=1-5, 2=6+';
label combinedscorelong='-1=<0; 0=0, 1=1, 2=2+';


run;

proc sort data=longcovs&agegroup; by bene_id age month; run;



/* Addition of baseline variables */


data longcovs&agegroup;
merge longcovs&agegroup (in=a) anndata.basevars&frommagein-anndata.basevars&tomagein /*sb*/;
by bene_id age; 
if a; 



data anndata.longcovs_all&agegroup;
length anymammo tslm tslm_lag tslm_lag1 tslm_lag2 tslm_lagII tslm_lagII1 tslm_lagII2 race_c division
region daysin6m_base2 ervisit6m_base2 /*lastmammowasdx*/ /*bsym6m_base*/ lagnumberofdxmcat lagnumberofscrmcat 3; 
set longcovs&agegroup ;


race=race*1;
race_c=race;
if race>3 then race_c=3;
if race=0 then race_c=3;
if state_cd in (07,20,22,30,41,47) then division=1;
if state_cd in (31,33,39,73) then division=2;
if state_cd in (14,15,23,36,52,72) then division=3;
if state_cd in (16,17,24,26,28,35,43) then division=4;
if state_cd in (08,09,10,11,21,34,42,49,51,68,69,70,80) then division=5;
if state_cd in (01,18,25,44) then division=6;
if state_cd in (04,19,37,45,67,71,74) then division=7;
if state_cd in (03,06,13,27,29,32,46,53) then division=8;
if state_cd in (02,05,12,38,50,55) then division=9;
if state_cd in (. ,40,48,54,56:99) then division=0;

if division in (1,2) then region=1;
if division in (3,4) then region=2;
if division in (5,6,7) then region=3;
if division in (8,9,0) then region=4;
label region='1:Northeast, 2:Midwest, 3:South, 4:West'; 

ervisit6m_base2=ervisit6m_base;
if ervisit6m_base=2 then ervisit6m_base2=1;

daysin6m_base2=daysin6m_base;
if daysin6m_base=3 then daysin6m_base2=2;


if month2=0 then scrmammo=1; /* month2=0 and scrmammo=0 in 301 individuals (0.09% for some reason) */
anymammo=(sum(scrmammo,dxmammo)>0);

lagbc=lag(breast_long); 
if month2=0 then lagbc=0;
if lagbc=1 and scrmammo=1 then scrmammo=0;

retain tslm; 
if anymammo=1 then tslm=0;
else tslm=tslm+1;
tslm_lag=lag(tslm);
if month2=0 then tslm_lag=.;
if 0<=tslm_lag<=8 and scrmammo=1 then do;
	dxmammo=1;
	scrmammo=0;
	end;
%rcspline(tslm_lag,24,28,32,40); /* these splines are for the combo model */
tslm_lagII=tslm_lag;
%rcspline(tslm_lagII,13,16,25,27); /* these splines are for the single model */

/*if bsym6m_base=. then bsym6m_base=0;*/

tslm_cat=0;

if tslm_lag=11 then tslm_cat=1;
if tslm_lag=12 then tslm_cat=2;
if tslm_lag=13 then tslm_cat=3;
if tslm_lag=14 then tslm_cat=4;
if 15<=tslm_lag<=22 then tslm_cat=5;
if 23<=tslm_lag<=34 then tslm_cat=6;
if tslm_lag>34 then tslm_cat=7;


retain numberofdxm numberofscrm;
if month2=0 then numberofdxm=dxmammo;
else numberofdxm=numberofdxm+dxmammo;
numberofdxmcat=numberofdxm;
if numberofdxm>4 then numberofdxmcat=4;
lagnumberofdxmcat=lag(numberofdxmcat);
if month2=0 then lagnumberofdxmcat=0;

if month2=0 then numberofscrm=scrmammo;
else numberofscrm=numberofscrm+scrmammo;
numberofscrmcat=numberofscrm;
if numberofscrm>8 then numberofscrmcat=8;
lagnumberofscrmcat=lag(numberofscrmcat);
if month2=0 then lagnumberofscrmcat=0;



drop lagbc race state_cd 
numberofdxm numberofscrm numberofdxmcat numberofscrmcat dxmammo anymammo;
run;

proc print data=anndata.longcovs_all&agegroup (obs=500);
*var bene_id month month2 breast_long scrmammo dxmammo anymammo tslm tslm_lag; run ;

%mend; /* cann17b_all */







%macro cann17b_all_model(agegroup= ); 



%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/rcspline.sas';


/****************************************************/
/**** Denominator of the weights ********************/
/****************************************************/

/**************************************************/
/* first approach: using restricted cubic splines */
/**************************************************/




proc hplogistic data=anndata.longcovs_all&agegroup /*test*/  ;
class ervisit6mlong2 (ref='0') daysin6mlong2 (ref='0') combinedscorelong (ref='0') ervisit6m_base2 (ref='0') daysin6m_base2 (ref='0') baseline_combinedscore (ref='0') 
race_c (ref='1') region (ref='3') lagnumberofdxmcat (ref='0') lagnumberofscrmcat (ref='1') /*tslm_cat (ref='1')*/ / param=ref;
model scrmammo (descending) = 
/* time */
tslm_lagII tslm_lagII1 tslm_lagII2 month2 month2*month2 
/* baseline */
 age age*age year_base year_base*year_base race_c region

ervisit6m_base2 daysin6m_base2 baseline_combinedscore
cvd_prev_base crc_prev_base diabetes_prev_base pelvic_prev_base influenza_base bonemass_base previsit_base     

AF_base CHF_base CKD_base COPD_base CRC_base LTC_base alzheimer_base anemia_base ami12_base asthma_base cataract_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base stroke12_base RA_base

/* tv */
ervisit6mlong2 daysin6mlong2 combinedscorelong 
cvd_prevlong crc_prevlong diabetes_prevlong pelvic_prevlong influenzalong bonemasslong previsitlong 
af_long alzheimer_long ami12_long anemia_long asthma_long cataract_long chf_long
ckd_long copd_long crc_long depre_long diabetes_long endometrial_long glaucoma_long hip12_long hta_long
hypoth_long ihd_long lipid_long lung_long osteo_long ra_long stroke12_long ltc_long 
bsym6m lagnumberofdxmcat lagnumberofscrmcat  ;  
where tslm_lag >=11;
output out = model_scrmammo_rcs copyvar=(bene_id month month2 scrmammo tslm tslm_lag) p=p_scrmammo_rcs;
title "model with just rcs";
run;

data anndata.pred_scrmammo_rcs_all&agegroup; set model_scrmammo_rcs;
keep bene_id month p_scrmammo_rcs;run;

proc sort data=anndata.pred_scrmammo_rcs_all&agegroup; by bene_id month ;run;


%mend; /* c17b_all_model */


%cann17b_all(frommagein=70, tomagein=84, agegroup=7084);

%cann17b_all_model(agegroup=7084);




