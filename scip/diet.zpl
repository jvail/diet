# Diet model for optimal feedstuff allocation within and across dairy cow groups and time periods
# -----------------------------------------------------------------------------------------------
#
# Example diet model solved with SCIP 3.1.0 (http://scip.zib.de/) using the German feed evaluation system (NEL, uCP, RNB)
# for two periods (T; 1-t), with two groups (G; 1-i) of cows (i.e. four different diets) and two (representative) cows 
# (C; 1-l) per group. Resulting diets may contain two feeds (F; 1-j) and two concentrates (K; 1-m)
#
# Example with two types of feeding systems: Total and enhanced/partial (aufgewertete Mischration) mixed ration. Scaling
# forage intake in a partial mixed ration requires a quadratic constraint.
#
# Objective
# ---------
# Create cow feed rations for all periods as such that the absolute (relative %) difference between cow/group
# requirements (energy, protein) and diets is minimized.
#
# Abbreviations
# ------------- 
#   - s.. surplus
#   - d.. deficit
#   - E energy (here NEL)
#   - P protein (here uCP)
#
# Constraints
# -----------
#   - E_.. & P_..: (feed nutrient content / total nutrient requirements) [nutrient unit kg-1 cow-1]
#   - IC_..: fill value (dry matter intake index)
#   - RNB_..: ruminal N balance; recommendation 0 <= RNB <= 50
#   - K_.._max: pc. of total dry matter intake: here 40% (maximum under organic farming regulations) 
#     (K1 + Km) / (K1 + Km + F1 + Fj) = 0.4 <=> 0.6 / 0.4 * K1 + 0.6 / 0.4 * Km = F1 + Fj
#
# Data (used to calculate coefficients)
# -------------------------------------
#
#   Forages
#   -------
#   F1 (Grass-clover, 1st growth, early mature): 
#   DM: 350, DOM: 73, NEL: 5.9, CP: 175, uCP: 135, RNB: 6, FV: 0.914
#   Fj (Maize silage, whole plant, medium quality):
#   DM: 330, DOM: 73, NEL: 6.9, CP: 77.7, uCP: 136, RNB: -9, FV: 0.962
#
#   Concentrates
#   ------------ 
#   K1 (Soybean seeds, heat treated):
#   DM: 900, DOM: 86, NEL: 9.9, CP: 400, uCP: 250, RNB: 24, FV: 0.55
#   Km (Wheat, grain):
#   DM: 880, DOM: 89, NEL: 8.5, CP: 140, uCP: 170, RNB: -5, FV: 0.55
#
#   Cows (intake and requirements for two cows in G1P1, G1Pt, GiP1, GiPt) 
#   ---------------------------------------------------------------------
#   IC: (15.25, 16.91), (17.20, 16.95), (16.60, 16.23), (15.85, 15.42)
#   uCP: (2399, 2330), (2274, 2198), (2135, 2097), (2070, 2069)
#   NEL: (111, 110), (108, 103), (99, 97), (95, 95) 


# declare variables and parameters

# decision variables (taking surpluses and deficits)
var sE_C1G1T1 real;
var dE_C1G1T1 real;
var sP_C1G1T1 real;
var dP_C1G1T1 real;

var sE_ClG1T1 real;
var dE_ClG1T1 real;
var sP_ClG1T1 real;
var dP_ClG1T1 real;

var sE_C1G1Tt real;
var dE_C1G1Tt real;
var sP_C1G1Tt real;
var dP_C1G1Tt real;

var sE_ClG1Tt real;
var dE_ClG1Tt real;
var sP_ClG1Tt real;
var dP_ClG1Tt real;

var sE_C1GiT1 real;
var dE_C1GiT1 real;
var sP_C1GiT1 real;
var dP_C1GiT1 real;

var sE_ClGiT1 real;
var dE_ClGiT1 real;
var sP_ClGiT1 real;
var dP_ClGiT1 real;

var sE_C1GiTt real;
var dE_C1GiTt real;
var sP_C1GiTt real;
var dP_C1GiTt real;

var sE_ClGiTt real;
var dE_ClGiTt real;
var sP_ClGiTt real;
var dP_ClGiTt real; 

# forage and concentrate contents of a diet in kg DM
var F1_G1T1 real;
var Fj_G1T1 real;
var K1_G1T1 real;
var Km_G1T1 real;

