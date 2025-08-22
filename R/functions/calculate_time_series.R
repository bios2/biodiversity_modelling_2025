### Getting a time series of summarized cohort data
# Load dependencies
library(tidyverse)
library(data.table)

## Input -  file path to cohort_properties, as a string, and bin size resolution
## Output - dataframe of summary statistics for each functional group, binned by body size, for each month of simulation


calculate_time_series <- function(file_path, size_bin_resolution){
  filepath = paste(file_path, "/cohort_properties", sep="")
  
  ## Get files of cohort data per month and put into a list of dataframes
  cohortFileNamesRaw <- list.files(path = filepath)
  numfiles <- length(cohortFileNamesRaw)
  
  cohortMonthlyData <- lapply(cohortFileNamesRaw,function(i){
    i <- paste(filepath, "/",i,sep="") 
    read.csv(i)
  })
  
  #Make more readable dataframe names from file names
  cohortFileNames <- gsub("FullCohortProperties_","cohortProp_Month",cohortFileNamesRaw)
  names(cohortMonthlyData) <- gsub(".csv","",cohortFileNames)
  
  # summarize cohort datasets by binning them by body mass, focusing on location, functional group, body mass, abundance, and trophic level, then adding together the total abundance in each group
  cohortSummary <- lapply(cohortMonthlyData, function(x) {
    x %>%
      select(GridcellIndex, FunctionalGroupIndex, IndividualBodyMass, CohortAbundance, TrophicIndex) %>%
      mutate(SizeClass = cut(IndividualBodyMass,
                              breaks = logspace(n = size_bin_resolution), #arbitrary number of bins
                              labels = as.character(c(1:(size_bin_resolution-1))))
      ) %>%
      mutate(SizeClass = as.factor(SizeClass),
             GridcellIndex = as.factor(GridcellIndex),
             FunctionalGroupIndex = as.factor(FunctionalGroupIndex)) %>%
      dplyr::group_by(GridcellIndex, FunctionalGroupIndex, SizeClass) %>%
      dplyr::summarise(GroupAbundance = sum(CohortAbundance)) %>% 
      dplyr::ungroup()
  })
  
  # puts a column in each dataframe with the month - !assumes files are in order, which they are by default!
  for(i in 1:length(cohortSummary)){
    cohortSummary[[i]] = mutate(cohortSummary[[i]], Month = i-1)
  }
  
  # puts all the monthly dataframes into one big dataframe, using data.table package
  cohortSummaryTogether <- rbindlist(cohortSummary)
  
  return(cohortSummaryTogether)
  
}


