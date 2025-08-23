#!/usr/bin/env Rscript
# =============================================================================
# MadingleyR – Land-use scenario:
# Gradually reduce autotroph production down to 5%, then hold at 5%
# Author: Wenhuan
# Date:   2025-08-22
# =============================================================================

suppressPackageStartupMessages({
  library(MadingleyR)
  library(raster)   # You can swap to 'terra' if preferred, but MadingleyR uses raster
})

# ------------------------------- 0) Paths & region ----------------------------

# Output directory (create if missing)
out_dir <- "/Users/wenhuan/Documents/Conferences-Workshop/Biodiversity modeling 2025/code and data/TempMadingleyOuts_default/"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Simulation window (xmin, xmax, ymin, ymax); here: East Africa-ish example
spatial_window <- c(30, 36, -6, 2)

# Optional quick map of the spatial window
plot_spatialwindow(spatial_window)

# ------------------------------- 1) Inputs & QA -------------------------------

# Load default spatial inputs (climate etc.)
sptl_inp <- madingley_inputs("spatial inputs")

# Quick sanity check on near-surface temperature input
r <- sptl_inp[["near-surface_temperature"]]
summary(r)          # overall summary
plot(r)             # quick look (12-month stack)
summary(values(r[[1]]))         # range for month 1
head(values(r[[1]], na.rm = TRUE))  # sample of non-NA values

# ---------------------------- 2) Core time settings ---------------------------

years_spinup  <- 200  # years to stabilize system before forcing
years_vegred  <-   5  # years per step while reducing autotroph production
years_postred <- 200  # years to hold at 5% production

# ----------------------------- 3) Cohorts & caps ------------------------------

# Load cohort definition and increase initial cohort count per functional group
chrt_def <- madingley_inputs("cohort definition")
chrt_def[, 13] <- 35   # column 13 = initial cohorts per functional group

# Reduce per-cell cohort cap to limit memory/CPU
max_cohort <- 350

# ------------------------------- 4) Initialization ----------------------------

mdata <- madingley_init(
  spatial_window = spatial_window,
  spatial_inputs = sptl_inp,
  max_cohort     = max_cohort,
  cohort_def     = chrt_def
)

# Spin-up run (export only at the last timestep to cut I/O)
mdata2 <- madingley_run(
  madingley_data  = mdata,
  years           = years_spinup,
  spatial_inputs  = sptl_inp,
  max_cohort      = max_cohort,
  cohort_def      = chrt_def,
  output_timestep = rep(years_spinup - 1, 4),  # export once near the end
  out_dir         = out_dir
)

# Save an R workspace snapshot for reproducibility/restarts
save.image(file.path(out_dir, "env_spinup_larger.RData"))

# ------------------------- 5) Progressive vegetation cuts ---------------------

# Helper: set the autotroph production scalar inside model parameters.
# NOTE: Index 86 is assumed to be the "autotroph production scalar" in your setup.
# If your local MadingleyR changes that ordering, adjust the row index accordingly.
set_autotroph_scalar <- function(model_params, scalar) {
  stopifnot(is.numeric(scalar), scalar >= 0, scalar <= 1)
  model_params[86, 2] <- scalar
  model_params
}

# Retrieve default model parameters once
m_params <- madingley_inputs("model parameters")

# We’ll keep a chain of model states for each reduction step, starting from spin-up.
mdata_list <- list(mdata2)

# Reduce autotroph production from 1.00 to 0.05 in 5% steps (19 steps).
# That is: 1.00, 0.95, ..., 0.10, 0.05
for (i in 1:19) {
  scalar <- 1 - i * 0.05
  m_params_step <- set_autotroph_scalar(m_params, scalar)
  message(sprintf("Running reduction step %02d: autotroph production scalar = %.2f", i, scalar))
  
  mdata_list[[i + 1]] <- madingley_run(
    madingley_data   = mdata_list[[i]],
    years            = years_vegred,
    model_parameters = m_params_step,
    spatial_inputs   = sptl_inp,
    max_cohort       = max_cohort,
    cohort_def       = chrt_def,
    silenced         = TRUE,   # quieter console
    out_dir          = out_dir
  )
}

# ------------------------------ 6) Hold at 5% ---------------------------------

# Fix at 0.05 and continue for years_postred
m_params_005 <- set_autotroph_scalar(m_params, 0.05)

mdata4 <- madingley_run(
  madingley_data   = mdata_list[[20]],  # last state from reduction loop
  years            = years_postred,
  model_parameters = m_params_005,
  spatial_inputs   = sptl_inp,
  cohort_def       = chrt_def,
  max_cohort       = max_cohort,
  out_dir          = out_dir
)

# ------------------------------- 7) Save outputs -------------------------------

saveRDS(mdata2, file = file.path(out_dir, "mdata2_spinup.rds"))
saveRDS(mdata4, file = file.path(out_dir, "mdata4_post5pct.rds"))

# Notes:
# - To export GeoTIFFs and figures from these states, run your preferred
#   post-processing pipeline (“Plan A” steps 1–3) using the saved states above.
# - If you restart from 'env_spinup_larger.RData', resume at Section 5.
# =============================================================================
