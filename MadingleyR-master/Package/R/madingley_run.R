madingley_run = function(out_dir=tempdir(),
             madingley_data,
             years=1,
             cohort_def=0,
             stock_def=0,
             spatial_inputs=0,
             model_parameters=0,
             output_timestep=c(0,0,0,0),
             max_cohort=500,
             dispersal_off=FALSE,
             silenced=FALSE,
             parallel=TRUE,
             apply_hanpp=FALSE,
             time_step_interval=NULL) {

  grid_size=0 # overwritten later using raster resolution

  hanpp = ifelse(apply_hanpp==1, 1, ifelse(apply_hanpp==2, 2, 0))

  if(!dir.exists(out_dir)) stop('Specified output folder does not exist, please make sure out_dir is correct')

  overwrite_sp_check = FALSE
  spatial_window = madingley_data$spatial_window

  # Remove trailing slashes (faster)
  out_dir = sub("[/\\\\]+$", "", out_dir)

  # Replace tilde with home folder path
  sysname = Sys.info()[['sysname']]
  if(sysname!="Windows") {
  out_dir = sub("~", Sys.getenv("HOME"), out_dir)
  } else if(grepl("~1",out_dir)){
  out_dir_tmp = strsplit(out_dir,"~1")[[1]]
  out_dir = paste0(Sys.getenv("USERPROFILE"),out_dir_tmp[length(out_dir_tmp)])
  }
  out_dir_save = out_dir

  # Load default input rasters if not specified by input function
  if(!is.list(spatial_inputs)) spatial_inputs = madingley_inputs(input_type = "spatial inputs")

  # Check all spatial inputs are provided and named correctly
  correct_sp_names = c("realm_classification","land_mask","hanpp","available_water_capacity","Ecto_max","Endo_C_max","Endo_H_max",
             "Endo_O_max","terrestrial_net_primary_productivity","near-surface_temperature","precipitation","ground_frost_frequency",
             "diurnal_temperature_range")
  if(length(spatial_inputs)<13) stop('Not all required spatial inputs are provided')
  spatial_inputs = spatial_inputs[match(correct_sp_names,names(spatial_inputs))]
  if(!identical(names(spatial_inputs),correct_sp_names)) stop('Not all required spatial inputs names correctly')

  # Precompute class and layer checks
  classes = rep("SpatRaster",13)
  layerdims = c(rep(1,8),rep(12,5))
  has_dynamic = FALSE

  # Vectorized check for SpatRaster or list of SpatRaster
  classes_check = vapply(spatial_inputs, function(x) inherits(x,"SpatRaster") || is.list(x), logical(1))
  if(!all(classes_check)) stop('Not all required spatial inputs formatted correctly')

  # Vectorized dimension check
  dims_check = logical(13)
  for(i in seq_along(spatial_inputs)) {
  x = spatial_inputs[[i]]
  if(inherits(x,"SpatRaster")) {
    dims_check[i] = (nlyr(x) == layerdims[i])
  } else if(is.list(x)) {
    has_dynamic = TRUE
    # Use vapply for speed
    dims_check[i] = length(x) > 0 && all(vapply(x, function(r) inherits(r,"SpatRaster") && nlyr(r)==layerdims[i], logical(1)))
    if(!dims_check[i]) stop(paste('Dynamic input', names(spatial_inputs)[i], 'contains invalid SpatRaster objects or incorrect dimensions'))
  }
  }
  if(!all(dims_check)) stop('Dimensions spatial inputs not formatted correctly')

  # Validate time_step_interval if dynamic variables detected
  if(has_dynamic) {
  if(is.null(time_step_interval)) stop('Dynamic variables detected in spatial_inputs but time_step_interval not specified')
  if(time_step_interval <= 0 || time_step_interval > years) stop('time_step_interval must be positive and not greater than total years')
  }

  # Check HANPP rasters
  hanpp_input = spatial_inputs$hanpp
  if(!is.null(hanpp_input) & hanpp > 0){
  hanpp_max = if(inherits(hanpp_input, "SpatRaster")) {
    as.numeric(terra::global(hanpp_input, 'max', na.rm=TRUE))
  } else if(is.list(hanpp_input) && length(hanpp_input) > 0) {
    max(vapply(hanpp_input, function(r) as.numeric(terra::global(r, 'max', na.rm=TRUE)), numeric(1)))
  } else stop('HANPP input is neither a SpatRaster nor a valid list of SpatRasters')
  if(hanpp_max > 1.5 & hanpp == 1) stop('Please make sure spatial hanpp raster matches with apply_hanpp input parameter \n(trying to apply hanpp with fractional values, hanpp raster supplied with unrealistic fractional values..)')
  }

  # Set correct grid cell size (resolution)
  if(grid_size==0) {
  # Use the first static SpatRaster to determine grid size
  first_spatraster = NULL
  for(i in seq_along(spatial_inputs)) {
    x = spatial_inputs[[i]]
    if(inherits(x, "SpatRaster")) {
    first_spatraster = x
    break
    } else if(is.list(x) && length(x) > 0) {
    first_spatraster = x[[1]]
    break
    }
  }
  if(!is.null(first_spatraster)) grid_size = terra::res(first_spatraster)[1]
  if(grid_size==0 | is.na(grid_size)) grid_size = 1
  }
  if(grid_size>1) stop('Grid cell sizes larger than 1 degree currently not supported')

  # Check if grid cell size of spatial_inputs and madingley_data are equal
  if(grid_size!=madingley_data$grid_size) stop('The grid cell size of madingley_data and spatial_inputs do not match')

  # Check resolution consistency across all inputs (vectorized)
  sum_res = sum(vapply(spatial_inputs, function(x) {
  if(inherits(x,"SpatRaster")) mean(terra::res(x))
  else if(is.list(x) && length(x)>0) mean(terra::res(x[[1]]))
  else 0
  }, numeric(1)))
  if(sum_res != (grid_size*13)) stop('Please make sure all input raster have the same resolutaion (0.5 or 1 degree)')

  # Check spatial window
  if(spatial_window[1]>spatial_window[2] || spatial_window[3]>spatial_window[4])
  stop('spatial_window should be defined as followed c(min long, max long, min lat, max lat)')

  # Function to extract layers for specific time period (vectorized)
  extract_time_layers = function(spatial_inputs, time_step, time_step_interval, total_years) {
  current_inputs = spatial_inputs
  for(i in seq_along(spatial_inputs)) {
    x = spatial_inputs[[i]]
    if(is.list(x)) {
    list_length = length(x)
    years_per_step = total_years / list_length
    current_time_step = min(ceiling((time_step - 1) * time_step_interval / years_per_step) + 1, list_length)
    current_inputs[[i]] = x[[current_time_step]]
    }
  }
  current_inputs
  }

  # Main execution logic
  if(has_dynamic) {
  dynamic_vars = names(spatial_inputs)[vapply(spatial_inputs, is.list, logical(1))]
  if(!silenced) {
    cat("Dynamic variables detected:", paste(dynamic_vars, collapse=", "), "\n")
    cat("Running model with", years, "total years,", time_step_interval, "years per time step\n")
  }
  n_time_steps = ceiling(years / time_step_interval)
  all_outputs = vector("list", n_time_steps)
  current_madingley_data = madingley_data

  for(time_step in seq_len(n_time_steps)) {
    remaining_years = years - (time_step - 1) * time_step_interval
    step_years = min(time_step_interval, remaining_years)
    if(step_years <= 0) break
    if(!silenced) {
    cat("Time step", time_step, "of", n_time_steps, ": running years",
      ((time_step - 1) * time_step_interval + 1), "to",
      ((time_step - 1) * time_step_interval + step_years), "\n")
    cat("Updating dynamic variables:", paste(dynamic_vars, collapse=", "), "\n")
    }
    current_spatial_inputs = extract_time_layers(spatial_inputs, time_step, time_step_interval, years)
    all_outputs[[time_step]] = run_single_step(
    out_dir = out_dir,
    madingley_data = current_madingley_data,
    years = step_years,
    cohort_def = cohort_def,
    stock_def = stock_def,
    spatial_inputs = current_spatial_inputs,
    model_parameters = model_parameters,
    output_timestep = output_timestep,
    max_cohort = max_cohort,
    dispersal_off = dispersal_off,
    silenced = silenced,
    parallel = parallel,
    hanpp = hanpp,
    grid_size = grid_size,
    spatial_window = spatial_window,
    out_dir_save = out_dir_save,
    time_step = time_step
    )
    if(time_step < n_time_steps && step_years > 0) {
    current_madingley_data = prepare_next_iteration_data(all_outputs[[time_step]], current_madingley_data)
    }
  }
  if(!silenced) cat("Dynamic run completed successfully\n")
  final_output = combine_time_step_outputs(all_outputs)
  final_output$spatial_window = madingley_data$spatial_window
  final_output$grid_size = grid_size
  if(!identical(out_dir_save, tempdir())) final_output$out_path = out_dir_save
  return(final_output)
  } else {
  if(!silenced) cat("No dynamic variables detected - running standard model\n")
  return(run_single_step(
    out_dir = out_dir,
    madingley_data = madingley_data,
    years = years,
    cohort_def = cohort_def,
    stock_def = stock_def,
    spatial_inputs = spatial_inputs,
    model_parameters = model_parameters,
    output_timestep = output_timestep,
    max_cohort = max_cohort,
    dispersal_off = dispersal_off,
    silenced = silenced,
    parallel = parallel,
    hanpp = hanpp,
    grid_size = grid_size,
    spatial_window = spatial_window,
    out_dir_save = out_dir_save,
    time_step = 1
  ))
  }
}

