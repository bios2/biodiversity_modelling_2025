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

### Important readings
- [Source code][ Process raster data for madingley model](https://github.com/CNeu-hub/Madingley_CC_LU)
- [Paper][Model-based impact analysis of climate change and land-use intensification on trophic networks](https://nsojournals.onlinelibrary.wiley.com/doi/full/10.1111/ecog.07533)
