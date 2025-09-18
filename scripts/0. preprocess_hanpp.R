library(MadingleyR)
library(terra)
library(tidyverse)

source("R/functions/utils_rasters.R")

input_folder <- "Data/land_cover/land_cover_projection/raw"
output_folder <- "Data/land_cover/land_cover_projection/processed"

# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
mask <- sptl_inp[["hanpp"]]

# Read land cover data
r_hanpp_list <- read_rasters(input_folder)

# Process HANPP
for(i in 1:length(r_hanpp_list)){
  r_hanpp <- r_hanpp_list[[i]]
  
  # Anthropic presence: 0.73 Agricultural land: 0.835
  r_hanpp <- subst(r_hanpp, from=c(5,6), to=c(0.165,0.27))
  r_hanpp[r_hanpp >= 1] <- 1
  
  r_hanpp <- project(r_hanpp, mask, method="bilinear")
  
  r_hanpp_list[[i]] <- r_hanpp
  
  writeRaster(r_hanpp,
              paste0(output_folder,"/hanpp_",
                     names(r_hanpp),'.tif'),
              overwrite=T)
}