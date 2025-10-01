# --- User Interface (ui.R) ---
# Defines the layout of the application using bslib for a modern card-based look.

library(shiny)
library(bslib)

# Define a reusable card height for the sidebar buttons
CARD_HEIGHT <- "50px"

ui <- page_navbar(
  title = "BIODIVERSITY MODELLING 2025 DASHBOARD",
  
  # Navigation Bar Controls
  sidebar = sidebar(
    title = "Simulation & Input Controls",
    
    # Projection Horizon Slider
    h4("Projection Horizon"),
    sliderInput(
      inputId = "projection_year", 
      label = NULL,
      min = 2020, 
      max = 2100, 
      value = 2025,
      step = 5,
      width = "100%"
    ),
    
    # Input Variables Selector (RESTUCTURED TO MATCH IMAGE)
    h4("Input Variables"),
    p("Define Initialization, Simulation, and Difference scenarios."),
    
    # Header Row
    layout_column_wrap(
      width = 1/3,
      class = "pb-2",
      style = "text-align: center; font-weight: bold;",
      tags$div("Initialization"),
      tags$div("Simulation"),
      tags$div("Difference")
    ),
    
    # -------------------------------------------------------------
    # ROW 1: CLIMATE INPUTS
    tags$div(class = "flex items-center space-x-2 pb-2",
             tags$div(class = "w-20 font-semibold text-sm", "Climate - Base 2050"),
             layout_column_wrap(
               width = 1/3,
               class = "flex-grow",
               # Use simple cards to represent buttons/inputs
               card(actionButton("climate_init", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("climate_sim", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("climate_diff", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0")
             )
    ),
    
    # -------------------------------------------------------------
    # ROW 2: HUMAN FOOTPRINT INPUTS
    tags$div(class = "flex items-center space-x-2 pb-2",
             tags$div(class = "w-20 font-semibold text-sm", "Human footprint - Base 2050"),
             layout_column_wrap(
               width = 1/3,
               class = "flex-grow",
               card(actionButton("footprint_init", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("footprint_sim", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("footprint_diff", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0")
             )
    ),
    
    # -------------------------------------------------------------
    # ROW 3: CARNIVORE REMOVAL INPUTS
    tags$div(class = "flex items-center space-x-2 pb-2",
             tags$div(class = "w-20 font-semibold text-sm", "Carnivore removal"),
             layout_column_wrap(
               width = 1/3,
               class = "flex-grow",
               card(actionButton("carnivore_init", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("carnivore_sim", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("carnivore_diff", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0")
             )
    ),
    
    # -------------------------------------------------------------
    # ROW 4: HERBIVORE REMOVAL INPUTS
    tags$div(class = "flex items-center space-x-2 pb-2",
             tags$div(class = "w-20 font-semibold text-sm", "Herbivore removal"),
             layout_column_wrap(
               width = 1/3,
               class = "flex-grow",
               card(actionButton("herbivore_init", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("herbivore_sim", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0"),
               card(actionButton("herbivore_diff", NULL, width = "100%"), height = CARD_HEIGHT, class = "p-1 m-0")
             )
    ),
    
    # Essential Biodiversity Variables (EBV) Selector (Remaing same)
    h4("Essential Biodiversity Variables"),
    selectInput(
      inputId = "ebv_select",
      label = "Select EBV to Map:",
      choices = c(
        "TotalAbundance" = "TotalAbundance",
        "TotalBiomass" = "TotalBiomass",
        "TrophicLevel" = "TrophicLevel"
      ),
      selected = "TotalAbundance",
      width = "100%"
    ),
    
    # Map Resolution Selector (Remaining same)
    h4("Map Resolution"),
    selectInput(
      inputId = "resolution_select",
      label = "Select Grid Size:",
      choices = c("1 degree" = 1),
      selected = 1,
      width = "100%"
    )
  ),
  
  # Main Content Area: Maps and Visualizations (Remaining same)
  nav_panel("Map View", 
            layout_column_wrap(
              width = 1/2, 
              heights_equal = "row",
              
              # 1. CARD FOR BASE/INITIALIZATION SCENARIO MAP (Left Map)
              card(
                full_screen = TRUE,
                card_header(uiOutput("map_title")), 
                plotOutput("cohort_map") 
              ),
              
              # 2. CARD FOR SCENARIO/DIFFERENCE MAP (Right Map)
              card(
                full_screen = TRUE,
                card_header(uiOutput("map_title_scenario")), 
                plotOutput("scenario_map") 
              )
            )
  ),
  
  # Placeholder for other navigation panels 
  nav_panel("Data Table", 
            card(
              card_header("Simulation Output Data"),
              p("Data table content will go here.")
            )
  )
)


