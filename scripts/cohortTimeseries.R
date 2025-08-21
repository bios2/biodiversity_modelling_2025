### Getting a time series of summarized cohort data
# Requires tidyverse and data.table

## Get files of cohort data per month and put into a list of dataframes
cohortFileNamesRaw <- list.files(path="~/Desktop/madingley_outs_21_08_25_11_45_11/cohort_properties") #whatever the madingley_run output directory is, then path to cohort properties
numfiles <- length(cohortFileNamesRaw)

cohortMonthlyData <- lapply(cohortFileNamesRaw,function(i){
  i <- paste("~/Desktop/madingley_outs_21_08_25_11_45_11/cohort_properties/",i,sep="") #whatever the madingley_run output directory is, then path to cohort properties
  read.csv(i)
})
cohortFileNames <- gsub("FullCohortProperties_","cohortProp_Month",cohortFileNamesRaw)
names(cohortMonthlyData) <- gsub(".csv","",cohortFileNames)

# summarize cohort datasets by binning them by body mass, focusing on location, functional group, body mass, abundance, and trophic level, then adding together the total abundance in each group
cohortSummary <- lapply(cohortMonthlyData, function(x) {
  x %>%
    select(GridcellIndex, FunctionalGroupIndex, IndividualBodyMass, CohortAbundance, TrophicIndex) %>%
    mutate(binnedSize = cut(IndividualBodyMass,
                            breaks = logspace(n = 13), #arbitrary number of bins
                            labels = as.character(c(1:12)))
    ) %>%
    mutate(binnedSize = as.factor(binnedSize),
           GridcellIndex = as.factor(GridcellIndex),
           FunctionalGroupIndex = as.factor(FunctionalGroupIndex)) %>%
    group_by(GridcellIndex, FunctionalGroupIndex, binnedSize) %>%
    summarise(totalAbundance = sum(CohortAbundance))
})

# puts a column in each dataframe with the month - !assumes files are in order!
for(i in 1:length(cohortSummary)){
  cohortSummary[[i]] = mutate(cohortSummary[[i]], Month = i-1)
  print(i)
}

# puts all the monthly dataframes into one big dataframe, using data.table package
cohortSummaryTogether <- rbindlist(cohortSummary)


