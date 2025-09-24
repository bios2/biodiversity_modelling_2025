# Runs land cover scenario
# Requirements: Run the script run_spin_up.R first
library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")

set.seed(123)
source("R/functions/assign_lat_lon.R")
source("R/functions/utils_rasters.R")

hanpp_folder <- "Data/land_cover/land_cover_projection/processed"
output_folder <- "~/Desktop/Madingley/output_madingley_scenarios"
spatial_window <- c(-170, -50, 15, 83)
countries_list <- c("United States of America", 
                    "Canada", 
                    "Mexico")
steps_years <- 10
final_years <- 120

#### Load spin-up ####
mdata_lc_list <- list()
mdata_lc_list[[1]] <- readRDS(file.path(output_folder,"mdata_spin_up.rds"))

#### Preprocess inputs ####
# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
chrt_def <- madingley_inputs("cohort definition")
stck_def <- madingley_inputs("stock definition")
mdl_prms <- madingley_inputs("model parameters")

# Get countries shapefile
world <- ne_countries(scale = "medium", returnclass = "sf")
north_america <- vect(world[world$name %in% countries_list, ])

# Crop and mask spatial inputs 
sptl_inp <- mask_rasters_with_vector(inputs = sptl_inp, 
                                     spatial_vector= north_america)
sptl_inp <- crop_rasters_with_window(inputs = sptl_inp, 
                                     spatial_window = spatial_window)
spatial_window <- as.vector(ext(sptl_inp$hanpp)) # Update window

# Preprocess HANPP data
r_hanpp_list <- read_rasters(hanpp_folder)
# Remove NA's
r_hanpp_list <- lapply(r_hanpp_list, function(r) {
  r[is.na(r[])] <- 1
  r
})
r_hanpp_list <- mask_rasters_with_vector(inputs = r_hanpp_list, 
                                         spatial_vector = north_america)
r_hanpp_list <- crop_rasters_with_window(inputs = r_hanpp_list, 
                                           spatial_window = spatial_window)

#### Run land cover scenario ####
# Run the Madingley model with HANPP input
for(i in 1:length(r_hanpp_list)){
  r_hanpp <- r_hanpp_list[[i]]
  hanpp_name <- names(r_hanpp)
  print(hanpp_name)
    
  sptl_inp$hanpp[] <- r_hanpp
  plot(sptl_inp$hanpp)

  dir_path <- paste0(output_folder,"/",hanpp_name)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  
  # Run the model for 100 years with the last HANPP raster
  # and for 10 years with the rest
  if(i == length(r_hanpp_list)){
    n_years <- final_years
  } else {
    n_years <- steps_years
  }
  mdata_lc_list[[i+1]] <- madingley_run(years = n_years, 
                                     out_dir = dir_path,
                                     madingley_data = mdata_lc_list[[i]],
                                     spatial_inputs = sptl_inp,
                                     silenced = F,
                                     max_cohort = 100,
                                     apply_hanpp = 1)
  saveRDS(mdata_lc_list[[i+1]], paste0(output_folder, "/", hanpp_name, ".rds"))
}