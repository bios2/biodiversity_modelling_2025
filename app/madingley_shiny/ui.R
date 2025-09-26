#
# This is the user-interface definition of the Shiny web application designed for the Madingley summer school

library(shiny)
library(bslib)
library(terra)

# Define UI
fluidPage(
    # Make the sidebarPanel sticky
    tags$style(
        HTML(
            "div.sticky {
        position: -webkit-sticky;
        position: sticky;
        top: 0;
        z-index: 1;
        }"
        )
    ),
    
    # Application titel
    titlePanel("Predicting change in biodiversity - Madingley"),
    
    # Sidebar with input controls
    sidebarLayout(
        tagAppendAttributes(sidebarPanel(
            width = 3,
            h4("Measure of Essential biodiversity variables using Madingley"),
            
            p(
                "This is an area where we will breifly describe the project and what this app does. Exemple of content include : origin of the input data, how the model was computed, what are the avaible EBV and what do they means, etc.."
            ),
            
            # Selection of the horizon of the projection
            # CAUTION ***** Please note that the projection for 2040 did not exist so we copied 2045 *****
            sliderInput(
                inputId = "projection_year",
                label = "Horizon of the projection",
                min = 2025,
                max = 2055,
                value = 2025,
                step = 5
            ),
        ), class = "sticky"),
        
        mainPanel(
            # width = 9,
            
            # Row 1: two cards side by side
            fluidRow(
                style = "display:flex;",
                # Control card heigh
                column(6, card(
                    # Left plot, raster of land in 2020
                    h3(textOutput("Land use - 2020")), 
                    plotOutput("rasterHANPPpresent"), 
                    style = "flex:1; height:35vh;"
                )),
                column(6, card(
                    # Right plot, raster of l;and use on the selected horizon
                    h3(textOutput("Land use - 2020")), 
                    plotOutput("rasterHANPPfuture"), 
                    style = "flex:1; height:35vh;"
                ))
            )
        )
    )
)