var F1_G1Tt real;
var Fj_G1Tt real;
var K1_G1Tt real;
var Km_G1Tt real;

var F1_GiT1 real;
var Fj_GiT1 real;
var K1_C1GiT1 real;
var Km_C1GiT1 real;
var K1_ClGiT1 real;
var Km_ClGiT1 real;

var F1_GiTt real;
var Fj_GiTt real;
var K1_C1GiTt real;
var Km_C1GiTt real;
var K1_ClGiTt real;
var Km_ClGiTt real;

# scale factor for enhanced/partial mixed rations (quadratic constraint)
var z_C1GiT1 real;
var z_C1GiTt real;

# weight: no. of cows represented by cow 1-l (here same no. for all cows across all groups and periods)
param w := 10;

# lower and upper bound of RNB
param RNB_lo := 0;
param RNB_up := 50;


# minimize deviations of energy (E) and utilizable crude protein (P) in diets from total requirements across groups and periods
maximize obj: 
- w*sE_C1G1T1 - w*dE_C1G1T1 - w*sP_C1G1T1 - w*dP_C1G1T1 - w*sE_ClG1T1 - w*dE_ClG1T1 - w*sP_ClG1T1 - w*dP_ClG1T1 # cows 1-l in group 1 & periode 1
- w*sE_C1G1Tt - w*dE_C1G1Tt - w*sP_C1G1Tt - w*dP_C1G1Tt - w*sE_ClG1Tt - w*dE_ClG1Tt - w*sP_ClG1Tt - w*dP_ClG1Tt # cows 1-l in group 1 & periode t
- w*sE_C1GiT1 - w*dE_C1GiT1 - w*sP_C1GiT1 - w*dP_C1GiT1 - w*sE_ClGiT1 - w*dE_ClGiT1 - w*sP_ClGiT1 - w*dP_ClGiT1 # cows 1-l in group i & periode 1 
- w*sE_C1GiTt - w*dE_C1GiTt - w*sP_C1GiTt - w*dP_C1GiTt - w*sE_ClGiTt - w*dE_ClGiTt - w*sP_ClGiTt - w*dP_ClGiTt # cows 1-l in group i & periode t
; 

