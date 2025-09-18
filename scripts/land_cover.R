library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")

set.seed(123)

# Functions
source("R/functions/assign_lat_lon.R")
source("R/functions/utils_rasters.R")

input_folder <- "Data/land_cover/land_cover_projection/processed"
output_folder <- "~/Desktop/Madingley/output_land_cover_scenario"

#### Preprocess inputs ####
# Load MadingleyR default inputs
sptl_inp <- madingley_inputs("spatial inputs")
chrt_def <- madingley_inputs("cohort definition")
stck_def <- madingley_inputs("stock definition")
mdl_prms <- madingley_inputs("model parameters")

# Get countries shapefile
spatial_window= c(-170, -50, 15, 83)
world <- ne_countries(scale = "medium", returnclass = "sf")
north_america <- vect(world[world$name %in% 
                         c("United States of America", 
                           "Canada", 
                           "Mexico"), ])

# Crop and mask spatial inputs 
sptl_inp <- mask_rasters_with_vector(inputs = sptl_inp, 
                                     spatial_vector= north_america)
sptl_inp <- crop_rasters_with_window(inputs = sptl_inp, 
                                     spatial_window = spatial_window)

# Preprocess HANPP data
r_hanpp_list <- read_rasters(input_folder)
# Remove NA's
r_hanpp_list <- lapply(r_hanpp_list, function(r) {
  r[is.na(r[])] <- 1
  r
})
r_hanpp_list <- mask_rasters_with_vector(inputs = r_hanpp_list, 
                                         spatial_vector = north_america)
r_hanpp_list <- crop_rasters_with_window(inputs = r_hanpp_list, 
                                           spatial_window = spatial_window)
spatial_window <- as.vector(ext(sptl_inp$hanpp))

#### Run spin-up ####
# Initialise the model using the pre-loaded inputs
mdata = madingley_init(spatial_window = spatial_window,
                       cohort_def = chrt_def,
                       stock_def = stck_def,
                       spatial_inputs = sptl_inp,
                       max_cohort = 100)

# Run spin-up
model_list <- list()
dir_path <- paste0(output_folder,"/spin_up")
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}
model_list[[1]] <- madingley_run(,madingley_data = mdata,
                                 out_dir = dir_path,
                                 years = 200,
                                 cohort_def = chrt_def,
                                 stock_def = stck_def,
                                 spatial_inputs = sptl_inp,
                                 model_parameters = mdl_prms,
                                 max_cohort = 100)

#### Run land cover scenario ####
# Run the Madingley model with HANPP input
for(i in 1:length(r_hanpp_list)){
  r_hanpp <- r_hanpp_list[[i]]
  hanpp_name <- names(r_hanpp)
  print(hanpp_name)
    
  sptl_inp$hanpp[] <- r_hanpp
  plot(sptl_inp$hanpp)

  dir_path <- paste0(output_folder,"/",hanpp_name)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
  
  # Run the model for 100 years with the last HANPP raster
  # and for 10 years with the rest
  if(i == length(r_hanpp_list)){
    n_years <- 100
  } else {
    n_years <- 10
  }
  model_list[[i+1]] <- madingley_run(years = n_years, 
                                     out_dir = dir_path,
                                     madingley_data = model_list[[i]],
                                     spatial_inputs = sptl_inp,
                                     silenced = F,
                                     max_cohort = 100,
                                     apply_hanpp = 1)
                                   
}

#### Run control scenario ####
dir_path <- paste0(output_folder,"/control")
if (!dir.exists(dir_path)) {
  dir.create(dir_path, recursive = TRUE)
}
model_list[[11]] <- madingley_run(out_dir = dir_path,
                                 years = 180, 
                                 madingley_data = model_list[[1]],
                                 spatial_inputs = sptl_inp,
                                 silenced = F,
                                 max_cohort = 100, # at least 500
                                 apply_hanpp = F)

