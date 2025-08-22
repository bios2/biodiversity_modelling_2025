#' Plot ther seasonality analysis on Madingley output 
#' @title Plot the seasonality analysis
#' @author Gabriel Bergeron
#' 
#' @param mdata A Madingley simulation output in a list format
#' 
#' @return A ggplot object
#' 
#' @export

# Packages dependancies : 
# dplyr
# tidyr
# ggplot2
# forcats
# ggpubr


plot_seasonality <- function(mdata){
  
  # Assign Lat Lon to the output of cohorts
  mdata <- assign_lat_lon(mdata)
  
  # Extract the number of birth per month for each cell
  cohorts <- mdata$cohorts
  
  cohorts_grid <- cohorts |>
    dplyr::mutate(BirthTimeStep = BirthTimeStep %% 12) |>
    dplyr::group_by(GridcellIndex, BirthTimeStep, lat, lon) |>
    dplyr::summarise(
      BirthCount = n() ,
      AbundanceCount = sum(CohortAbundance),
      BiomassTotal = sum(CohortAbundance * IndividualBodyMass),
      .groups = "drop"
    )
  
  # Change to long format : one month by columns
  cohorts_wide <- cohorts_grid %>%
    dplyr::select(BirthTimeStep, lat, lon, BirthCount) |> 
    tidyr::pivot_wider(names_from = BirthTimeStep, values_from = BirthCount, values_fill = 0)
  
  # Switch from month number to named month
  month_map <- setNames(month.abb, as.character(0:11))
  old.month.cols <- names(cohorts_wide)[names(cohorts_wide) %in% names(month_map)]
  names(cohorts_wide)[match(old.month.cols, names(cohorts_wide))] <- month_map[old.month.cols]
  
  # Create a rasterstack
  rstack <- terra::rast(
    cohorts_wide,
    type = "xyz"
  )
  
  # Vizualize
  cohorts_long <-
    cohorts_wide |>
    tidyr::pivot_longer(
      cols = !c(lat, lon),
      # all month columns
      names_to = "Month",
      # new column with month name
      values_to = "BirthCount" # new column with values
    ) |>
    dplyr::mutate(Month = factor(Month, levels = month.abb))
  
  cohorts_long |>
    ggplot2::ggplot(aes(x = lon, y = lat, fill = BirthCount)) +
    ggplot2::geom_tile() +
    ggplot2::facet_wrap(~ Month) +
    ggplot2::theme_minimal()
  
  # Group latitude into bins of 10 degrees
  # Plot the distribution of birth across latitude
  lat_distribution <- cohorts_long |> 
    dplyr::mutate(latBin = cut(lat, seq(min(lat), max(lat) + 10, by = 10), right = FALSE)) |> 
    dplyr::group_by(Month, latBin) |> 
    dplyr::summarise(BirthCount = sum(BirthCount)) |> 
    ggplot2::ggplot(aes(x = Month, y = BirthCount)) +
    ggplot2::geom_col() +
    ggplot2::theme_minimal() +
    ggplot2::facet_wrap(~ forcats::fct_rev(latBin), ncol = 1, scales = "free_y")
  
  # Measure seasonal amplitude of birth
  seasonal_amplitude <- cohorts_long |>
    dplyr::mutate(latBin = cut(lat, seq(min(lat), max(lat) + 10, by = 10), right = FALSE)) |>
    dplyr::group_by(Month, latBin) |>
    dplyr::summarise(BirthCount = sum(BirthCount), .groups = "drop") |>
    dplyr::group_by(latBin) |>
    dplyr::summarise(
      min = min(BirthCount),
      max = max(BirthCount),
      amplitude = max - min
    ) |>
    ggplot2::ggplot(aes(x = latBin, y = amplitude, group = 1)) +
    ggplot2::geom_point() +
    ggplot2::geom_line() +
    ggplot2::theme_minimal() + 
    ggplot2::coord_flip() + 
    ggplot2::theme(plot.margin = margin(1, 0.1, 0.1, 0.1, "cm"))
  
  # Measure seasonal variation of birth
  seasonal_variance <- cohorts_long |>
    dplyr::mutate(latBin = cut(lat, seq(min(lat), max(lat) + 10, by = 10), right = FALSE)) |>
    dplyr::group_by(Month, latBin) |>
    dplyr::summarise(BirthCount = sum(BirthCount), .groups = "drop") |>
    dplyr::group_by(latBin) |>
    dplyr::summarise(variance = var(BirthCount)) |>
    ggplot2::ggplot(aes(x = latBin, y = variance, group = 1)) +
    ggplot2::geom_point() +
    ggplot2::geom_line() +
    ggplot2::theme_minimal() + 
    ggplot2::coord_flip() + 
    ggplot2::theme(plot.margin = margin(1,0.1,0.1,0.1, "cm"))
  
  # Measure peak birth timing
  seasonal_timing <- cohorts_long |>
    dplyr::mutate(latBin = cut(lat, seq(min(lat), max(lat) + 10, by = 10), right = FALSE)) |>
    dplyr::group_by(Month, latBin) |>
    dplyr::summarise(BirthCount = sum(BirthCount), .groups = "drop") |>
    dplyr::group_by(latBin) |>
    dplyr::filter(BirthCount == max(BirthCount)) |> 
    ggplot2::ggplot(aes(x = latBin, y = Month, group = 1)) +
    ggplot2::geom_point() +
    ggplot2::geom_line() +
    ggplot2::theme_minimal() + 
    ggplot2::coord_flip() + 
    ggplot2::theme(plot.margin = margin(1,0.1,0.1,0.1, "cm")) 
  
  # Combine the three plots
  final_plot <- ggpubr::ggarrange(
    lat_distribution,
    ggpubr::ggarrange(
      seasonal_amplitude,
      seasonal_variance,
      seasonal_timing,
      labels = c("Amplitude", "Variance", "Timing"),
      ncol = 1
    ),
    ncol = 2,
    widths = c(2, 1)
  )
  
  return(final_plot)
  
}

