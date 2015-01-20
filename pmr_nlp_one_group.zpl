#optimize PMR accross all cows: minimize total sum of (relative) requirement violations
# set limits solutions 2
# set numerics feastol 0.001

set Feeds := { "GS", "MS", "SY", "WH" };
set Nutrients := { "NEL", "uCP"};
set FeedAttributes := Nutrients + { "RNB", "FV", "GSR", "UFL" };
set Cows := { 1,10,15,20,25,30,35,40 };
set CowAttributes := { "PLPOT", "IC", "UFL", "NEL", "uCP", "parity", "BWC" };

param cc_intake_max := 0.4;
param energy_weight := 10;

param feed_data[Feeds * FeedAttributes] :=
     |"NEL", "uCP", "RNB", "FV" , "GSR", "UFL"|
|"GS"| 5.9 , 135  , 6    , 0.978, 0    , 0.885|     
|"MS"| 6.9 , 136  , -9   , 0.978, 0    , 0.899|
|"SY"| 9.9 , 250  , 24   , 0    , 0.55 , 0    |
|"WH"| 8.5 , 170  , -5   , 0    , 0.55 , 0    |;

param cow_data[Cows * CowAttributes] :=
  |"PLPOT", "IC" , "UFL", "NEL", "uCP", "parity", "BWC" |
|1 |17.937,  8.996, 11.126,  83.464, 1809.722, 1, -0.664|
#|2 |21.046, 11.311, 12.416,  92.344, 1951.971, 1, -0.480|
#|3 |21.205, 12.463, 12.840,  94.670, 1952.242, 1, -0.302|
#|4 |20.440, 12.934, 13.055,  95.335, 1901.638, 1, -0.117|
#|5 |19.317, 13.136, 13.079,  94.742, 1841.836, 1,  0.022|
#|6 |18.033, 13.202, 12.907,  93.018, 1823.985, 1,  0.087|
#|7 |16.644, 13.199, 12.710,  91.066, 1778.238, 1,  0.155|
#|8 |15.317, 13.169, 12.554,  89.436, 1739.088, 1,  0.220|
#|9 |13.986, 13.136, 12.444,  88.142, 1706.697, 1,  0.288|
|10|12.769, 13.113, 12.403,  87.411, 1686.068, 1,  0.353|
#|11|11.584, 13.098, 12.449,  87.357, 1678.325, 1,  0.421|
#|12|10.523, 13.080, 12.607,  88.211, 1686.771, 1,  0.486|
#|13| 9.542, 13.015, 12.915,  90.288, 1713.494, 1,  0.551|
#|14|25.470, 13.172, 14.313, 107.214, 2404.585, 2, -0.738|
|15|26.947, 15.410, 15.430, 113.981, 2397.340, 2, -0.378|
#|16|24.422, 15.716, 15.502, 112.664, 2222.772, 2, -0.008|
#|17|21.117, 15.537, 14.497, 104.799, 2077.020, 2,  0.061|
#|18|17.926, 15.211, 13.554,  97.402, 1926.440, 2,  0.122|
#|19|14.951, 14.867, 12.755,  91.085, 1798.388, 2,  0.184|
|20|12.357, 14.565, 12.178,  86.478, 1705.218, 2,  0.247|
#|21|10.199, 14.309, 11.886,  84.112, 1654.877, 2,  0.308|
#|22| 8.337, 13.961, 11.971,  84.764, 1652.150, 2,  0.371|
#|23|21.538, 12.448, 13.511, 101.184, 2352.955, 3, -0.837|
#|24|27.999, 14.533, 15.753, 117.499, 2622.384, 3, -0.700|
|25|29.889, 15.772, 16.511, 122.648, 2675.932, 3, -0.562|
#|26|30.096, 16.552, 16.779, 124.070, 2656.110, 3, -0.425|
#|27|29.509, 16.836, 16.823, 123.805, 2599.545, 3, -0.297|
#|28|28.415, 16.926, 16.757, 122.653, 2519.604, 3, -0.159|
#|29|27.049, 16.902, 16.637, 121.067, 2429.596, 3, -0.022|
|30|25.538, 16.806, 16.174, 117.404, 2340.522, 3,  0.017|
#|31|23.965, 16.656, 15.676, 113.612, 2282.881, 3,  0.039|
#|32|22.382, 16.474, 15.160, 109.650, 2199.742, 3,  0.060|
#|33|20.825, 16.278, 14.664, 105.835, 2119.750, 3,  0.081|
#|34|19.408, 16.089, 14.223, 102.442, 2048.671, 3,  0.101|
|35|17.959, 15.891, 13.784,  99.057, 1977.851, 3,  0.122|
#|36|16.581, 15.699, 13.381,  95.946, 1912.848, 3,  0.144|
#|37|15.280, 15.516, 13.018,  93.137, 1854.213, 3,  0.165|
#|38|14.058, 15.344, 12.697,  90.657, 1802.433, 3,  0.186|
#|39|12.916, 15.183, 12.422,  88.537, 1757.967, 3,  0.208|
|40|11.852, 15.029, 12.198,  86.815, 1721.275, 3,  0.229|
;

