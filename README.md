# 2025 Summer Biodiversity Modelling Sharing

This repository contains scripts and data preparation steps for running **MadingleyR** experiments on biodiversity responses under **climate change (CHELSA CMIP6, SSP585, 2050s)** and **vegetation reduction (autotroph removal)** scenarios. Outputs for the North America experiment are saved in `TempMadingleyOuts_climate_change_NA/`.

## Study Areas (spatial windows)

* **North America (Group 1 main run)**

  ```r
  spatial_window <- c(-150, -50, 10, 85)
  ```
* **Small window for quick tests**

  ```r
  spatial_window <- c(30, 36, -6, 2)
  ```

## Directory Structure

```
CHELSA ssp585 2050s/                # CHELSA CMIP6 climate inputs (tmax/tmin, 30")
TempMadingleyOuts_climate_change_NA/ # Model outputs for NA runs
Readme.md

1-climate data stack.R
2-model_run_remove_autotrophs_small_window.R
3-model_run_climte_change_and_remove_autotrophs_small_window.R
4-Shannon diversity_reference.R
5-Shannon diversity_remove_autotrophs.R
6-Shannon diversity_climate_change_after_spin.R
7-Shannon diversity_climate_change_and_remove_autotraph_final.R
Group-1-climate change scenario_NA.R

```

## Data Source

* **CHELSA CMIP6 (SSP585, 2050s)**: monthly **tmax/tmin** at 30″ resolution.
  I compute **tmean** and aggregate to **1°** to be compatible with MadingleyR spatial inputs.
  Website: [https://chelsa-climate.org/cmip6/](https://chelsa-climate.org/cmip6/)

## Script Overview

1. **`1-climate data stack.R`**

   * Builds climate stacks from CHELSA downloads.
   * Computes `tmean = (tmax + tmin) / 2` and aggregates to **1°**.
   * Ensures units and layer order are compatible with other MadingleyR spatial inputs.

2. **`2-model_run_remove_autotrophs_small_window.R`**

   * Runs a vegetation-reduction scenario by **removing autotroph biomass until \~5% remains**.
   * Uses the **small test window** for faster iteration.

3. **`3-model_run_climte_change_and_remove_autotrophs_small_window.R`**

   * Combines **climate change** (CHELSA SSP585 2050s) **and** **autotroph removal** in one run (small window).

4. **`4-Shannon diversity_reference.R`**

   * Computes **Shannon diversity** under the **reference (baseline)** scenario after model spin-up.

5. **`5-Shannon diversity_remove_autotrophs.R`**

   * Computes **Shannon diversity** under the **autotroph-removal** scenario.

6. **`6-Shannon diversity_climate_change_after_spin.R`**

   * Computes **Shannon diversity** under the **climate change only** scenario (after spin-up).

7. **`7-Shannon diversity_climate_change_and_remove_autotraph_final.R`**

   * Computes **Shannon diversity** for the **combined scenario** (climate change + autotroph removal).

8. **`Group-1-climate change scenario_NA.R`**

   * Entry script for the **North America** experiment.
   * Results are stored in `TempMadingleyOuts_climate_change_NA/`.

## Quick Start

1. Prepare CHELSA inputs under `CHELSA ssp585 2050s/` (tmax/tmin, 30″).
2. Run **`1-climate data stack.R`** to produce 1° tmean stacks compatible with MadingleyR.
3. For **North America**, use the Group 1 script (`Group-1-climate change scenario.R`); outputs will go to `TempMadingleyOuts_climate_change_NA/`.
4. Use scripts **4–7** to compute and compare **Shannon diversity** under different scenarios.

### R Packages (typical)

* `MadingleyR`, `terra`, `dplyr`, `vegan` (and any others noted in the scripts).


## Notes

* Keep paths in the scripts consistent with your local layout (e.g., CHELSA folder).
* Ensure layer units and names match MadingleyR expectations.
* For HPC runs, adapt `out_dir`, walltime, and memory requests accordingly.

## Acknowledgements

* **CHELSA** for CMIP6 climate projections.
* **MadingleyR** team for the ecosystem model framework.

---

