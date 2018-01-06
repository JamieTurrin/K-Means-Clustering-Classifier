* James Turrin
* June 2017
* Program to classify body motion data from a Samsung smart phone;
* 79 variables of body motion, measured for 30 subjects and 6 activities,;
* yields 180 observations each of 79 variables.;
* The 6 activities are LAYING, SITTING, STANDING, WALKING, WALKING UPSTAIRS, WALKING DOWNSTAIRS;

* Because the activities are known before hand, this will be a supervised cluster analysis.
************************************************************************************************;
*************************************************************************************************;

DATA train;  

* where to find data, skip first line, data begins at line 2;
INFILE '/home/jturrin0/Body_Motion_Means.txt' FIRSTOBS = 2;  

* how to read the data, Activity is in columns 1-22, then 79 numeric variables;
INPUT Activity $ 1-22 var1-var79;

* Re-label activity for simplicity;		
IF FIND(Activity, 'LAYING') GE 1 THEN Active = 1;
IF FIND(Activity, 'SITTING') GE 1 THEN Active = 2;
IF FIND(Activity, 'STANDING') GE 1 THEN Active = 3;
IF FIND(Activity, 'DOWNSTAIRS') GE 1 THEN Active = 4;
IF FIND(Activity, 'UPSTAIRS') GE 1 THEN Active = 5;
IF FIND(Activity, 'WALKING') GE 1 THEN Active = 6;

idnum = _N_;  * id for merging datasets later;

* parse data into the two datasets based on # iterations of DATA step _N_;
* each dataset will have 90 observations of 79 variables, 15 observations for each of the 6 activities;		
*IF MOD(_N_,2) = 0 THEN OUTPUT test;
*ELSE OUTPUT train;
RUN;


* standardize training data;
PROC STANDARD DATA=train  OUT=train_standardized MEAN=0  STD=1;
VAR var1-var79;
RUN;

* Since this is a supervised cluster analysis, I know before hand there are 6 clusters;
* one cluster for each activity, so I don't need to perform clustering for k=1,2,3,4,5;
* Just run clustering for k=6;
PROC FASTCLUS DATA=train_standardized  
OUT=cluster_data
OUTSTAT=cluster_stats
MAXCLUSTERS=6
MAXITER=300;
VAR var1-var79;
RUN;

* compute 1st and 2nd canonical discriminant variables for plotting purposes;
PROC CANDISC DATA=cluster_data ANOVA OUT=canonical_data;
CLASS cluster;  *categorical variable, cluster number;
VAR var1-var79;
RUN;

* plot canonical variables to see clusters;
PROC SGPLOT DATA=canonical_data;
SCATTER Y=Can2 X=Can1 / 
MARKERATTRS = (SYMBOL = CIRCLEFILLED  SIZE = 2MM)
GROUP=Cluster;
TITLE 'Canonical Variables Identified by Cluster';
RUN;

* better cluster separation is seen by plotting Can4 vs Can3;
PROC SGPLOT DATA=canonical_data;
SCATTER Y=Can4 X=Can3 / 
MARKERATTRS = (SYMBOL = CIRCLEFILLED  SIZE = 2MM)
GROUP=Cluster;
TITLE 'Canonical Variables Identified by Cluster';
RUN;

* sort datasets by idnum before merging;
PROC SORT DATA=train; BY idnum; RUN;
PROC SORT DATA=cluster_data; BY idnum; RUN;

* merge datasets so I can run ANOVA on clustering results to see if clusters are significant;
DATA merged;
MERGE train cluster_data;
BY idnum;
RUN;

* Run ANOVA to see if there are significant differences between clusters;
PROC ANOVA DATA=merged;
CLASS cluster Active;  * categorical variable;
MODEL Active=cluster;
MEANS cluster/tukey;
RUN;








