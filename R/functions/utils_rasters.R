library("terra")
library("sf")

#' Reads all rasters in a folder and save them in a list
#' @param input_folder String of folder path
#' @return List of rasters
read_rasters <- function(input_folder){
  raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
  
  r_list <- lapply(raster_files, rast)
  
  return(r_list)
}

#' Crops and masks list of rasters with SpatVector
#' @param inputs List of rasters or one raster
#' @param spatial_vector SpatVector
#' @return List of rasters or one raster
mask_rasters_with_vector <- function(inputs, spatial_vector){
  
  if(class(inputs)=="list"){
    for(i in 1:length(inputs)) { 
      r_crop <- crop(inputs[[i]], spatial_vector)
      r_mask <- mask(r_crop, spatial_vector) 
      inputs[[i]] <- r_mask
    }
  }else{
    r_crop <- crop(inputs, spatial_vector)
    r_mask <- mask(r_crop, spatial_vector) 
    inputs <- r_mask
  }
  
  return(inputs)
}

#' Crops list of rasters with spatial window
#' @param inputs List of rasters or one raster
#' @param spatial_window Vector with coordinates 
#' c(minimum longitude, maximum longitude, minimum latitude, maximum latitude)
#' @return List of rasters or one raster
crop_rasters_with_window <- function(inputs, spatial_window){
  
  if(class(inputs)=="list"){
    for(i in 1:length(inputs)) { inputs[[i]] = raster::crop(inputs[[i]], spatial_window) }
  }else{
    inputs = raster::crop(inputs, spatial_window)
  }
  
  return(inputs)
}
