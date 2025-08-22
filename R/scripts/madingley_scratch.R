#Generating "dummy data" for investigating cohort timeseries data
#Using MadingleyR 

#Created on: Aug 21 2025
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


#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_#_
#Step 1. Initialize and run spin-up for MadingleyR for
#North America (not including Greenland)

#Set North America spatial window
#spatial_window = c(-175, -45, 10, 80) 
#For now, use serengeti spatial window
spatial_window = c(31, 35, -5, -1) # region of interest: Serengeti


#Load the default madingley inputs, and adjust manually 
sptl_inp = madingley_inputs('spatial inputs') # load default inputs
#Take a look at some of the default inputs
plot(sptl_inp$realm_classification) # This is ocean vs terrestrial vs antarctica
plot(sptl_inp$land_mask) #Pure ocean vs terrestrial
plot(sptl_inp$hanpp) #Human appropriation of net primary productivity 
plot(sptl_inp$available_water_capacity) #available water
plot(sptl_inp$Ecto_max) #maximum size of ecothterms across the globe
plot(sptl_inp$Endo_C_max) #maximum size of endotherm carnivores across the globe
plot(sptl_inp$Endo_H_max) #maximum size of endotherm herbivores across the globe
plot(sptl_inp$Endo_O_max) #maximum size of endotherm omnivores across the globe
plot(sptl_inp$`near-surface_temperature`)

#Investigate cohort definitions
cohort_defs = madingley_inputs('cohort definition') # load default inputs
colnames(cohort_defs)
table(cohort_defs$DEFINITION_Endo.Ectotherm, 
      cohort_defs$PROPERTY_Minimum.mass)
table(cohort_defs$DEFINITION_Endo.Ectotherm, 
      cohort_defs$PROPERTY_Herbivory.assimilation)
table(cohort_defs$DEFINITION_Endo.Ectotherm, 
      cohort_defs$NOTES_group.description)

#Investigating model parameters 
model_parameters = madingley_inputs('model parameters') # load default inputs


#Run the vingette 
mdata = madingley_init(spatial_window = spatial_window, spatial_inputs = sptl_inp, cohort_def = cohort_defs)

bios2 <- madingley_run_BIOS2(mdata,
                             out_dir = tempdir(), 
                             years = 10, 
                             output_name = "bios_test_run", 
                             output_timestep = c(10, 0, 10, 10))

#output of mdata: 
head(mdata)

mdata2 = madingley_run(out_dir = 'C:/MadingleyOut', 
  madingley_data = mdata, 
                       cohort_def = cohort_defs,
                       spatial_inputs = sptl_inp, 
                       years = 15)
head(mdata2)

#Read in Ruby's data to test function
assign_lat_lon <- function(madingley_data) {
  ncol <- (madingley_data$spatial_window[2] - madingley_data$spatial_window[1]) / madingley_data$grid_size
  nrow <- (madingley_data$spatial_window[4] - madingley_data$spatial_window[3]) / madingley_data$grid_size
  
  lat_lon_output <-  rast(
    nrows = nrow,
    ncols = ncol,
    xmin = madingley_data$spatial_window[1],
    xmax = madingley_data$spatial_window[2],
    ymin = madingley_data$spatial_window[3],
    ymax = madingley_data$spatial_window[4],
    crs = "EPSG:4326"  # lat/long
  )
  
  coords <- as.data.frame(terra::xyFromCell(lat_lon_output, c(unique(madingley_data$cohorts$GridcellIndex) + 1)))
  
  coords_with_IDs <- cbind(coords, c(unique(madingley_data$cohorts$GridcellIndex)))
  colnames(coords_with_IDs) <- c("lon", "lat", "GridcellIndex")
  
  madingley_data$cohorts <- dplyr::left_join(madingley_data$cohorts, coords_with_IDs, by = "GridcellIndex")
  madingley_data$stocks <- dplyr::left_join(madingley_data$stocks, coords_with_IDs, by = "GridcellIndex")
  
  
  return(madingley_data)
}

ruby_data <- readRDS("R/input_data/exampleRunOutput")

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


ruby_data <- assign_lat_lon(ruby_data)

#spatialize ruby data
cohort_data <- ruby_data$cohorts %>%
  rename(x = "lon", y = "lat")
