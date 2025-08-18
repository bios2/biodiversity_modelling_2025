# This scripts runs a Madingley simulation with default parameters and inputs over Canada

library(MadingleyR)

# Region of interest
spatial_window <- c(-141, -52, 41, 83) # Canada

out_dir <- file.path(Sys.getenv("SCRATCH"), "biodiversity_modelling_2025_out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

mdata <- madingley_init(spatial_window = spatial_window)
mdata2 <- madingley_run(out_dir = out_dir, madingley_data = mdata, years = 10)

saveRDS(mdata2, file.path(out_dir, "demo_results.rds"))