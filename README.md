<<<<<<< HEAD
# BIOS2 Biodiversity Modelling 2025 Summer School collaboration repository

This repository provides resources and scripts for the Biodiversity Modelling 2025 summer school, with a focus on using the Madingley model. 🌍

The purpose is to facilitate collaboration and learning among students: run simulations, analyse results, and share reusable code. This is a living project — contributions are welcome! 🤝

You are encouraged to contribute by:
- 🧩 Adding reusable functions to the `R/` folder.
- 📦 Packaging the project as an R package for better organization and sharing.
- 🎛️ Creating a Shiny app in the `app/` folder to visualise simulation outputs.
- 📝 Writing vignettes in the `vignettes/` folder to document workflows and collaboration guidelines.
- ▶️ Creating simulation scripts using the `MadingleyR` package in the `scripts/` folder.

## Getting Started

### Cloning the repository

To get started, make sure you have Git installed and configured and then clone the repository

```bash
# Configure your Git username and email if you haven't already
git config --global user.name "Your Name"
git config --global user.email your.name@institution.com

# Clone the repository
git clone https://github.com/bios2/biodiversity_modelling_2025.git
```

### Working with the repository

You can work with the repository in your preferred R environment, such as RStudio, JupyterLab or vscode, or directly in R :

```bash
cd biodiversity_modelling_2025
R
```

### Installation Instructions for local machine

Follow the instructions in the `vignettes/installing_madingleyR.md` file to install the `madingleyR` package and its dependencies on your local machine. This is essential for running biodiversity simulations using the Madingley model in R.

```r
# Install the packages for package development
install.packages(c("devtools", "roxygen2", "testthat", "usethis"))

# Install shiny package if you haven't already
install.packages("shiny")
```

### Run the demo simulation

```r
# Load the package
library(MadingleyR)

source("scripts/demo_madingley.R")
# or run the demo script directly
# Rscript scripts/demo_madingley.R
```

## Modifying the Madingley R code
Prerequisites: pull the latest version of the repository to ensure you have the most recent changes. Or a specific branch you want to work on.
First make sure you have this project installed, otherwise clone it.

Then uninstall your current version of the package:

```r 
  try(detach("package:MadingleyR", unload = TRUE))
  try(remove.packages("MadingleyR"))
```

Then reinstall the package from the local source code:

```r
library(remotes)
remotes::install_github(
  "bios2/biodiversity_modelling_2025",
  subdir = "MadingleyR-master/Package",
  build_vignettes = TRUE
)

#You can also get the pacakge from a specific branch like so
remotes::install_github(
  "bios2/biodiversity_modelling_2025@my-branch-name",
  subdir = "MadingleyR-master/Package",
  build_vignettes = TRUE
)
```

You will now have the latest version of the madingleyR from the Bios2 workshop

Now if you want to modify a part of the package, you need to go inside the folder where you have the `biodiversity_modelling_2025` repository and edit the files in the `MadingleyR-master/Package/R/` folder. 

After making changes, you need to reload your library:
```r
devtools::load_all("YOUR_PATH/biodiversity_modelling_2025/MadingleyR-master/Package")

```

### Important readings
- [Source code][ Process raster data for madingley model](https://github.com/CNeu-hub/Madingley_CC_LU)
- [Paper][Model-based impact analysis of climate change and land-use intensification on trophic networks](https://nsojournals.onlinelibrary.wiley.com/doi/full/10.1111/ecog.07533)
=======
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

>>>>>>> wenhuan_local_snapshot
