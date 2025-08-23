#!/usr/bin/env Rscript
# =============================================================================
# MadingleyR – Future climate (CHELSA ssp585 2050s) climate stack

# Author: Wenhuan
# Last update: 2025-08-22
# =============================================================================

# --- Packages ---
library(terra)
library(MadingleyR)

# ------------ A) 先降到 1° 再 stack 12 层 Tmean ----------------
base_dir <- "/Users/wenhuan/Documents/Climate Data/CHELSA ssp585 2050s"
out_dir  <- file.path(base_dir, "madingley_out_ssp585_2050s")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# 目标 1° 网格
template1deg <- rast(xmin=-180, xmax=180, ymin=-90, ymax=90,
                     resolution=1, crs="EPSG:4326")

# 找某月文件（严格匹配 _MM_2041_2070_norm.tif）
find_month <- function(mm, var=c("tasmax","tasmin"),
                       dir=base_dir, period="2041_2070") {
  var <- match.arg(var)
  patt <- sprintf("%s_%s_%s_norm\\.tif$", var, mm, period)
  f <- list.files(dir, pattern=patt, full.names=TRUE, recursive=FALSE)
  if (length(f) != 1)
    stop(sprintf("期望找到 1 个 %s_%s 文件，但找到 %d 个", var, mm, length(f)))
  f
}

# 单位修正（通常 CHELSA 为 °C，此处做保护性判断）
fix_units <- function(r){
  gm <- as.numeric(global(r, "mean", na.rm=TRUE))
  if (!is.na(gm) && gm > 200) r <- r - 273.15        # Kelvin -> °C
  if (!is.na(gm) && gm > 70 && gm < 200) r <- r/10   # 乘10的°C -> °C
  r
}

# 从 30″ -> 1° 的聚合：温度用均值
to_1deg <- function(r, target=template1deg){
  fact <- round(1 / res(r)[1])         # ~120 对 30″
  r_agg <- aggregate(r, fact=fact, fun=mean, na.rm=TRUE)
  resample(r_agg, target, method="bilinear")
}

tmean_1deg_list <- vector("list", 12)

for (m in 1:12) {
  mm <- sprintf("%02d", m)
  fmax <- find_month(mm, "tasmax")
  fmin <- find_month(mm, "tasmin")
  
  rmax <- fix_units(rast(fmax))
  rmin <- fix_units(rast(fmin))
  
  # 先各自降到 1°
  rmax_1d <- to_1deg(rmax)
  rmin_1d <- to_1deg(rmin)
  
  # 再算该月的 Tmean
  tmean_1deg_list[[m]] <- (rmax_1d + rmin_1d) / 2
}

tmean_1deg_stack <- rast(tmean_1deg_list)
names(tmean_1deg_stack) <- sprintf("near_surface_temperature_%02d", 1:12)

# 写出（可选）
for (m in 1:12) {
  writeRaster(tmean_1deg_stack[[m]],
              file.path(out_dir, sprintf("near-surface_temperature_%02d.tif", m)),
              overwrite=TRUE)
}
writeRaster(tmean_1deg_stack,
            file.path(out_dir, "near-surface_temperature_1-12.tif"),
            overwrite=TRUE)



