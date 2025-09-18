library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")
source("R/functions/assign_lat_lon.R")
source("R/functions/utils_rasters.R")

output_folder <- "~/Desktop/Madingley/output_test"
rds_name <- "mdata_control.rds"
scenario_name <- "control"

mdata_sc_path <- file.path(output_folder,rds_name)
mdata_sc <- readRDS(mdata_sc_path)
spatial_window <- mdata_sc$spatial_window

#### Food web ####
png(paste0(output_folder, "/", "foodweb_",scenario_name,".png"), 
    width = 700, height = 600, res = 100) 
plot_foodweb(mdata_sc, max_flows = 5)
dev.off() # Close the device

#### Spatial Biomass ####
r_biomass <- plot_spatialbiomass(mdata_sc, functional_filter = T, plot = F)

FG_names <- c("Herbivore iteroparity endotherm",
              "Carnivore iteroparity endotherm",
              "Omnivore iteroparity endotherm",
              "Herbivore semelparity ectotherm",
              "Carnivore semelparity ectotherm",
              "Omnivore semelparity ectotherm",
              "Herbivore iteroparity ectotherm",
              "Carnivore iteroparity ectotherm",
              "Omnivore iteroparity ectotherm")

names(r_biomass) <- FG_names

ggplot() +
  geom_spatraster(data = r_biomass) +
  scale_fill_viridis_c(limits = c(-2, 10), oob = scales::squish) + 
  facet_wrap(~lyr, ncol = 3) +
  theme_minimal() +
  labs(fill = "log10 Biomass[kg]")
ggsave(paste0(output_folder, "/", "spatialbiomass_",scenario_name,".png"),
       width = 10, height = 8, dpi = 300)

#### Spatial autotroph biomass ####
df_autotroph <- assign_lat_lon(mdata_sc$stocks, spatial_window)
r_autotroph <- terra::rast(df_autotroph %>% 
                             select(lon, lat, TotalBiomass))
crs(r_autotroph) <- crs(r_biomass)

ggplot() +
  geom_spatraster(data = log10(r_autotroph)) +
  scale_fill_viridis_c(limits = c(11, 14), oob = scales::squish) + 
  theme_minimal() +
  labs(fill = "log10 Biomass[kg]")
ggsave(paste0(output_folder, "/", "spatialautotroph_",scenario_name,".png"),
       width = 6, height = 4, dpi = 300)