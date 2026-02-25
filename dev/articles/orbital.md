# Introduction to orbital

## Introduction

The orbital package allows you to turn a fitted workflow into a new
object, that retains all the information needed to perform prediction.
These predictions should be identical to predictions made using the
original workflow objects but with smaller objects and fewer
dependencies needed.

## Creating a fitted model

``` r
library(orbital)
library(recipes)
library(parsnip)
library(workflows)
library(modeldata)
```

We will be using the Ames housing data:

``` r
ames
#> # A tibble: 2,930 × 74
#>    MS_SubClass   MS_Zoning Lot_Frontage Lot_Area Street Alley Lot_Shape
#>  * <fct>         <fct>            <dbl>    <int> <fct>  <fct> <fct>    
#>  1 One_Story_19… Resident…          141    31770 Pave   No_A… Slightly…
#>  2 One_Story_19… Resident…           80    11622 Pave   No_A… Regular  
#>  3 One_Story_19… Resident…           81    14267 Pave   No_A… Slightly…
#>  4 One_Story_19… Resident…           93    11160 Pave   No_A… Regular  
#>  5 Two_Story_19… Resident…           74    13830 Pave   No_A… Slightly…
#>  6 Two_Story_19… Resident…           78     9978 Pave   No_A… Slightly…
#>  7 One_Story_PU… Resident…           41     4920 Pave   No_A… Regular  
#>  8 One_Story_PU… Resident…           43     5005 Pave   No_A… Slightly…
#>  9 One_Story_PU… Resident…           39     5389 Pave   No_A… Slightly…
#> 10 Two_Story_19… Resident…           60     7500 Pave   No_A… Regular  
#> # ℹ 2,920 more rows
#> # ℹ 67 more variables: Land_Contour <fct>, Utilities <fct>,
#> #   Lot_Config <fct>, Land_Slope <fct>, Neighborhood <fct>,
#> #   Condition_1 <fct>, Condition_2 <fct>, Bldg_Type <fct>,
#> #   House_Style <fct>, Overall_Cond <fct>, Year_Built <int>,
#> #   Year_Remod_Add <int>, Roof_Style <fct>, Roof_Matl <fct>,
#> #   Exterior_1st <fct>, Exterior_2nd <fct>, Mas_Vnr_Type <fct>, …
```

