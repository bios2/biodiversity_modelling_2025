library(MadingleyR)
library(terra)
library(tidyverse)

read_rasters <- function(input_folder){
  raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
  
  r_list <- lapply(raster_files, rast)
  
  return(r_list)
}

input_folder <- "Data/land_cover/land_cover_projection/raw"
output_folder <- "Data/land_cover/land_cover_projection/processed"

# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")

# Read land cover data
r_hanpp_list <- read_rasters(input_folder)
mask <- sptl_inp[["hanpp"]]

# Process HANPP
for(i in 1:length(r_hanpp_list)){
  r_hanpp <- r_hanpp_list[[i]]
  r_hanpp <- subst(r_hanpp, from=c(5,6), to=c(0.165,0.27))
  r_hanpp[r_hanpp >= 1] <- 1
  
  r_hanpp <- project(r_hanpp, mask, method="bilinear")
  
  r_hanpp_list[[i]] <- r_hanpp
  
  writeRaster(r_hanpp,
              paste0(output_folder,"/hanpp_",
                     names(r_hanpp),'.tif'),
              overwrite=T)
}