# 1: Spin-up (200y)
# 2-10: 10y x 8 + 100y x 1
# 11: Control 180

#### Plot biomass timeline ####
# Get timeline dataframe for land cover scenario
autotroph_biomass <- c()
FG_biomass <- c()
for (i in 2:10) {
  v_stocks <- model_list[[i]]$time_line_stocks
  v_cohorts <- model_list[[i]]$time_line_cohorts
  
  autotroph_biomass <- rbind(autotroph_biomass, v_stocks)
  FG_biomass <- rbind(FG_biomass, v_cohorts)
  
}
FG_biomass$Month <- seq(1, nrow(FG_biomass), 1)
#summarize ectotherms biomass: 
FG_biomass <- FG_biomass %>% rowwise() %>% 
  dplyr::mutate(Biomass_FG_3 = sum(c(Biomass_FG_3,Biomass_FG_6)),Biomass_FG_4 = sum(c(Biomass_FG_4,Biomass_FG_7)),Biomass_FG_5 = sum(c(Biomass_FG_5, Biomass_FG_8))) %>%
  summarize(Month,Year,Biomass_FG_0,Biomass_FG_1,Biomass_FG_2,Biomass_FG_3,Biomass_FG_4,Biomass_FG_5) %>%
  ungroup() %>%   as.data.frame()

Biomass <- cbind(FG_biomass, autotroph_biomass[,3])
names(Biomass)[length(names(Biomass))] <- "TotalStockBiomass"
Biomass$scenario <- "land cover"

# Get timeline dataframe for control scenario
autotroph_biomass_c <- model_list[[11]]$time_line_stocks
FG_biomass_c <- model_list[[11]]$time_line_cohorts
FG_biomass_c$Month <- seq(1, nrow(FG_biomass_c), 1)

#summarize ectotherms biomass: 
FG_biomass_c <- FG_biomass_c %>% rowwise() %>% 
  dplyr::mutate(Biomass_FG_3 = sum(c(Biomass_FG_3,Biomass_FG_6)),Biomass_FG_4 = sum(c(Biomass_FG_4,Biomass_FG_7)),Biomass_FG_5 = sum(c(Biomass_FG_5, Biomass_FG_8))) %>%
  summarize(Month,Year,Biomass_FG_0,Biomass_FG_1,Biomass_FG_2,Biomass_FG_3,Biomass_FG_4,Biomass_FG_5) %>%
  ungroup() %>%   as.data.frame()

Biomass_c <- cbind(FG_biomass_c, autotroph_biomass_c[,3])
names(Biomass_c)[length(names(Biomass_c))] <- "TotalStockBiomass"
Biomass_c$scenario <- "control"

Biomass_total <- rbind(Biomass, Biomass_c)

ggplot(data=Biomass_total, aes(x=Month/12))+
  geom_line(aes(y=log10(TotalStockBiomass),colour="Autotrophs"))+
  geom_line(aes(y=log10(Biomass_FG_0),colour="End. Herbivores"),linewidth=0.8)+
  geom_line(aes(y=log10(Biomass_FG_1),colour="End. Carnivores"),linewidth=0.8)+
  geom_line(aes(y=log10(Biomass_FG_2),colour="End. Omnivores"),linewidth=0.8)+
  geom_line(aes(y=log10(Biomass_FG_3),colour="Ect. Herbivores"),linewidth=0.8)+
  geom_line(aes(y=log10(Biomass_FG_4),colour="Ect. Carnivores"),linewidth=0.8)+
  geom_line(aes(y=log10(Biomass_FG_5),colour="Ect. Omnivores"),linewidth=0.8)+
  scale_colour_manual(name = "Functional Group", values = c("Autotrophs"="#009E73",
                                                            "End. Herbivores" = "#CC79A7",
                                                            "End. Carnivores" = "#E69F00",
                                                            "End. Omnivores" = "#56B4E9",
                                                            "Ect. Herbivores" = "#F0E442",
                                                            "Ect. Carnivores" = "#0072B2",
                                                            "Ect. Omnivores" = "#D55E00"))+
  labs(x='Year of Simulation', y = "Log10 Biomass [kg]")+
  theme_classic()+
  facet_wrap(~scenario, scales = "free_y", ncol = 2) +  # two panels side by side
  ylim(10.5, 13.5) +
  xlim(0, 180) +
  theme(axis.text.y = element_text(size = 10), 
        axis.title.y = element_text(margin = margin(t = 0, r = 5, b = 0, l = 0),size=10)) +
  theme(axis.text.x = element_text(size = 10),
        axis.title.x = element_text(margin = margin(t = 5, r = 0, b = 0, l = 0),size=10))+
  theme(legend.text = element_text(size=10),legend.title = element_text(size=10,face="bold")) +
  theme(legend.position = "bottom") 
