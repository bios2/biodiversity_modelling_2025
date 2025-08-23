#!/usr/bin/env Rscript
# =============================================================================
# Compute diversity maps from post–land-use run (MadingleyR)
# - Reads saved run: mdata4.rds  (produced after vegetation reduction to 5%)
# - Computes three Shannon indices:
#     1) Abundance-weighted
#     2) Biomass-weighted (abundance * individual mass)
#     3) By FunctionalGroupIndex ("metabolism") using abundance
# - Writes GeoTIFFs and quick previews
#
# Author: Wenhuan
# Date:   2025-08-22
# =============================================================================

suppressPackageStartupMessages({
  library(MadingleyR)
  library(dplyr)
  library(vegan)   # diversity()
  library(terra)   # rasters / GeoTIFF IO
})

# ------------------------------ 0) Paths --------------------------------------

# Folder that contains your post–land-use result mdata4.rds
# (If you saved to a different folder, update this.)
base_dir <- "/Users/wenhuan/Documents/Conferences-Workshop/Biodiversity modeling 2025/code and data/TempMadingleyOuts_default/"
stopifnot(dir.exists(base_dir))

# Input (post–land-use) and output folders
input_rds <- file.path(base_dir, "mdata4.rds")
stopifnot(file.exists(input_rds))

out_dir <- file.path(base_dir, "diversity_from_post_landuse")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# --------------------------- 1) Load and checks -------------------------------

mres <- readRDS(input_rds)

# Expecting these fields from MadingleyR:
needed_cols <- c("GridcellIndex", "FunctionalGroupIndex",
                 "IndividualBodyMass", "CohortAbundance")
if (!("cohorts" %in% names(mres))) stop("`mres$cohorts` not found in the loaded object.")
if (!all(needed_cols %in% names(mres$cohorts))) {
  missing <- setdiff(needed_cols, names(mres$cohorts))
  stop("Missing columns in `mres$cohorts`: ", paste(missing, collapse = ", "))
}
if (!all(c("spatial_window", "grid_size") %in% names(mres))) {
  stop("`spatial_window` or `grid_size` missing in the saved result.")
}

cohorts <- mres$cohorts
sw <- mres$spatial_window  # c(xmin, xmax, ymin, ymax)
gs <- as.numeric(mres$grid_size)

# ---------------------------- 2) Size-bin helper (optional) -------------------
size_class_fun <- function(mass_g) {
  cut(log10(pmax(mass_g, 1e-12)),
      breaks = c(-Inf, 2, 4, 6, Inf),
      labels = c("tiny", "small", "medium", "large"),
      right = FALSE)
}

cohorts <- cohorts %>%
  mutate(size_class = size_class_fun(IndividualBodyMass),
         fg_size    = paste0("FG", FunctionalGroupIndex, "_", size_class))

# ------------------------- 3) Three Shannon indices ---------------------------

## 3A) Abundance-weighted
shannon_abund <- cohorts %>%
  group_by(GridcellIndex, fg_size) %>%
  summarise(n_abund = sum(CohortAbundance), .groups = "drop") %>%
  group_by(GridcellIndex) %>%
  summarise(Shannon_abund = vegan::diversity(n_abund, index = "shannon"),
            .groups = "drop")

## 3B) Biomass-weighted (abundance * individual mass)
shannon_biom <- cohorts %>%
  mutate(cohort_biomass = CohortAbundance * IndividualBodyMass) %>%
  group_by(GridcellIndex, fg_size) %>%
  summarise(n_biom = sum(cohort_biomass), .groups = "drop") %>%
  group_by(GridcellIndex) %>%
  summarise(Shannon_biomass = vegan::diversity(n_biom, index = "shannon"),
            .groups = "drop")

## 3C) By FunctionalGroupIndex (“metabolism”) using abundance
shannon_meta <- cohorts %>%
  group_by(GridcellIndex, FunctionalGroupIndex) %>%
  summarise(n_abund = sum(CohortAbundance), .groups = "drop") %>%
  group_by(GridcellIndex) %>%
  summarise(Shannon_metabolism = vegan::diversity(n_abund, index = "shannon"),
            .groups = "drop")

# Merge
div_df <- Reduce(
  function(x, y) dplyr::full_join(x, y, by = "GridcellIndex"),
  list(shannon_abund, shannon_biom, shannon_meta)
)

# ------------------------- 4) Map GridcellIndex to lon/lat --------------------

xmin <- sw[1]; xmax <- sw[2]; ymin <- sw[3]; ymax <- sw[4]
ncol <- as.integer(round((xmax - xmin) / gs))
nrow <- as.integer(round((ymax - ymin) / gs))

# Use relative indexing to be robust to 0/1-based GridcellIndex
min_idx <- min(div_df$GridcellIndex, na.rm = TRUE)
idx_adj <- div_df$GridcellIndex - min_idx

col0 <- idx_adj %% ncol
row0 <- idx_adj %/% ncol
div_df$lon <- xmin + (as.numeric(col0) + 0.5) * gs
div_df$lat <- ymin + (as.numeric(row0) + 0.5) * gs

# ---------------------- 5) Rasterize and write GeoTIFFs -----------------------

# Template at model window and resolution
r_template <- rast(ext = ext(xmin, xmax, ymin, ymax),
                   resolution = gs, crs = "EPSG:4326")

rasterize_metric <- function(df, value_col, template) {
  r <- template
  cells <- terra::cellFromXY(r, as.matrix(df[, c("lon", "lat")]))
  r[cells] <- df[[value_col]]
  r
}

r_abund <- rasterize_metric(div_df, "Shannon_abund",      r_template)
r_biom  <- rasterize_metric(div_df, "Shannon_biomass",    r_template)
r_meta  <- rasterize_metric(div_df, "Shannon_metabolism", r_template)

writeRaster(r_abund, file.path(out_dir, "shannon_abundance_post_landuse.tif"), overwrite = TRUE)
writeRaster(r_biom,  file.path(out_dir, "shannon_biomass_post_landuse.tif"),   overwrite = TRUE)
writeRaster(r_meta,  file.path(out_dir, "shannon_metabolism_post_landuse.tif"),overwrite = TRUE)

# ---------------------------- 6) Quick previews -------------------------------

tiff(file.path(out_dir, "shannon_abundance_post_landuse_preview.tiff"),
     width = 4, height = 4, units = "in", res = 300)
plot(r_abund, main = "Shannon (Abundance-weighted) — Post Land-use")
dev.off()

tiff(file.path(out_dir, "shannon_biomass_post_landuse_preview.tiff"),
     width = 4, height = 4, units = "in", res = 300)
plot(r_biom, main = "Shannon (Biomass-weighted) — Post Land-use")
dev.off()

tiff(file.path(out_dir, "shannon_metabolism_post_landuse_preview.tiff"),
     width = 4, height = 4, units = "in", res = 300)
plot(r_meta, main = "Shannon (By FunctionalGroupIndex) — Post Land-use")
dev.off()

cat("✅ Post–land-use diversity rasters written to:\n", out_dir, "\n")
# =============================================================================
