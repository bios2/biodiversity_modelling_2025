#!/usr/bin/env Rscript
# =============================================================================
# MadingleyR – Future climate (CHELSA ssp585 2050s) + Vegetation reduction
# Replaces default near-surface temperature with a custom 12-month 1° stack,
# then simulates progressive autotroph production cuts down to 5% and holds.
#
# Author: Wenhuan
# Last update: 2025-08-22
# =============================================================================

suppressPackageStartupMessages({
  library(MadingleyR)
  library(terra)   # for modern raster handling
  library(raster)  # for compatibility (MadingleyR often expects raster::*)
})

# ------------------------------ A) Paths & window -----------------------------

# Output directory (created if missing)
out_dir <- "/Users/wenhuan/Documents/Conferences-Workshop/Biodiversity modeling 2025/code and data/TempMadingleyOuts_climate_change/"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Directory containing 12 monthly near-surface temperature GeoTIFFs at 1°
# Expected filenames: near-surface_temperature_01.tif ... near-surface_temperature_12.tif
clim_dir <- "/Users/wenhuan/Documents/Climate Data/CHELSA ssp585 2050s/madingley_out_ssp585_2050s"

# Simulation window (xmin, xmax, ymin, ymax)
spatial_window <- c(30, 36, -6, 2)
plot_spatialwindow(spatial_window)

# ---------------- B) Load built-in inputs and replace temperature ------------- 

# 1) Load the default spatial inputs (climate, masks, etc.)
sptl_inp <- madingley_inputs("spatial inputs")

# 2) Load your 12-layer near-surface temperature (CHELSA, 2050s, ssp585) as a SpatRaster
tfiles <- file.path(clim_dir, sprintf("near-surface_temperature_%02d.tif", 1:12))
stopifnot(all(file.exists(tfiles)))
tmean_1deg_stack <- rast(tfiles)  # SpatRaster with 12 layers
names(tmean_1deg_stack) <- sprintf("near_surface_temperature_%02d", 1:12)

# 3) Unit sanity fixer
#    - If Kelvin (~>200), convert to °C
#    - If degrees * 10 (70–200), divide by 10
fix_temperature_units <- function(rspat) {
  stopifnot(inherits(rspat, "SpatRaster"))
  out_list <- vector("list", nlyr(rspat))
  for (i in seq_len(nlyr(rspat))) {
    ri <- rspat[[i]]
    gm <- as.numeric(global(ri, "mean", na.rm = TRUE))
    if (!is.na(gm) && gm > 200) ri <- ri - 273.15
    if (!is.na(gm) && gm > 70 && gm < 200) ri <- ri / 10
    out_list[[i]] <- ri
  }
  rast(out_list)
}

tmean_1deg_stack <- fix_temperature_units(tmean_1deg_stack)

# 4) Ensure exact 1° grid alignment and CRS = EPSG:4326 (WGS84)
template1deg <- rast(xmin = -180, xmax = 180, ymin = -90, ymax = 90,
                     resolution = 1, crs = "EPSG:4326")

if (!all.equal(res(tmean_1deg_stack), res(template1deg)) ||
    !compareGeom(tmean_1deg_stack, template1deg, stopOnError = FALSE)) {
  tmean_1deg_stack <- resample(tmean_1deg_stack, template1deg, method = "bilinear")
}

# 5) Replace the near-surface temperature in sptl_inp with your custom stack.
#    We try several possible key names that MadingleyR might use.
cand_keys <- c(
  "near-surface_temperature",
  "near_surface_temperature",
  "near-surface_temperature_1-12",
  "near_surface_temperature_1-12"
)
key_hit <- intersect(names(sptl_inp), cand_keys)
if (length(key_hit) == 0) {
  stop("Could not find the near-surface temperature key in sptl_inp. ",
       "Run `names(sptl_inp)` to inspect available keys and update `cand_keys`.")
}

# IMPORTANT: many MadingleyR internals still rely on raster::* types.
# Convert the SpatRaster to a RasterStack before inserting.
tmean_raster_stack <- raster::stack(tmean_1deg_stack)
sptl_inp[[ key_hit[1] ]] <- tmean_raster_stack