# Save to file
ggsave(paste0(output_folder, "/figures/biomass_timeline.png"),
       width = 15, height = 4, dpi = 300)


#### Other plots ####
# Foodweeb
png(paste0(output_folder, "/figures/foodweeb_lc.png"), width = 700, height = 600, res = 100) # Open PNG device
plot_foodweb(model_list[[10]], max_flows = 5)
dev.off() # Close the device

png(paste0(output_folder, "/figures/foodweeb_control.png"), width = 700, height = 600, res = 100) # Open PNG device
plot_foodweb(model_list[[11]], max_flows = 5)
dev.off() # Close the device


# Spatial Biomass
r_biomass <- plot_spatialbiomass(model_list[[10]], functional_filter = T, plot = F)
r_biomass_c <- plot_spatialbiomass(model_list[[11]], functional_filter = T, plot = F)

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
names(r_biomass_c) <- FG_names

ggplot() +
  geom_spatraster(data = r_biomass) +
  scale_fill_viridis_c(limits = c(-2, 10), oob = scales::squish) + 
  facet_wrap(~lyr, ncol = 3) +
  theme_minimal() +
  labs(fill = "log10 Biomass[kg]")
ggsave(paste0(output_folder, "/figures/spatialbiomass_lc.png"),
       width = 10, height = 8, dpi = 300)

ggplot() +
  geom_spatraster(data = r_biomass_c) +
  scale_fill_viridis_c(limits = c(-2, 10), oob = scales::squish) + 
  facet_wrap(~lyr, ncol = 3) +
  theme_minimal() +
  labs(fill = "log10 Biomass[kg]")
ggsave(paste0(output_folder, "/figures/spatialbiomass_control.png"),
       width = 10, height = 8, dpi = 300)


# Spatial autotroph biomass
df_autotroph <- assign_lat_lon(model_list[[10]]$stocks, spatial_window)
r_autotroph <- terra::rast(df_autotroph %>% 
                        select(lon, lat, TotalBiomass))
crs(r_autotroph) <- crs(r_biomass)

df_autotroph_c <- assign_lat_lon(model_list[[11]]$stocks, spatial_window)
r_autotroph_c <- terra::rast(df_autotroph_c %>% 
                             select(lon, lat, TotalBiomass))
crs(r_autotroph_c) <- crs(r_biomass)

ggplot() +
  geom_spatraster(data = log10(r_autotroph)) +
  scale_fill_viridis_c(limits = c(11, 14), oob = scales::squish) + 
  theme_minimal() +
  labs(fill = "log10 Biomass[kg]")
ggsave(paste0(output_folder, "/figures/spatialautotroph_lc.png"),
       width = 6, height = 4, dpi = 300)

ggplot() +
  geom_spatraster(data = log10(r_autotroph_c)) +
  scale_fill_viridis_c(limits = c(11, 14), oob = scales::squish) + 
  theme_minimal() +
  labs(fill = "log10 Biomass[kg]")
ggsave(paste0(output_folder, "/figures/spatialautotroph_control.png"),
       width = 6, height = 4, dpi = 300)