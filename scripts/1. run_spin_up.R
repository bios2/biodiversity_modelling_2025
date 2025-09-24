# Runs spin-up
library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")

set.seed(123)
source("R/functions/utils_rasters.R")

output_folder <- "~/Desktop/Madingley/output_madingley_scenarios"
spatial_window <- c(-170, -50, 15, 83)
countries_list <- c("United States of America", 
                    "Canada", 
                    "Mexico")
spin_up_years <- 200

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

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

#### Run spin-up ####
# Initialize the model using the pre-loaded inputs
mdata_init <- madingley_init(spatial_window = spatial_window,
                             cohort_def = chrt_def,
                             stock_def = stck_def,
                             spatial_inputs = sptl_inp,
                             max_cohort = 100)
saveRDS(mdata_init, file.path(output_folder, "mdata_init.rds"))

# Run spin-up
dir_path <- paste0(output_folder,"/spin_up")
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}
mdata_spin_up <- madingley_run(madingley_data = mdata_init,
                               out_dir = dir_path,
                               years = spin_up_years,
                               cohort_def = chrt_def,
                               stock_def = stck_def,
                               spatial_inputs = sptl_inp,
                               model_parameters = mdl_prms,
                               max_cohort = 100)
saveRDS(mdata_spin_up, file.path(output_folder, "mdata_spin_up.rds"))