library("MadingleyR")
library("terra")
library("sf")

set.seed(123)

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

input_folder <- "Data/hanpp_projections"

# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
chrt_def <- madingley_inputs("cohort definition")
stck_def <- madingley_inputs("stock definition")
mdl_prms <- madingley_inputs("model parameters") # useful later for running the model


# Spatial model domain = c(min_long, max_long, min_lat, max_lat)
# spatial_window = c(-91, -86, 17, 21)
# spatial_window = c(-180, -50, 5, 85)
spatial_window = c(-140, -110, 48, 60)
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
r_hanpp_list <- process_hanpp(r_hanpp_list, sptl_inp[["hanpp"]])

plot(sptl_inp$hanpp)
plot(r_hanpp_list[[1]])

model_list <- list()
model_list[[1]] <- mdata2
for(i in 5:(length(r_hanpp_list)+1)){
  print(i-1)
  sptl_inp$hanpp[] <- r_hanpp_list[[i-1]]
  model_list[[i]] <- madingley_run(out_dir = "~/Desktop/Madingley_output/final",
                                   years = 5, 
                                   madingley_data = model_list[[i-1]],
                                   spatial_inputs = sptl_inp,
                                   silenced = F,
                                   max_cohort = 100, # at least 500
                                   apply_hanpp = 1)
  }

model_list[[6]] <- madingley_run(out_dir = "~/Desktop/Madingley_output",
                                 years = 25, 
                                 madingley_data = model_list[[5]],
                                 spatial_inputs = sptl_inp,
                                 silenced = F,
                                 max_cohort = 100, # at least 500
                                 apply_hanpp = 1)

model_list[[7]] <- madingley_run(out_dir = "~/Desktop/Madingley_output",
                                 years = 45, 
                                 madingley_data = model_list[[1]],
                                 spatial_inputs = sptl_inp,
                                 silenced = F,
                                 max_cohort = 100, # at least 500
                                 apply_hanpp = 0)

# 1:Spin-up 10
# 2: 5
# 3: 5
# 4: 5
# 5: 5
# 6: 25
# 7: Control 45
# 8: Herv
# 9: Herv control

plot_timelines(model_list[[7]])

plot_foodweb(model_list[[7]],
             max_flows = 5)



# set the maximum allowed body masses during the simulation run per functional group
chrt_def$PROPERTY_Maximum.mass[1] = 4000000 # set max size herbivores = 4000000 g (4000 kg)
chrt_def$PROPERTY_Maximum.mass[2] = 600000 # set max size carnivores = 600000 g (600 kg)
chrt_def$PROPERTY_Maximum.mass[3] = 200000 # set max size omnivores = 200000 g (200 kg)


# Remove large (>100 kg) endothermic herbivores from mdata$cohorts
mdata_her <- model_list[[6]]
remove_idx = which(mdata_her$cohorts$AdultMass > 1e5 &
                     mdata_her$cohorts$FunctionalGroupIndex == 0)
mdata_her$cohorts = mdata_her$cohorts[-remove_idx, ]

# Set max allowed endothermic herbivore body mass in cohort definitions
chrt_def$PROPERTY_Maximum.mass[1] = 100000 # set max size herbivores = 100000 g (100 kg)

sptl_inp$hanpp[] <- r_hanpp_list[[4]]
model_list[[8]] <- madingley_run(out_dir = "~/Desktop/Madingley_output/herv",
                                 years = 10, 
                                 madingley_data = mdata_her,
                                 spatial_inputs = sptl_inp,
                                 output_timestep = c(10,0,10,10),
                                 silenced = F,
                                 max_cohort = 100, # at least 500
                                 apply_hanpp = 1)

plot_timelines(model_list[[8]])



mdata_her <- model_list[[6]]
model_list[[9]] <- madingley_run(out_dir = "~/Desktop/Madingley_output/herv_control",
                                 years = 10, 
                                 madingley_data = mdata_her,
                                 spatial_inputs = sptl_inp,
                                 output_timestep = c(10,0,10,10),
                                 silenced = F,
                                 max_cohort = 100, # at least 500
                                 apply_hanpp = 1)
plot_timelines(model_list[[8]])
plot_timelines(model_list[[9]])
