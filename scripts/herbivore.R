# load libraries
library(terra)
library(MadingleyR)
library(sf)

# # Folder for outputs:
# outdir <- "E:/BIOS2 summer school/BIO2-Biodiversity Coding/Madingley_outputs"
# dir.create(outdir, showWarnings = FALSE)

#read new hanpp
#custom_hanpp <- rast("E:/BIOS2 summer school/BIO2-Biodiversity Coding/Input/hanpp/HANPPglobal_SSP5_RCP85_2020_1deg.tif")

#spatial window
# # template window
# spatial_window <- c(-100, -85, 50, 60)
#
# #Alberta
# spatial_window <- c(-120, -110, 48, 60)
# AB and BC
spatial_window <- c(-140, -110, 48, 60)

# these are used to seed the cohorts
sptl_inp = madingley_inputs('spatial inputs') # load default inputs
sptl_inp$Endo_H_max[ ] = 4000000 # set max size herbivores = 4000000 g (4000 kg)
sptl_inp$Endo_C_max[ ] = 600000 # set max size carnivores = 600000 g (600 kg)
sptl_inp$Endo_O_max[ ] = 200000 # set max size omnivores = 200000 g (200 kg)
sptl_inp$Ecto_max[ ] = 150000 # set max size ectotherms = 150000 g (150 kg)

# set the maximum allowed body masses during the simulation run per functional group
cohort_defs = madingley_inputs('cohort definition') # load default inputs
cohort_defs$PROPERTY_Maximum.mass[1] = 4000000 # set max size herbivores = 4000000 g (4000 kg)
cohort_defs$PROPERTY_Maximum.mass[2] = 600000 # set max size carnivores = 600000 g (600 kg)
cohort_defs$PROPERTY_Maximum.mass[3] = 200000 # set max size omnivores = 200000 g (200 kg)

# Initialise model
mdata = madingley_init(spatial_window = spatial_window, spatial_inputs = sptl_inp, cohort_def = cohort_defs)
# Run spin-up of 5 years
mdata2 = madingley_run(out_dir = "E:/",
                       output_timestep = c(5, 0, 5, 5),
                       madingley_data = mdata,
                       cohort_def = cohort_defs,
                       spatial_inputs = sptl_inp,
                       years = )
# Remove large (>100 kg) endothermic herbivores from mdata$cohorts
remove_idx = which(mdata2$cohorts$AdultMass > 1e5 &
                     mdata2$cohorts$FunctionalGroupIndex == 0)
mdata2$cohorts = mdata2$cohorts[-remove_idx, ]

# Set max allowed endothermic herbivore body mass in cohort definitions
cohort_defs$PROPERTY_Maximum.mass[1] = 100000 # set max size herbivores = 100000 g (100 kg)

# Run large herbivore removal simulation (for 5 years)
mdata4 = madingley_run(out_dir = "E:/",
                       output_timestep = c(5, 0, 5, 5),
                       madingley_data = mdata2, years = 5, spatial_inputs = sptl_inp, cohort_def = cohort_defs)

# Make plots
plot_foodweb(mdata4, max_flows = 5)rsité de Sherbrooke