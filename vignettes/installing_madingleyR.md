# Installing madingleyR

These instructions guide you through installing the `madingleyR` package on your local machine, which is essential for running biodiversity simulations using the Madingley model in R.

## Installing spatial dependencies for madingleyR

MadingleyR depends on spatial R packages (`sf`, `terra`). They each require additional system dependencies to be installed before the R packages can be installed. Follow the instructions on their respective project pages to install the packages and their dependencies to your system (windows, macOS, or Linux).

* [Installing sf](https://github.com/r-spatial/sf?tab=readme-ov-file#installing)
* [Installing terra](https://rspatial.github.io/terra/)

You can test your terra and sf installations by running the following commands in R:

```r
# Check installed package versions
packageVersion("terra")
packageVersion("sf")

# For `sf`, also show versions of system dependencies (GDAL/GEOS/PROJ)
sf::sf_extSoftVersion()
```

## Installing madingleyR

```r
# Install the missing dependencies
install.packages(c("remotes","data.table"))

remotes::install_github("MadingleyR/MadingleyR", subdir="Package", build_vignettes=FALSE)

# Test the installation
library(MadingleyR)
madingley_version()
```



