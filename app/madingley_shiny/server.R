#
# This is the server for the Shiny app of the Madingley summer school project
#

library(shiny)
library(bslib)
library(terra)

# Define server 
function(input, output, session) {

    # First output : rasterinput map
    output$rasterHANPPpresent <- renderPlot({

        # Load a raster of HANPP
        rasterinput <- terra::rast(here::here("Data", "HANPPglobal_SSP5_RCP85_2020.tif"))
        
        mask_NorthAm <- terra::vect(cbind(c(-175, -175, -45,  -45), c(10, 80, 80, 10)), type="polygon", crs="+proj=longlat +datum=WGS84")

        rasterinput <- terra::crop(rasterinput, mask_NorthAm)
        
        terra::plot(rasterinput)
    })
    
    
    # Second output : rasterouput map
    output$rasterHANPPfuture <- renderPlot({
        
        # Load a raster of HANPP
        rasterouput <- terra::rast(here::here("Data", paste0("HANPPglobal_SSP5_RCP85_", input$projection_year, ".tif")))
        
        mask_NorthAm <- terra::vect(cbind(c(-175, -175, -45,  -45), c(10, 80, 80, 10)), type="polygon", crs="+proj=longlat +datum=WGS84")
        
        rasterouput <- terra::crop(rasterouput, mask_NorthAm)
        
        terra::plot(rasterouput)
    })

}
