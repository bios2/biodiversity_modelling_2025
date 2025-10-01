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
        tagAppendAttributes(
            sidebarPanel(
                width = 3,
                h4("Measure of Essential biodiversity variables using Madingley"),
                
                p(
                    "This is an area where we will breifly describe the project and what this app does. Exemple of content include : origin of the input data, how the model was computed, what are the avaible EBV and what do they means, etc.."
                ),
                
                h4("Input variables", style = "text-align:center;"),
                
                # Selection of the horizon of the climate projection
                radioButtons(
                    inputId = "temp",
                    label = "Climate scenario",
                    choices = c("Baseline" = "2020",
                                "2050" = "2050"), 
                    inline = TRUE
                ),
                
                # Select the human impact projection
                radioButtons(
                    inputId = "HANPP",
                    label = "Human footprint scenario",
                    choices = c("Baseline" = "2020",
                                "2050" = "2050"),
                    inline = TRUE
                ),
                
                h4("Special scenarios", style = "text-align:center;"),
                
                # Select one of two special scenarios
                radioButtons(
                    inputId = "scenario",
                    label = "",
                    choices = c("Baseline" = "Baseline",
                                "Large predator removal" = "NoPred",
                                "Large herbivore removal" = "NoHerb"),
                    inline = FALSE
                ),
            ),
            class = "sticky"
        ),
        
        mainPanel(

            column(
                width = 12, 
                
                # Title of the grid
                h2("Input variables", style = "text-align:center; margin-bottom:20px;"),
                
                # Subheaders aligned with each card
                fluidRow(
                    column(4, h4("Initialisation", style = "text-align:center;")),
                    column(4, h4("Simulation", style = "text-align:center;")),
                    column(4, h4("Differences", style = "text-align:center;"))
                ),
                
                
                # === 3 columns × 2 rows grid of cards ===
                layout_column_wrap(
                    width = 1 / 3,
                    # 3 card per row
                    heigt = "35vh",
                    
                    # First row
                    card(plotOutput("rasterinittemp", height = "250px")),
                    card(plotOutput("rastersimtemp", height = "250px")),
                    card(plotOutput("rasterdifftemp", height = "250px")),
                    
                    # Second row
                    card(plotOutput("rasterinitHANPP", height = "250px")),
                    card(plotOutput("rastersimHANPP", height = "250px")),
                    card(plotOutput("rasterdiffHANPP", height = "250px")),
                ),
                
                h2("Essential Biodiversity Variables", style = "text-align:center; margin-bottom:20px;"),
                
                h3("Shannon Diversity index", style = "text-align:center; margin-bottom:20px;"),
                
                # Subheaders aligned with each card
                fluidRow(
                    column(4, h4("Initialisation", style = "text-align:center;")),
                    column(4, h4("Simulation", style = "text-align:center;")),
                    column(4, h4("Differences", style = "text-align:center;"))
                ),
                
                # === 3 columns × 1 rows grid of cards ===
                layout_column_wrap(
                    width = 1 / 3,
                    # 3 card per row
                    heigt = "35vh",
                    
                    # First row
                    card(plotOutput("rasterinitshannon", height = "250px")),
                    card(plotOutput("rastersimshannon", height = "250px")),
                    card(plotOutput("rasterdiffshannon", height = "250px"))
                ),
                
                h3("Seasonality of births", style = "text-align:center; margin-bottom:20px;"),
                
                # === 2 columns × 1 rows grid of cards ===
                layout_column_wrap(
                    width = 1 / 2,
                    # 3 card per row
                    heigt = "35vh",
                    
                    # First row
                    card(plotOutput("seasonalityinit")),
                    card(plotOutput("seasonalitysim"))
                )
            )
        )
    )
)
