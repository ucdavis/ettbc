/*********************************************************************/
/** Project: BREAST screening project 				    **/
/* create the appropriate datasets for plotting the incidence using the program */
/*	cann17_XXX_incidence_byagegroup2groups.r	    **/
/*********************************************************************/


libname mydata "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data";
libname anndata '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review';
libname myCCW '/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/firstCCW/';




data firstendometrial; 
set myCCW.first70endometrial myCCW.first71endometrial myCCW.first72endometrial myCCW.first73endometrial 
myCCW.first74endometrial myCCW.first75endometrial myCCW.first76endometrial myCCW.first77endometrial 
myCCW.first78endometrial myCCW.first79endometrial myCCW.first80endometrial myCCW.first81endometrial 
myCCW.first82endometrial myCCW.first83endometrial myCCW.first84endometrial; 
monthENDO=((year(dfo_endometrial)-2000)*12)+month(dfo_endometrial);

proc sort data=firstendometrial nodupkey; by bene_id; run;

proc print data=firstendometrial (obs=20); run;


data firstlung; 
set myCCW.first70lung myCCW.first71lung myCCW.first72lung myCCW.first73lung 
myCCW.first74lung myCCW.first75lung myCCW.first76lung myCCW.first77lung 
myCCW.first78lung myCCW.first79lung myCCW.first80lung myCCW.first81lung 
myCCW.first82lung myCCW.first83lung myCCW.first84lung; 
monthLUNG=((year(dfo_lung)-2000)*12)+month(dfo_lung);

proc sort data=firstlung nodupkey; by bene_id; run;

proc print data=firstlung (obs=20); run;


data firstcrc; 
set myCCW.first70crc myCCW.first71crc myCCW.first72crc myCCW.first73crc 
myCCW.first74crc myCCW.first75crc myCCW.first76crc myCCW.first77crc 
myCCW.first78crc myCCW.first79crc myCCW.first80crc myCCW.first81crc 
myCCW.first82crc myCCW.first83crc myCCW.first84crc; 
monthCRC=((year(dfo_crc)-2000)*12)+month(dfo_crc);

proc sort data=firstcrc nodupkey; by bene_id; run;

proc print data=firstcrc (obs=20); run;



%macro c17b (agegroup=);





%do j=70 %to 84;

proc sort data=anndata.cloned12m&j; by bene_id; run;

data a&j; 
merge anndata.cloned12m&j (in=a) firstendometrial firstlung firstcrc; 
by bene_id; 
if a; 

if mstartfup <= monthENDO <= mend then do; 
fupmonthENDO=monthENDO-mstartfup;
end;
if mstartfup <= monthLUNG <= mend then do; 
fupmonthLUNG=monthLUNG-mstartfup;
end; 
if mstartfup <= monthCRC <= mend then do; 
fupmonthCRC=monthCRC-mstartfup;
end;
drop dfo_: ; 
run;



PROC EXPORT DATA= WORK.a&j 
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/cloned12m&j..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

%end;




data long12m&agegroup; 
set anndata.long12m&agegroup; 
run;

proc sort data=long12m&agegroup; by bene_id; run;

data long12m&agegroup; 
merge long12m&agegroup (in=a) firstendometrial firstlung firstcrc; 
by bene_id; 
if a; 
if monthENDO=month then endo_long=1;
if monthLUNG=month then lung_long=1;
if monthCRC=month then crc_long=1;
run;


proc freq data=long12m&agegroup;
table bc_long endo_long lung_long crc_long / missing;
run;




%do i=0 %to 107;


/* arm=STOPBASE */
proc freq data=long12m&agegroup; table bc_long / missing out=mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;

proc freq data=long12m&agegroup; table endo_long / missing out=endo_mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;

proc freq data=long12m&agegroup; table lung_long / missing out=lung_mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;

proc freq data=long12m&agegroup; table crc_long / missing out=crc_mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;


/*proc print data=mSTOPBASE&i;run;*/

data mSTOPBASE&i; set mSTOPBASE&i; percent&i=percent; if bc_long=1; keep percent&i; run;

