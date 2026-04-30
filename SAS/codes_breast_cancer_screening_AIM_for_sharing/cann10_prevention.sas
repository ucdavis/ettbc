/********************************************************************************(*******/
/* Code to extract preventive services use 						*/
/* Note that this code calls the linkages cann09_* 					*/
/*******************************************************************************(********/

options mprint notes compress=yes;
/*libname mydata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/';*/

libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';

%macro cann10(agein= );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann10_logsANDlsts/cann10_prevention&agein..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann10_logsANDlsts/cann10_prevention&agein..log" new; run;

%macro dx1y(margindays= ,
icd9_pr_set1=  ,hcpcs_set1= , label_pr1= ,
icd9_pr_set2=  ,hcpcs_set2= , label_pr2= ,
icd9_pr_set3=  ,hcpcs_set3= , label_pr3= ,
icd9_pr_set4=  ,hcpcs_set4= , label_pr4= ,
icd9_pr_set5=  ,hcpcs_set5= , label_pr5= ,
icd9_pr_set6=  ,hcpcs_set6= , label_pr6= ,
icd9_pr_set7=  ,hcpcs_set7= , label_pr7= ,
icd9_pr_set8=  ,hcpcs_set8= , label_pr8= ,
icd9_pr_set9=  ,hcpcs_set9= , label_pr9= ,
icd9_pr_set10=  ,hcpcs_set10= , label_pr10= ,
icd9_pr_set11=  ,hcpcs_set11= , label_pr11= ,
icd9_pr_set12=  ,hcpcs_set12= , label_pr12= ,
icd9_pr_set13=  ,hcpcs_set13= , label_pr13= ,
icd9_pr_set14=  ,hcpcs_set14= , label_pr14= ,
icd9_pr_set15=  ,hcpcs_set15= , label_pr15= ,
icd9_pr_set16=  ,hcpcs_set16= , label_pr16= ,
icd9_pr_set17=  ,hcpcs_set17= , label_pr17= , );

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann09_1_link_op.sas';
%bildu_op(daysbeforeinclusion= 366, agein=&agein);

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann09_2_link_ip.sas';
%bildu_ip(daysbeforeinclusion= 366, agein=&agein);

%include '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann09_3_link_car.sas';
%bildu_car(daysbeforeinclusion= 366, agein=&agein);


data ids;
set anndata.box8_baseline&agein (keep = bene_id);
run;

proc sort data=ids;by bene_id;run;



%do i=1 %to 108;


/* from constant part of claims: icd9 proc and diagnoses, OUTPATIENT */
data prev_op_c;
length &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17 3 ;
set anndata.enrolled&agein._c_op_d366  /*(obs=1000000)*/  ;

upbound=INTNX( 'MONTH', mdy(1,1,1999), &i+11, 'SAME' );
lowbound=INTNX( 'MONTH', mdy(1,1,1999), &i-1, 'SAME' );

if .<lowbound <= thru_dt < upbound;

/*if .<(inclusion_date-366)<thru_dt<=(inclusion_date+&margindays);  */

ARRAY ICDP[25] icd_prcdr_cd1-icd_prcdr_cd25;
do j=1 to 25;
if ICDP[j] in &icd9_pr_set1 then &label_pr1=1;if ICDP[j] in &icd9_pr_set2 then &label_pr2=1;
if ICDP[j] in &icd9_pr_set3 then &label_pr3=1;if ICDP[j] in &icd9_pr_set4 then &label_pr4=1;
if ICDP[j] in &icd9_pr_set5 then &label_pr5=1;if ICDP[j] in &icd9_pr_set6 then &label_pr6=1;
if ICDP[j] in &icd9_pr_set7 then &label_pr7=1;if ICDP[j] in &icd9_pr_set8 then &label_pr8=1;
if ICDP[j] in &icd9_pr_set9 then &label_pr9=1;if ICDP[j] in &icd9_pr_set10 then &label_pr10=1;
if ICDP[j] in &icd9_pr_set11 then &label_pr11=1;if ICDP[j] in &icd9_pr_set12 then &label_pr12=1;
if ICDP[j] in &icd9_pr_set13 then &label_pr13=1;if ICDP[j] in &icd9_pr_set14 then &label_pr14=1;
if ICDP[j] in &icd9_pr_set15 then &label_pr15=1;if ICDP[j] in &icd9_pr_set16 then &label_pr16=1;
if ICDP[j] in &icd9_pr_set17 then &label_pr17=1;
end;

prevention=(sum(&label_pr1,&label_pr2,&label_pr3,&label_pr4,&label_pr5,&label_pr6,&label_pr7,&label_pr8,&label_pr9,
&label_pr10,&label_pr11,&label_pr12,&label_pr13,&label_pr14,&label_pr15,&label_pr16,&label_pr17  ) > 0);
if prevention = 1;
keep bene_id &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17;

