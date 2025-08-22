#Test Madingley run with new scenario 
#

#Created on: Aug 22 2025
#Created by ENB
#Last edited: 
#Last edited by: 

#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#Step 0. Download neccesary packages
rm(list=ls())

#load relevant libraries for script
pkgs <- c("tidyverse", "sp", "sf", "terra", "raster",  "parallel", 
          "lubridate", "MadingleyR")
#install.packages(pkgs)
lapply(pkgs, library, character.only = TRUE)
rm(pkgs)

#Step 1. Initialize and run spin-up for MadingleyR for
#North America (not including Greenland)

#Set North America spatial window
#spatial_window = c(-175, -45, 10, 80) 
#test with small spatial window 
#spatial_window = c(-110, -108, 50, 52) 


#Read in an example raster for new HaPP
hanpp_2055 <- rast("Data/HANPPglobal_SSP5_RCP85_2055.tif")
#change resolution to 1 degree
hanpp_2055 <- project(hanpp_2055, rast(crs = crs(hanpp_2055), ext = ext (hanpp_2055), 
                                       res = 1))


#Load in the default spatial inputs 
sptl_inp = madingley_inputs('spatial inputs') # load default inputs
#add in the new hanpp 2055 raster
sptl_inp$hanpp = hanpp_2055

mdata = madingley_init(spatial_window = spatial_window, spatial_inputs = sptl_inp)


# Run spin-up of 100 years 
mdata2 = madingley_run(madingley_data = mdata,
                       out_dir = "madingley_data_test",
                       spatial_inputs = sptl_inp,
                       years = 100)

#Run with the new HANPP
mdata4 = madingley_run(
  out_dir = "madingley_data_test",
  years = 50,
  madingley_data = mdata2,
  spatial_inputs = sptl_inp,
  apply_hanpp = 1) 



