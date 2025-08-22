#Function to assign latitude and longitude to madinley outputs 
#Created on: Aug 21 2025
#Created by ENB
#Last edited: Aug 22 2025 
#Last edited by: ENB 

#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#Step 0. Download dependencies
rm(list=ls())

#load relevant libraries for script
pkgs <- c("tidyverse", "terra", "MadingleyR")
#install.packages(pkgs)
lapply(pkgs, library, character.only = TRUE)
rm(pkgs)

#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#Function
#Requires: a madingley data input with spatial window, grid size, and 
#Grid cell indices

assign_lat_lon <- function(madingley_data) {
  ncol <- (madingley_data$spatial_window[2] - madingley_data$spatial_window[1]) / madingley_data$grid_size
  nrow <- (madingley_data$spatial_window[4] - madingley_data$spatial_window[3]) / madingley_data$grid_size
  
  lat_lon_output <- rast(
    nrows = nrow,
    ncols = ncol,
    xmin = madingley_data$spatial_window[1],
    xmax = madingley_data$spatial_window[2],
    ymin = madingley_data$spatial_window[3],
    ymax = madingley_data$spatial_window[4],
    crs = "EPSG:4326"
  )
  
  # Extract coords in "default" orientation
  coords <- as.data.frame(
    terra::xyFromCell(lat_lon_output, c(unique(madingley_data$cohorts$GridcellIndex) + 1))
  )
  
  # Flip latitude so north is at the top 
  coords$y <- madingley_data$spatial_window[4] - (coords$y - madingley_data$spatial_window[3])
  
  coords_with_IDs <- cbind(coords, GridcellIndex = unique(madingley_data$cohorts$GridcellIndex))
  colnames(coords_with_IDs) <- c("lon", "lat", "GridcellIndex")
  
  madingley_data$cohorts <- dplyr::left_join(madingley_data$cohorts, coords_with_IDs, by = "GridcellIndex")
  madingley_data$stocks  <- dplyr::left_join(madingley_data$stocks,  coords_with_IDs, by = "GridcellIndex")
  
  return(madingley_data)
}