run;

/*proc print data=prev_op_c&i (obs=2000);
var bene_id lowbound thru_dt upbound;
title "i=&i";
run;*/



/* from revenue-recurrent part of claims: icd9 proc and diagnoses, OUTPATIENT */
data prev_op_r;
length &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17 3 ;
set anndata.enrolled&agein._r_op_d366   /*(obs=1000000)*/  ;

upbound=INTNX( 'MONTH', mdy(1,1,1999), &i+11, 'SAME' );
lowbound=INTNX( 'MONTH', mdy(1,1,1999), &i-1, 'SAME' );

if .<lowbound <= thru_dt < upbound;

/*if .<(inclusion_date-366)<thru_dt<=(inclusion_date+&margindays);  */

if hcpcs_cd in &hcpcs_set1 then &label_pr1=1;if hcpcs_cd in &hcpcs_set2 then &label_pr2=1;
if hcpcs_cd in &hcpcs_set3 then &label_pr3=1;if hcpcs_cd in &hcpcs_set4 then &label_pr4=1;
if hcpcs_cd in &hcpcs_set5 then &label_pr5=1;if hcpcs_cd in &hcpcs_set6 then &label_pr6=1;
if hcpcs_cd in &hcpcs_set7 then &label_pr7=1;if hcpcs_cd in &hcpcs_set8 then &label_pr8=1;
if hcpcs_cd in &hcpcs_set9 then &label_pr9=1;if hcpcs_cd in &hcpcs_set10 then &label_pr10=1;
if hcpcs_cd in &hcpcs_set11 then &label_pr11=1;if hcpcs_cd in &hcpcs_set12 then &label_pr12=1;
if hcpcs_cd in &hcpcs_set13 then &label_pr13=1;if hcpcs_cd in &hcpcs_set14 then &label_pr14=1;
if hcpcs_cd in &hcpcs_set15 then &label_pr15=1;if hcpcs_cd in &hcpcs_set16 then &label_pr16=1;
if hcpcs_cd in &hcpcs_set17 then &label_pr17=1;

prevention=(sum(&label_pr1,&label_pr2,&label_pr3,&label_pr4,&label_pr5,&label_pr6,&label_pr7,&label_pr8,&label_pr9,
&label_pr10,&label_pr11,&label_pr12,&label_pr13,&label_pr14,&label_pr15,&label_pr16,&label_pr17  ) > 0);
if prevention = 1;
keep bene_id &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17;
run;



/* from revenue-recurrent part of claims: icd9 proc and diagnoses, CARRIER */
data prev_car_r;
length &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17 3 ;
set anndata.enrolled&agein._r_car_d366    /*( obs=1000000 )*/     ;

upbound=INTNX( 'MONTH', mdy(1,1,1999), &i+11, 'SAME' );
lowbound=INTNX( 'MONTH', mdy(1,1,1999), &i-1, 'SAME' );

if .<lowbound <= thru_dt < upbound;

/*if .<(inclusion_date-366)<thru_dt<=(inclusion_date+&margindays);  */
	
if hcpcs_cd in &hcpcs_set1 then &label_pr1=1;if hcpcs_cd in &hcpcs_set2 then &label_pr2=1;
if hcpcs_cd in &hcpcs_set3 then &label_pr3=1;if hcpcs_cd in &hcpcs_set4 then &label_pr4=1;
if hcpcs_cd in &hcpcs_set5 then &label_pr5=1;if hcpcs_cd in &hcpcs_set6 then &label_pr6=1;
if hcpcs_cd in &hcpcs_set7 then &label_pr7=1;if hcpcs_cd in &hcpcs_set8 then &label_pr8=1;
if hcpcs_cd in &hcpcs_set9 then &label_pr9=1;if hcpcs_cd in &hcpcs_set10 then &label_pr10=1;
if hcpcs_cd in &hcpcs_set11 then &label_pr11=1;if hcpcs_cd in &hcpcs_set12 then &label_pr12=1;
if hcpcs_cd in &hcpcs_set13 then &label_pr13=1;if hcpcs_cd in &hcpcs_set14 then &label_pr14=1;
if hcpcs_cd in &hcpcs_set15 then &label_pr15=1;if hcpcs_cd in &hcpcs_set16 then &label_pr16=1;
if hcpcs_cd in &hcpcs_set17 then &label_pr17=1;

prevention=(sum(&label_pr1,&label_pr2,&label_pr3,&label_pr4,&label_pr5,&label_pr6,&label_pr7,&label_pr8,&label_pr9,
&label_pr10,&label_pr11,&label_pr12,&label_pr13,&label_pr14,&label_pr15,&label_pr16,&label_pr17  ) > 0);
if prevention = 1;
keep bene_id &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17;
run;


