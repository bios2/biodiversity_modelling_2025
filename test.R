library("MadingleyR")
library("terra")
library("sf")

library("MadingleyR")
library("terra")
library("sf")

input_folder <- 'Data/hanpp_projections/'


read_rasters <- function(input_folder){
  raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
  
  r_list <- lapply(raster_files, rast)
  
  return(r_list)
}

r_list <- read_rasters(input_folder)
length(r_list)


r_list[[1]]


process_hanpp <- function(r_hanpp, mask){
  r_hanpp <- project(r_hanpp, mask)
  r_hanpp[is.na(r_hanpp),] <- 0
  r_hanpp <- 1- r_hanpp
  
  return(r_hanpp)
}


set.seed(123)

# source("https://raw.githubusercontent.com/SHoeks/MadingleyR_0.5degree_inputs/master/DownloadLoadHalfDegreeInputs.R")
# DownloadLoadHalfDegreeInputs('data/data_0.5')
# (8, 180, 360, 1)
input_folder <- 'Data/hanpp_projections/'
raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
r_hanpp_list <- rast(raster_files)

# Save rasters' names to name dataframe columns
col_names <- gsub('.tif','',raster_files)
col_names <- gsub(paste0(input_folder,'/'),'',col_names)
names(r_hanpp_list) <- col_names


# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
chrt_def <- madingley_inputs("cohort definition")
stck_def <- madingley_inputs("stock definition")
mdl_prms <- madingley_inputs("model parameters") # useful later for running the model


# Spatial model domain = c(min_long, max_long, min_lat, max_lat)
spatial_window = c(-91, -86, 17, 21)
plot_spatialwindow(spatial_window)

# Initialise model the model using the pre-loaded inputs
mdata = madingley_init(spatial_window = spatial_window,
                       cohort_def = chrt_def,
                       stock_def = stck_def,
                       spatial_inputs = sptl_inp,
                       max_cohort = 100)

# Run the Madingley model for n years (spin-up)
mdata2 = madingley_run(madingley_data = mdata,
                       years = 10,
                       cohort_def = chrt_def,
                       stock_def = stck_def,
                       spatial_inputs = sptl_inp,
                       model_parameters = mdl_prms,
                       max_cohort = 100)
str(mdata2,1)

# Process HANPP data
r_hanpp_list <- read_rasters(input_folder)
process_hanpp(r_hanpp_list[[1]], sptl_inp[["hanpp"]])

names(r_hanpp_list)
r_hanpp <- project(r_hanpp_list[[1]], sptl_inp[["hanpp"]])
r_hanpp[is.na(r_hanpp),] <- 0
r_hanpp <- 1- r_hanpp

plot(sptl_inp$hanpp)
plot(r_hanpp)

# Run the Madingley model for n years with HANPP
sptl_inp$hanpp[] <- r_hanpp
mdata3 <- madingley_run(years = 2, 
                        madingley_data = mdata2,
                        spatial_inputs = sptl_inp,
                        silenced = F,
                        max_cohort = 100, # at least 500
                        apply_hanpp = 1) #apply_hanpp = 1, reduces NPP in fractions provided in the hanpp spatial input raster, a fraction of 0.9 represent a 0.1 reduction in autotroph productivity.
plot_timelines(mdata2)

sptl_inp$hanpp[] <- 0.1
mdata4 <- madingley_run(out_dir = "/Users/kasanchez/Desktop/test/",
                        years = 10,
                        madingley_data = mdata2,
                        spatial_inputs = sptl_inp,
                        silenced = F,
                        max_cohort = 100, # at least 500
                        apply_hanpp = 1) #apply_hanpp = 1, reduces NPP in fractions provided in the hanpp spatial input raster, a fraction of 0.9 represent a 0.1 reduction in autotroph productivity.

plot_timelines(mdata4)

sptl_inp$hanpp[] <- 1
mdata5 <- madingley_run(out_dir = "/Users/kasanchez/Desktop/test/",
                        years = 10,
                        madingley_data = mdata2,
                        spatial_inputs = sptl_inp,
                        silenced = F,
                        max_cohort = 100, # at least 500
                        apply_hanpp = 1) #apply_hanpp = 1, reduces NPP in fractions provided in the hanpp spatial input raster, a fraction of 0.9 represent a 0.1 reduction in autotroph productivity.

plot_timelines(mdata5)
# plot_foodweb(mdata4)
