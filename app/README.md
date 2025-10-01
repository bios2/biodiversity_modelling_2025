# Biodiversity Modelling 2025 / `app`

This subdirectory is where the `shiny` app for the Biodiversity Modelling 2025 project should be located ! 🦋

## Organisation of the shiny app

The shiny app allow to visualise the results from the different scenarios that were run on Madingley. 
The scenarios that were chosen are :
- A baseline scenario with Madingley current default parameters
- Climate projection in 2050 following RCP 8.5
- Projected change in Humain footprint up to 2050 (highest impact scenario)
- The intesection of these different scenario (climate x Human footprint)

Two additional scenarios were computed : removal of large carnivores and removal of large herbivore. Due to challenge in computing time, these scenarios were only run with the default climate and human footprint of the Madingley package. 

### Sidebar input controls

On the left of the webpage, we find the sidebar with the controls of the dynamic element. 

As both the model and the analysis takes a long time to run, most of the intercivness of the shiny app is to change toward which file is the app pointing. Indeed, most raster and results have to be computed and saved for the app to run smoothly. Running the analysis "on demand" as input change would make the app much slower and thus remove the perks of interactiveness. This however, comes at the price of a loss in how flexible we can make the app. 

The two first input are temperature and human footprint. As there are only two scenario in each, they are presented as button. In the future this feature could be updated when more scenarios becomes available. 

The last input is the "special scenario" section. Selecting a scenario forces the other input to go back at the "baseline" option as we did not ran all the combinaisons for those models. 

### Main panel with results

The main panel present the inputs and the results of the EBV analysis.

#### Input data layer. 

The input data layers are stored in the folder 'Data/' for climate and 'Data/HANPP/' for human footprint. Please be aware that changing the file names or location will cause the app to fail.

#### EBV analysis

For now, the results in this section are placeholders. These files are located in 'R/figures/'. Please replace the placeholders with the actual result following the naming convention :
AnalysisName_Clim**Year**_Hum**Year**.rds (or.tif)