/* DO NOT DELETE THEM HERE BECAUSE THEY'LL BE USED BY c11_comorbidity_score.sas */
/*proc datasets library=mydata;
   delete enrolled_c_car_d731 enrolled_r_car_d731;
quit;*/


/* stacking */

data a&i;
set  prev_op_c  prev_op_r  prev_car_r;
run;


proc datasets library=work;
   delete prev_op_c prev_op_r prev_car_r;
run;


/*proc freq data=a; table  &label_pr1 &label_pr2 &label_pr3 &label_pr4 &label_pr5 &label_pr6 &label_pr7 &label_pr8 &label_pr9 
&label_pr10 &label_pr11 &label_pr12 &label_pr13 &label_pr14 &label_pr15 &label_pr16 &label_pr17 /missing;run;*/



/* extracting each of the symptoms/procs to delete duplicates */


data d&label_pr1; set a&i (rename=(&label_pr1=&label_pr1.&i)); if &label_pr1.&i=1;keep bene_id &label_pr1.&i;run; proc sort data=d&label_pr1 nodupkey;by bene_id;run;
data d&label_pr2; set a&i (rename=(&label_pr2=&label_pr2.&i)); if &label_pr2.&i=1;keep bene_id &label_pr2.&i;run; proc sort data=d&label_pr2 nodupkey;by bene_id;run;
data d&label_pr3; set a&i (rename=(&label_pr3=&label_pr3.&i)); if &label_pr3.&i=1;keep bene_id &label_pr3.&i;run; proc sort data=d&label_pr3 nodupkey;by bene_id;run;
data d&label_pr4; set a&i (rename=(&label_pr4=&label_pr4.&i)); if &label_pr4.&i=1;keep bene_id &label_pr4.&i;run; proc sort data=d&label_pr4 nodupkey;by bene_id;run;
data d&label_pr5; set a&i (rename=(&label_pr5=&label_pr5.&i)); if &label_pr5.&i=1;keep bene_id &label_pr5.&i;run; proc sort data=d&label_pr5 nodupkey;by bene_id;run;
data d&label_pr6; set a&i (rename=(&label_pr6=&label_pr6.&i)); if &label_pr6.&i=1;keep bene_id &label_pr6.&i;run; proc sort data=d&label_pr6 nodupkey;by bene_id;run;
data d&label_pr7; set a&i (rename=(&label_pr7=&label_pr7.&i)); if &label_pr7.&i=1;keep bene_id &label_pr7.&i;run; proc sort data=d&label_pr7 nodupkey;by bene_id;run;
data d&label_pr8; set a&i (rename=(&label_pr8=&label_pr8.&i)); if &label_pr8.&i=1;keep bene_id &label_pr8.&i;run; proc sort data=d&label_pr8 nodupkey;by bene_id;run;
data d&label_pr9; set a&i (rename=(&label_pr9=&label_pr9.&i)); if &label_pr9.&i=1;keep bene_id &label_pr9.&i;run; proc sort data=d&label_pr9 nodupkey;by bene_id;run;
data d&label_pr10; set a&i (rename=(&label_pr10=&label_pr10.&i)); if &label_pr10.&i=1;keep bene_id &label_pr10.&i;run; proc sort data=d&label_pr10 nodupkey;by bene_id;run;
data d&label_pr11; set a&i (rename=(&label_pr11=&label_pr11.&i)); if &label_pr11.&i=1;keep bene_id &label_pr11.&i;run; proc sort data=d&label_pr11 nodupkey;by bene_id;run;
data d&label_pr12; set a&i (rename=(&label_pr12=&label_pr12.&i)); if &label_pr12.&i=1;keep bene_id &label_pr12.&i;run; proc sort data=d&label_pr12 nodupkey;by bene_id;run;
data d&label_pr13; set a&i (rename=(&label_pr13=&label_pr13.&i)); if &label_pr13.&i=1;keep bene_id &label_pr13.&i;run; proc sort data=d&label_pr13 nodupkey;by bene_id;run;
data d&label_pr14; set a&i (rename=(&label_pr14=&label_pr14.&i)); if &label_pr14.&i=1;keep bene_id &label_pr14.&i;run; proc sort data=d&label_pr14 nodupkey;by bene_id;run;
data d&label_pr15; set a&i (rename=(&label_pr15=&label_pr15.&i)); if &label_pr15.&i=1;keep bene_id &label_pr15.&i;run; proc sort data=d&label_pr15 nodupkey;by bene_id;run;
data d&label_pr16; set a&i (rename=(&label_pr16=&label_pr16.&i)); if &label_pr16.&i=1;keep bene_id &label_pr16.&i;run; proc sort data=d&label_pr16 nodupkey;by bene_id;run;
data d&label_pr17; set a&i (rename=(&label_pr17=&label_pr17.&i)); if &label_pr17.&i=1;keep bene_id &label_pr17.&i;run; proc sort data=d&label_pr17 nodupkey;by bene_id;run;

