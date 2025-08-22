library("MadingleyR")
library("terra")
library("sf")

input_folder <- '/home/alexis/Documents/Data'


read_rasters <- function(input_folder){
  raster_files <- list.files(input_folder, ".tif$", full.names = TRUE)
  r_list <- lapply(raster_files, rast)
  
  return(r_list)
}

process_hanpp <- function(r_hanpp_list, mask){
  for(i in 1:length(r_hanpp_list)){
    r_hanpp <- r_hanpp_list[[i]]
    r_hanpp <- project(r_hanpp, mask)
    r_hanpp[is.na(r_hanpp),] <- 0
    r_hanpp <- 1- r_hanpp
    
    r_hanpp_list[[i]] <- r_hanpp
  }
  
  return(r_hanpp_list)
}


# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
chrt_def <- madingley_inputs("cohort definition")
stck_def <- madingley_inputs("stock definition")
mdl_prms <- madingley_inputs("model parameters") # useful later for running the model





spatial_window = c(-140, -110, 48, 60)

mdata = madingley_init(spatial_window = spatial_window,
                       cohort_def = chrt_def,
                       stock_def = stck_def,
                       spatial_inputs = sptl_inp,
                       max_cohort = 100)

# Process HANPP data
r_hanpp_list <- read_rasters(input_folder)
r_hanpp_list <-process_hanpp(r_hanpp_list, sptl_inp[["hanpp"]])

sptl_inp[['hanpp']] <-r_hanpp_list
library(MadingleyR)


mdata2 = madingley_run(madingley_data = mdata,
                       years = 7,
                       cohort_def = chrt_def,
                       stock_def = stck_def,
                       spatial_inputs = sptl_inp,
                       model_parameters = mdl_prms,
                       max_cohort = 100,
                       time_step_interval = 1,
                       apply_hanpp = 1
                       )

#devtools::load_all("/home/alexis/Documents/projets/biodiversity_modelling_2025/MadingleyR-master/Package")

try(detach("package:MadingleyR", unload = TRUE))
try(remove.packages("MadingleyR"))

library(remotes)
remotes::install_github(
  "bios2/biodiversity_modelling_2025",
  subdir = "MadingleyR-master/Package",
  build_vignettes = TRUE
)
