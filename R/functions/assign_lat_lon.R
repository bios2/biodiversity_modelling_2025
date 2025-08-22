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

assign_lat_lon <- function(x, spatial_window = NULL) {
  # If x is a list (Madingley object)
  if (is.list(x) && !is.data.frame(x)) {
    ncol <- (x$spatial_window[2] - x$spatial_window[1]) / x$grid_size
    nrow <- (x$spatial_window[4] - x$spatial_window[3]) / x$grid_size
    
    lat_lon_output <- rast(
      nrows = nrow,
      ncols = ncol,
      xmin = x$spatial_window[1],
      xmax = x$spatial_window[2],
      ymin = x$spatial_window[3],
      ymax = x$spatial_window[4],
      crs = "EPSG:4326"
    )
    
    coords <- as.data.frame(
      terra::xyFromCell(lat_lon_output, c(unique(x$cohorts$GridcellIndex) + 1))
    )
    
    coords$y <- x$spatial_window[4] - (coords$y - x$spatial_window[3])
    
    
    coords_with_IDs <- cbind(coords, GridcellIndex = unique(x$cohorts$GridcellIndex))
    colnames(coords_with_IDs) <- c("lon", "lat", "GridcellIndex")
    
    x$cohorts <- dplyr::left_join(x$cohorts, coords_with_IDs, by = "GridcellIndex")
    x$stocks  <- dplyr::left_join(x$stocks,  coords_with_IDs, by = "GridcellIndex")
    
    return(x)
  }
  
  # If x is a dataframe
  else if (is.data.frame(x)) {
    if (is.null(spatial_window)) {
      stop("You must provide spatial_window = c(xmin, xmax, ymin, ymax) when using a dataframe.")
    }
    
    ncell <- max(as.numeric(x$GridcellIndex))
    aspect_ratio <- (spatial_window[2] - spatial_window[1]) / (spatial_window[4] - spatial_window[3])
    ncol <- round(sqrt(ncell * aspect_ratio))
    nrow <- ncell / ncol
    
    lat_lon_output <- rast(
      nrows = nrow,
      ncols = ncol,
      xmin = spatial_window[1],
      xmax = spatial_window[2],
      ymin = spatial_window[3],
      ymax = spatial_window[4],
      crs = "EPSG:4326"
    )
    
    coords <- as.data.frame(
      terra::xyFromCell(lat_lon_output, c(unique(as.numeric(x$GridcellIndex))))
    )
    coords$y <- spatial_window[4] - (coords$y - spatial_window[3])
    
    coords_with_IDs <- cbind(coords, GridcellIndex = unique(x$GridcellIndex))
    colnames(coords_with_IDs) <- c("lon", "lat", "GridcellIndex")
    
    x <- dplyr::left_join(x, coords_with_IDs, by = "GridcellIndex")
    
    return(x)
  }
  
  else {
    stop("Input must be either a list (Madingley object) or a dataframe with GridcellIndex.")
  }
}
