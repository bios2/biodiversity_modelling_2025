# Set directory - don't forget to change the 
setwd("/home/samsam/biodiversity_modelling_2025/")

# Load GitHub functions
source("R/functions/assign_lat_lon.R")
source("R/functions/calculate_madingley_diversity.R")
source("R/functions/calculate_time_series.R")
source("R/functions/plot_seasonality.R")
source("R/functions/compare_scenarios.R")

# Load libraries
library(tidyverse)
library(tidyterra)
library(terra)

# Read and transform raw outputs into monthly cohort list
analyze_diversity <- function(scenario = c("Control", "Climate", "LandUse",
                                           "Mixed","HerbRem","CarnRem")){
  
  #Write filepath
  filepath = paste0("R/output_data/MadingleySimulationOutputs/", scenario, sep = "")
  
  #Calculate full dataset
  dataset <- calculate_time_series(out_dir = filepath, size_bin_resolution = 100)
  dataset <- filter(dataset, Month == "7")
  
  #Calculate diversity
  analysis <- calculate_madingley_diversity(dataset)
  analysis <- assign_lat_lon(analysis, spatial_window = c(-170, -50, 15, 83))
  analysis <- analysis[,c("DiversityIndex", "lon", "lat")]
  analysis$DiversityIndex <- as.numeric(analysis$DiversityIndex)
  
  #Transform into raster
  points <- vect(analysis, geom = c("lon", "lat"), crs = "EPSG:4326")
  r <- rast(ext(points), resolution = 1)  # adjust resolution as needed
  crs(r) <- "EPSG:4326"
  rasterized <- rasterize(points, r, field = "DiversityIndex", fun = "mean")
  
  #Represent graph
  graph <- ggplot()+
    geom_spatraster(data = rasterized, aes(fill = mean))+
    scale_fill_grass_c(palette = "plasma", limits = c(0,5))+
    theme_classic()
  
  #Write raster as .tiff
  if(scenario == "CarnRem"){
    terra::writeRaster(rasterized, 
                       filename = "R/figures/shannon_NoPred.tif", 
                       overwrite = TRUE)
  }
  if(scenario == "HerbRem"){
    terra::writeRaster(rasterized, 
                       filename = "R/figures/shannon_NoHerb.tif", 
                       overwrite = TRUE)
  }
  if(scenario == "Control"){
    terra::writeRaster(rasterized, 
                       filename = "R/figures/shannon_t2020_h2020.tif", 
                       overwrite = TRUE)
  }
  if(scenario == "Climate"){
    terra::writeRaster(rasterized,
                      filename = "R/figures/shannon_t2050_h2020.tif",
                      overwrite = TRUE)
  }
  if(scenario == "LandUse"){
    terra::writeRaster(rasterized,
                       filename = "R/figures/shannon_t2020_h2050.tif",
                       overwrite = TRUE)
  }
  if(scenario == "Mixed"){
    terra::writeRaster(rasterized,
                       filename = "R/figures/shannon_t2050_h2050.tif",
                       overwrite = TRUE)
    
  }
  
  print(graph)
  
  return(rasterized)
}

#Running the function for all scenarios
scenarios <- c("Control",
               "LandUse",
               "Climate",
               "HerbRem",
               "CarnRem",
               "Mixed")
for(s in scenarios){
  analyze_diversity(scenario = s)
}

# Generate seasonality plots
analyze_seasonality <- function(scenario = c("Control", "Climate", "LandUse",
                                             "Mixed","HerbRem","CarnRem")){
  #Write filepath
  filepath = paste0("R/output_data/MadingleySimulationOutputs/", scenario, sep = "")
  
  #Calculate full dataset
  dataset <- calculate_time_series(out_dir = filepath, size_bin_resolution = 100)
  
  #Calculate and output seasonality plots
  graph <- plot_seasonality(dataset)
  
  #Write plot as .RDS
  if(scenario == "CarnRem"){
    saveRDS(graph, file = "R/figures/seasonality_NoPred.RDS")
  }
  if(scenario == "HerbRem"){
    saveRDS(graph, file = "R/figures/seasonality_NoHerb.RDS")
  }
  if(scenario == "Control"){
    saveRDS(graph, file = "R/figures/seasonality_Clim2020_Hum2020.RDS")
  }
  if(scenario == "Climate"){
    saveRDS(graph, file = "R/figures/seasonality_Clim2050_Hum2020.RDS")
  }
  if(scenario == "LandUse"){
    saveRDS(graph, file = "R/figures/seasonality_Clim2020_Hum2050.RDS")
  }
  if(scenario == "Mixed"){
    saveRDS(graph, file = "R/figures/seasonality_Clim2050_Hum2050.RDS")
  }
  return(graph)
}

#Run analyses for all scenarios
for(s in scenarios){
  analyze_seasonality(s)}