run_single_step = function(out_dir, madingley_data, years, cohort_def, stock_def, 
                          spatial_inputs, model_parameters, output_timestep, max_cohort,
                          dispersal_off, silenced, parallel, hanpp, grid_size, 
                          spatial_window, out_dir_save, time_step) {
  
  # setup basic C++ input arguments
  spatial_window_str = paste(spatial_window,collapse=" ") # xmin, xmax, ymin, ymax
  if(sum(output_timestep)==0) {
    output_ts_years = c(years-1,years-1,years-1,years-1)
  }else{
    output_ts_years = output_timestep
  }
  output_ts_months = paste(output_ts_years*12,collapse=" ") # bin cohort, full cohort, bin food-web, full stock
  gridout_bool = 1
  start_t = 0

  # create temporary output dir with time step suffix
  out_dir_name = paste0("/madingley_outs_",format(Sys.time(), "%d_%m_%y_%H_%M_%S"),"_step",time_step,"/")
  current_out_dir = paste0(out_dir,out_dir_name)
  dir.create(current_out_dir, showWarnings = FALSE)

  # create temporary input dir
  input_dir = paste0(current_out_dir,"input/")
  unlink(input_dir, recursive = TRUE)
  dir.create(input_dir, showWarnings = FALSE)

  # def checks
  if(class(cohort_def)=="numeric") cohort_def = madingley_data$cohort_def # if argument is not used, use defs from madingley_data
  if(class(stock_def)=="numeric") stock_def = madingley_data$stock_def # if argument is not used, use defs from madingley_data
  if(is.null(cohort_def)) cohort_def = get_default_cohort_def() # cannot find defs in madingley_data ?!
  if(is.null(stock_def)) stock_def = get_default_stock_def() # cannot find defs in madingley_data ?!

  # write inputs csv files to temp dir
  write_cohort_def(current_out_dir,cohort_def)
  write_stock_def(current_out_dir,stock_def)
  write_simulation_parameters(current_out_dir)
  write_mass_bin_def(current_out_dir)

  # write madingley_data cohorts and stocks to temp dir
  write_madingley_data_cohorts_stocks_to_temp_dir_fast(input_dir=input_dir,madingley_data=madingley_data)

  # write spatial outputs
  write_spatial_inputs_to_temp_dir(spatial_inputs=spatial_inputs,
                                  XY_window=spatial_window_str,
                                  crop=TRUE,
                                  input_dir=current_out_dir,
                                  silenced)

  # use user defined model parameters or default
  if(class(model_parameters)!="data.frame"){ # default
    model_params = 0
  }else{ # not default
    model_params = paste(c(1,model_parameters$values),collapse=" ")
  }

  if(dispersal_off) {
    NoDispersal=1
  }else{
    NoDispersal=0
  }

  RunInParallel=parallel
  if(RunInParallel){
    int_RunInParallel = 1
  }else{
    int_RunInParallel = 0
  }

  # Run the C++ code (run)
  switch(Sys.info()[['sysname']],

  # run on windows
  Windows = {
    # setup C++ input arguments
    sp_dir = paste0(current_out_dir,"spatial_inputs/1deg/")
    exec_args = paste(spatial_window_str,'"%PATH1%"',
                     output_ts_months,gridout_bool,
                     '"%PATH2%"',max_cohort,
                     '"%PATH3%"','"%PATH4%"',
                     start_t,'"%PATH5%"',
                     grid_size,hanpp,
                     NoDispersal,int_RunInParallel,model_params)

    # setup windows executable path
    win_dist_dir = paste0(get_lib_path(),'/win_exec/')
    madingley_exec = paste0('"',win_dist_dir,'madingley.exe" run')

    # create madingley.bat file for running the C++ code
    bat_l1 = "ECHO off"
    bat_l2 = paste0("set PATH1=",paste0(gsub("/", "\\\\", current_out_dir),'\\'))
    bat_l3 = paste0("set PATH2=",paste0(gsub("/", "\\\\", input_dir),'\\'))
    bat_l4 = paste0("set PATH3=",paste0(gsub("/", "\\\\", input_dir),"C.csv"))
    bat_l5 = paste0("set PATH4=",paste0(gsub("/", "\\\\", input_dir),"S.csv"))
    bat_l6 = paste0("set PATH5=",paste0(gsub("/", "\\\\", sp_dir),'\\'))
    bat_l7 = paste(madingley_exec,years,exec_args)
    bat_l7 = gsub("/", "\\\\", bat_l7)
    run_exec = paste0(win_dist_dir,'madingley.bat')
    writeLines(c(bat_l1,bat_l2,bat_l3,bat_l4,bat_l5,bat_l6,bat_l7), run_exec)
    run_exec = paste0('"',run_exec,'"')

    # init model
    if(silenced){
      print_out = system(run_exec,intern=TRUE)
    }else{
      system(run_exec)
    }

    # return data
    out = return_output_list_run(cohort_def,stock_def,current_out_dir,out_dir_name)
    out$spatial_window = madingley_data$spatial_window
    if(!out_dir_save==tempdir()){
      out$out_path = out_dir_save
    }
    out$grid_size = grid_size
    return(out)
  },

  # run on linux
  Linux = {
    # setup C++ input arguments
    sp_dir = paste0(current_out_dir,"/spatial_inputs/1deg/")
    exec_args = paste(spatial_window_str,
                     paste0('\"',gsub("\\\\", "/", current_out_dir),'\"'),
                     output_ts_months,
                     gridout_bool,
                     paste0('\"',gsub("\\\\", "/", input_dir),'\"'),
                     max_cohort,
                     paste0('\"',gsub("\\\\", "/", paste0(input_dir,"C.csv")),'\"'),
                     paste0('\"',gsub("\\\\", "/", paste0(input_dir,"S.csv")),'\"'),
                     start_t,
                     paste0('\"',gsub("\\\\", "/", sp_dir),'\"'),
                     grid_size,
                     hanpp,
                     NoDispersal,
                     int_RunInParallel,
                     model_params)

    # setup linux executable path
    lin_dist_dir = paste0('"',get_lib_path(),'/lin_exec/','"')
    system(paste('cd',lin_dist_dir,'&&','chmod u+x madingley'))
    madingley_exec = paste('cd',lin_dist_dir,'&&','./madingley run',years,exec_args)

    # init model
    if(silenced){
      print_out = system(madingley_exec,intern=TRUE)
    }else{
      system(madingley_exec)
    }

    # return data
    out = return_output_list_run(cohort_def,stock_def,current_out_dir,out_dir_name)
    out$spatial_window = madingley_data$spatial_window
    if(!out_dir_save==tempdir()){
      out$out_path = out_dir_save
    }
    out$grid_size = grid_size
    return(out)
  },

  # run on mac
  Darwin = {
    # setup C++ input arguments
    sp_dir = paste0(current_out_dir,"/spatial_inputs/1deg/")
    exec_args = paste(spatial_window_str,
                     paste0('\"',gsub("\\\\", "/", current_out_dir),'\"'),
                     output_ts_months,
                     gridout_bool,
                     paste0('\"',gsub("\\\\", "/", input_dir),'\"'),
                     max_cohort,
                     paste0('\"',gsub("\\\\", "/", paste0(input_dir,"C.csv")),'\"'),
                     paste0('\"',gsub("\\\\", "/", paste0(input_dir,"S.csv")),'\"'),
                     start_t,
                     paste0('\"',gsub("\\\\", "/", sp_dir),'\"'),
                     grid_size,
                     hanpp,
                     NoDispersal,
                     int_RunInParallel,
                     model_params)

    # setup mac executable path
    mac_dist_dir = paste0('"',get_lib_path(),'/mac_exec/','"')
    system(paste('cd',mac_dist_dir,'&&','chmod u+x madingley'))
    madingley_exec = paste('cd',mac_dist_dir,'&&','./madingley run',years,exec_args)

    # init model
    if(silenced){
      print_out = system(madingley_exec,intern=TRUE)
    }else{
      system(madingley_exec)
    }

    # return data
    out = return_output_list_run(cohort_def,stock_def,current_out_dir,out_dir_name)
    out$spatial_window = madingley_data$spatial_window
    if(!out_dir_save==tempdir()){
      out$out_path = out_dir_save
    }
    out$grid_size = grid_size
    return(out)
  }
  )
}

# Helper function to prepare data for next iteration
prepare_next_iteration_data = function(step_output, original_madingley_data) {
  # This function should extract the final state from step_output
  # and prepare it as input for the next iteration
  # The exact implementation depends on your output structure
  
  # Placeholder implementation - you'll need to adapt this
  next_madingley_data = original_madingley_data
  
  # Extract final cohort and stock states from step_output
  # and update next_madingley_data accordingly
  
  return(next_madingley_data)
}

# Helper function to combine outputs from multiple time steps
combine_time_step_outputs = function(all_outputs) {
  # This function should combine the outputs from all time steps
  # into a single coherent output structure
  # The exact implementation depends on your output structure
  
  # Placeholder implementation - you'll need to adapt this
  if(length(all_outputs) == 1) {
    return(all_outputs[[1]])
  }
  
  # Combine outputs - this is a simplified approach
  final_output = all_outputs[[length(all_outputs)]]  # Use last output as base
  
  # You might want to combine time series data, aggregate results, etc.
  
  return(final_output)
}