# group 1 (total mixed ration i.e. including concentrates)

  # in period 1

    # cow 1

      # NEL and uCP deviations
      subto E_C1G1T1: - sE_C1G1T1 + dE_C1G1T1 + 15.25 / ((15.25 + 16.91) / 2.0) * (0.0532*F1_G1T1 + 0.0622*Fj_G1T1 + 0.0892*K1_G1T1 + 0.0766*Km_G1T1) == 1.0;
      subto P_C1G1T1: - sP_C1G1T1 + dP_C1G1T1 + 15.25 / ((15.25 + 16.91) / 2.0) * (0.0563*F1_G1T1 + 0.0567*Fj_G1T1 + 0.1042*K1_G1T1 + 0.0709*Km_G1T1) == 1.0;
      
      # RNB
      subto RNB_C1G1T1: RNB_lo <= 15.25 / ((15.25 + 16.91) / 2.0) * (6.0*F1_G1T1 - 9.0*Fj_G1T1 + 25.0*K1_G1T1 - 5.0*Km_G1T1) <= RNB_up;

    # cow l

      # NEL and uCP deviations
      subto E_ClG1T1: - sE_ClG1T1 + dE_ClG1T1 +  16.91 / ((15.25 + 16.91) / 2.0) * (0.0536*F1_G1T1 + 0.0627*Fj_G1T1 + 0.0900*K1_G1T1 + 0.0773*Km_G1T1) == 1.0;
      subto P_ClG1T1: - sP_ClG1T1 + dP_ClG1T1 +  16.91 / ((15.25 + 16.91) / 2.0) * (0.0579*F1_G1T1 + 0.0584*Fj_G1T1 + 0.1073*K1_G1T1 + 0.0730*Km_G1T1) == 1.0;

      # RNB
      subto RNB_ClG1T1: RNB_lo <= 16.91 / ((15.25 + 16.91) / 2.0) * (6.0*F1_G1T1 - 9.0*Fj_G1T1 + 25.0*K1_G1T1 - 5.0*Km_G1T1) <= RNB_up;

    # intake constraint: average reference dry matter intake
    subto IC_G1T1: + 0.91*F1_G1T1 + 0.96*Fj_G1T1 + 0.55*K1_G1T1 + 0.55*Km_G1T1 == (15.25 + 16.91) / 2.0;

    # concentrate constraint
    subto K_G1T1_max: 1.5 * (K1_G1T1 + Km_G1T1) - F1_G1T1 - Fj_G1T1 <= 0;

  # in period t

    # cow 1

      # NEL and uCP deviations
      subto E_C1G1Tt: - sE_C1G1Tt + dE_C1G1Tt + 17.20 / ((17.20 + 16.95) / 2.0) * (0.0546*F1_G1Tt + 0.0639*Fj_G1Tt + 0.0917*K1_G1Tt + 0.0787*Km_G1Tt) == 1.0;
      subto P_C1G1Tt: - sP_C1G1Tt + dP_C1G1Tt + 17.20 / ((17.20 + 16.95) / 2.0) * (0.0594*F1_G1Tt + 0.0598*Fj_G1Tt + 0.1099*K1_G1Tt + 0.0748*Km_G1Tt) == 1.0;

      # RNB
      subto RNB_C1G1Tt: RNB_lo <= 17.20 / ((17.20 + 16.95) / 2.0) * (6.0*F1_G1Tt - 9.0*Fj_G1Tt + 25.0*K1_G1Tt - 5.0*Km_G1Tt) <= RNB_up;

    # cow l

      # NEL and uCP deviations
      subto E_ClG1Tt: - sE_ClG1Tt + dE_ClG1Tt + 16.95 / ((17.20 + 16.95) / 2.0) * (0.0573*F1_G1Tt + 0.0670*Fj_G1Tt + 0.0961*K1_G1Tt + 0.0825*Km_G1Tt) == 1.0;
      subto P_ClG1Tt: - sP_ClG1Tt + dP_ClG1Tt + 16.95 / ((17.20 + 16.95) / 2.0) * (0.0614*F1_G1Tt + 0.0619*Fj_G1Tt + 0.1137*K1_G1Tt + 0.0773*Km_G1Tt) == 1.0;

      # RNB
      subto RNB_ClG1Tt: RNB_lo <= 16.95 / ((17.20 + 16.95) / 2.0) * (6.0*F1_G1Tt - 9.0*Fj_G1Tt + 25.0*K1_G1Tt - 5.0*Km_G1Tt) <= RNB_up;

    # intake constraint: average reference dry matter intake
    subto IC_G1Tt: + 0.91*F1_G1Tt + 0.96*Fj_G1Tt + 0.55*K1_G1Tt + 0.55*Km_G1Tt == (17.20 + 16.95) / 2.0;

    # concentrate constraint
    subto K_G1Tt_max: 1.5 * (K1_G1Tt + Km_G1Tt) - F1_G1Tt - Fj_G1Tt <= 0;