proc datasets library=work; delete a&i ;run;



data x&i;
merge ids (in=a) d&label_pr1 d&label_pr2 d&label_pr3 d&label_pr4 d&label_pr5 d&label_pr6 d&label_pr7 d&label_pr8 d&label_pr9 
d&label_pr10 d&label_pr11 d&label_pr12 d&label_pr13 d&label_pr14 d&label_pr15 d&label_pr16 d&label_pr17;
by bene_id;
if a;
run;

proc datasets lib=work; delete d&label_pr1 d&label_pr2 d&label_pr3 d&label_pr4 d&label_pr5 d&label_pr6 d&label_pr7 d&label_pr8 d&label_pr9 
d&label_pr10 d&label_pr11 d&label_pr12 d&label_pr13 d&label_pr14 d&label_pr15 d&label_pr16 d&label_pr17; run;

%end;

data anndata.tvpreventive&agein;
merge ids (in=a) x: ; 
run;

proc freq data=anndata.tvpreventive&agein;
table &label_pr1: &label_pr2: &label_pr3: &label_pr4: &label_pr5: &label_pr6: &label_pr7: &label_pr8: &label_pr9: 
&label_pr10: &label_pr11: &label_pr12: &label_pr13: &label_pr14: &label_pr15: &label_pr16: &label_pr17: /missing;run;



%mend; /* %dx2y */


%dx1y(margindays=0, /* days away from date_inclusion to extract diagnoses */

label_pr1=pneumococo, 
icd9_pr_set1=('none'),
hcpcs_set1=('4040F','90732','90669','G0009','G8864'),

label_pr2=influenza, 
icd9_pr_set2=('9952'), 
hcpcs_set2=('90655','90656','90657','90658','90660','90659','4037F','G0008','G8482',
'G8636','G9141','G9142','Q2035','Q2036','Q2037','Q2038','Q2039'),

label_pr3=mammo_prev, 
icd9_pr_set3=('none'), 
hcpcs_set3=('76092','77052','77057','G0202'),

label_pr4=crc_prev, /* fecal tests, sigmo and colonoscopy */
icd9_pr_set4=('4522','4523','4525', /*colono */
'4524' /* sigmo */),
hcpcs_set4=('82270','82272','82274','G0328','G0107', /*fobt*/
'45378','45380','45381','45382','45383','45384','45385','45386','45387','45391','45392','G0105','G0121', /* colono */
'45330','45331','45333','45334','45335','45338','45339','45340','45341','45342' /*sigmo */),

label_pr5=previsit,
icd9_pr_set5=('none'),
hcpcs_set5=('99387','99397','99401','99402','99403','99404','99405','99406','99407',
'99408','99409','G0402','G0403','G0404','G0405','G0438','G0439'),

label_pr6=bonemass, 
icd9_pr_set6=('none'),
hcpcs_set6=('76977','77078','77079','76070','76071','77080','76075','76076','77081','G0130'),

label_pr7=obesity_prev, 
icd9_pr_set7=('V8530','V8531','V8532','V8533','V8534','V8535','V8536','V8537','V8538','V8539','V8541','V8542','V8543','V8544','V8545'),
hcpcs_set7=('G0447','G0473'),

label_pr8=pelvic_prev, 
icd9_pr_set8=('V7231','V762','V7647','V7649','V1589'),
hcpcs_set8=('G0101','G0123','G0124','G0141','G0143','G0144','G0145','G0147','G0148','P3000','P3001','Q0091'),

label_pr9=cvd_prev, 
icd9_pr_set9=('V810','V811','V812'),
hcpcs_set9=('80061','82465','83718','84478'),

label_pr10=tobacco, 
icd9_pr_set10=('3051','V1582'),
hcpcs_set10=('G0436','G0437'),

label_pr11=diabetes_prev, 
icd9_pr_set11=('V771'),
hcpcs_set11=('82947','82950','82951'),

label_pr12=glaucoma_prev, 
icd9_pr_set12=('V801'),
hcpcs_set12=('G0117','G0118'),

label_pr13=ibt_cvd, 
icd9_pr_set13=('none'),
hcpcs_set13=('G0446'),

label_pr14=AAA_prev, 
icd9_pr_set14=('none'),
hcpcs_set14=('G0389'),

label_pr15=alcohol_prev, 
icd9_pr_set15=('none'),
hcpcs_set15=('G0442','G0443'),

label_pr16=depre_prev, 
icd9_pr_set16=('none'),
hcpcs_set16=('G0444'),

label_pr17=mnt_prev, 
icd9_pr_set17=('none'),
hcpcs_set17=('97802','97803','97804','G0270','G0271')

);

proc datasets lib=work kill memtype=data;run;

%mend; /* %cann10 */

/*%cann10(agein= 84);*/