We won’t do a [data split](https://www.tmwr.org/splitting) here to get
to the point of the package faster, but you should do that in practice.

our model will be in two parts. First, we will create a recipe to do the
preprocessing, then specify a parsnip model to go along with it.

This is the recipe we will be going with

``` r
rec_spec <- recipe(Sale_Price ~ ., data = ames) |>
  step_impute_median(all_numeric_predictors()) |>
  step_unknown(all_nominal_predictors()) |>
  step_other(all_nominal_predictors()) |>
  step_dummy(all_nominal_predictors()) |>
  step_nzv(all_numeric_predictors()) |>
  step_normalize(all_numeric_predictors()) |>
  step_corr(all_numeric_predictors())
```

we will be using a standard linear regression

``` r
lm_spec <- linear_reg()
```

Putting them together in a workflow gives us this fitted model.

``` r
wf_spec <- workflow(rec_spec, lm_spec)
wf_fit <- fit(wf_spec, data = ames)
wf_fit
#> ══ Workflow [trained] ═════════════════════════════════════════════════
#> Preprocessor: Recipe
#> Model: linear_reg()
#> 
#> ── Preprocessor ───────────────────────────────────────────────────────
#> 7 Recipe Steps
#> 
#> • step_impute_median()
#> • step_unknown()
#> • step_other()
#> • step_dummy()
#> • step_nzv()
#> • step_normalize()
#> • step_corr()
#> 
#> ── Model ──────────────────────────────────────────────────────────────
#> 
#> Call:
#> stats::lm(formula = ..y ~ ., data = data)
#> 
#> Coefficients:
#>                                      (Intercept)  
#>                                        180796.06  
#>                                     Lot_Frontage  
#>                                           955.64  
#>                                         Lot_Area  
#>                                          1516.76  
#>                                       Year_Built  
#>                                          8074.10  
#>                                   Year_Remod_Add  
#>                                          5932.22  
#>                                     Mas_Vnr_Area  
#>                                          6997.31  
#>                                     BsmtFin_SF_1  
#>                                         -2548.65  
#>                                      Bsmt_Unf_SF  
#>                                         -3924.57  
#>                                    Total_Bsmt_SF  
#>                                          9069.96  
#>                                     First_Flr_SF  
#>                                          6568.67  
#>                                    Second_Flr_SF  
#>                                         15604.79  
#>                                      Gr_Liv_Area  
#>                                         19292.62  
#>                                   Bsmt_Full_Bath  
#>                                          3296.45  
#>                                   Bsmt_Half_Bath  
#>                                          -533.51  
#>                                        Full_Bath  
#>                                          2431.15  
#>                                        Half_Bath  
#>                                          1403.62  
#>                                    Bedroom_AbvGr  
#>                                         -3345.31  
#>                                    TotRms_AbvGrd  
#>                                           915.76  
#>                                       Fireplaces  
#>                                          4709.45  
#>                                      Garage_Cars  
#>                                          7318.62  
#>                                      Garage_Area  
#>                                          1681.64  
#>                                     Wood_Deck_SF  
#>                                          1017.69  
#>                                          Mo_Sold  
#> 
#> ...
#> and 150 more lines.
```

## Converting model

Once we have a fitted workflow all we have to do is call the
[`orbital()`](https://orbital.tidymodels.org/dev/reference/orbital.md)
function on the fitted workflow. This will create an orbital object that
we will use from here on out.

``` r
orbital_obj <- orbital(wf_fit)
orbital_obj
#> 
#> ── orbital Object ─────────────────────────────────────────────────────
#> • Lot_Frontage = dplyr::if_else(is.na(Lot_Frontage), 63, Lot_Fro ...
#> • Lot_Area = dplyr::if_else(is.na(Lot_Area), 9436, Lot_Area)
#> • Year_Built = dplyr::if_else(is.na(Year_Built), 1973, Year_Buil ...
#> • Year_Remod_Add = dplyr::if_else(is.na(Year_Remod_Add), 1993, Y ...
#> • Mas_Vnr_Area = dplyr::if_else(is.na(Mas_Vnr_Area), 0, Mas_Vnr_ ...
#> • BsmtFin_SF_1 = dplyr::if_else(is.na(BsmtFin_SF_1), 3, BsmtFin_ ...
#> • Bsmt_Unf_SF = dplyr::if_else(is.na(Bsmt_Unf_SF), 465.5, Bsmt_U ...
#> • Total_Bsmt_SF = dplyr::if_else(is.na(Total_Bsmt_SF), 990, Tota ...
#> • First_Flr_SF = dplyr::if_else(is.na(First_Flr_SF), 1084, First ...
#> • Second_Flr_SF = dplyr::if_else(is.na(Second_Flr_SF), 0, Second ...
#> • Gr_Liv_Area = dplyr::if_else(is.na(Gr_Liv_Area), 1442, Gr_Liv_ ...
#> • Bsmt_Full_Bath = dplyr::if_else(is.na(Bsmt_Full_Bath), 0, Bsmt ...
#> • Bsmt_Half_Bath = dplyr::if_else(is.na(Bsmt_Half_Bath), 0, Bsmt ...
#> • Full_Bath = dplyr::if_else(is.na(Full_Bath), 2, Full_Bath)
#> • Half_Bath = dplyr::if_else(is.na(Half_Bath), 0, Half_Bath)
#> • Bedroom_AbvGr = dplyr::if_else(is.na(Bedroom_AbvGr), 3, Bedroo ...
#> • TotRms_AbvGrd = dplyr::if_else(is.na(TotRms_AbvGrd), 6, TotRms ...
#> • Fireplaces = dplyr::if_else(is.na(Fireplaces), 1, Fireplaces)
#> • Garage_Cars = dplyr::if_else(is.na(Garage_Cars), 2, Garage_Car ...
#> • Garage_Area = dplyr::if_else(is.na(Garage_Area), 480, Garage_A ...
#> • Wood_Deck_SF = dplyr::if_else(is.na(Wood_Deck_SF), 0, Wood_Dec ...
#> • Mo_Sold = dplyr::if_else(is.na(Mo_Sold), 6, Mo_Sold)
#> • Year_Sold = dplyr::if_else(is.na(Year_Sold), 2008, Year_Sold)
#> • Longitude = dplyr::if_else(is.na(Longitude), -93.64181, Longit ...
#> • Latitude = dplyr::if_else(is.na(Latitude), 42.03466, Latitude)
#> • MS_SubClass = dplyr::if_else(is.na(MS_SubClass), "unknown", MS ...
#> • MS_Zoning = dplyr::if_else(is.na(MS_Zoning), "unknown", MS_Zon ...
#> • Alley = dplyr::if_else(is.na(Alley), "unknown", Alley)
#> • Lot_Shape = dplyr::if_else(is.na(Lot_Shape), "unknown", Lot_Sh ...
#> • Land_Contour = dplyr::if_else(is.na(Land_Contour), "unknown", ...
#> • Lot_Config = dplyr::if_else(is.na(Lot_Config), "unknown", Lot_ ...
#> • Neighborhood = dplyr::if_else(is.na(Neighborhood), "unknown", ...
#> • Condition_1 = dplyr::if_else(is.na(Condition_1), "unknown", Co ...
#> • Bldg_Type = dplyr::if_else(is.na(Bldg_Type), "unknown", Bldg_T ...
#> • House_Style = dplyr::if_else(is.na(House_Style), "unknown", Ho ...
#> • Overall_Cond = dplyr::if_else(is.na(Overall_Cond), "unknown", ...
#> • Roof_Style = dplyr::if_else(is.na(Roof_Style), "unknown", Roof ...
#> • Exterior_1st = dplyr::if_else(is.na(Exterior_1st), "unknown", ...
#> • Exterior_2nd = dplyr::if_else(is.na(Exterior_2nd), "unknown", ...
#> • Mas_Vnr_Type = dplyr::if_else(is.na(Mas_Vnr_Type), "unknown", ...
#> • Exter_Cond = dplyr::if_else(is.na(Exter_Cond), "unknown", Exte ...
#> • Foundation = dplyr::if_else(is.na(Foundation), "unknown", Foun ...
#> • Bsmt_Cond = dplyr::if_else(is.na(Bsmt_Cond), "unknown", Bsmt_C ...
#> • Bsmt_Exposure = dplyr::if_else(is.na(Bsmt_Exposure), "unknown" ...
#> • BsmtFin_Type_1 = dplyr::if_else(is.na(BsmtFin_Type_1), "unknow ...
#> • BsmtFin_Type_2 = dplyr::if_else(is.na(BsmtFin_Type_2), "unknow ...
#> • Heating_QC = dplyr::if_else(is.na(Heating_QC), "unknown", Heat ...
#> • Central_Air = dplyr::if_else(is.na(Central_Air), "unknown", Ce ...
#> • Electrical = dplyr::if_else(is.na(Electrical), "unknown", Elec ...
#> • Functional = dplyr::if_else(is.na(Functional), "unknown", Func ...
#> • Garage_Type = dplyr::if_else(is.na(Garage_Type), "unknown", Ga ...
#> • Garage_Finish = dplyr::if_else(is.na(Garage_Finish), "unknown" ...
#> • Garage_Cond = dplyr::if_else(is.na(Garage_Cond), "unknown", Ga ...
#> • Paved_Drive = dplyr::if_else(is.na(Paved_Drive), "unknown", Pa ...
#> • Fence = dplyr::if_else(is.na(Fence), "unknown", Fence)
#> • Sale_Type = dplyr::if_else(is.na(Sale_Type), "unknown", Sale_T ...
#> • Sale_Condition = dplyr::if_else(is.na(Sale_Condition), "unknow ...
#> • MS_SubClass = dplyr::if_else(is.na(MS_SubClass), NA, dplyr::if ...
#> • MS_Zoning = dplyr::if_else(is.na(MS_Zoning), NA, dplyr::if_els ...
#> • Alley = dplyr::if_else(is.na(Alley), NA, dplyr::if_else(Alley ...
#> • Lot_Shape = dplyr::if_else(is.na(Lot_Shape), NA, dplyr::if_els ...
#> • Land_Contour = dplyr::if_else(is.na(Land_Contour), NA, dplyr:: ...
#> • Lot_Config = dplyr::if_else(is.na(Lot_Config), NA, dplyr::if_e ...
#> • Neighborhood = dplyr::if_else(is.na(Neighborhood), NA, dplyr:: ...
#> • Condition_1 = dplyr::if_else(is.na(Condition_1), NA, dplyr::if ...
#> • Bldg_Type = dplyr::if_else(is.na(Bldg_Type), NA, dplyr::if_els ...
#> • House_Style = dplyr::if_else(is.na(House_Style), NA, dplyr::if ...
#> • Overall_Cond = dplyr::if_else(is.na(Overall_Cond), NA, dplyr:: ...
#> • Roof_Style = dplyr::if_else(is.na(Roof_Style), NA, dplyr::if_e ...
#> • Exterior_1st = dplyr::if_else(is.na(Exterior_1st), NA, dplyr:: ...
#> • Exterior_2nd = dplyr::if_else(is.na(Exterior_2nd), NA, dplyr:: ...
#> • Mas_Vnr_Type = dplyr::if_else(is.na(Mas_Vnr_Type), NA, dplyr:: ...
#> • Exter_Cond = dplyr::if_else(is.na(Exter_Cond), NA, dplyr::if_e ...
#> • Foundation = dplyr::if_else(is.na(Foundation), NA, dplyr::if_e ...
#> • Bsmt_Cond = dplyr::if_else(is.na(Bsmt_Cond), NA, dplyr::if_els ...
#> • Bsmt_Exposure = dplyr::if_else(is.na(Bsmt_Exposure), NA, dplyr ...
#> • BsmtFin_Type_1 = dplyr::if_else(is.na(BsmtFin_Type_1), NA, dpl ...
#> • BsmtFin_Type_2 = dplyr::if_else(is.na(BsmtFin_Type_2), NA, dpl ...
#> • Heating_QC = dplyr::if_else(is.na(Heating_QC), NA, dplyr::if_e ...
#> • Central_Air = dplyr::if_else(is.na(Central_Air), NA, dplyr::if ...
#> • Electrical = dplyr::if_else(is.na(Electrical), NA, dplyr::if_e ...
#> • Functional = dplyr::if_else(is.na(Functional), NA, dplyr::if_e ...
#> • Garage_Type = dplyr::if_else(is.na(Garage_Type), NA, dplyr::if ...
#> • Garage_Finish = dplyr::if_else(is.na(Garage_Finish), NA, dplyr ...
#> • Garage_Cond = dplyr::if_else(is.na(Garage_Cond), NA, dplyr::if ...
#> • Paved_Drive = dplyr::if_else(is.na(Paved_Drive), NA, dplyr::if ...
#> • Fence = dplyr::if_else(is.na(Fence), NA, dplyr::if_else(Fence ...
#> • Sale_Type = dplyr::if_else(is.na(Sale_Type), NA, dplyr::if_els ...
#> • Sale_Condition = dplyr::if_else(is.na(Sale_Condition), NA, dpl ...
#> • MS_SubClass_One_and_Half_Story_Finished_All_Ages = as.numeric( ...
#> • MS_SubClass_Two_Story_1946_and_Newer = as.numeric(MS_SubClass ...
#> • MS_SubClass_One_Story_PUD_1946_and_Newer = as.numeric(MS_SubCl ...
#> • MS_SubClass_other = as.numeric(MS_SubClass == "other")
#> • MS_Zoning_Residential_Medium_Density = as.numeric(MS_Zoning == ...
#> • MS_Zoning_other = as.numeric(MS_Zoning == "other")
#> • Alley_other = as.numeric(Alley == "other")
#> • Lot_Shape_Slightly_Irregular = as.numeric(Lot_Shape == "Slight ...
#> • Land_Contour_other = as.numeric(Land_Contour == "other")
#> • Lot_Config_CulDSac = as.numeric(Lot_Config == "CulDSac")
#> • Lot_Config_Inside = as.numeric(Lot_Config == "Inside")
#> • Neighborhood_College_Creek = as.numeric(Neighborhood == "Colle ...
#> • Neighborhood_Old_Town = as.numeric(Neighborhood == "Old_Town")
#> • Neighborhood_Edwards = as.numeric(Neighborhood == "Edwards")
#> • Neighborhood_Somerset = as.numeric(Neighborhood == "Somerset")
#> • Neighborhood_Northridge_Heights = as.numeric(Neighborhood == " ...
#> • Neighborhood_Gilbert = as.numeric(Neighborhood == "Gilbert")
#> • Neighborhood_Sawyer = as.numeric(Neighborhood == "Sawyer")
#> • Neighborhood_other = as.numeric(Neighborhood == "other")
#> • Condition_1_Norm = as.numeric(Condition_1 == "Norm")
#> • Condition_1_other = as.numeric(Condition_1 == "other")
#> • Bldg_Type_TwnhsE = as.numeric(Bldg_Type == "TwnhsE")
#> • Bldg_Type_other = as.numeric(Bldg_Type == "other")
#> • House_Style_One_Story = as.numeric(House_Style == "One_Story")
#> • House_Style_Two_Story = as.numeric(House_Style == "Two_Story")
#> • House_Style_other = as.numeric(House_Style == "other")
#> • Overall_Cond_Above_Average = as.numeric(Overall_Cond == "Above ...
#> • Overall_Cond_Good = as.numeric(Overall_Cond == "Good")
#> • Overall_Cond_other = as.numeric(Overall_Cond == "other")
#> • Roof_Style_Hip = as.numeric(Roof_Style == "Hip")
#> • Exterior_1st_Plywood = as.numeric(Exterior_1st == "Plywood")
#> • Exterior_1st_Wd.Sdng = as.numeric(Exterior_1st == "Wd Sdng")
#> • Exterior_1st_other = as.numeric(Exterior_1st == "other")
#> • Exterior_2nd_MetalSd = as.numeric(Exterior_2nd == "MetalSd")
#> • Exterior_2nd_Plywood = as.numeric(Exterior_2nd == "Plywood")
#> • Exterior_2nd_VinylSd = as.numeric(Exterior_2nd == "VinylSd")
#> • Exterior_2nd_Wd.Sdng = as.numeric(Exterior_2nd == "Wd Sdng")
#> • Exterior_2nd_other = as.numeric(Exterior_2nd == "other")
#> • Mas_Vnr_Type_None = as.numeric(Mas_Vnr_Type == "None")
#> • Mas_Vnr_Type_Stone = as.numeric(Mas_Vnr_Type == "Stone")
#> • Exter_Cond_Typical = as.numeric(Exter_Cond == "Typical")
#> • Foundation_CBlock = as.numeric(Foundation == "CBlock")
#> • Foundation_PConc = as.numeric(Foundation == "PConc")
#> • Bsmt_Cond_other = as.numeric(Bsmt_Cond == "other")
#> • Bsmt_Exposure_Gd = as.numeric(Bsmt_Exposure == "Gd")
#> • Bsmt_Exposure_Mn = as.numeric(Bsmt_Exposure == "Mn")
#> • Bsmt_Exposure_No = as.numeric(Bsmt_Exposure == "No")
#> • BsmtFin_Type_1_BLQ = as.numeric(BsmtFin_Type_1 == "BLQ")
#> • BsmtFin_Type_1_GLQ = as.numeric(BsmtFin_Type_1 == "GLQ")
#> • BsmtFin_Type_1_LwQ = as.numeric(BsmtFin_Type_1 == "LwQ")
#> • BsmtFin_Type_1_Rec = as.numeric(BsmtFin_Type_1 == "Rec")
#> • BsmtFin_Type_1_Unf = as.numeric(BsmtFin_Type_1 == "Unf")
#> • BsmtFin_Type_2_other = as.numeric(BsmtFin_Type_2 == "other")
#> • Heating_QC_Good = as.numeric(Heating_QC == "Good")
#> • Heating_QC_Typical = as.numeric(Heating_QC == "Typical")
#> • Central_Air_Y = as.numeric(Central_Air == "Y")
#> • Electrical_SBrkr = as.numeric(Electrical == "SBrkr")
#> • Functional_other = as.numeric(Functional == "other")
#> • Garage_Type_BuiltIn = as.numeric(Garage_Type == "BuiltIn")
#> • Garage_Type_Detchd = as.numeric(Garage_Type == "Detchd")
#> • Garage_Type_No_Garage = as.numeric(Garage_Type == "No_Garage")
#> • Garage_Finish_RFn = as.numeric(Garage_Finish == "RFn")
#> • Garage_Finish_Unf = as.numeric(Garage_Finish == "Unf")
#> • Garage_Cond_Typical = as.numeric(Garage_Cond == "Typical")
#> • Paved_Drive_Paved = as.numeric(Paved_Drive == "Paved")
#> • Fence_No_Fence = as.numeric(Fence == "No_Fence")
#> • Fence_other = as.numeric(Fence == "other")
#> • Sale_Type_WD. = as.numeric(Sale_Type == "WD ")
#> • Sale_Type_other = as.numeric(Sale_Type == "other")
#> • Sale_Condition_Normal = as.numeric(Sale_Condition == "Normal")
#> • Sale_Condition_Partial = as.numeric(Sale_Condition == "Partial ...
#> • Lot_Frontage = (Lot_Frontage - 57.64778) / 33.49944
#> • Lot_Area = (Lot_Area - 10147.92) / 7880.018
#> • Year_Built = (Year_Built - 1971.356) / 30.24536
#> • Year_Remod_Add = (Year_Remod_Add - 1984.267) / 20.86029
#> • Mas_Vnr_Area = (Mas_Vnr_Area - 101.0969) / 178.6345
#> • BsmtFin_SF_1 = (BsmtFin_SF_1 - 4.177474) / 2.233372
#> • Bsmt_Unf_SF = (Bsmt_Unf_SF - 559.0717) / 439.5406
#> • Total_Bsmt_SF = (Total_Bsmt_SF - 1051.256) / 440.968
#> • First_Flr_SF = (First_Flr_SF - 1159.558) / 391.8909
#> • Second_Flr_SF = (Second_Flr_SF - 335.456) / 428.3957
#> • Gr_Liv_Area = (Gr_Liv_Area - 1499.69) / 505.5089
#> • Bsmt_Full_Bath = (Bsmt_Full_Bath - 0.431058) / 0.524762
#> • Bsmt_Half_Bath = (Bsmt_Half_Bath - 0.06109215) / 0.245175
#> • Full_Bath = (Full_Bath - 1.566553) / 0.5529406
#> • Half_Bath = (Half_Bath - 0.3795222) / 0.5026293
#> • Bedroom_AbvGr = (Bedroom_AbvGr - 2.854266) / 0.8277311
#> • TotRms_AbvGrd = (TotRms_AbvGrd - 6.443003) / 1.572964
#> • Fireplaces = (Fireplaces - 0.5993174) / 0.6479209
#> • Garage_Cars = (Garage_Cars - 1.766212) / 0.7611367
#> • Garage_Area = (Garage_Area - 472.6584) / 215.1872
#> • Wood_Deck_SF = (Wood_Deck_SF - 93.75188) / 126.3616
#> • Mo_Sold = (Mo_Sold - 6.216041) / 2.714492
#> • Year_Sold = (Year_Sold - 2007.79) / 1.316613
#> • Longitude = (Longitude - -93.6429) / 0.02569957
#> • Latitude = (Latitude - 42.03448) / 0.01841007
#> • MS_SubClass_One_and_Half_Story_Finished_All_Ages = (MS_SubClas ...
#> • MS_SubClass_Two_Story_1946_and_Newer = (MS_SubClass_Two_Story_ ...
#> • MS_SubClass_One_Story_PUD_1946_and_Newer = (MS_SubClass_One_St ...
#> • MS_SubClass_other = (MS_SubClass_other - 0.2720137) / 0.445072 ...
#> • MS_Zoning_Residential_Medium_Density = (MS_Zoning_Residential_ ...
#> • MS_Zoning_other = (MS_Zoning_other - 0.0665529) / 0.2492886
#> • Alley_other = (Alley_other - 0.06757679) / 0.2510611
#> • Lot_Shape_Slightly_Irregular = (Lot_Shape_Slightly_Irregular - ...
#> • Land_Contour_other = (Land_Contour_other - 0.1013652) / 0.3018 ...
#> • Lot_Config_CulDSac = (Lot_Config_CulDSac - 0.06143345) / 0.240 ...
#> • Lot_Config_Inside = (Lot_Config_Inside - 0.7303754) / 0.443840 ...
#> • Neighborhood_College_Creek = (Neighborhood_College_Creek - 0.0 ...
#> • Neighborhood_Old_Town = (Neighborhood_Old_Town - 0.08156997) / ...
#> • Neighborhood_Edwards = (Neighborhood_Edwards - 0.0662116) / 0. ...
#> • Neighborhood_Somerset = (Neighborhood_Somerset - 0.06211604) / ...
#> • Neighborhood_Northridge_Heights = (Neighborhood_Northridge_Hei ...
#> • Neighborhood_Gilbert = (Neighborhood_Gilbert - 0.05631399) / 0 ...
#> • Neighborhood_Sawyer = (Neighborhood_Sawyer - 0.05153584) / 0.2 ...
#> • Neighborhood_other = (Neighborhood_other - 0.3832765) / 0.4862 ...
#> • Condition_1_Norm = (Condition_1_Norm - 0.8607509) / 0.3462654
#> • Condition_1_other = (Condition_1_other - 0.08327645) / 0.27634 ...
#> • Bldg_Type_TwnhsE = (Bldg_Type_TwnhsE - 0.07952218) / 0.2705982
#> • Bldg_Type_other = (Bldg_Type_other - 0.09283276) / 0.2902475
#> • House_Style_One_Story = (House_Style_One_Story - 0.5054608) / ...
#> • House_Style_Two_Story = (House_Style_Two_Story - 0.2979522) / ...
#> • House_Style_other = (House_Style_other - 0.0894198) / 0.285397 ...
#> • Overall_Cond_Above_Average = (Overall_Cond_Above_Average - 0.1 ...
#> • Overall_Cond_Good = (Overall_Cond_Good - 0.1331058) / 0.339747
#> • Overall_Cond_other = (Overall_Cond_other - 0.1204778) / 0.3255 ...
#> • Roof_Style_Hip = (Roof_Style_Hip - 0.1880546) / 0.3908225
#> • Exterior_1st_Plywood = (Exterior_1st_Plywood - 0.07542662) / 0 ...
#> • Exterior_1st_Wd.Sdng = (Exterior_1st_Wd.Sdng - 0.1433447) / 0. ...
#> • Exterior_1st_other = (Exterior_1st_other - 0.1266212) / 0.3326 ...
#> • Exterior_2nd_MetalSd = (Exterior_2nd_MetalSd - 0.1525597) / 0. ...
#> • Exterior_2nd_Plywood = (Exterior_2nd_Plywood - 0.09351536) / 0 ...
#> • Exterior_2nd_VinylSd = (Exterior_2nd_VinylSd - 0.3464164) / 0. ...
#> • Exterior_2nd_Wd.Sdng = (Exterior_2nd_Wd.Sdng - 0.1354949) / 0. ...
#> • Exterior_2nd_other = (Exterior_2nd_other - 0.1334471) / 0.3401 ...
#> • Mas_Vnr_Type_None = (Mas_Vnr_Type_None - 0.605802) / 0.4887611
#> • Mas_Vnr_Type_Stone = (Mas_Vnr_Type_Stone - 0.08498294) / 0.278 ...
#> • Exter_Cond_Typical = (Exter_Cond_Typical - 0.8699659) / 0.3363 ...
#> • Foundation_CBlock = (Foundation_CBlock - 0.4245734) / 0.494362 ...
#> • Foundation_PConc = (Foundation_PConc - 0.447099) / 0.4972785
#> • Bsmt_Cond_other = (Bsmt_Cond_other - 0.1071672) / 0.3093785
#> • Bsmt_Exposure_Gd = (Bsmt_Exposure_Gd - 0.09692833) / 0.2959106
#> • Bsmt_Exposure_Mn = (Bsmt_Exposure_Mn - 0.08156997) / 0.2737552
#> • Bsmt_Exposure_No = (Bsmt_Exposure_No - 0.6505119) / 0.4768897
#> • BsmtFin_Type_1_BLQ = (BsmtFin_Type_1_BLQ - 0.09180887) / 0.288 ...
#> • BsmtFin_Type_1_GLQ = (BsmtFin_Type_1_GLQ - 0.2931741) / 0.4552 ...
#> • BsmtFin_Type_1_LwQ = (BsmtFin_Type_1_LwQ - 0.05255973) / 0.223 ...
#> • BsmtFin_Type_1_Rec = (BsmtFin_Type_1_Rec - 0.09829352) / 0.297 ...
#> • BsmtFin_Type_1_Unf = (BsmtFin_Type_1_Unf - 0.2904437) / 0.4540 ...
#> • BsmtFin_Type_2_other = (BsmtFin_Type_2_other - 0.147099) / 0.3 ...
#> • Heating_QC_Good = (Heating_QC_Good - 0.1624573) / 0.3689328
#> • Heating_QC_Typical = (Heating_QC_Typical - 0.2948805) / 0.4560 ...
#> • Central_Air_Y = (Central_Air_Y - 0.9331058) / 0.2498813
#> • Electrical_SBrkr = (Electrical_SBrkr - 0.9153584) / 0.2783952
#> • Functional_other = (Functional_other - 0.06894198) / 0.2533987
#> • Garage_Type_BuiltIn = (Garage_Type_BuiltIn - 0.06348123) / 0.2 ...
#> • Garage_Type_Detchd = (Garage_Type_Detchd - 0.2668942) / 0.4424 ...
#> • Garage_Type_No_Garage = (Garage_Type_No_Garage - 0.05358362) / ...
#> • Garage_Finish_RFn = (Garage_Finish_RFn - 0.2771331) / 0.447659 ...
#> • Garage_Finish_Unf = (Garage_Finish_Unf - 0.4201365) / 0.493664 ...
#> • Garage_Cond_Typical = (Garage_Cond_Typical - 0.9095563) / 0.28 ...
#> • Paved_Drive_Paved = (Paved_Drive_Paved - 0.9051195) / 0.293099 ...
#> • Fence_No_Fence = (Fence_No_Fence - 0.8047782) / 0.396439
#> • Fence_other = (Fence_other - 0.08259386) / 0.2753143
#> • Sale_Type_WD. = (Sale_Type_WD. - 0.865529) / 0.3412159
#> • Sale_Type_other = (Sale_Type_other - 0.05290102) / 0.2238741
#> • Sale_Condition_Normal = (Sale_Condition_Normal - 0.8235495) / ...
#> • Sale_Condition_Partial = (Sale_Condition_Partial - 0.08361775) ...
#> • .pred = 180796.1 + (Lot_Frontage * 955.6351) + (Lot_Area * 151 ...
#> ───────────────────────────────────────────────────────────────────────
#> 257 equations in total.
```

One of the neat things about orbital objects is that they only require
the orbital package to be loaded, compared to the workflow object which
needs recipes, parsnip, workflows and the engine package to be loaded.
It is also substantially smaller in size.

``` r
object.size(orbital_obj)
#> 48992 bytes
object.size(wf_fit)
#> 9637184 bytes
```

## Predicting

Predicting with an orbital object is done using the
[`predict()`](https://rdrr.io/r/stats/predict.html) function, the same
way it is done with workflows objects.

``` r
predict(orbital_obj, ames)
#> # A tibble: 2,930 × 1
#>      .pred
#>      <dbl>
#>  1 241950.
#>  2  89436.
#>  3 150919.
#>  4 258130.
#>  5 199195.
#>  6 189319.
#>  7 211575.
#>  8 166227.
#>  9 232087.
#> 10 188203.
#> # ℹ 2,920 more rows
```

Notice how it produces the same results as if we were to
[`predict()`](https://rdrr.io/r/stats/predict.html) on the workflow
object.

``` r
predict(wf_fit, ames)
#> # A tibble: 2,930 × 1
#>      .pred
#>      <dbl>
#>  1 241950.
#>  2  89436.
#>  3 150919.
#>  4 258130.
#>  5 199195.
#>  6 189319.
#>  7 211575.
#>  8 166227.
#>  9 232087.
#> 10 188203.
#> # ℹ 2,920 more rows
```

orbital objects also allow for prediction in database objects such as
SQL or spark databases. Below is a small example using an ephemeral
in-memory RSQLite database.

``` r
library(DBI)
library(RSQLite)

con <- dbConnect(SQLite(), path = ":memory:")
ames_sqlite <- copy_to(con, ames)

predict(orbital_obj, ames_sqlite)
#> # Source:   SQL [?? x 1]
#> # Database: sqlite 3.51.2 []
#>      .pred
#>      <dbl>
#>  1 241950.
#>  2  89436.
#>  3 150919.
#>  4 258130.
#>  5 199195.
#>  6 189319.
#>  7 211575.
#>  8 166227.
#>  9 232087.
#> 10 188203.
#> # ℹ more rows
```

## Code Generation

In the same way that you can predict in databases, you can also get the
code needed to run the query.

``` r
orbital_sql(orbital_obj, con)
#> <SQL> CASE WHEN ((`Lot_Frontage` IS NULL)) THEN 63.0 WHEN NOT ((`Lot_Frontage` IS NULL)) THEN `Lot_Frontage` END AS Lot_Frontage
#> <SQL> CASE WHEN ((`Lot_Area` IS NULL)) THEN 9436.0 WHEN NOT ((`Lot_Area` IS NULL)) THEN `Lot_Area` END AS Lot_Area
#> <SQL> CASE WHEN ((`Year_Built` IS NULL)) THEN 1973.0 WHEN NOT ((`Year_Built` IS NULL)) THEN `Year_Built` END AS Year_Built
#> <SQL> CASE WHEN ((`Year_Remod_Add` IS NULL)) THEN 1993.0 WHEN NOT ((`Year_Remod_Add` IS NULL)) THEN `Year_Remod_Add` END AS Year_Remod_Add
#> <SQL> CASE WHEN ((`Mas_Vnr_Area` IS NULL)) THEN 0.0 WHEN NOT ((`Mas_Vnr_Area` IS NULL)) THEN `Mas_Vnr_Area` END AS Mas_Vnr_Area
#> <SQL> CASE WHEN ((`BsmtFin_SF_1` IS NULL)) THEN 3.0 WHEN NOT ((`BsmtFin_SF_1` IS NULL)) THEN `BsmtFin_SF_1` END AS BsmtFin_SF_1
#> <SQL> CASE WHEN ((`Bsmt_Unf_SF` IS NULL)) THEN 465.5 WHEN NOT ((`Bsmt_Unf_SF` IS NULL)) THEN `Bsmt_Unf_SF` END AS Bsmt_Unf_SF
#> <SQL> CASE WHEN ((`Total_Bsmt_SF` IS NULL)) THEN 990.0 WHEN NOT ((`Total_Bsmt_SF` IS NULL)) THEN `Total_Bsmt_SF` END AS Total_Bsmt_SF
#> <SQL> CASE WHEN ((`First_Flr_SF` IS NULL)) THEN 1084.0 WHEN NOT ((`First_Flr_SF` IS NULL)) THEN `First_Flr_SF` END AS First_Flr_SF
#> <SQL> CASE WHEN ((`Second_Flr_SF` IS NULL)) THEN 0.0 WHEN NOT ((`Second_Flr_SF` IS NULL)) THEN `Second_Flr_SF` END AS Second_Flr_SF
#> <SQL> CASE WHEN ((`Gr_Liv_Area` IS NULL)) THEN 1442.0 WHEN NOT ((`Gr_Liv_Area` IS NULL)) THEN `Gr_Liv_Area` END AS Gr_Liv_Area
#> <SQL> CASE WHEN ((`Bsmt_Full_Bath` IS NULL)) THEN 0.0 WHEN NOT ((`Bsmt_Full_Bath` IS NULL)) THEN `Bsmt_Full_Bath` END AS Bsmt_Full_Bath
#> <SQL> CASE WHEN ((`Bsmt_Half_Bath` IS NULL)) THEN 0.0 WHEN NOT ((`Bsmt_Half_Bath` IS NULL)) THEN `Bsmt_Half_Bath` END AS Bsmt_Half_Bath
#> <SQL> CASE WHEN ((`Full_Bath` IS NULL)) THEN 2.0 WHEN NOT ((`Full_Bath` IS NULL)) THEN `Full_Bath` END AS Full_Bath
#> <SQL> CASE WHEN ((`Half_Bath` IS NULL)) THEN 0.0 WHEN NOT ((`Half_Bath` IS NULL)) THEN `Half_Bath` END AS Half_Bath
#> <SQL> CASE WHEN ((`Bedroom_AbvGr` IS NULL)) THEN 3.0 WHEN NOT ((`Bedroom_AbvGr` IS NULL)) THEN `Bedroom_AbvGr` END AS Bedroom_AbvGr
#> <SQL> CASE WHEN ((`TotRms_AbvGrd` IS NULL)) THEN 6.0 WHEN NOT ((`TotRms_AbvGrd` IS NULL)) THEN `TotRms_AbvGrd` END AS TotRms_AbvGrd
#> <SQL> CASE WHEN ((`Fireplaces` IS NULL)) THEN 1.0 WHEN NOT ((`Fireplaces` IS NULL)) THEN `Fireplaces` END AS Fireplaces
#> <SQL> CASE WHEN ((`Garage_Cars` IS NULL)) THEN 2.0 WHEN NOT ((`Garage_Cars` IS NULL)) THEN `Garage_Cars` END AS Garage_Cars
#> <SQL> CASE WHEN ((`Garage_Area` IS NULL)) THEN 480.0 WHEN NOT ((`Garage_Area` IS NULL)) THEN `Garage_Area` END AS Garage_Area
#> <SQL> CASE WHEN ((`Wood_Deck_SF` IS NULL)) THEN 0.0 WHEN NOT ((`Wood_Deck_SF` IS NULL)) THEN `Wood_Deck_SF` END AS Wood_Deck_SF
#> <SQL> CASE WHEN ((`Mo_Sold` IS NULL)) THEN 6.0 WHEN NOT ((`Mo_Sold` IS NULL)) THEN `Mo_Sold` END AS Mo_Sold
#> <SQL> CASE WHEN ((`Year_Sold` IS NULL)) THEN 2008.0 WHEN NOT ((`Year_Sold` IS NULL)) THEN `Year_Sold` END AS Year_Sold
#> <SQL> CASE WHEN ((`Longitude` IS NULL)) THEN (-93.641806) WHEN NOT ((`Longitude` IS NULL)) THEN `Longitude` END AS Longitude
#> <SQL> CASE WHEN ((`Latitude` IS NULL)) THEN 42.0346625 WHEN NOT ((`Latitude` IS NULL)) THEN `Latitude` END AS Latitude
#> <SQL> CASE WHEN ((`MS_SubClass` IS NULL)) THEN 'unknown' WHEN NOT ((`MS_SubClass` IS NULL)) THEN `MS_SubClass` END AS MS_SubClass
#> <SQL> CASE WHEN ((`MS_Zoning` IS NULL)) THEN 'unknown' WHEN NOT ((`MS_Zoning` IS NULL)) THEN `MS_Zoning` END AS MS_Zoning
#> <SQL> CASE WHEN ((`Alley` IS NULL)) THEN 'unknown' WHEN NOT ((`Alley` IS NULL)) THEN `Alley` END AS Alley
#> <SQL> CASE WHEN ((`Lot_Shape` IS NULL)) THEN 'unknown' WHEN NOT ((`Lot_Shape` IS NULL)) THEN `Lot_Shape` END AS Lot_Shape
#> <SQL> CASE WHEN ((`Land_Contour` IS NULL)) THEN 'unknown' WHEN NOT ((`Land_Contour` IS NULL)) THEN `Land_Contour` END AS Land_Contour
#> <SQL> CASE WHEN ((`Lot_Config` IS NULL)) THEN 'unknown' WHEN NOT ((`Lot_Config` IS NULL)) THEN `Lot_Config` END AS Lot_Config
#> <SQL> CASE WHEN ((`Neighborhood` IS NULL)) THEN 'unknown' WHEN NOT ((`Neighborhood` IS NULL)) THEN `Neighborhood` END AS Neighborhood
#> <SQL> CASE WHEN ((`Condition_1` IS NULL)) THEN 'unknown' WHEN NOT ((`Condition_1` IS NULL)) THEN `Condition_1` END AS Condition_1
#> <SQL> CASE WHEN ((`Bldg_Type` IS NULL)) THEN 'unknown' WHEN NOT ((`Bldg_Type` IS NULL)) THEN `Bldg_Type` END AS Bldg_Type
#> <SQL> CASE WHEN ((`House_Style` IS NULL)) THEN 'unknown' WHEN NOT ((`House_Style` IS NULL)) THEN `House_Style` END AS House_Style
#> <SQL> CASE WHEN ((`Overall_Cond` IS NULL)) THEN 'unknown' WHEN NOT ((`Overall_Cond` IS NULL)) THEN `Overall_Cond` END AS Overall_Cond
#> <SQL> CASE WHEN ((`Roof_Style` IS NULL)) THEN 'unknown' WHEN NOT ((`Roof_Style` IS NULL)) THEN `Roof_Style` END AS Roof_Style
#> <SQL> CASE WHEN ((`Exterior_1st` IS NULL)) THEN 'unknown' WHEN NOT ((`Exterior_1st` IS NULL)) THEN `Exterior_1st` END AS Exterior_1st
#> <SQL> CASE WHEN ((`Exterior_2nd` IS NULL)) THEN 'unknown' WHEN NOT ((`Exterior_2nd` IS NULL)) THEN `Exterior_2nd` END AS Exterior_2nd
#> <SQL> CASE WHEN ((`Mas_Vnr_Type` IS NULL)) THEN 'unknown' WHEN NOT ((`Mas_Vnr_Type` IS NULL)) THEN `Mas_Vnr_Type` END AS Mas_Vnr_Type
#> <SQL> CASE WHEN ((`Exter_Cond` IS NULL)) THEN 'unknown' WHEN NOT ((`Exter_Cond` IS NULL)) THEN `Exter_Cond` END AS Exter_Cond
#> <SQL> CASE WHEN ((`Foundation` IS NULL)) THEN 'unknown' WHEN NOT ((`Foundation` IS NULL)) THEN `Foundation` END AS Foundation
#> <SQL> CASE WHEN ((`Bsmt_Cond` IS NULL)) THEN 'unknown' WHEN NOT ((`Bsmt_Cond` IS NULL)) THEN `Bsmt_Cond` END AS Bsmt_Cond
#> <SQL> CASE WHEN ((`Bsmt_Exposure` IS NULL)) THEN 'unknown' WHEN NOT ((`Bsmt_Exposure` IS NULL)) THEN `Bsmt_Exposure` END AS Bsmt_Exposure
#> <SQL> CASE WHEN ((`BsmtFin_Type_1` IS NULL)) THEN 'unknown' WHEN NOT ((`BsmtFin_Type_1` IS NULL)) THEN `BsmtFin_Type_1` END AS BsmtFin_Type_1
#> <SQL> CASE WHEN ((`BsmtFin_Type_2` IS NULL)) THEN 'unknown' WHEN NOT ((`BsmtFin_Type_2` IS NULL)) THEN `BsmtFin_Type_2` END AS BsmtFin_Type_2
#> <SQL> CASE WHEN ((`Heating_QC` IS NULL)) THEN 'unknown' WHEN NOT ((`Heating_QC` IS NULL)) THEN `Heating_QC` END AS Heating_QC
#> <SQL> CASE WHEN ((`Central_Air` IS NULL)) THEN 'unknown' WHEN NOT ((`Central_Air` IS NULL)) THEN `Central_Air` END AS Central_Air
#> <SQL> CASE WHEN ((`Electrical` IS NULL)) THEN 'unknown' WHEN NOT ((`Electrical` IS NULL)) THEN `Electrical` END AS Electrical
#> <SQL> CASE WHEN ((`Functional` IS NULL)) THEN 'unknown' WHEN NOT ((`Functional` IS NULL)) THEN `Functional` END AS Functional
#> <SQL> CASE WHEN ((`Garage_Type` IS NULL)) THEN 'unknown' WHEN NOT ((`Garage_Type` IS NULL)) THEN `Garage_Type` END AS Garage_Type
#> <SQL> CASE WHEN ((`Garage_Finish` IS NULL)) THEN 'unknown' WHEN NOT ((`Garage_Finish` IS NULL)) THEN `Garage_Finish` END AS Garage_Finish
#> <SQL> CASE WHEN ((`Garage_Cond` IS NULL)) THEN 'unknown' WHEN NOT ((`Garage_Cond` IS NULL)) THEN `Garage_Cond` END AS Garage_Cond
#> <SQL> CASE WHEN ((`Paved_Drive` IS NULL)) THEN 'unknown' WHEN NOT ((`Paved_Drive` IS NULL)) THEN `Paved_Drive` END AS Paved_Drive
#> <SQL> CASE WHEN ((`Fence` IS NULL)) THEN 'unknown' WHEN NOT ((`Fence` IS NULL)) THEN `Fence` END AS Fence
#> <SQL> CASE WHEN ((`Sale_Type` IS NULL)) THEN 'unknown' WHEN NOT ((`Sale_Type` IS NULL)) THEN `Sale_Type` END AS Sale_Type
#> <SQL> CASE WHEN ((`Sale_Condition` IS NULL)) THEN 'unknown' WHEN NOT ((`Sale_Condition` IS NULL)) THEN `Sale_Condition` END AS Sale_Condition
#> <SQL> CASE WHEN ((`MS_SubClass` IS NULL)) THEN NULL WHEN NOT ((`MS_SubClass` IS NULL)) THEN (CASE WHEN (`MS_SubClass` IN ('One_Story_1946_and_Newer_All_Styles', 'One_and_Half_Story_Finished_All_Ages', 'Two_Story_1946_and_Newer', 'One_Story_PUD_1946_and_Newer')) THEN `MS_SubClass` WHEN NOT (`MS_SubClass` IN ('One_Story_1946_and_Newer_All_Styles', 'One_and_Half_Story_Finished_All_Ages', 'Two_Story_1946_and_Newer', 'One_Story_PUD_1946_and_Newer')) THEN 'other' END) END AS MS_SubClass
#> <SQL> CASE WHEN ((`MS_Zoning` IS NULL)) THEN NULL WHEN NOT ((`MS_Zoning` IS NULL)) THEN (CASE WHEN (`MS_Zoning` IN ('Residential_Low_Density', 'Residential_Medium_Density')) THEN `MS_Zoning` WHEN NOT (`MS_Zoning` IN ('Residential_Low_Density', 'Residential_Medium_Density')) THEN 'other' END) END AS MS_Zoning
#> <SQL> CASE WHEN ((`Alley` IS NULL)) THEN NULL WHEN NOT ((`Alley` IS NULL)) THEN (CASE WHEN (`Alley` IN ('No_Alley_Access')) THEN `Alley` WHEN NOT (`Alley` IN ('No_Alley_Access')) THEN 'other' END) END AS Alley
#> <SQL> CASE WHEN ((`Lot_Shape` IS NULL)) THEN NULL WHEN NOT ((`Lot_Shape` IS NULL)) THEN (CASE WHEN (`Lot_Shape` IN ('Regular', 'Slightly_Irregular')) THEN `Lot_Shape` WHEN NOT (`Lot_Shape` IN ('Regular', 'Slightly_Irregular')) THEN 'other' END) END AS Lot_Shape
#> <SQL> CASE WHEN ((`Land_Contour` IS NULL)) THEN NULL WHEN NOT ((`Land_Contour` IS NULL)) THEN (CASE WHEN (`Land_Contour` IN ('Lvl')) THEN `Land_Contour` WHEN NOT (`Land_Contour` IN ('Lvl')) THEN 'other' END) END AS Land_Contour
#> <SQL> CASE WHEN ((`Lot_Config` IS NULL)) THEN NULL WHEN NOT ((`Lot_Config` IS NULL)) THEN (CASE WHEN (`Lot_Config` IN ('Corner', 'CulDSac', 'Inside')) THEN `Lot_Config` WHEN NOT (`Lot_Config` IN ('Corner', 'CulDSac', 'Inside')) THEN 'other' END) END AS Lot_Config
#> <SQL> CASE WHEN ((`Neighborhood` IS NULL)) THEN NULL WHEN NOT ((`Neighborhood` IS NULL)) THEN (CASE WHEN (`Neighborhood` IN ('North_Ames', 'College_Creek', 'Old_Town', 'Edwards', 'Somerset', 'Northridge_Heights', 'Gilbert', 'Sawyer')) THEN `Neighborhood` WHEN NOT (`Neighborhood` IN ('North_Ames', 'College_Creek', 'Old_Town', 'Edwards', 'Somerset', 'Northridge_Heights', 'Gilbert', 'Sawyer')) THEN 'other' END) END AS Neighborhood
#> <SQL> CASE WHEN ((`Condition_1` IS NULL)) THEN NULL WHEN NOT ((`Condition_1` IS NULL)) THEN (CASE WHEN (`Condition_1` IN ('Feedr', 'Norm')) THEN `Condition_1` WHEN NOT (`Condition_1` IN ('Feedr', 'Norm')) THEN 'other' END) END AS Condition_1
#> <SQL> CASE WHEN ((`Bldg_Type` IS NULL)) THEN NULL WHEN NOT ((`Bldg_Type` IS NULL)) THEN (CASE WHEN (`Bldg_Type` IN ('OneFam', 'TwnhsE')) THEN `Bldg_Type` WHEN NOT (`Bldg_Type` IN ('OneFam', 'TwnhsE')) THEN 'other' END) END AS Bldg_Type
#> <SQL> CASE WHEN ((`House_Style` IS NULL)) THEN NULL WHEN NOT ((`House_Style` IS NULL)) THEN (CASE WHEN (`House_Style` IN ('One_and_Half_Fin', 'One_Story', 'Two_Story')) THEN `House_Style` WHEN NOT (`House_Style` IN ('One_and_Half_Fin', 'One_Story', 'Two_Story')) THEN 'other' END) END AS House_Style
#> <SQL> CASE WHEN ((`Overall_Cond` IS NULL)) THEN NULL WHEN NOT ((`Overall_Cond` IS NULL)) THEN (CASE WHEN (`Overall_Cond` IN ('Average', 'Above_Average', 'Good')) THEN `Overall_Cond` WHEN NOT (`Overall_Cond` IN ('Average', 'Above_Average', 'Good')) THEN 'other' END) END AS Overall_Cond
#> <SQL> CASE WHEN ((`Roof_Style` IS NULL)) THEN NULL WHEN NOT ((`Roof_Style` IS NULL)) THEN (CASE WHEN (`Roof_Style` IN ('Gable', 'Hip')) THEN `Roof_Style` WHEN NOT (`Roof_Style` IN ('Gable', 'Hip')) THEN 'other' END) END AS Roof_Style
#> <SQL> CASE WHEN ((`Exterior_1st` IS NULL)) THEN NULL WHEN NOT ((`Exterior_1st` IS NULL)) THEN (CASE WHEN (`Exterior_1st` IN ('HdBoard', 'MetalSd', 'Plywood', 'VinylSd', 'Wd Sdng')) THEN `Exterior_1st` WHEN NOT (`Exterior_1st` IN ('HdBoard', 'MetalSd', 'Plywood', 'VinylSd', 'Wd Sdng')) THEN 'other' END) END AS Exterior_1st
#> <SQL> CASE WHEN ((`Exterior_2nd` IS NULL)) THEN NULL WHEN NOT ((`Exterior_2nd` IS NULL)) THEN (CASE WHEN (`Exterior_2nd` IN ('HdBoard', 'MetalSd', 'Plywood', 'VinylSd', 'Wd Sdng')) THEN `Exterior_2nd` WHEN NOT (`Exterior_2nd` IN ('HdBoard', 'MetalSd', 'Plywood', 'VinylSd', 'Wd Sdng')) THEN 'other' END) END AS Exterior_2nd
#> <SQL> CASE WHEN ((`Mas_Vnr_Type` IS NULL)) THEN NULL WHEN NOT ((`Mas_Vnr_Type` IS NULL)) THEN (CASE WHEN (`Mas_Vnr_Type` IN ('BrkFace', 'None', 'Stone')) THEN `Mas_Vnr_Type` WHEN NOT (`Mas_Vnr_Type` IN ('BrkFace', 'None', 'Stone')) THEN 'other' END) END AS Mas_Vnr_Type
#> <SQL> CASE WHEN ((`Exter_Cond` IS NULL)) THEN NULL WHEN NOT ((`Exter_Cond` IS NULL)) THEN (CASE WHEN (`Exter_Cond` IN ('Good', 'Typical')) THEN `Exter_Cond` WHEN NOT (`Exter_Cond` IN ('Good', 'Typical')) THEN 'other' END) END AS Exter_Cond
#> <SQL> CASE WHEN ((`Foundation` IS NULL)) THEN NULL WHEN NOT ((`Foundation` IS NULL)) THEN (CASE WHEN (`Foundation` IN ('BrkTil', 'CBlock', 'PConc')) THEN `Foundation` WHEN NOT (`Foundation` IN ('BrkTil', 'CBlock', 'PConc')) THEN 'other' END) END AS Foundation
#> <SQL> CASE WHEN ((`Bsmt_Cond` IS NULL)) THEN NULL WHEN NOT ((`Bsmt_Cond` IS NULL)) THEN (CASE WHEN (`Bsmt_Cond` IN ('Typical')) THEN `Bsmt_Cond` WHEN NOT (`Bsmt_Cond` IN ('Typical')) THEN 'other' END) END AS Bsmt_Cond
#> <SQL> CASE WHEN ((`Bsmt_Exposure` IS NULL)) THEN NULL WHEN NOT ((`Bsmt_Exposure` IS NULL)) THEN (CASE WHEN (`Bsmt_Exposure` IN ('Av', 'Gd', 'Mn', 'No')) THEN `Bsmt_Exposure` WHEN NOT (`Bsmt_Exposure` IN ('Av', 'Gd', 'Mn', 'No')) THEN 'other' END) END AS Bsmt_Exposure
#> <SQL> CASE WHEN ((`BsmtFin_Type_1` IS NULL)) THEN NULL WHEN NOT ((`BsmtFin_Type_1` IS NULL)) THEN (CASE WHEN (`BsmtFin_Type_1` IN ('ALQ', 'BLQ', 'GLQ', 'LwQ', 'Rec', 'Unf')) THEN `BsmtFin_Type_1` WHEN NOT (`BsmtFin_Type_1` IN ('ALQ', 'BLQ', 'GLQ', 'LwQ', 'Rec', 'Unf')) THEN 'other' END) END AS BsmtFin_Type_1
#> <SQL> CASE WHEN ((`BsmtFin_Type_2` IS NULL)) THEN NULL WHEN NOT ((`BsmtFin_Type_2` IS NULL)) THEN (CASE WHEN (`BsmtFin_Type_2` IN ('Unf')) THEN `BsmtFin_Type_2` WHEN NOT (`BsmtFin_Type_2` IN ('Unf')) THEN 'other' END) END AS BsmtFin_Type_2
#> <SQL> CASE WHEN ((`Heating_QC` IS NULL)) THEN NULL WHEN NOT ((`Heating_QC` IS NULL)) THEN (CASE WHEN (`Heating_QC` IN ('Excellent', 'Good', 'Typical')) THEN `Heating_QC` WHEN NOT (`Heating_QC` IN ('Excellent', 'Good', 'Typical')) THEN 'other' END) END AS Heating_QC
#> <SQL> CASE WHEN ((`Central_Air` IS NULL)) THEN NULL WHEN NOT ((`Central_Air` IS NULL)) THEN (CASE WHEN (`Central_Air` IN ('N', 'Y')) THEN `Central_Air` WHEN NOT (`Central_Air` IN ('N', 'Y')) THEN 'other' END) END AS Central_Air
#> <SQL> CASE WHEN ((`Electrical` IS NULL)) THEN NULL WHEN NOT ((`Electrical` IS NULL)) THEN (CASE WHEN (`Electrical` IN ('FuseA', 'SBrkr')) THEN `Electrical` WHEN NOT (`Electrical` IN ('FuseA', 'SBrkr')) THEN 'other' END) END AS Electrical
#> <SQL> CASE WHEN ((`Functional` IS NULL)) THEN NULL WHEN NOT ((`Functional` IS NULL)) THEN (CASE WHEN (`Functional` IN ('Typ')) THEN `Functional` WHEN NOT (`Functional` IN ('Typ')) THEN 'other' END) END AS Functional
#> <SQL> CASE WHEN ((`Garage_Type` IS NULL)) THEN NULL WHEN NOT ((`Garage_Type` IS NULL)) THEN (CASE WHEN (`Garage_Type` IN ('Attchd', 'BuiltIn', 'Detchd', 'No_Garage')) THEN `Garage_Type` WHEN NOT (`Garage_Type` IN ('Attchd', 'BuiltIn', 'Detchd', 'No_Garage')) THEN 'other' END) END AS Garage_Type
#> <SQL> CASE WHEN ((`Garage_Finish` IS NULL)) THEN NULL WHEN NOT ((`Garage_Finish` IS NULL)) THEN (CASE WHEN (`Garage_Finish` IN ('Fin', 'No_Garage', 'RFn', 'Unf')) THEN `Garage_Finish` WHEN NOT (`Garage_Finish` IN ('Fin', 'No_Garage', 'RFn', 'Unf')) THEN 'other' END) END AS Garage_Finish
#> <SQL> CASE WHEN ((`Garage_Cond` IS NULL)) THEN NULL WHEN NOT ((`Garage_Cond` IS NULL)) THEN (CASE WHEN (`Garage_Cond` IN ('No_Garage', 'Typical')) THEN `Garage_Cond` WHEN NOT (`Garage_Cond` IN ('No_Garage', 'Typical')) THEN 'other' END) END AS Garage_Cond
#> <SQL> CASE WHEN ((`Paved_Drive` IS NULL)) THEN NULL WHEN NOT ((`Paved_Drive` IS NULL)) THEN (CASE WHEN (`Paved_Drive` IN ('Dirt_Gravel', 'Paved')) THEN `Paved_Drive` WHEN NOT (`Paved_Drive` IN ('Dirt_Gravel', 'Paved')) THEN 'other' END) END AS Paved_Drive
#> <SQL> CASE WHEN ((`Fence` IS NULL)) THEN NULL WHEN NOT ((`Fence` IS NULL)) THEN (CASE WHEN (`Fence` IN ('Minimum_Privacy', 'No_Fence')) THEN `Fence` WHEN NOT (`Fence` IN ('Minimum_Privacy', 'No_Fence')) THEN 'other' END) END AS Fence
#> <SQL> CASE WHEN ((`Sale_Type` IS NULL)) THEN NULL WHEN NOT ((`Sale_Type` IS NULL)) THEN (CASE WHEN (`Sale_Type` IN ('New', 'WD ')) THEN `Sale_Type` WHEN NOT (`Sale_Type` IN ('New', 'WD ')) THEN 'other' END) END AS Sale_Type
#> <SQL> CASE WHEN ((`Sale_Condition` IS NULL)) THEN NULL WHEN NOT ((`Sale_Condition` IS NULL)) THEN (CASE WHEN (`Sale_Condition` IN ('Abnorml', 'Normal', 'Partial')) THEN `Sale_Condition` WHEN NOT (`Sale_Condition` IN ('Abnorml', 'Normal', 'Partial')) THEN 'other' END) END AS Sale_Condition
#> <SQL> CAST(`MS_SubClass` = 'One_and_Half_Story_Finished_All_Ages' AS REAL) AS MS_SubClass_One_and_Half_Story_Finished_All_Ages
#> <SQL> CAST(`MS_SubClass` = 'Two_Story_1946_and_Newer' AS REAL) AS MS_SubClass_Two_Story_1946_and_Newer
#> <SQL> CAST(`MS_SubClass` = 'One_Story_PUD_1946_and_Newer' AS REAL) AS MS_SubClass_One_Story_PUD_1946_and_Newer
#> <SQL> CAST(`MS_SubClass` = 'other' AS REAL) AS MS_SubClass_other
#> <SQL> CAST(`MS_Zoning` = 'Residential_Medium_Density' AS REAL) AS MS_Zoning_Residential_Medium_Density
#> <SQL> CAST(`MS_Zoning` = 'other' AS REAL) AS MS_Zoning_other
#> <SQL> CAST(`Alley` = 'other' AS REAL) AS Alley_other
#> <SQL> CAST(`Lot_Shape` = 'Slightly_Irregular' AS REAL) AS Lot_Shape_Slightly_Irregular
#> <SQL> CAST(`Land_Contour` = 'other' AS REAL) AS Land_Contour_other
#> <SQL> CAST(`Lot_Config` = 'CulDSac' AS REAL) AS Lot_Config_CulDSac
#> <SQL> CAST(`Lot_Config` = 'Inside' AS REAL) AS Lot_Config_Inside
#> <SQL> CAST(`Neighborhood` = 'College_Creek' AS REAL) AS Neighborhood_College_Creek
#> <SQL> CAST(`Neighborhood` = 'Old_Town' AS REAL) AS Neighborhood_Old_Town
#> <SQL> CAST(`Neighborhood` = 'Edwards' AS REAL) AS Neighborhood_Edwards
#> <SQL> CAST(`Neighborhood` = 'Somerset' AS REAL) AS Neighborhood_Somerset
#> <SQL> CAST(`Neighborhood` = 'Northridge_Heights' AS REAL) AS Neighborhood_Northridge_Heights
#> <SQL> CAST(`Neighborhood` = 'Gilbert' AS REAL) AS Neighborhood_Gilbert
#> <SQL> CAST(`Neighborhood` = 'Sawyer' AS REAL) AS Neighborhood_Sawyer
#> <SQL> CAST(`Neighborhood` = 'other' AS REAL) AS Neighborhood_other
#> <SQL> CAST(`Condition_1` = 'Norm' AS REAL) AS Condition_1_Norm
#> <SQL> CAST(`Condition_1` = 'other' AS REAL) AS Condition_1_other
#> <SQL> CAST(`Bldg_Type` = 'TwnhsE' AS REAL) AS Bldg_Type_TwnhsE
#> <SQL> CAST(`Bldg_Type` = 'other' AS REAL) AS Bldg_Type_other
#> <SQL> CAST(`House_Style` = 'One_Story' AS REAL) AS House_Style_One_Story
#> <SQL> CAST(`House_Style` = 'Two_Story' AS REAL) AS House_Style_Two_Story
#> <SQL> CAST(`House_Style` = 'other' AS REAL) AS House_Style_other
#> <SQL> CAST(`Overall_Cond` = 'Above_Average' AS REAL) AS Overall_Cond_Above_Average
#> <SQL> CAST(`Overall_Cond` = 'Good' AS REAL) AS Overall_Cond_Good
#> <SQL> CAST(`Overall_Cond` = 'other' AS REAL) AS Overall_Cond_other
#> <SQL> CAST(`Roof_Style` = 'Hip' AS REAL) AS Roof_Style_Hip
#> <SQL> CAST(`Exterior_1st` = 'Plywood' AS REAL) AS Exterior_1st_Plywood
#> <SQL> CAST(`Exterior_1st` = 'Wd Sdng' AS REAL) AS Exterior_1st_Wd.Sdng
#> <SQL> CAST(`Exterior_1st` = 'other' AS REAL) AS Exterior_1st_other
#> <SQL> CAST(`Exterior_2nd` = 'MetalSd' AS REAL) AS Exterior_2nd_MetalSd
#> <SQL> CAST(`Exterior_2nd` = 'Plywood' AS REAL) AS Exterior_2nd_Plywood
#> <SQL> CAST(`Exterior_2nd` = 'VinylSd' AS REAL) AS Exterior_2nd_VinylSd
#> <SQL> CAST(`Exterior_2nd` = 'Wd Sdng' AS REAL) AS Exterior_2nd_Wd.Sdng
#> <SQL> CAST(`Exterior_2nd` = 'other' AS REAL) AS Exterior_2nd_other
#> <SQL> CAST(`Mas_Vnr_Type` = 'None' AS REAL) AS Mas_Vnr_Type_None
#> <SQL> CAST(`Mas_Vnr_Type` = 'Stone' AS REAL) AS Mas_Vnr_Type_Stone
#> <SQL> CAST(`Exter_Cond` = 'Typical' AS REAL) AS Exter_Cond_Typical
#> <SQL> CAST(`Foundation` = 'CBlock' AS REAL) AS Foundation_CBlock
#> <SQL> CAST(`Foundation` = 'PConc' AS REAL) AS Foundation_PConc
#> <SQL> CAST(`Bsmt_Cond` = 'other' AS REAL) AS Bsmt_Cond_other
#> <SQL> CAST(`Bsmt_Exposure` = 'Gd' AS REAL) AS Bsmt_Exposure_Gd
#> <SQL> CAST(`Bsmt_Exposure` = 'Mn' AS REAL) AS Bsmt_Exposure_Mn
#> <SQL> CAST(`Bsmt_Exposure` = 'No' AS REAL) AS Bsmt_Exposure_No
#> <SQL> CAST(`BsmtFin_Type_1` = 'BLQ' AS REAL) AS BsmtFin_Type_1_BLQ
#> <SQL> CAST(`BsmtFin_Type_1` = 'GLQ' AS REAL) AS BsmtFin_Type_1_GLQ
#> <SQL> CAST(`BsmtFin_Type_1` = 'LwQ' AS REAL) AS BsmtFin_Type_1_LwQ
#> <SQL> CAST(`BsmtFin_Type_1` = 'Rec' AS REAL) AS BsmtFin_Type_1_Rec
#> <SQL> CAST(`BsmtFin_Type_1` = 'Unf' AS REAL) AS BsmtFin_Type_1_Unf
#> <SQL> CAST(`BsmtFin_Type_2` = 'other' AS REAL) AS BsmtFin_Type_2_other
#> <SQL> CAST(`Heating_QC` = 'Good' AS REAL) AS Heating_QC_Good
#> <SQL> CAST(`Heating_QC` = 'Typical' AS REAL) AS Heating_QC_Typical
#> <SQL> CAST(`Central_Air` = 'Y' AS REAL) AS Central_Air_Y
#> <SQL> CAST(`Electrical` = 'SBrkr' AS REAL) AS Electrical_SBrkr
#> <SQL> CAST(`Functional` = 'other' AS REAL) AS Functional_other
#> <SQL> CAST(`Garage_Type` = 'BuiltIn' AS REAL) AS Garage_Type_BuiltIn
#> <SQL> CAST(`Garage_Type` = 'Detchd' AS REAL) AS Garage_Type_Detchd
#> <SQL> CAST(`Garage_Type` = 'No_Garage' AS REAL) AS Garage_Type_No_Garage
#> <SQL> CAST(`Garage_Finish` = 'RFn' AS REAL) AS Garage_Finish_RFn
#> <SQL> CAST(`Garage_Finish` = 'Unf' AS REAL) AS Garage_Finish_Unf
#> <SQL> CAST(`Garage_Cond` = 'Typical' AS REAL) AS Garage_Cond_Typical
#> <SQL> CAST(`Paved_Drive` = 'Paved' AS REAL) AS Paved_Drive_Paved
#> <SQL> CAST(`Fence` = 'No_Fence' AS REAL) AS Fence_No_Fence
#> <SQL> CAST(`Fence` = 'other' AS REAL) AS Fence_other
#> <SQL> CAST(`Sale_Type` = 'WD ' AS REAL) AS Sale_Type_WD.
#> <SQL> CAST(`Sale_Type` = 'other' AS REAL) AS Sale_Type_other
#> <SQL> CAST(`Sale_Condition` = 'Normal' AS REAL) AS Sale_Condition_Normal
#> <SQL> CAST(`Sale_Condition` = 'Partial' AS REAL) AS Sale_Condition_Partial
#> <SQL> (`Lot_Frontage` - 57.6477815699659) / 33.4994407936297 AS Lot_Frontage
#> <SQL> (`Lot_Area` - 10147.9218430034) / 7880.01775943909 AS Lot_Area
#> <SQL> (`Year_Built` - 1971.35631399317) / 30.2453606293747 AS Year_Built
#> <SQL> (`Year_Remod_Add` - 1984.26655290102) / 20.8602858768493 AS Year_Remod_Add
#> <SQL> (`Mas_Vnr_Area` - 101.096928327645) / 178.634544825758 AS Mas_Vnr_Area
#> <SQL> (`BsmtFin_SF_1` - 4.17747440273038) / 2.23337248339064 AS BsmtFin_SF_1
#> <SQL> (`Bsmt_Unf_SF` - 559.071672354949) / 439.540571056778 AS Bsmt_Unf_SF
#> <SQL> (`Total_Bsmt_SF` - 1051.25563139932) / 440.968017663732 AS Total_Bsmt_SF
#> <SQL> (`First_Flr_SF` - 1159.55767918089) / 391.890885253492 AS First_Flr_SF
#> <SQL> (`Second_Flr_SF` - 335.455972696246) / 428.395715008826 AS Second_Flr_SF
#> <SQL> (`Gr_Liv_Area` - 1499.69044368601) / 505.508887472041 AS Gr_Liv_Area
#> <SQL> (`Bsmt_Full_Bath` - 0.431058020477816) / 0.524761963021569 AS Bsmt_Full_Bath
#> <SQL> (`Bsmt_Half_Bath` - 0.0610921501706485) / 0.245175019961096 AS Bsmt_Half_Bath
#> <SQL> (`Full_Bath` - 1.56655290102389) / 0.552940611645541 AS Full_Bath
#> <SQL> (`Half_Bath` - 0.379522184300341) / 0.502629253315165 AS Half_Bath
#> <SQL> (`Bedroom_AbvGr` - 2.8542662116041) / 0.827731141985373 AS Bedroom_AbvGr
#> <SQL> (`TotRms_AbvGrd` - 6.44300341296928) / 1.57296439633446 AS TotRms_AbvGrd
#> <SQL> (`Fireplaces` - 0.599317406143345) / 0.647920916551218 AS Fireplaces
#> <SQL> (`Garage_Cars` - 1.76621160409556) / 0.761136719051791 AS Garage_Cars
#> <SQL> (`Garage_Area` - 472.658361774744) / 215.187195710444 AS Garage_Area
#> <SQL> (`Wood_Deck_SF` - 93.7518771331058) / 126.361561878906 AS Wood_Deck_SF
#> <SQL> (`Mo_Sold` - 6.2160409556314) / 2.71449242543017 AS Mo_Sold
#> <SQL> (`Year_Sold` - 2007.79044368601) / 1.31661292261053 AS Year_Sold
#> <SQL> (`Longitude` - -93.6428968985665) / 0.0256995708419148 AS Longitude
#> <SQL> (`Latitude` - 42.034482233959) / 0.0184100719647591 AS Latitude
#> <SQL> (`MS_SubClass_One_and_Half_Story_Finished_All_Ages` - 0.0979522184300341) / 0.297300769930882 AS MS_SubClass_One_and_Half_Story_Finished_All_Ages
#> <SQL> (`MS_SubClass_Two_Story_1946_and_Newer` - 0.196245733788396) / 0.397224367384822 AS MS_SubClass_Two_Story_1946_and_Newer
#> <SQL> (`MS_SubClass_One_Story_PUD_1946_and_Newer` - 0.0655290102389079) / 0.247499223220503 AS MS_SubClass_One_Story_PUD_1946_and_Newer
#> <SQL> (`MS_SubClass_other` - 0.272013651877133) / 0.44507283956783 AS MS_SubClass_other
#> <SQL> (`MS_Zoning_Residential_Medium_Density` - 0.157679180887372) / 0.364502129111775 AS MS_Zoning_Residential_Medium_Density
#> <SQL> (`MS_Zoning_other` - 0.0665529010238908) / 0.249288632364439 AS MS_Zoning_other
#> <SQL> (`Alley_other` - 0.0675767918088737) / 0.251061111160191 AS Alley_other
#> <SQL> (`Lot_Shape_Slightly_Irregular` - 0.334129692832765) / 0.471765833087708 AS Lot_Shape_Slightly_Irregular
#> <SQL> (`Land_Contour_other` - 0.101365187713311) / 0.301863190671308 AS Land_Contour_other
#> <SQL> (`Lot_Config_CulDSac` - 0.0614334470989761) / 0.240164660939135 AS Lot_Config_CulDSac
#> <SQL> (`Lot_Config_Inside` - 0.73037542662116) / 0.443840507830802 AS Lot_Config_Inside
#> <SQL> (`Neighborhood_College_Creek` - 0.0911262798634812) / 0.287837727934596 AS Neighborhood_College_Creek
#> <SQL> (`Neighborhood_Old_Town` - 0.0815699658703072) / 0.273755153326887 AS Neighborhood_Old_Town
#> <SQL> (`Neighborhood_Edwards` - 0.0662116040955631) / 0.248694061775502 AS Neighborhood_Edwards
#> <SQL> (`Neighborhood_Somerset` - 0.0621160409556314) / 0.241407390841803 AS Neighborhood_Somerset
#> <SQL> (`Neighborhood_Northridge_Heights` - 0.0566552901023891) / 0.231222220401891 AS Neighborhood_Northridge_Heights
#> <SQL> (`Neighborhood_Gilbert` - 0.0563139931740614) / 0.230566413401495 AS Neighborhood_Gilbert
#> <SQL> (`Neighborhood_Sawyer` - 0.0515358361774744) / 0.221125715420464 AS Neighborhood_Sawyer
#> <SQL> (`Neighborhood_other` - 0.383276450511945) / 0.486267739839728 AS Neighborhood_other
#> <SQL> (`Condition_1_Norm` - 0.860750853242321) / 0.346265423193008 AS Condition_1_Norm
#> <SQL> (`Condition_1_other` - 0.0832764505119454) / 0.276346788132951 AS Condition_1_other
#> <SQL> (`Bldg_Type_TwnhsE` - 0.0795221843003413) / 0.270598221400413 AS Bldg_Type_TwnhsE
#> <SQL> (`Bldg_Type_other` - 0.0928327645051195) / 0.290247470995809 AS Bldg_Type_other
#> <SQL> (`House_Style_One_Story` - 0.505460750853242) / 0.500055520299657 AS House_Style_One_Story
#> <SQL> (`House_Style_Two_Story` - 0.297952218430034) / 0.457436454275077 AS House_Style_Two_Story
#> <SQL> (`House_Style_other` - 0.089419795221843) / 0.285397432815224 AS House_Style_other
#> <SQL> (`Overall_Cond_Above_Average` - 0.181911262798635) / 0.385837225088097 AS Overall_Cond_Above_Average
#> <SQL> (`Overall_Cond_Good` - 0.133105802047782) / 0.339747027574091 AS Overall_Cond_Good
#> <SQL> (`Overall_Cond_other` - 0.120477815699659) / 0.325575012535217 AS Overall_Cond_other
#> <SQL> (`Roof_Style_Hip` - 0.188054607508532) / 0.390822469348808 AS Roof_Style_Hip
#> <SQL> (`Exterior_1st_Plywood` - 0.0754266211604096) / 0.264123560635696 AS Exterior_1st_Plywood
#> <SQL> (`Exterior_1st_Wd.Sdng` - 0.143344709897611) / 0.350483849258404 AS Exterior_1st_Wd.Sdng
#> <SQL> (`Exterior_1st_other` - 0.126621160409556) / 0.332604868364192 AS Exterior_1st_other
#> <SQL> (`Exterior_2nd_MetalSd` - 0.152559726962457) / 0.35962396527113 AS Exterior_2nd_MetalSd
#> <SQL> (`Exterior_2nd_Plywood` - 0.0935153583617747) / 0.291202983863757 AS Exterior_2nd_Plywood
#> <SQL> (`Exterior_2nd_VinylSd` - 0.34641638225256) / 0.475908996013667 AS Exterior_2nd_VinylSd
#> <SQL> (`Exterior_2nd_Wd.Sdng` - 0.135494880546075) / 0.34230981537792 AS Exterior_2nd_Wd.Sdng
#> <SQL> (`Exterior_2nd_other` - 0.133447098976109) / 0.3401153502139 AS Exterior_2nd_other
#> <SQL> (`Mas_Vnr_Type_None` - 0.60580204778157) / 0.488761146410944 AS Mas_Vnr_Type_None
#> <SQL> (`Mas_Vnr_Type_Stone` - 0.0849829351535836) / 0.278903898290525 AS Mas_Vnr_Type_Stone
#> <SQL> (`Exter_Cond_Typical` - 0.869965870307167) / 0.336398390738686 AS Exter_Cond_Typical
#> <SQL> (`Foundation_CBlock` - 0.42457337883959) / 0.494362453896239 AS Foundation_CBlock
#> <SQL> (`Foundation_PConc` - 0.447098976109215) / 0.497278472872521 AS Foundation_PConc
#> <SQL> (`Bsmt_Cond_other` - 0.107167235494881) / 0.309378548700855 AS Bsmt_Cond_other
#> <SQL> (`Bsmt_Exposure_Gd` - 0.0969283276450512) / 0.295910648619028 AS Bsmt_Exposure_Gd
#> <SQL> (`Bsmt_Exposure_Mn` - 0.0815699658703072) / 0.273755153326887 AS Bsmt_Exposure_Mn
#> <SQL> (`Bsmt_Exposure_No` - 0.650511945392491) / 0.476889686750965 AS Bsmt_Exposure_No
#> <SQL> (`BsmtFin_Type_1_BLQ` - 0.0918088737201365) / 0.288805248362092 AS BsmtFin_Type_1_BLQ
#> <SQL> (`BsmtFin_Type_1_GLQ` - 0.293174061433447) / 0.455295266685691 AS BsmtFin_Type_1_GLQ
#> <SQL> (`BsmtFin_Type_1_LwQ` - 0.0525597269624573) / 0.223190957475276 AS BsmtFin_Type_1_LwQ
#> <SQL> (`BsmtFin_Type_1_Rec` - 0.0982935153583618) / 0.297761918854365 AS BsmtFin_Type_1_Rec
#> <SQL> (`BsmtFin_Type_1_Unf` - 0.290443686006826) / 0.454044614382599 AS BsmtFin_Type_1_Unf
#> <SQL> (`BsmtFin_Type_2_other` - 0.147098976109215) / 0.354265015722136 AS BsmtFin_Type_2_other
#> <SQL> (`Heating_QC_Good` - 0.162457337883959) / 0.368932792871923 AS Heating_QC_Good
#> <SQL> (`Heating_QC_Typical` - 0.294880546075085) / 0.456066879260253 AS Heating_QC_Typical
#> <SQL> (`Central_Air_Y` - 0.933105802047782) / 0.249881321917311 AS Central_Air_Y
#> <SQL> (`Electrical_SBrkr` - 0.915358361774744) / 0.278395192381353 AS Electrical_SBrkr
#> <SQL> (`Functional_other` - 0.0689419795221843) / 0.253398693690373 AS Functional_other
#> <SQL> (`Garage_Type_BuiltIn` - 0.063481228668942) / 0.243868119627035 AS Garage_Type_BuiltIn
#> <SQL> (`Garage_Type_Detchd` - 0.266894197952218) / 0.442412123006273 AS Garage_Type_Detchd
#> <SQL> (`Garage_Type_No_Garage` - 0.0535836177474403) / 0.225232607667554 AS Garage_Type_No_Garage
#> <SQL> (`Garage_Finish_RFn` - 0.277133105802048) / 0.447659181683976 AS Garage_Finish_RFn
#> <SQL> (`Garage_Finish_Unf` - 0.420136518771331) / 0.493664866213914 AS Garage_Finish_Unf
#> <SQL> (`Garage_Cond_Typical` - 0.909556313993174) / 0.286865319578217 AS Garage_Cond_Typical
#> <SQL> (`Paved_Drive_Paved` - 0.905119453924915) / 0.293099894291764 AS Paved_Drive_Paved
#> <SQL> (`Fence_No_Fence` - 0.804778156996587) / 0.396439042702726 AS Fence_No_Fence
#> <SQL> (`Fence_other` - 0.0825938566552901) / 0.275314331476267 AS Fence_other
#> <SQL> (`Sale_Type_WD.` - 0.865529010238908) / 0.341215883698071 AS Sale_Type_WD.
#> <SQL> (`Sale_Type_other` - 0.052901023890785) / 0.223874096830013 AS Sale_Type_other
#> <SQL> (`Sale_Condition_Normal` - 0.823549488054607) / 0.381268070423093 AS Sale_Condition_Normal
#> <SQL> (`Sale_Condition_Partial` - 0.083617747440273) / 0.276860941338605 AS Sale_Condition_Partial
#> <SQL> (((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((180796.060068261 + (`Lot_Frontage` * 955.635117988102)) + (`Lot_Area` * 1516.76354238106)) + (`Year_Built` * 8074.09994040537)) + (`Year_Remod_Add` * 5932.22192419818)) + (`Mas_Vnr_Area` * 6997.31007185544)) + (`BsmtFin_SF_1` * -2548.64981850423)) + (`Bsmt_Unf_SF` * -3924.5747680907)) + (`Total_Bsmt_SF` * 9069.9604766667)) + (`First_Flr_SF` * 6568.67460482999)) + (`Second_Flr_SF` * 15604.7900975189)) + (`Gr_Liv_Area` * 19292.6248611375)) + (`Bsmt_Full_Bath` * 3296.44905707814)) + (`Bsmt_Half_Bath` * -533.514930287272)) + (`Full_Bath` * 2431.14756181473)) + (`Half_Bath` * 1403.62028448762)) + (`Bedroom_AbvGr` * -3345.30530477555)) + (`TotRms_AbvGrd` * 915.757489815814)) + (`Fireplaces` * 4709.45091860584)) + (`Garage_Cars` * 7318.62377224312)) + (`Garage_Area` * 1681.64099399674)) + (`Wood_Deck_SF` * 1017.69312375784)) + (`Mo_Sold` * -217.895951839059)) + (`Year_Sold` * -1007.19585740409)) + (`Longitude` * 2773.88419706623)) + (`Latitude` * 7287.77027386768)) + (`MS_SubClass_One_and_Half_Story_Finished_All_Ages` * -1687.41646914787)) + (`MS_SubClass_Two_Story_1946_and_Newer` * -3446.69967089123)) + (`MS_SubClass_One_Story_PUD_1946_and_Newer` * 62.0994382871212)) + (`MS_SubClass_other` * -535.707786962906)) + (`MS_Zoning_Residential_Medium_Density` * -2675.78583268023)) + (`MS_Zoning_other` * -2924.69567314633)) + (`Alley_other` * -316.99110420436)) + (`Lot_Shape_Slightly_Irregular` * 1245.06912629884)) + (`Land_Contour_other` * 735.18400407958)) + (`Lot_Config_CulDSac` * 2734.60341025334)) + (`Lot_Config_Inside` * 884.153669999533)) + (`Neighborhood_College_Creek` * 4526.82057036694)) + (`Neighborhood_Old_Town` * 1306.00158697638)) + (`Neighborhood_Edwards` * 538.075017955702)) + (`Neighborhood_Somerset` * 6714.41917837366)) + (`Neighborhood_Northridge_Heights` * 10903.2646416317)) + (`Neighborhood_Gilbert` * -3618.64478818433)) + (`Neighborhood_Sawyer` * 2749.71489400735)) + (`Neighborhood_other` * 8551.13463346536)) + (`Condition_1_Norm` * 4909.71154465354)) + (`Condition_1_other` * 1934.41525135308)) + (`Bldg_Type_TwnhsE` * -6070.06289564394)) + (`Bldg_Type_other` * -8159.52292042577)) + (`House_Style_One_Story` * 3381.4443870777)) + (`House_Style_Two_Story` * -3021.28835917451)) + (`House_Style_other` * -904.047140141237)) + (`Overall_Cond_Above_Average` * 1125.01512632643)) + (`Overall_Cond_Good` * 2685.0288965588)) + (`Overall_Cond_other` * 351.426196807595)) + (`Roof_Style_Hip` * 3907.97725791189)) + (`Exterior_1st_Plywood` * 225.291064359611)) + (`Exterior_1st_Wd.Sdng` * 384.762479987224)) + (`Exterior_1st_other` * 4477.11592638793)) + (`Exterior_2nd_MetalSd` * 2284.58015409167)) + (`Exterior_2nd_Plywood` * -1588.48199587958)) + (`Exterior_2nd_VinylSd` * 1474.80729570628)) + (`Exterior_2nd_Wd.Sdng` * 1831.29879973843)) + (`Exterior_2nd_other` * -976.637274539353)) + (`Mas_Vnr_Type_None` * 4971.05846503306)) + (`Mas_Vnr_Type_Stone` * 1944.99896140768)) + (`Exter_Cond_Typical` * 19.6204254164979)) + (`Foundation_CBlock` * -891.86945726365)) + (`Foundation_PConc` * 2068.63383426027)) + (`Bsmt_Cond_other` * -172.334350524604)) + (`Bsmt_Exposure_Gd` * 5690.28657826563)) + (`Bsmt_Exposure_Mn` * -2679.99772126547)) + (`Bsmt_Exposure_No` * -5597.49995139766)) + (`BsmtFin_Type_1_BLQ` * 432.57727936453)) + (`BsmtFin_Type_1_GLQ` * 5201.48231449896)) + (`BsmtFin_Type_1_LwQ` * 126.495750334258)) + (`BsmtFin_Type_1_Rec` * 1691.7550284456)) + (`BsmtFin_Type_1_Unf` * 3596.92372466205)) + (`BsmtFin_Type_2_other` * -666.080853545791)) + (`Heating_QC_Good` * -788.259085823185)) + (`Heating_QC_Typical` * -2456.20980903068)) + (`Central_Air_Y` * 402.919986048993)) + (`Electrical_SBrkr` * 139.091114370893)) + (`Functional_other` * -5120.42353672279)) + (`Garage_Type_BuiltIn` * -427.250007631446)) + (`Garage_Type_Detchd` * -207.741377522263)) + (`Garage_Type_No_Garage` * 2153.29068352442)) + (`Garage_Finish_RFn` * -3908.39521205631)) + (`Garage_Finish_Unf` * -2216.40003714453)) + (`Garage_Cond_Typical` * 1711.68386807371)) + (`Paved_Drive_Paved` * 913.813251909226)) + (`Fence_No_Fence` * -1204.23822888682)) + (`Fence_other` * -406.889886687666)) + (`Sale_Type_WD.` * -4040.58640251206)) + (`Sale_Type_other` * -2800.14205589687)) + (`Sale_Condition_Normal` * 2884.92023929979)) + (`Sale_Condition_Partial` * 2258.73838712945) AS .pred
```
