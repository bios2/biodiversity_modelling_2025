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

### Installation Instructions for local machine

```r
# Install the packages for package development
install.packages(c("devtools", "roxygen2", "testthat", "usethis"))

# Install shiny package if you haven't already
install.packages("shiny")

# Install madingleyR
# Read vignettes\getting_started_madingleyr_on_HPC.md for instructions on how to install the dependencies on an HPC such as cedar

install.packages(c("remotes","data.table","terra","sf"))
library(remotes)
install_github("MadingleyR/MadingleyR", subdir="Package", build_vignettes=FALSE)

# Load the package and check the version
library(MadingleyR)
madingley_version()
```

### Run the demo simulation

```r
# Load the package
library(MadingleyR)

source("scripts/demo_madingley.R")
# or run the demo script directly
# Rscript scripts/demo_madingley.R
```