cohort_data_wide <- cohort_data %>%
  group_by(FunctionalGroupIndex, x ,y) %>%
  summarize(functional_group_biomass = sum(CohortAbundance))  %>%
  pivot_wider(
    names_from = "FunctionalGroupIndex", 
    values_from = "functional_group_biomass"
  )
cohort_data_wide <- cohort_data_wide %>%
  dplyr::select(x, y, '0', '6', '8')
raster_stocks <- rasterFromXYZ(cohort_data_wide)

#Now, have the function be able to take ruby's data with GridcellIndex and spatial window 
ruby_timeseries <- readRDS("R/output_data/cohortTimeseriesData")
ruby_spatialwindow <- c(30, 35, -15, -10)

#Adjust the function to work with ruby's output
assign_lat_lon_dataset <- function(dataframe, spatial_window) {

  ncell <- max(as.numeric(dataframe$GridcellIndex))
  aspect_ratio <- (spatial_window[2] - spatial_window[1]) / (spatial_window[4] - spatial_window[3])
  ncol <- round(sqrt(ncell * aspect_ratio))
  nrow <- ncell / ncol
  
  
  lat_lon_output <-  rast(
    nrows = nrow,
    ncols = ncol,
    xmin = spatial_window[1],
    xmax = spatial_window[2],
    ymin = spatial_window[3],
    ymax = spatial_window[4],
    crs = "EPSG:4326"  # lat/long
  )
  
  coords <- as.data.frame(terra::xyFromCell(lat_lon_output, c(unique(as.numeric(dataframe$GridcellIndex)))))
  
  coords_with_IDs <- cbind(coords, c(unique(dataframe$GridcellIndex)))
  colnames(coords_with_IDs) <- c("lon", "lat", "GridcellIndex")
  
 dataframe <- dplyr::left_join(dataframe, coords_with_IDs, by = "GridcellIndex")
  
  return(dataframe)
}




#Test the chatgpt function
assign_lat_lon_flex <- function(x, spatial_window = NULL) {
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
    
    coords_with_IDs <- cbind(coords, GridcellIndex = unique(x$GridcellIndex))
    colnames(coords_with_IDs) <- c("lon", "lat", "GridcellIndex")
    
    x <- dplyr::left_join(x, coords_with_IDs, by = "GridcellIndex")
    
    return(x)
  }
  
  else {
    stop("Input must be either a list (Madingley object) or a dataframe with GridcellIndex.")
  }
}






######## Working with the diversity data
final_diversity_data <- readRDS("RemovingHerbivores")
diversity_spatial_extent <- c(-140, -110, 48, 60)
final_diversity_data <- assign_lat_lon(final_diversity_data, diversity_spatial_extent)
final_diversity_data <- final_diversity_data %>%
  dplyr::select(lon, lat, DiversityIndex) %>%
  rename(x = "lon", y = "lat")
final_diversity_data$DiversityIndex <- as.numeric(final_diversity_data$DiversityIndex)


#Download the maps of BC and Alberta
#Crop final defol to only contain points that fall within the boundaries 
library(rnaturalearth)
state_prov <- rnaturalearth::ne_states(c("canada"))
state_prov_sf <- st_as_sf(state_prov)
provs<- state_prov_sf %>%
  filter(name %in% c("British Columbia", "Alberta"))

state_prov_usa <- rnaturalearth::ne_states(c("United States of America"))
state_prov_sf_usa <- st_as_sf(state_prov_usa)


my.theme_2<-theme(axis.text=element_text(size=18),
                  axis.title = element_text(size = 18),
                  legend.text=element_text(size=18),
                  legend.title = element_text(size=18),
                  panel.border = element_rect(color = "black", linetype = "solid", fill = NA),
                  plot.title = element_text(face="bold",size=14,margin=margin(0,0,20,0),hjust = 0.5),
                  axis.title.y = element_text(margin = margin(t = 0, r = 15, b = 0, l = 0)),
                  axis.title.x = element_text(margin = margin(t = 15, r = 0, b = 0, l = 0)))