data endo_mSTOPBASE&i; set endo_mSTOPBASE&i; percent&i=percent; if endo_long=1; keep percent&i; run;

data lung_mSTOPBASE&i; set lung_mSTOPBASE&i; percent&i=percent; if lung_long=1; keep percent&i; run;

data crc_mSTOPBASE&i; set crc_mSTOPBASE&i; percent&i=percent; if crc_long=1; keep percent&i; run;


/*proc print data=mSTOPBASE&i;run;*/

/* arm=CONTINUE */
proc freq data=long12m&agegroup; table bc_long / missing out=mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;

proc freq data=long12m&agegroup; table endo_long / missing out=endo_mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;

proc freq data=long12m&agegroup; table lung_long / missing out=lung_mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;

proc freq data=long12m&agegroup; table crc_long / missing out=crc_mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;


data mCONTINUE&i; set mCONTINUE&i; percent&i=percent; if bc_long=1; keep percent&i; run;

data endo_mCONTINUE&i; set endo_mCONTINUE&i; percent&i=percent; if endo_long=1; keep percent&i; run;

data lung_mCONTINUE&i; set lung_mCONTINUE&i; percent&i=percent; if lung_long=1; keep percent&i; run;

data crc_mCONTINUE&i; set crc_mCONTINUE&i; percent&i=percent; if crc_long=1; keep percent&i; run;

%end;


data BCdxSTOPBASE; merge mSTOPBASE0-mSTOPBASE107;run;
proc print data=BCdxSTOPBASE;run;

PROC EXPORT DATA= WORK.BCdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/BCdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;


data ENDOdxSTOPBASE; merge endo_mSTOPBASE0-endo_mSTOPBASE107;run;
proc print data=ENDOdxSTOPBASE;run;

PROC EXPORT DATA= WORK.ENDOdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/ENDOdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data LUNGdxSTOPBASE; merge lung_mSTOPBASE0-lung_mSTOPBASE107;run;
proc print data=LUNGdxSTOPBASE;run;

PROC EXPORT DATA= WORK.LUNGdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/LUNGdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data CRCdxSTOPBASE; merge crc_mSTOPBASE0-crc_mSTOPBASE107;run;
proc print data=CRCdxSTOPBASE;run;

PROC EXPORT DATA= WORK.CRCdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/CRCdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;



data BCdxCONTINUE; merge mCONTINUE0-mCONTINUE107;run;
proc print data=BCdxCONTINUE;run;

PROC EXPORT DATA= WORK.BCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/BCdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data ENDOBCdxCONTINUE; merge endo_mCONTINUE0-endo_mCONTINUE107;run;
proc print data=ENDOBCdxCONTINUE;run;

PROC EXPORT DATA= WORK.ENDOBCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/ENDOdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data LUNGBCdxCONTINUE; merge lung_mCONTINUE0-lung_mCONTINUE107;run;
proc print data=LUNGBCdxCONTINUE;run;

PROC EXPORT DATA= WORK.LUNGBCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/LUNGdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data CRCBCdxCONTINUE; merge crc_mCONTINUE0-crc_mCONTINUE107;run;
proc print data=CRCBCdxCONTINUE;run;

PROC EXPORT DATA= WORK.CRCBCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/CRCdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;



%mend;


%c17b(agegroup=7074);


/******************* 10y *******************/

%macro c17b_10y(agegroup=);


data long12m&agegroup;
set anndata.long12m7579 anndata.long12m8084;
run;


proc sort data=long12m&agegroup; by bene_id; run;

data long12m&agegroup; 
merge long12m&agegroup (in=a) firstendometrial firstlung firstcrc; 
by bene_id; 
if a; 
if monthENDO=month then endo_long=1;
if monthLUNG=month then lung_long=1;
if monthCRC=month then crc_long=1;
run;


proc freq data=long12m&agegroup;
table bc_long endo_long lung_long crc_long / missing;
run;


%do i=0 %to 107;


/* arm=STOPBASE */
proc freq data=long12m&agegroup; table bc_long / missing out=mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;