# Final consistency checks
stopifnot(all.equal(raster::res(sptl_inp[[ key_hit[1] ]]), c(1, 1)))
stopifnot(raster::compareCRS(sptl_inp[[ key_hit[1] ]], raster::raster(template1deg)))

# ---------------- C) Time settings and cohort configuration -------------------

# Time budget
years_spinup  <- 100  # stabilize prior to forcing
years_vegred  <-   5  # years per cut step
years_postred <- 100  # hold at 5%

# Cohorts: increase initial cohorts per functional group to 35 (column 13)
chrt_def <- madingley_inputs("cohort definition")
chrt_def[, 13] <- 35

# Per-cell maximum cohort cap (keeps memory/CPU manageable)
max_chrt <- 350

# ---------------- D) Initialize and Spin-up -----------------------------------

# Initialize the model over the specified spatial window
mdata <- madingley_init(
  spatial_window = spatial_window,
  spatial_inputs = sptl_inp,
  max_cohort     = max_chrt,
  cohort_def     = chrt_def
)

# Spin-up run (export once near the end to reduce I/O)
mdata2 <- madingley_run(
  madingley_data  = mdata,
  years           = years_spinup,
  spatial_inputs  = sptl_inp,
  max_cohort      = max_chrt,
  cohort_def      = chrt_def,
  output_timestep = rep(years_spinup - 1, 4),  # “export only at the last year”
  out_dir         = out_dir
)
saveRDS(mdata2, file.path(out_dir, "mdata_after_spinup.rds"))

# ---------------- E) Progressive vegetation reduction (land-use proxy) -------

# Load default model parameters (we will modify the autotroph production scalar)
m_params <- madingley_inputs("model parameters")

# Helper to set autotroph production scalar.
# WARNING: row index 86 assumes your MadingleyR build uses that row for the scalar.
#          If your local table differs, adjust this index accordingly.
set_autotroph_scalar <- function(model_params, scalar) {
  stopifnot(is.numeric(scalar), scalar >= 0, scalar <= 1)
  model_params[86, 2] <- scalar
  model_params
}

# Build a chain of states, starting from spin-up
mdata_list <- list(mdata2)

# Steps: 1.00 → 0.95 → … → 0.05 (19 steps of -0.05)
for (i in 1:19) {
  scalar <- 1 - i * 0.05
  message(sprintf("Running vegetation production scalar = %.2f", scalar))
  m_params_i <- set_autotroph_scalar(m_params, scalar)
  
  mdata_list[[i + 1]] <- madingley_run(
    madingley_data   = mdata_list[[i]],
    years            = years_vegred,
    model_parameters = m_params_i,
    spatial_inputs   = sptl_inp,
    max_cohort       = max_chrt,
    cohort_def       = chrt_def,
    silenced         = TRUE,
    out_dir          = out_dir
  )
}

# ---------------- F) Post-reduction: hold at 5% ------------------------------

m_params_005 <- set_autotroph_scalar(m_params, 0.05)

mdata_final <- madingley_run(
  madingley_data   = mdata_list[[20]],  # last state after reductions
  years            = years_postred,
  model_parameters = m_params_005,
  spatial_inputs   = sptl_inp,
  cohort_def       = chrt_def,
  max_cohort       = max_chrt,
  out_dir          = out_dir
)
saveRDS(mdata_final, file.path(out_dir, "mdata_final.rds"))

cat("✅ Future climate (CHELSA ssp585 2050s) injected, vegetation reduction executed, and final state saved.\n")
# =============================================================================
# Notes for collaborators:
# - Replace `clim_dir` with your own path to 12 monthly 1° near-surface temperature files.
# - If your CHELSA files are Kelvin or ×10 °C, unit correction is automatic via fix_temperature_units().
# - If MadingleyR changes the internal parameter table ordering, update the index used in set_autotroph_scalar().
# - Post-processing (e.g., computing Shannon or guild biomass and writing GeoTIFFs) can be added below.
# =============================================================================