set Forages := { <f> in Feeds with feed_data[f, "GSR"] == 0 };
set Concentrates := { <f> in Feeds with feed_data[f, "GSR"] > 0 };
do print Forages;
do print Concentrates;

var surplus[Cows * Nutrients] real;
var deficit[Cows * Nutrients] real;
var intake_kg[Feeds] real;
var intake_extra_conc_kg[Cows * Concentrates] real;
var intake_conc_total[Cows] real;
var intake_scale[Cows] real;
subto fix_scale: intake_scale[20] == 1;
var gsr[Cows] real;

var ffvs real;
var fufl real;
var fkgs real;
var def real;
var e_def real;
var sqrt_plpot[Cows] real;
var gsr_zero[Cows] real;

defnumb d(c) := if (cow_data[c, "parity"] > 1) then 1.10 else 0.96 end;  

maximize satisfaction: sum <c,n> in Cows * Nutrients: 
  if (n == "NEL") then
    -1 * energy_weight * (surplus[c,n] + deficit[c,n])
  else
    -1 * (surplus[c,n] + deficit[c,n])
  end;

subto need: forall <c,n> in Cows * Nutrients do
  intake_scale[c] * sum <f> in Feeds: feed_data[f,n] / cow_data[c,n] * intake_kg[f] + 
  sum <k> in Concentrates: feed_data[k,n] / cow_data[c,n] * intake_extra_conc_kg[c, k]
  == 1 + surplus[c,n] - deficit[c,n];

subto intake: forall <c> in Cows do
  intake_scale[c] *
  sum <f> in Feeds: 
    if (feed_data[f, "GSR"] == 0) then
      feed_data[f, "FV"] * intake_kg[f] * fkgs
    else
      gsr[c] * intake_kg[f] * ffvs + 
      gsr[c] * intake_extra_conc_kg[c, f] * ffvs
    end  <= cow_data[c,"IC"] * fkgs;

subto rnb: forall <c> in Cows do
  0 <= sum <f> in Feeds: feed_data[f, "RNB"] * intake_scale[c] * intake_kg[f] + sum <k> in Concentrates: feed_data[k, "RNB"] * intake_extra_conc_kg[c, k] <= 50;

subto conc_max: forall <c> in Cows do
  sum <f> in Feeds:
    if (feed_data[f, "GSR"] > 0) then
      (1 - cc_intake_max) / cc_intake_max * intake_scale[c] * intake_kg[f] + (1 - cc_intake_max) / cc_intake_max * intake_extra_conc_kg[c, f] 
    else
      - intake_scale[c] * intake_kg[f] end <= 0;

subto forage_fvs: sum <fr> in Forages: feed_data[fr, "FV"] * intake_kg[fr] - ffvs == 0;
subto forage_ufl: sum <fr> in Forages: feed_data[fr, "UFL"] * intake_kg[fr] - fufl == 0;
subto forage_kgs: sum <fr> in Forages: intake_kg[fr] - fkgs == 0;
subto forage_def: fufl - ffvs * def == 0;
subto conc_intake: forall <c> in Cows do
  sum <k> in Concentrates: intake_scale[c] * intake_kg[k] + 
  sum <k> in Concentrates: intake_extra_conc_kg[c, k] - intake_conc_total[c] == 0;
subto gsr: forall <c> in Cows do
      if (cow_data[c, "BWC"] < 0) then
        -0.43 + 1.82 * gsr_zero[c] + 0.035 * intake_conc_total[c] - 0.00053 * cow_data[c, "PLPOT"] * intake_conc_total[c]
      else
        gsr_zero[c]
      end == gsr[c];

subto def: exp(1.32 * def) == e_def;
# ZIMPL does only accept integer exponents: PLPOT^-0.62 -> exp(-0.62*ln(PLPOT))
subto plpot:  forall <c> in Cows do exp(-0.62*ln(cow_data[c, "PLPOT"])) == sqrt_plpot[c];
subto gsr_zero:  forall <c> in Cows do d(c) * sqrt_plpot[c] * e_def == gsr_zero[c];
