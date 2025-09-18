# Runs control scenario
# Requirements: Run the script run_spin_up.R first
library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")

set.seed(123)
source("R/functions/utils_rasters.R")

output_folder <- "~/Desktop/Madingley/output_test"
spatial_window <- c(-170, -50, 15, 83)
countries_list <- c("United States of America", 
                    "Canada", 
                    "Mexico")
control_years <- 200

#### Load spin-up ####
mdata_spin_up <- readRDS(file.path(output_folder,"mdata_spin_up.rds"))

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

#### Run control scenario ####
dir_path <- paste0(output_folder,"/control")
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}
mdata_control <- madingley_run(out_dir = dir_path,
                                  years = control_years, 
                                  madingley_data = mdata_spin_up,
                                  spatial_inputs = sptl_inp,
                                  silenced = F,
                                  max_cohort = 100, # at least 500
                                  apply_hanpp = F)
saveRDS(mdata_control, paste0(output_folder, "/mdata_control.rds"))
