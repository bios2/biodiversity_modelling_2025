
# --- Server Logic (server.R) ---
# This version loads clean data and injects a mock raster in memory if real data is missing.

library(MadingleyR) 
library(terra) 

# --- Define the necessary data locations (used inside server function now) ---
output_folder <- "~/Desktop/Madingley/my_test_output"

server <- function(input, output, session) {
  
  # Reactive value to hold the loaded Madingley data
  madingley_data <- reactiveVal(NULL)
  
  # 1. Load Madingley data once the session starts
  observe({
    tryCatch({
      mdata_test <- readRDS(file.path(output_folder, "mdata_test.rds"))
      madingley_data(mdata_test) 
    }, error = function(e) {
      cat("Error loading mdata_test.rds:", conditionMessage(e), "
")
      madingley_data(NULL)
    })
  })
  
  # Reactive output for the map title
  output$map_title <- renderUI({
    tagList(
      "North America Map:", tags$b(input$ebv_select), 
      tags$span(paste0(" (Projection Year: ", input$projection_year, ")"))
    )
  })
  
  # Reactive function to extract and plot the raster data
  output$cohort_map <- renderPlot({
    
    mdata_test <- madingley_data()
    
    # 1. Basic checks
    if (!exists("sptl_inp", envir = .GlobalEnv) || is.null(mdata_test)) {
      msg <- if (!exists("sptl_inp", envir = .GlobalEnv)) "ERROR: sptl_inp object not found." else "LOADING ERROR: Model output data (mdata_test.rds) failed to load."
      plot(1, type="n", axes=FALSE, xlab="", ylab="")
      text(1, 1, msg, col="red", cex=1.5)
      return()
    }
    
    selected_category <- input$ebv_select %||% "TotalAbundance"
    
    # 2. Check all possible raster slots
    plot_data <- NULL
    data_source <- "Unknown Raster"
    
    if (!is.null(mdata_test$stock_raster)) {
      plot_data <- mdata_test$stock_raster
      data_source <- "Total Stock Biomass (Simulated)"
    } else if (!is.null(mdata_test$cohort_raster)) {
      plot_data <- mdata_test$cohort_raster
      data_source <- "Cohort Biomass/Abundance (Simulated)"
    } else if (!is.null(mdata_test$grid_summary)) {
      plot_data <- mdata_test$grid_summary
      data_source <- "Grid Summary / Spatial Output (Simulated)"
    }

    # 3. IF RASTER IS MISSING, CREATE MOCK RASTER IN MEMORY
    if (is.null(plot_data)) {
        # Use sptl_inp (from global environment) to base the mock data
        if(exists("sptl_inp", envir = .GlobalEnv) && length(sptl_inp) > 0) {
            
            # Create a mock data layer using the first raster in sptl_inp
            mock_raster_base <- sptl_inp[[1]]
            mock_data_layer <- mock_raster_base
            
            # Populate with dummy data
            values(mock_data_layer) <- runif(terra::ncell(mock_data_layer), min = 5, max = 500)
            names(mock_data_layer) <- "MOCK RASTER DATA"
            
            plot_data <- mock_data_layer
            data_source <- "MOCK RASTER (Generated In-Memory)"
            
            print("Successfully injected MOCK RASTER data.")
            
        } else {
            # Still no raster found, and sptl_inp is missing/empty
            plot(1, type="n", axes=FALSE, xlab="", ylab="")
            text(1, 1, 
                 "FATAL ERROR: No spatial raster data found in ANY tested slot.

                 AND global sptl_inp is missing for mock generation.", 
                 col="red", cex=1.5)
            return()
        }
    }
    
    # 4. Set the name and plot
    names(plot_data) <- data_source
    
    terra::plot(plot_data, 
                main = paste("Simulated", names(plot_data), "Distribution"),
                col = hcl.colors(100, "Oslo"), 
                axes = TRUE)
    
  }, res = 100)
}

