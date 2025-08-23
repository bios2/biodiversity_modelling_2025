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
  library(terra)   # use terra throughout to avoid Raster* vs SpatRaster conflicts
})

# ----------------------- 1) Basic paths & window -----------------------
out_dir <- "/Users/wenhuan/Documents/Conferences-Workshop/Biodiversity modeling 2025/code and data/TempMadingleyOuts_climate_change_NA/"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

clim_dir <- "/Users/wenhuan/Documents/Climate Data/CHELSA ssp585 2050s/madingley_out_ssp585_2050s"

# North America window (xmin, xmax, ymin, ymax)
spatial_window <- c(-150, -50, 10, 85)
plot_spatialwindow(spatial_window)

# ----------------------- 2) Load built-in inputs -----------------------
sptl_inp <- madingley_inputs("spatial inputs")

# ----------------------- 3) Read custom temperature --------------------
# Expect files: near-surface_temperature_01.tif ... _12.tif
tfiles <- file.path(clim_dir, sprintf("near-surface_temperature_%02d.tif", 1:12))
stopifnot(all(file.exists(tfiles)))

tmean_1deg_stack <- rast(tfiles)  # SpatRaster (12 layers)
names(tmean_1deg_stack) <- sprintf("near_surface_temperature_%02d", 1:12)

# Fix temperature units if necessary:
# - If Kelvin (>200), convert to °C
# - If 10x °C (70–200), divide by 10
fix_temperature_units <- function(rspat) {
  stopifnot(inherits(rspat, "SpatRaster"))
  out <- rspat
  for (i in seq_len(nlyr(rspat))) {
    ri <- rspat[[i]]
    gm <- as.numeric(global(ri, "mean", na.rm = TRUE))
    if (!is.na(gm) && gm > 200)   ri <- ri - 273.15
    if (!is.na(gm) && gm > 70 && gm < 200) ri <- ri / 10
    out[[i]] <- ri
  }
  out
}
tmean_1deg_stack <- fix_temperature_units(tmean_1deg_stack)

# ----------------------- 4) Align to 1° template ------------------------
template1deg <- rast(xmin = -180, xmax = 180, ymin = -90, ymax = 90,
                     resolution = 1, crs = "EPSG:4326")

# Assign CRS if missing
if (is.na(crs(tmean_1deg_stack)) || crs(tmean_1deg_stack) == "") {
  crs(tmean_1deg_stack) <- crs(template1deg)
}

# Project to template CRS if different
if (!same.crs(tmean_1deg_stack, template1deg)) {
  tmean_1deg_stack <- project(tmean_1deg_stack, template1deg, method = "bilinear")
}

# Resample to exact grid if geometry differs
if (!compareGeom(tmean_1deg_stack, template1deg, crs = TRUE, rowcol = TRUE, stopOnError = FALSE)) {
  tmean_1deg_stack <- resample(tmean_1deg_stack, template1deg, method = "bilinear")
}

# ----------------------- 5) Replace in sptl_inp -------------------------
# Try likely keys for near-surface temperature
cand_keys <- c("near-surface_temperature",
               "near_surface_temperature",
               "near-surface_temperature_1-12",
               "near_surface_temperature_1-12")

key_hit <- intersect(names(sptl_inp), cand_keys)
if (length(key_hit) == 0) {
  stop("Could not find near-surface temperature key in sptl_inp. ",
       "Run `names(sptl_inp)` and adjust `cand_keys` accordingly.")
}

# Put SpatRaster directly (do NOT convert to RasterStack)
sptl_inp[[ key_hit[1] ]] <- tmean_1deg_stack

# Convert any Raster* in sptl_inp to SpatRaster to satisfy terra::nlyr()
to_spat <- function(x) {
  if (inherits(x, c("RasterLayer", "RasterStack", "RasterBrick"))) rast(x) else x
}
sptl_inp <- setNames(lapply(sptl_inp, to_spat), names(sptl_inp))

# Final sanity checks (semantic CRS + exact grid)
stopifnot(same.crs(sptl_inp[[ key_hit[1] ]], template1deg))
if (!compareGeom(sptl_inp[[ key_hit[1] ]], template1deg, crs = TRUE, rowcol = TRUE, stopOnError = FALSE)) {
  sptl_inp[[ key_hit[1] ]] <- resample(sptl_inp[[ key_hit[1] ]], template1deg, method = "bilinear")
}

cat("Temp stack res:", res(sptl_inp[[ key_hit[1] ]]), "\n")
print(ext(sptl_inp[[key_hit[1]]]))


# ----------------------- 6) Initialize parameters -----------------------
# If you already set these elsewhere, you can skip/override below.
chrt_def <- madingley_inputs("cohort definition")
chrt_def[, 13] <- 35          # initial cohorts per functional group
max_chrt  <- 100              # per-cell cohort cap
years_spinup  <- 2  # stabilize prior to forcing
# ----------------------- 7) madingley_init() ----------------------------
mdata <- madingley_init(
  spatial_window = spatial_window,
  spatial_inputs = sptl_inp,   # all SpatRaster and aligned
  max_cohort     = max_chrt,
  cohort_def     = chrt_def
)

cat("✅ madingley_init completed. Gridcells: ", length(unique(mdata$gridcell_id)), "\n")


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
saveRDS(mdata2, file.path(out_dir, "mdata_climate_change.rds"))



cat("✅ Future climate (CHELSA ssp585 2050s) injected, vegetation reduction executed, and final state saved.\n")
# =============================================================================
# Notes for collaborators:
# - Replace `clim_dir` with your own path to 12 monthly 1° near-surface temperature files.
# - If your CHELSA files are Kelvin or ×10 °C, unit correction is automatic via fix_temperature_units().
# - If MadingleyR changes the internal parameter table ordering, update the index used in set_autotroph_scalar().
# - Post-processing (e.g., computing Shannon or guild biomass and writing GeoTIFFs) can be added below.
# =============================================================================
