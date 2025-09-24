# Runs climate change scenario
# Requirements: Run the script run_spin_up.R first
library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")

set.seed(123)
source("R/functions/assign_lat_lon.R")
source("R/functions/utils_rasters.R")

climate_folder <- "Data/madingley_out_ssp585_2050s"
output_folder <- "~/Desktop/Madingley/output_madingley_scenarios"
spatial_window <- c(-170, -50, 15, 83)
countries_list <- c("United States of America", 
                    "Canada", 
                    "Mexico")
n_years <- 200

#### Load spin-up ####
mdata_climate_list <- list()
mdata_climate_list[[1]] <- readRDS(file.path(output_folder,"mdata_spin_up.rds"))

#### Preprocess inputs ####
# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
chrt_def <- madingley_inputs("cohort definition")
stck_def <- madingley_inputs("stock definition")
mdl_prms <- madingley_inputs("model parameters")

# Get countries shapefile
world <- ne_countries(scale = "medium", returnclass = "sf")
north_america <- vect(world[world$name %in% 
                              c("United States of America", 
                                "Canada", 
                                "Mexico"), ])

# Crop and mask spatial inputs 
sptl_inp <- mask_rasters_with_vector(inputs = sptl_inp, 
                                     spatial_vector= north_america)
sptl_inp <- crop_rasters_with_window(inputs = sptl_inp, 
                                     spatial_window = spatial_window)
spatial_window <- as.vector(ext(sptl_inp$hanpp)) # Update window

# Preprocess temperature data
r_temp <- rast(file.path(climate_folder,"near-surface_temperature_1-12.tif"))
r_temp <- mask_rasters_with_vector(inputs = r_temp, 
                                   spatial_vector = north_america)
r_temp <- crop_rasters_with_window(inputs = r_temp, 
                                   spatial_window = spatial_window)

#### Run climate change scenario ####
r_temp_control <- sptl_inp$`near-surface_temperature`
sptl_inp$`near-surface_temperature` <- r_temp

dir_path <- paste0(output_folder,"/climate_scenario")
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}
mdata_climate_list[[2]] <- madingley_run(years = n_years, 
                                 out_dir = dir_path,
                                 madingley_data = mdata_climate_list[[1]],
                                 spatial_inputs = sptl_inp,
                                 silenced = F,
                                 max_cohort = 100,
                                 apply_hanpp = F)

saveRDS(mdata_climate_list[[2]], paste0(output_folder, "/mdata_climate_scenario.rds"))