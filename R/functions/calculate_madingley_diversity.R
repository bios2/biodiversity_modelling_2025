# Function to compute bins in bodymass
logspace <- function(a = 10e-8, b = 10e5, n) {
  10 ^ seq(log10(a), log10(b), length.out = n)
}


# Function to calculate diversity
# This function calculates the shannon diversity index for each
# grid cell. It bins the cohorts into size classes : the width of
# those bins depends on parameter 'size_bin_resolution'.

# Input : cohort dataframe from a madingley simulation

# Arguments: 
# cohort_data : data from a madingley simulation
# size_bin_resolution : resolution for size bins
# functional_group : functional group index from madingley simulation :
# 0 : Herbivore itéropare endotherme
# 1 : Carnivore itéropare endotherme
# 2 : Omnivore itéropare endotherme
# 3 : Herbivore semelpare ectotherme
# 4 : Carnivore semelpare ectotherme
# 5 : Omnivore semelpare ectotherme
# 6 : Herbivore itéropare ectotherme
# 7 : Carnivore itéropare ectotherme
# 8 : Omnivore itéropare ectotherme
# Can also take into argument a string qualifier
# (Carnivore, Herbivore, Omnivore, Iteroparous, Semelparous,
# Ectotherm, Endotherm)

# Output : Dataframe with community diversity in each grid cell

# Dependancies : 'tidyverse' library, 'madingleyR library' logspace handmade function
calculate_madingley_diversity <- function(cohort_data, size_bin_resolution,
                                          functional_group = NULL){
  #Filter for specified functional group
  if(!is.null(functional_group)){
    if(functional_group == "Carnivore"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 1 |
                              FunctionalGroupIndex == 4 |
                              FunctionalGroupIndex == 7)
    }
    if(functional_group == "Omnivore"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 2 |
                              FunctionalGroupIndex == 5 |
                              FunctionalGroupIndex == 8)
    }
    if(functional_group == "Herbivore"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 0 |
                              FunctionalGroupIndex == 3 |
                              FunctionalGroupIndex == 6)
    }
    if(functional_group == "Semelparous"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 3 |
                              FunctionalGroupIndex == 4 |
                              FunctionalGroupIndex == 5)
    }
    if(functional_group == "Iteroparous"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 0 |
                              FunctionalGroupIndex == 1 |
                              FunctionalGroupIndex == 2 |
                              FunctionalGroupIndex == 6 |
                              FunctionalGroupIndex == 7 |
                              FunctionalGroupIndex == 8)
    }
    if(functional_group == "Ectotherm"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 3 |
                              FunctionalGroupIndex == 4 |
                              FunctionalGroupIndex == 5 |
                              FunctionalGroupIndex == 6 |
                              FunctionalGroupIndex == 7 |
                              FunctionalGroupIndex == 8)
    }
    if(functional_group == "Endotherm"){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == 0 |
                              FunctionalGroupIndex == 1 |
                              FunctionalGroupIndex == 2)
    }
    
    #Functional group by index
    else if(is_integer(functional_group)){
      cohort_data <- filter(cohort_data, FunctionalGroupIndex == functional_group)
    }
  }
  # Reorganize data to calculate Relative Abundance (by biomass) in each cell
  data <- cohort_data[,c("GridcellIndex","FunctionalGroupIndex",
                         "Biomass", "SizeClass", "Month")] %>%
    
    # Group similar functional groups
    group_by(SizeClass, FunctionalGroupIndex, GridcellIndex, Month) %>%
    summarise(RealBiomass = sum(Biomass)) %>%
    ungroup() %>%
    
    # Add new column with relative abundance
    group_by(GridcellIndex) %>%
    mutate(RelativeAbundance = RealBiomass/sum(RealBiomass)) %>%
    ungroup()
  
  # Calculate Shannon Diversity Index for each grid cell

  #Loop in each cell
  Resultats <- list()
  for(m in unique(data$Month)){
    for(i in unique(data$GridcellIndex)){
      #Filter to have only the data per cell
      filtered_data <- filter(data, GridcellIndex == i, Month == m)
      
      #Calculate the index using loops
      diversity <- 0
      #Loop running through every cohort
      for(j in nrow(filtered_data)){
        p <- filtered_data$RelativeAbundance[j]
        print(p)
        diversity <- diversity + p*log(p)
      }
      diversity <- -diversity
      
      #Add the result to the container vector
      Row <- c(m,i,diversity)
      Resultats <- append(Resultats,Row)
    }
  }
  
  #Build dataframe
  df <- matrix(ncol = 3)
  for(k in 1:length(Resultats)){
    df <- rbind(df,Resultats[[k]])
  }
  df <- as.data.frame(df[-1,])
  
  return(df)
}
