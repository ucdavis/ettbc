/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* Arrangement of baseline variables			    **/
/*********************************************************************/


options mprint notes compress=yes varlenchk=nowarn;

/*libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";*/
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';



%macro alltogether();

%do i=70 %to 84;
	data cloned&i;
	set anndata.cloned12m&i /*(where=(arm ne 'STOPCOIN'))*/;
	age=&i;
	run;
%end;

data all;
set cloned70-cloned84 ;
bc=(mstartfup <= monthBC <= mend);
run;


proc print data=all (obs=100);run;

data singleids; set all; run;
proc sort nodupkey; by bene_id; run;
proc means data=singleids n; var age; title "number of unique individuals"; run;


proc freq data=all; table arm / missing; run;

proc freq data=all; table bc*arm; title 'total number BC'; run;

proc freq data=all; table bc*arm; title 'total number BC'; where 70<=age<=74; title '70-74';run;
proc freq data=all; table bc*arm; title 'total number BC'; where 75<=age<=79; title '75-79';run;
proc freq data=all; table bc*arm; title 'total number BC'; where 80<=age<=84; title '80-84';run;

proc means data=all sum mean; var fup; where arm='STOPBASE'; title 'STOPBASE';run;

proc means data=all sum mean; var fup; where arm='CONTINUE'; title 'CONTINUE';run;

proc means data=all sum mean p50 p25 p75; var fup; title 'all';run;

proc freq data=all noprint;
table bene_id / out=n; run;

proc means data=n mean p50 min max; var count;title 'individual contribution to trials'; run;

%mend;

%alltogether();

endsas;

%macro cann12_5(agein1= ,agein2=, agein3=, agein4=, agein5= , agegroup=  );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_5_logsANDlsts/cann12_5_base&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_5_logsANDlsts/cann12_5_base&agegroup..log" new;run;

/*proc contents data=anndata.basevars&agein1; run;
proc contents data=anndata.basevars&agein2; run;
proc contents data=anndata.basevars&agein3; run;
proc contents data=anndata.basevars&agein4; run;*/

data base&agegroup;
set anndata.basevars&agein1 anndata.basevars&agein2 anndata.basevars&agein3 anndata.basevars&agein4 anndata.basevars&agein5;

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
label race_c='1:White, 2:Black, 3:Other';
label division='1:New England, 2:Middle Atlantic, 3:East North Central, 4:West North Central, 5:South Atlantic, 6: East South Central, 
7:West South Central, 8:Mountain, 9:Pacific, 0:Non Census Division';
run;


/* baseline description -- table 1 */
proc freq data=base&agegroup;
table race_c division

year_base

ervisit6m_base daysin6m_base   
pneumococo_base influenza_base bonemass_base cvd_prev_base diabetes_prev_base previsit_base crc_prev_base pelvic_prev_base    

ltc_base

baseline_combinedscore baseline_combinedscore2

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base  / missing;
run;




%mend; /* c12_5 */



%cann12_5(agein1=70, agein2=71, agein3=72, agein4=73, agein5=74, agegroup=7074);
%cann12_5(agein1=75, agein2=76, agein3=77, agein4=78, agein5=79, agegroup=7579);
%cann12_5(agein1=80, agein2=81, agein3=82, agein4=83, agein5=84, agegroup=8084);




%macro cann12_5ag(agein1=, agein2=, agein3=, agein4=, agein5=, agein6=, agein7=, agein8=, agein9=, agein10=, agegroup=   );

proc printto print="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_5_logsANDlsts/cann12_5_base&agegroup..lst" new; run;
proc printto log="/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/programs/CODES_FOR_ANNALS_REVIEW/cann12_5_logsANDlsts/cann12_5_base&agegroup..log" new;run;

/*proc contents data=anndata.basevars&agein1; run;
proc contents data=anndata.basevars&agein2; run;
proc contents data=anndata.basevars&agein3; run;
proc contents data=anndata.basevars&agein4; run;*/

data base&agegroup;
set anndata.basevars&agein1 anndata.basevars&agein2 anndata.basevars&agein3 anndata.basevars&agein4 anndata.basevars&agein5 anndata.basevars&agein6 anndata.basevars&agein7 anndata.basevars&agein8 anndata.basevars&agein9 anndata.basevars&agein10;

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
label race_c='1:White, 2:Black, 3:Other';
label division='1:New England, 2:Middle Atlantic, 3:East North Central, 4:West North Central, 5:South Atlantic, 6: East South Central, 
7:West South Central, 8:Mountain, 9:Pacific, 0:Non Census Division';
run;


/* baseline description -- table 1 */
proc freq data=base&agegroup;
table race_c division

year_base

ervisit6m_base daysin6m_base   
pneumococo_base influenza_base bonemass_base cvd_prev_base diabetes_prev_base previsit_base crc_prev_base pelvic_prev_base    

ltc_base

baseline_combinedscore baseline_combinedscore2

alzheimer_base ami12_base AF_base anemia_base asthma_base cataract_base CHF_base CKD_base COPD_base CRC_base depre_base diabetes_base endometrial_base glaucoma_base hip12_base HTA_base hypoth_base IHD_base 
lipid_base lung_base osteo_base RA_base stroke12_base  / missing;
run;


proc datasets lib=work kill memtype=data;run;

%mend; /* c12_5 */



%cann12_5ag(agein1=75, agein2=76, agein3=77, agein4=78, agein5=79, 
	agein6=80, agein7=81, agein8=82, agein9=83, agein10=84, agegroup=7584);