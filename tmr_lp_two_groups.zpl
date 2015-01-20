# LP implementation of TMR problem
# For simplicity we assume one cow in each group
# The concentrate fill value (FVC) has been estimated with dairy.js (dairy.intake.FV_cs_diet)
# and is corrected by 0.05 (the average overestimation we find when calculating diets 
# using dairy.js forage database)

# solved with scip 3.1.0 (64bit) 
# build with gcc 4.7.2 including Ipopt 3.11.9 and coinhsl 2014.01.10
#
# solution status: optimal solution found
# objective value:                   -0.105761941317059
# surplus#1$P                        0.0860620000740139   (obj:-1)
# surplus#2$P                         0.019699941243044   (obj:-1)
# kg#1$GS                              11.3069132606174   (obj:0)
# kg#1$MS                                           2.5   (obj:0)
# kg#1$WH                             0.905509307086318   (obj:0)
# kg#2$GS                              11.6612109662645   (obj:0)
# kg#2$WH                              4.60677801244548   (obj:0)

set Feeds := { "GS", "MS", "SY", "WH" };
set Nutrients := { "E", "P"};
set FeedAttributes := Nutrients + { "RNB", "FV", "isCC" };
set Groups := { 1, 2 }; # one 'focus cow' in each group
set CowAttributes := { "PLPOT", "IC", "E", "P", "parity", "BWC", "FVC"};

param feed_data[Feeds * FeedAttributes] :=
     |"E"  , "P"  , "RNB", "FV" , "isCC"|
|"GS"| 6.10, 135.0,  3   , 1.061, 0     | 
|"MS"| 7.20, 138.0, -11  , 0.911, 0     |
|"SY"| 9.90, 250.0,  24  , 0    , 1     |
|"WH"| 8.50, 170.0, -5   , 0    , 1     |;
#      (NEL) (uCP)  (N)    (UEL)  (bool)

param cow_data[Groups * CowAttributes] :=
  |"PLPOT", "IC"  , "E"    , "P"     , "parity", "BWC" , "FVC"        |
|1|15.899 , 14.676, 94.669 , 1864.875,  1      ,  0.201, (0.4938-0.05)|
|2|25.346 , 14.517, 110.291, 2311.872,  2      , -0.347, (0.5155-0.05)|;
#  (kg)     (UEL)   (NEL)    (uCP)      (#)       (kg)   (UEL) 
  
param max_c[Groups] := <1> 0.4, <2> 0.4; # max. fraction of concentrate in diet [DM DM-1]
param weight_n[Groups * Nutrients] := <1,"E"> 10, <1,"P"> 1, <2,"E"> 10, <2,"P"> 1;

set Concentrates := { <f> in Feeds with feed_data[f, "isCC"] > 0 };
set Forages := { Feeds \ Concentrates };

var surplus[Groups * Nutrients] real;
var deficit[Groups * Nutrients] real;
var kg[Groups * Feeds] real;

maximize satisfaction: sum <c,n> in Groups * Nutrients:
  weight_n[c, n] * -(surplus[c,n] + deficit[c,n]);

subto need: forall <c,n> in Groups * Nutrients do
  sum <f> in Feeds: feed_data[f,n] / cow_data[c,n] * kg[c,f] - surplus[c,n] + deficit[c,n] == 1;

subto intake: forall <c> in Groups do
  sum <fr> in Forages: 
    feed_data[fr, "FV"] * kg[c,fr] +
  sum <k> in Concentrates: 
    cow_data[c, "FVC"] * kg[c,k]
  == cow_data[c,"IC"];

subto rnb: forall <c> in Groups do
  0 <= sum <f> in Feeds: feed_data[f, "RNB"] * kg[c,f] <= 50;

subto conc_max: forall <c> in Groups do
  sum <k> in Concentrates: 
    (1 - max_c[c]) / max_c[c] * kg[c,k] -
  sum <fr> in Forages: 
    kg[c,fr] 
  <= 0;

subto max_ms: sum <c> in Groups:
  kg[c,"MS"] <= 2.5;
