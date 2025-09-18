library("MadingleyR")
library("terra")
library("sf")
library("rnaturalearth")
library("tidyterra")
source("R/functions/assign_lat_lon.R")
source("R/functions/utils_rasters.R")

output_folder <- "~/Desktop/Madingley/output_test"
scenario_name <- "climate"
rds_name <- "mdata_climate_scenario.rds"

files <- file.path(output_folder,rds_name)
# For a list of files
# files <- list.files(
#   path = output_folder, 
#   pattern = "^global_SSP5_RCP85.*\\.rds$", 
#   full.names = TRUE
# )

# read all into a list
mdata_lc_list <- lapply(files, readRDS)
mdata_control <- readRDS(file.path(output_folder,"mdata_control.rds"))


#### Plot biomass timeline ####
# Get timeline dataframe for land cover scenario
autotroph_biomass <- c()
FG_biomass <- c()
for (i in 1:length(mdata_lc_list)) {
  v_stocks <- mdata_lc_list[[i]]$time_line_stocks
  v_cohorts <- mdata_lc_list[[i]]$time_line_cohorts
  
  autotroph_biomass <- rbind(autotroph_biomass, v_stocks)
  FG_biomass <- rbind(FG_biomass, v_cohorts)
  
}
FG_biomass$Month <- seq(1, nrow(FG_biomass), 1)
#summarize ectotherms biomass: 
FG_biomass <- FG_biomass %>% rowwise() %>% 
  dplyr::mutate(Biomass_FG_3 = sum(c(Biomass_FG_3,Biomass_FG_6)),
                Biomass_FG_4 = sum(c(Biomass_FG_4,Biomass_FG_7)),
                Biomass_FG_5 = sum(c(Biomass_FG_5, Biomass_FG_8))) %>%
  summarize(Month,Year,Biomass_FG_0,Biomass_FG_1,Biomass_FG_2,
            Biomass_FG_3,Biomass_FG_4,Biomass_FG_5) %>%
  ungroup() %>%   as.data.frame()

Biomass <- cbind(FG_biomass, autotroph_biomass[,3])
names(Biomass)[length(names(Biomass))] <- "TotalStockBiomass"
Biomass$scenario <- scenario_name

# Get timeline dataframe for control scenario
autotroph_biomass_c <- mdata_control$time_line_stocks
FG_biomass_c <- mdata_control$time_line_cohorts
FG_biomass_c$Month <- seq(1, nrow(FG_biomass_c), 1)

#summarize ectotherms biomass: 
FG_biomass_c <- FG_biomass_c %>% rowwise() %>% 
  dplyr::mutate(Biomass_FG_3 = sum(c(Biomass_FG_3,Biomass_FG_6)),
                Biomass_FG_4 = sum(c(Biomass_FG_4,Biomass_FG_7)),
                Biomass_FG_5 = sum(c(Biomass_FG_5, Biomass_FG_8))) %>%
  summarize(Month,Year,Biomass_FG_0,Biomass_FG_1,Biomass_FG_2,
            Biomass_FG_3,Biomass_FG_4,Biomass_FG_5) %>%
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
ggsave(paste0(output_folder, "/biomass_timeline.png"),
       width = 15, height = 4, dpi = 300)


