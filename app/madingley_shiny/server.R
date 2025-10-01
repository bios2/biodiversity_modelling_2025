#
# This is the server for the Shiny app of the Madingley summer school project
#

library(shiny)
library(bslib)
library(terra)

# Define server 
function(input, output, session) {
    
    mask_NorthAm <- terra::vect(
        cbind(c(-175, -175, -45,  -45), c(10, 80, 80, 10)),
        type="polygon", crs="+proj=longlat +datum=WGS84")
    
    land_mask <- terra::rast(here::here("Data/land_mask.tif")) |> 
        terra::crop(mask_NorthAm)
        
    
    
    # Switch the Temperature and HANPP radiobutton if scenarios are selected
    observeEvent(input$scenario, {
        if (input$scenario != "Baseline") {
            updateRadioButtons(session, "temp", selected = "2020")
            updateRadioButtons(session, "HANPP", selected = "2020")
        }
    })
    
    # Switch the scenarios if projections are selected
    observeEvent(input$temp, {
        if (input$temp == "2050") {
            updateRadioButtons(session, "scenario", selected = "Baseline")
        }
    })
    
    # Switch the scenarios if projections are selected
    observeEvent(input$HANPP, {
        if (input$HANPP == "2050") {
            updateRadioButtons(session, "scenario", selected = "Baseline")
        }
    })

    
    ## Temperature
    # --- Reactive sources for temperature ---
    
    # Initial temperature raster
    inittemp_rast <- reactive({
        r <- mean(terra::rast(here::here("Data", "Tempglobal_2020.tif")))
        terra::crop(r, mask_NorthAm) |> 
            terra::mask(land_mask, maskvalues = 0)
    })
    
    # Simulated temperature raster
    simtemp_rast <- reactive({
        r <- mean(terra::rast(here::here("Data", paste0("Tempglobal_", input$temp, ".tif"))))
        terra::crop(r, mask_NorthAm) |> 
            terra::mask(land_mask, maskvalues = 0)
    })
    
    # Difference raster
    difftemp_rast <- reactive({
        simtemp_rast() - inittemp_rast()
    })
    
    # --- Outputs ---
    
    output$rasterinittemp <- renderPlot({
        terra::plot(inittemp_rast())
    })
    
    output$rastersimtemp <- renderPlot({
        terra::plot(simtemp_rast())
    })
    
    output$rasterdifftemp <- renderPlot({
        terra::plot(difftemp_rast())
    })
    
    
    ## HANPP
    # --- Reactive sources for HANPP ---
    
    # Initial HANPP raster
    initHANPP_rast <- reactive({
        r <- terra::rast(here::here("Data/HANPP", "HANPPglobal_SSP5_RCP85_2020_1deg.tif"))
        terra::crop(r, mask_NorthAm)
    })
    
    # Simulated HANPP raster
    simHANPP_rast <- reactive({
        r <- terra::rast(here::here("Data/HANPP", paste0("HANPPglobal_SSP5_RCP85_", input$HANPP, "_1deg.tif")))
        terra::crop(r, mask_NorthAm)
    })
    
    # Difference raster (sim - init)
    diffHANPP_rast <- reactive({
        simHANPP_rast() - initHANPP_rast()
    })
    
    # --- Outputs ---
    
    output$rasterinitHANPP <- renderPlot({
        terra::plot(initHANPP_rast())
    })
    
    output$rastersimHANPP <- renderPlot({
        terra::plot(simHANPP_rast())
    })
    
    output$rasterdiffHANPP <- renderPlot({
        terra::plot(diffHANPP_rast())
    })    

    
    ## Shanon diversity index
    # --- Reactive sources for shannon ---
    
    # Initial shannon raster
    initshannon_rast <- reactive({
        r <- terra::rast(here::here("R/figures", "shannon_t2020_h2020.tif"))
        terra::crop(r, mask_NorthAm)
    })
    
    # Simulated HANPP raster
    simshannon_rast <- reactive({
        if(input$scenario %in% c("NoPred", "NoHerb")){
            r <- terra::rast(here::here("R/figures", paste0("shannon_", input$scenario, ".tif")))
            terra::crop(r, mask_NorthAm)
            
        } else {
            r <- terra::rast(here::here("R/figures", paste0("shannon_t", input$temp, "_h", input$HANPP,".tif")))
            terra::crop(r, mask_NorthAm)
        }
    })
    
    # Difference raster (sim - init)
    diffshannon_rast <- reactive({
        simshannon_rast() - initshannon_rast()
    })
    
    # --- Outputs ---
    
    output$rasterinitshannon <- renderPlot({
        terra::plot(initshannon_rast())
    })
    
    output$rastersimshannon <- renderPlot({
        terra::plot(simshannon_rast())
    })
    
    output$rasterdiffshannon <- renderPlot({
        terra::plot(diffshannon_rast())
    })    
    
    ## Seasonality
    # --- Reactive sources for seasonality ---
    pltinit <- reactive({
        readRDS(paste0(here::here("R/figures/seasonality_Clim2020_Hum2020.rds")))
    })
    
    pltsim <- reactive({
        if(input$scenario %in% c("NoPred", "NoHerb")){
            readRDS(paste0(here::here("R/figures", paste0("seasonality_", input$scenario, ".rds"))))
        } else {
            readRDS(paste0(here::here("R/figures", paste0("seasonality_Clim", input$temp, "_Hum", input$HANPP, ".rds"))))
        }
    })
    
    # --- Outputs ---
    
    output$seasonalityinit <- renderPlot({
        pltinit()
    })
    
    output$seasonalitysim <- renderPlot({
        pltsim()
    })
    
    
}