proc freq data=long12m&agegroup; table endo_long / missing out=endo_mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;

proc freq data=long12m&agegroup; table lung_long / missing out=lung_mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;

proc freq data=long12m&agegroup; table crc_long / missing out=crc_mSTOPBASE&i;
where month2=&i AND arm='STOPBASE'; run;


/*proc print data=mSTOPBASE&i;run;*/

data mSTOPBASE&i; set mSTOPBASE&i; percent&i=percent; if bc_long=1; keep percent&i; run;

data endo_mSTOPBASE&i; set endo_mSTOPBASE&i; percent&i=percent; if endo_long=1; keep percent&i; run;

data lung_mSTOPBASE&i; set lung_mSTOPBASE&i; percent&i=percent; if lung_long=1; keep percent&i; run;

data crc_mSTOPBASE&i; set crc_mSTOPBASE&i; percent&i=percent; if crc_long=1; keep percent&i; run;


/*proc print data=mSTOPBASE&i;run;*/

/* arm=CONTINUE */
proc freq data=long12m&agegroup; table bc_long / missing out=mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;

proc freq data=long12m&agegroup; table endo_long / missing out=endo_mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;

proc freq data=long12m&agegroup; table lung_long / missing out=lung_mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;

proc freq data=long12m&agegroup; table crc_long / missing out=crc_mCONTINUE&i;
where month2=&i AND arm='CONTINUE'; run;


data mCONTINUE&i; set mCONTINUE&i; percent&i=percent; if bc_long=1; keep percent&i; run;

data endo_mCONTINUE&i; set endo_mCONTINUE&i; percent&i=percent; if endo_long=1; keep percent&i; run;

data lung_mCONTINUE&i; set lung_mCONTINUE&i; percent&i=percent; if lung_long=1; keep percent&i; run;

data crc_mCONTINUE&i; set crc_mCONTINUE&i; percent&i=percent; if crc_long=1; keep percent&i; run;

%end;


data BCdxSTOPBASE; merge mSTOPBASE0-mSTOPBASE107;run;
proc print data=BCdxSTOPBASE;run;

PROC EXPORT DATA= WORK.BCdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/BCdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;


data ENDOdxSTOPBASE; merge endo_mSTOPBASE0-endo_mSTOPBASE107;run;
proc print data=ENDOdxSTOPBASE;run;

PROC EXPORT DATA= WORK.ENDOdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/ENDOdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data LUNGdxSTOPBASE; merge lung_mSTOPBASE0-lung_mSTOPBASE107;run;
proc print data=LUNGdxSTOPBASE;run;

PROC EXPORT DATA= WORK.LUNGdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/LUNGdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data CRCdxSTOPBASE; merge crc_mSTOPBASE0-crc_mSTOPBASE107;run;
proc print data=CRCdxSTOPBASE;run;

PROC EXPORT DATA= WORK.CRCdxSTOPBASE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/CRCdxSTOPBASE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;



data BCdxCONTINUE; merge mCONTINUE0-mCONTINUE107;run;
proc print data=BCdxCONTINUE;run;

PROC EXPORT DATA= WORK.BCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/BCdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data ENDOBCdxCONTINUE; merge endo_mCONTINUE0-endo_mCONTINUE107;run;
proc print data=ENDOBCdxCONTINUE;run;

PROC EXPORT DATA= WORK.ENDOBCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/ENDOdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data LUNGBCdxCONTINUE; merge lung_mCONTINUE0-lung_mCONTINUE107;run;
proc print data=LUNGBCdxCONTINUE;run;

PROC EXPORT DATA= WORK.LUNGBCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/LUNGdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

data CRCBCdxCONTINUE; merge crc_mCONTINUE0-crc_mCONTINUE107;run;
proc print data=CRCBCdxCONTINUE;run;

PROC EXPORT DATA= WORK.CRCBCdxCONTINUE
            OUTFILE= "/disk/agedisk3/medicare.work/newhouse-DUA25730/xabi/BC_screening/data/annals_review/CRCdxCONTINUE12m&agegroup..csv"
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;


%mend;


%c17b_10y(agegroup=7584);



