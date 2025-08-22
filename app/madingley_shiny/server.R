#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# Define server logic required to draw a histogram
function(input, output, session) {

    # First output : rasterinput map
    output$rasterinput <- renderPlot({

        # Load a raster of HANPP
        rasterinput <- terra::rast(here::here("Data", "HANPPglobal_SSP5_RCP85_2020.tif"))
        
        mask_NorthAm <- terra::vect(cbind(c(-175, -175, -45,  -45), c(10, 80, 80, 10)), type="polygon", crs="+proj=longlat +datum=WGS84")

        rasterinput <- terra::crop(rasterinput, mask_NorthAm)
        
        terra::plot(rasterinput)
    })
    
    
    # Second output : rasterouput map
    output$rasterouput <- renderPlot({
        
        # Load a raster of HANPP
        rasterouput <- terra::rast(here::here("Data", "HANPPglobal_SSP5_RCP85_2055.tif"))
        
        mask_NorthAm <- terra::vect(cbind(c(-175, -175, -45,  -45), c(10, 80, 80, 10)), type="polygon", crs="+proj=longlat +datum=WGS84")
        
        rasterouput <- terra::crop(rasterouput, mask_NorthAm)
        
        terra::plot(rasterouput)
    })

}
