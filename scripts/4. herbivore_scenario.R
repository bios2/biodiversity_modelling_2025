# Runs herbivore removal scenario
# Requirements: Run the script run_spin_up.R first
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
n_years <- 200

#### Load spin-up ####
mdata_spin_up <- readRDS(file.path(output_folder,"mdata_spin_up.rds"))

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


#### Run herbivore removal scenario ####
# Remove large (>100 kg) endothermic herbivores
remove_idx <- which(mdata_spin_up$cohorts$AdultMass > 1e5 & 
                     mdata_spin_up$cohorts$FunctionalGroupIndex == 0)
mdata_spin_up$cohorts <- mdata_spin_up$cohorts[-remove_idx, ]

# Set max allowed endothermic herbivore body mass in cohort definitions
chrt_def$PROPERTY_Maximum.mass[1] = 100000 # set max size herbivores = 100000 g (100 kg)

dir_path <- paste0(output_folder,"/herbivore_scenario")
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}
mdata_herbivore_scenario <- madingley_run(years = n_years, 
                                         out_dir = dir_path,
                                         madingley_data = mdata_spin_up,
                                         spatial_inputs = sptl_inp,
                                         cohort_def = chrt_def,
                                         silenced = F,
                                         max_cohort = 100,
                                         apply_hanpp = F)

saveRDS(mdata_herbivore_scenario, 
        paste0(output_folder, "/mdata_herbivore_scenario.rds"))