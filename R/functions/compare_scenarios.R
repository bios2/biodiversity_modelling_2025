# Function to compare scenarios

compare_scenarios <- function(scenario1, scenario2){
  
  #Compute raster of differences
  compared <- scenario1 - scenario2
  
  #Extract max absolute value for divergent color scale
  df <- as.data.frame(compared, xy = TRUE, na.rm = TRUE)
  colnames(df)[3] <- "comparison"
  max_val <- max(abs(df$comparison), na.rm = TRUE)
  
  #Représentation graphique
  a <- ggplot()+
    geom_spatraster(data = compared, aes(fill = mean))+
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", 
                         midpoint = 0, limits = c(-max_val, max_val),
                         name = "Difference") +
    theme_classic()
  
  print(a)
  
  return(compared)
  
}