# group i (enhanced/partial mixed ration i.e. separate concentrates)
# assumption: it is technically possible to feed different concentrate mixtures individually for cows within one group

  # period 1

    # cow 1

      # NEL and uCP deviations
      subto E_C1GiT1: - sE_C1GiT1 + dE_C1GiT1 + z_C1GiT1 * (0.0596*F1_GiT1 + 0.0697*Fj_GiT1) + 0.1000*K1_C1GiT1 + 0.0859*Km_C1GiT1 == 1.0;
      subto P_C1GiT1: - sP_C1GiT1 + dP_C1GiT1 + z_C1GiT1 * (0.0632*F1_GiT1 + 0.0637*Fj_GiT1) + 0.1171*K1_C1GiT1 + 0.0796*Km_C1GiT1 == 1.0;

      # RNB
      subto RNB_C1GiT1: RNB_lo <= z_C1GiT1 * (6.0*F1_GiT1 - 9.0*Fj_GiT1) + 25.0*K1_C1GiT1 - 5.0*Km_C1GiT1 <= RNB_up;

      # intake constraint
      subto IC_C1GiT1: z_C1GiT1 * (0.91*F1_GiT1 + 0.96*Fj_GiT1) + 0.55*K1_C1GiT1 + 0.55*Km_C1GiT1 == 16.60;

      # concentrate constraint
      subto K_C1G1T1_max: 1.5 * (K1_C1GiT1 + Km_C1GiT1) - z_C1GiT1 * (F1_GiT1 + Fj_GiT1) <= 0;

    # cow l

      # NEL and uCP deviations
      subto E_ClGiT1: - sE_ClGiT1 + dE_ClGiT1 + 0.0608*F1_GiT1 + 0.0711*Fj_GiT1 + 0.1021*K1_ClGiT1 + 0.0876*Km_ClGiT1 == 1.0;
      subto P_ClGiT1: - sP_ClGiT1 + dP_ClGiT1 + 0.0644*F1_GiT1 + 0.0649*Fj_GiT1 + 0.1192*K1_ClGiT1 + 0.0811*Km_ClGiT1 == 1.0;

      # RNB
      subto RNB_ClGiT1: RNB_lo <= 6.0*F1_GiT1 - 9.0*Fj_GiT1 + 25.0*K1_ClGiT1 - 5.0*Km_ClGiT1 <= RNB_up;

      # intake constraint
      subto IC_ClGiT1: 0.91*F1_GiT1 + 0.96*Fj_GiT1 + 0.55*K1_ClGiT1 + 0.55*Km_ClGiT1 == 16.23;

      # concentrate constraint
      subto K_ClG1T1_max: 1.5 * (K1_ClGiT1 + Km_ClGiT1) - (F1_GiT1 + Fj_GiT1) <= 0;

  # period t

    # cow 1

      # NEL and uCP deviations
      subto E_C1GiTt: - sE_C1GiTt + dE_C1GiTt + z_C1GiTt * (0.0621*F1_GiTt + 0.0726*Fj_GiTt) + 0.1042*K1_C1GiTt + 0.0895*Km_C1GiTt == 1.0;
      subto P_C1GiTt: - sP_C1GiTt + dP_C1GiTt + z_C1GiTt * (0.0652*F1_GiTt + 0.0657*Fj_GiTt) + 0.0128*K1_C1GiTt + 0.0821*Km_C1GiTt == 1.0;

      # RNB
      subto RNB_C1GiTt: RNB_lo <= z_C1GiTt * (6.0*F1_GiTt - 9.0*Fj_GiTt) + 25.0*K1_C1GiTt - 5.0*Km_C1GiTt <= RNB_up;

      # intake constraint
      subto IC_C1GiTt: z_C1GiTt * (0.91*F1_GiTt + 0.96*Fj_GiTt) + 0.55*K1_C1GiTt + 0.55*Km_C1GiTt == 15.85;

      # concentrate constraint
      subto K_C1GiTt_max: 1.5 * (K1_C1GiTt + Km_C1GiTt) - z_C1GiTt * (F1_GiTt + Fj_GiTt) <= 0;

    # cow l
      
      # NEL and uCP deviations
      subto E_ClGiTt: - sE_ClGiTt + dE_ClGiTt + 0.0621*F1_GiTt + 0.0726*Fj_GiTt + 0.1042*K1_ClGiTt + 0.0895*Km_ClGiTt == 1.0;
      subto P_ClGiTt: - sP_ClGiTt + dP_ClGiTt + 0.0652*F1_GiTt + 0.0657*Fj_GiTt + 0.1208*K1_ClGiTt + 0.0822*Km_ClGiTt == 1.0;

      # RNB
      subto RNB_ClGiTt: RNB_lo <= 6.0*F1_GiTt - 9.0*Fj_GiTt + 25.0*K1_ClGiTt - 5.0*Km_ClGiTt <= RNB_up;

      # intake constraint
      subto IC_ClGiTt: 0.91*F1_GiTt + 0.96*Fj_GiTt + 0.55*K1_ClGiTt + 0.55*Km_ClGiTt == 15.42;

      # concentrate constraint
      subto K_ClGiTt_max: 1.5 * (K1_ClGiTt + Km_ClGiTt) - (F1_GiTt + Fj_GiTt) <= 0;


# example total feed availability constraint for a feed (maizesilage) available in all periods
subto F1_max: 
 + w * 15.25 / ((15.25 + 16.91) / 2.0) * Fj_G1T1 + w * 16.91 / ((15.25 + 16.91) / 2.0) * Fj_G1T1 # group 1 & period 1
 + w * 17.20 / ((17.20 + 16.95) / 2.0) * Fj_G1Tt + w * 16.95 / ((17.20 + 16.95) / 2.0) * Fj_G1Tt # group 1 & period t
 + w * z_C1GiT1 * Fj_GiT1 + w * Fj_GiT1 # group i & period 1
 + w * z_C1GiTt * Fj_GiTt + w * Fj_GiTt # group i & period t
 <= 250.0;
