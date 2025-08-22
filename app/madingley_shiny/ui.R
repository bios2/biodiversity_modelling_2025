#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)

# Define UI for application that draws a histogram
fluidPage(
    
    titlePanel("Simulation results and Essential Biodiversity Variables"),
    
    fluidRow(
        column(
            width = 4,
            plotOutput("rasterinput")
        ),
        
        column(
            width = 4,
            plotOutput("rasterouput")
        ),
        
        column(
            width = 2,
            
            # Placeholder for inputs
            h3("Placeholder for controls over simulation"),
            selectInput("Climate", "Choose climate scenario:",
                        choices = c("Control", "Warming")),
            selectInput("Land use", "Choose land use scenario:", 
                        choices = c("Control", "Land use +"))
        )
    )
)