#Plot the defoliation and save 
diversity_map_noherbs <- ggplot() +
  geom_tile(data = final_diversity_data, aes(x = x, y = y, fill = DiversityIndex)) +
  scale_fill_viridis_c(option = "plasma",  # options: "viridis", "magma", "plasma", "cividis", "inferno", etc.
                       direction = 1, 
                       limits = c(0, 0.08)) +
    theme_minimal() +
  my.theme_2+
  xlim(-140, -110)+
  ylim(48, 60)+
  labs(x = "Longitude", y = "Latitude", fill = "Shannon-Wiener
Diversity
Index")+
  geom_sf(data = state_prov_sf,
          color = "white", fill = NA)+
  geom_sf(data = state_prov_sf_usa,
          color = "white", fill = NA)
diversity_map_noherbs

ggsave("R/figures/no_herbivores_plot.png", diversity_map_noherbs )

#No carnivores
carnivores <- readRDS("Carnivores")
carnivores <- assign_lat_lon(carnivores, diversity_spatial_extent)
carnivores <- carnivores %>%
  dplyr::select(lon, lat, DiversityIndex) %>%
  rename(x = "lon", y = "lat")
carnivores$DiversityIndex <- as.numeric(carnivores$DiversityIndex)

diversity_map_carnivores <- ggplot() +
  geom_tile(data = carnivores, aes(x = x, y = y, fill = DiversityIndex)) +
  scale_fill_viridis_c(option = "plasma",  # options: "viridis", "magma", "plasma", "cividis", "inferno", etc.
                       direction = 1, 
                       limits = c(0, 0.08)) +
  theme_minimal() +
  my.theme_2+
  xlim(-140, -110)+
  ylim(48, 60)+
  labs(x = "Longitude", y = "Latitude", fill = "Shannon-Wiener
Diversity
Index")+
  geom_sf(data = state_prov_sf,
          color = "white", fill = NA)+
  geom_sf(data = state_prov_sf_usa,
          color = "white", fill = NA)
diversity_map_carnivores
ggsave("R/figures/no_carnivores_plot.png", diversity_map_carnivores)



#control
control <- readRDS("control")
control <- assign_lat_lon(control, diversity_spatial_extent)
control <- control %>%
  dplyr::select(lon, lat, DiversityIndex) %>%
  rename(x = "lon", y = "lat")
control$DiversityIndex <- as.numeric(control$DiversityIndex)

diversity_map_control <- ggplot() +
  geom_tile(data = control, aes(x = x, y = y, fill = DiversityIndex)) +
  scale_fill_viridis_c(option = "plasma",  # options: "viridis", "magma", "plasma", "cividis", "inferno", etc.
                       direction = 1, 
                       limits = c(0, 0.08)) +
  theme_minimal() +
  my.theme_2+
  xlim(-140, -110)+
  ylim(48, 60)+
  labs(x = "Longitude", y = "Latitude", fill = "Shannon-Wiener
Diversity
Index")+
  geom_sf(data = state_prov_sf,
          color = "white", fill = NA)+
  geom_sf(data = state_prov_sf_usa,
          color = "white", fill = NA)
diversity_map_control
ggsave("R/figures/control_plot.png", diversity_map_control)




#LandCover
LandCover <- readRDS("LandCover")
LandCover <- assign_lat_lon(LandCover, diversity_spatial_extent)
LandCover <- LandCover %>%
  dplyr::select(lon, lat, DiversityIndex) %>%
  rename(x = "lon", y = "lat")
LandCover$DiversityIndex <- as.numeric(LandCover$DiversityIndex)

diversity_map_LandCover <- ggplot() +
  geom_tile(data = LandCover, aes(x = x, y = y, fill = DiversityIndex)) +
  scale_fill_viridis_c(option = "plasma",  # options: "viridis", "magma", "plasma", "cividis", "inferno", etc.
                       direction = 1, 
                       limits = c(0, 0.08)) +
  theme_minimal() +
  my.theme_2+
  xlim(-140, -110)+
  ylim(48, 60)+
  labs(x = "Longitude", y = "Latitude", fill = "Shannon-Wiener
Diversity
Index")+
  geom_sf(data = state_prov_sf,
          color = "white", fill = NA)+
  geom_sf(data = state_prov_sf_usa,
          color = "white", fill = NA)
diversity_map_LandCover

ggsave("R/figures/landcover_plot.png", diversity_map_LandCover)


