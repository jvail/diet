# Copywrite (C) 2015 Jan Vaillant <jan.vaillant@zalf.de>
# Licensed under the MIT licence

# NLP implementation of TMR problem
# For simplicity we assume one cow in each group

# solved with scip 3.1.0 (64bit) 
# build with gcc 4.7.2 including Ipopt 3.11.9 and coinhsl 2014.01.10
# 
# solution status: optimal solution found
# objective value:                   -0.106661610193143
# surplus#1$P                        0.0852538373581339   (obj:-1)
# surplus#2$P                        0.0214077728350102   (obj:-1)
# kg#1$GS                              11.1909807648654   (obj:0)
# kg#1$MS                                           2.5   (obj:0)
# kg#1$WH                             0.988707921684836   (obj:0)
# kg#2$GS                                11.96492543074   (obj:0)
# kg#2$WH                              4.38881822029244   (obj:0)

set Feeds := { "GS", "MS", "SY", "WH" };
set Nutrients := { "E", "P"};
set FeedAttributes := Nutrients + { "RNB", "FV", "isCC", "UFL" };
set Groups := { 1, 2 }; # one 'focus cow' in each group
set CowAttributes := { "PLPOT", "IC", "E", "P", "parity", "BWC"};

param feed_data[Feeds * FeedAttributes] :=
     |"E"  , "P"  , "RNB", "FV" , "isCC", "UFL"|
|"GS"| 6.10, 135.0,  3   , 1.061, 0     , 0.809| 
|"MS"| 7.20, 138.0, -11  , 0.911, 0     , 0.930|
|"SY"| 9.90, 250.0,  24  , 0    , 1     , 0    |
|"WH"| 8.50, 170.0, -5   , 0    , 1     , 0    |;
#      (NEL) (uCP)  (N)    (UEL)  (bool)  (UFL)

param cow_data[Groups * CowAttributes] :=
  |"PLPOT", "IC"  , "E"    , "P"     , "parity", "BWC" |
|1|15.899 , 14.676, 94.669 , 1864.875,  1      ,  0.201|
|2|25.346 , 14.517, 110.291, 2311.872,  2      , -0.347|;
#  (kg)     (UEL)   (NEL)    (uCP)      (#)       (kg)   (#) 
  
param max_c[Groups] := <1> 0.4, <2> 0.4; # max. fraction of concentrate in diet [DM DM-1]
param weight_n[Groups * Nutrients] := <1,"E"> 10, <1,"P"> 1, <2,"E"> 10, <2,"P"> 1;

set Concentrates := { <f> in Feeds with feed_data[f, "isCC"] > 0 };
set Forages := { Feeds \ Concentrates };

var surplus[Groups * Nutrients] real;
var deficit[Groups * Nutrients] real;
var kg[Groups * Feeds] real;

var gsr[Groups] real;       # global substitution rate
var kg_f[Groups] real;      # sum kg forages in diet
var kg_c[Groups] real;      # sum kg concentrate intake
var fv_fs[Groups] real;     # sum forage fill values in diet
var ufl_f[Groups] real;     # sum UFL in diet
var def[Groups] real;       # UFL density in forages in diet
var gsr_plpot[Groups] real; # GSR eq. part I  (animal related)
var gsr_def[Groups] real;   # GSR eq. part II (diet related)
var gsr_zero[Groups] real;  # GSR zero
var fv_f[Groups] real;      # average forage fill value in diet 
var fv_c[Groups] real;      # concentrate fill value in diet

defnumb d(c) := if (cow_data[c, "parity"] > 1) then 1.10 else 0.96 end;  

maximize satisfaction: sum <c,n> in Groups * Nutrients:
  weight_n[c, n] * -(surplus[c,n] + deficit[c,n]);

subto need: forall <c,n> in Groups * Nutrients do
  sum <f> in Feeds: feed_data[f,n] / cow_data[c,n] * kg[c,f] - surplus[c,n] + deficit[c,n] == 1;

subto intake: forall <c> in Groups do
  sum <fr> in Forages: 
    feed_data[fr, "FV"] * kg[c,fr] +
  sum <k> in Concentrates: 
    fv_c[c] * kg[c,k]
  == cow_data[c,"IC"];

subto rnb: forall <c> in Groups do
  0 <= sum <f> in Feeds: feed_data[f, "RNB"] * kg[c,f] <= 50;

subto conc_max: forall <c> in Groups do
  sum <k> in Concentrates: 
    (1 - max_c[c]) / max_c[c] * kg[c,k] -
  sum <fr> in Forages: 
    kg[c,fr] 
  <= 0;

# GSR & concentrate FV calculation.
# Split into several constraints (better to debug and read)

subto forage_fill_values: forall <c> in Groups do 
  sum <fr> in Forages: feed_data[fr, "FV"] * kg[c,fr] == fv_fs[c];

subto forage_ufl: forall <c> in Groups do
  sum <fr> in Forages: feed_data[fr, "UFL"] * kg[c,fr] == ufl_f[c];

subto forage_kgs: forall <c> in Groups do 
  sum <fr> in Forages: kg[c,fr] == kg_f[c];

subto forage_def: forall <c> in Groups do
  ufl_f[c] - fv_fs[c] * def[c] == 0;

subto conc_kgs: forall <c> in Groups do
  sum <k> in Concentrates: kg[c,k] == kg_c[c];

subto gsr_def: forall <c> in Groups do
  exp(1.32 * def[c]) == gsr_def[c];

# ZIMPL does only accept integer exponents:
#   PLPOT^-0.62 -> exp(-0.62*ln(PLPOT))

subto gsr_plpot: forall <c> in Groups do 
  exp(-0.62*ln(cow_data[c, "PLPOT"])) == gsr_plpot[c];
  
subto gsr_zero: forall <c> in Groups do 
  d(c) * gsr_plpot[c] * gsr_def[c] == gsr_zero[c];

subto gsr: forall <c> in Groups do
  if (cow_data[c, "BWC"] < 0) then # cow is mobilizing 
    -0.43 + 1.82 * gsr_zero[c] + 0.035 * kg_c[c] - 0.00053 * cow_data[c, "PLPOT"] * kg_c[c]
  else
    gsr_zero[c]
  end == gsr[c];

subto fv_f: forall <c> in Groups do 
  fv_fs[c] == fv_f[c] * kg_f[c];

subto fv_c: forall <c> in Groups do 
  gsr[c] * fv_f[c] == fv_c[c];

subto max_ms: sum <c> in Groups:
  kg[c,"MS"] <= 2.5;
