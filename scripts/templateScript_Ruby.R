## Testing MadingleyR Simulations

library(MadingleyR)
madingley_version()
vignette('MadingleyR')

# create spatial window
spatial_window = c(-170, -45, 10, 80)
plot_spatialwindow(spatial_window)

madingley_inputs()
mdata = madingley_init(spatial_window = spatial_window,
                       max_cohort = 100) # you can also specify spatial imputs cohort and stock definitions, and model parameters here. Leaving blank will use defaults
str(mdata, 1)
# madingley_init() puts all the initial variables together. not the spinup

mdata2 = madingley_run(madingley_data = mdata,
                       years = 5, #this is the spin-up
                       max_cohort = 100)
#by default, run in parallel. there is a parallel input to tweak this

str(mdata2,1)
# end with a list of dataframes (generally). Cohorts at end, stocks at end, cohort definitions, stock definitions, the timeline of cohorts, the timeline of stocks, the spatial window and the grid size

str(mdata2$time_line_cohorts) #biomass in each functional group for each month
str(mdata2$time_line_stocks) #biomass in each stock for each month - does not seem to split deciduous from evergreen??

plot_timelines(mdata2)
plot_foodweb(mdata2)
plot_spatialbiomass(mdata2)


