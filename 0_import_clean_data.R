library(tidyverse)
library(extrafont)
library(ggrepel)
library(readr)


library(sf)
library(sp)
# library(tmap)
# library(ggmap)
# library(maps)
# library(maptools)
# library(leaflet)

# library(geojsonR)
# library(rgdal)
# library(geojsonio)
# library(geojsonsf)




# import data -------------------------------------------------------------

commune <- read_csv("par_commune.csv")
trajet <- read_csv("par_trajet.csv")

#unzip(file.path(extraWD, "departement.zip"), exdir = extraWD)

# import geojson
sf_commune <- st_read("par_commune.txt")



# COMMUNE wrangling ----------------------------------------------------------

# I can't get my head around the column names. Why would someone call "inter" the travels intra commune?!!

# The latitude and longitude were inversed. let's fix this.

communes <- commune %>%
  rename_all(~str_replace_all(., "extra", "sortant")) %>% 
  rename_all(~str_replace_all(., "intra", "entrant")) %>% 
  rename_all(~str_replace_all(., "inter", "intra")) %>% 
  mutate(latitude2 = longitude,
         longitude2 = latitude) %>% 
  select(-latitude, -longitude) %>% 
  rename(emplois_2017 = emplois,
         habitants_2014 = habitants,
         menages_2014 = menages,
         personnes_actives_2015 = '2015',
         personnes_actives_2009 = '2009',
         personnes_actives_2014 = '2014') %>% 
  
  # Création de variables intéressantes
  mutate(log_habitants_2014 = log(habitants_2014),
         
         prop_habitants_actifs_2014 = personnes_actives_2014 / habitants_2014,
         
         pop_classification = as.factor(case_when(
           habitants_2014 < 50                     ~ "0-50",
           between(habitants_2014, 50,         99) ~ "50-99",
           between(habitants_2014, 100,       199) ~ "100-199",
           between(habitants_2014, 200,       399) ~ "200-399",
           between(habitants_2014, 400,       999) ~ "400-999",
           between(habitants_2014, 1000,     1999) ~ "1000-1999",
           between(habitants_2014, 2000,     3499) ~ "2000-3499",
           between(habitants_2014, 3500,     4999) ~ "3500-4999",
           between(habitants_2014, 5000,     9999) ~ "5000-9999",
           between(habitants_2014, 10000,   19999) ~ "10000-19999",
           between(habitants_2014, 20000,   49999) ~ "20000-49999",
           between(habitants_2014, 50000,   99999) ~ "50000-99999",
           between(habitants_2014, 100000, 199999) ~ "100000-199999",
           habitants_2014 > 200000                 ~ ">200000")),
         
         type_commune = case_when(
           habitants_2014 < 1999 ~ "village",
           between(habitants_2014, 2000,   4999) ~ "bourg",
           between(habitants_2014, 5000,   19999) ~ "petite ville",
           between(habitants_2014, 20000,   49999) ~ "moyenne ville",
           between(habitants_2014, 50000,   199999) ~ "grande ville",
           habitants_2014 > 200000 ~ "metropole"),
         
         habitants_per_hectare = habitants_2014 / superficie,
         
         menages_per_hectare   = menages_2014 / superficie,
         
         taille_menage_2014 = case_when(
           menages_2014 > 0 ~ habitants_2014 / menages_2014,
           menages_2014 == 0 ~ NA_real_),
         # emploi par habitant: approximatif, pas les mêmes années
         emploi_par_habitant_actif = case_when(
           personnes_actives_2015 == 0 ~ 0,
           personnes_actives_2015 > 0 ~ emplois_2017 / personnes_actives_2015),
         
         revenu_median = case_when(
           revenu_median == 0 ~ NA_real_,
           revenu_median > 0 ~ as.double(revenu_median)),
         
         # 2009
         nb_communes_sortants_par_sortant_2009 = `2009_sortant_communes` / `2009_sortant`,
         
         nb_km_sortants_par_sortant_2009 = round(`2009_sortant_km` / `2009_sortant`),
         nb_km_sortants_par_sortant_2009_cat = case_when(
           nb_km_sortants_par_sortant_2009 < 10 ~ "0km-10km",
           between(nb_km_sortants_par_sortant_2009, 10, 19) ~ "10km-19km",
           between(nb_km_sortants_par_sortant_2009, 20, 29) ~ "20km-29km",
           between(nb_km_sortants_par_sortant_2009, 30, 39) ~ "30km-39km",
           nb_km_sortants_par_sortant_2009 >= 40 ~ "40km et plus"),
         
         nb_h_par_sortant_2009 = `2009_sortant_heure` / `2009_sortant`,
         
         
         # 2014
         nb_communes_sortants_par_sortant_2014 = `2014_sortant_communes` / `2014_sortant`,
         
         nb_km_sortants_par_sortant_2014 = round(`2014_sortant_km` / `2014_sortant`),
         nb_km_sortants_par_sortant_2014_cat = case_when(
           nb_km_sortants_par_sortant_2014 < 10 ~ "0km-10km",
           between(nb_km_sortants_par_sortant_2014, 10, 19) ~ "10km-19km",
           between(nb_km_sortants_par_sortant_2014, 20, 29) ~ "20km-29km",
           between(nb_km_sortants_par_sortant_2014, 30, 39) ~ "30km-39km",
           nb_km_sortants_par_sortant_2014 >= 40 ~ "40km et plus"),
         
         nb_h_par_sortant_2014 = `2014_sortant_heure` / `2014_sortant`)



sf_communes <- sf_commune %>%
  rename_all(~str_replace_all(., "extra", "sortant")) %>% 
  rename_all(~str_replace_all(., "intra", "entrant")) %>% 
  rename_all(~str_replace_all(., "inter", "intra")) %>% 
  mutate(latitude2 = longitude,
         longitude2 = latitude) %>% 
  select(-latitude, -longitude) %>% 
  
  rename(emplois_2017 = emplois,
         habitants_2014 = habitants,
         menages_2014 = menages,
         personnes_actives_2015 = X2015_1,
         personnes_actives_2009 = X2009_1,
         personnes_actives_2014 = X2014_1) %>% 
  
  mutate(log_habitants_2014 = log(habitants_2014),
         
         prop_habitants_actifs_2014 = personnes_actives_2014 / habitants_2014,
         
         pop_classification = as.factor(case_when(
           habitants_2014 < 50                     ~ "0-50",
           between(habitants_2014, 50,         99) ~ "50-99",
           between(habitants_2014, 100,       199) ~ "100-199",
           between(habitants_2014, 200,       399) ~ "200-399",
           between(habitants_2014, 400,       999) ~ "400-999",
           between(habitants_2014, 1000,     1999) ~ "1000-1999",
           between(habitants_2014, 2000,     3499) ~ "2000-3499",
           between(habitants_2014, 3500,     4999) ~ "3500-4999",
           between(habitants_2014, 5000,     9999) ~ "5000-9999",
           between(habitants_2014, 10000,   19999) ~ "10000-19999",
           between(habitants_2014, 20000,   49999) ~ "20000-49999",
           between(habitants_2014, 50000,   99999) ~ "50000-99999",
           between(habitants_2014, 100000, 199999) ~ "100000-199999",            habitants_2014 > 200000                 ~ ">200000")),
         
         type_commune = case_when(
           habitants_2014 < 1999 ~ "village",
           between(habitants_2014, 2000,   4999) ~ "bourg",
           between(habitants_2014, 5000,   19999) ~ "petite ville",
           between(habitants_2014, 20000,   49999) ~ "moyenne ville",
           between(habitants_2014, 50000,   199999) ~ "grande ville",
           habitants_2014 > 200000 ~ "metropole"),
         
         habitants_per_hectare = habitants_2014 / superficie,
         
         menages_per_hectare   = menages_2014 / superficie,
         
         taille_menage_2014 = case_when(
           menages_2014 > 0 ~ habitants_2014 / menages_2014,
           menages_2014 == 0 ~ NA_real_),
         
         # emploi par habitant: approximatif, pas les mêmes années
         emploi_par_habitant_actif = case_when(
           personnes_actives_2015 == 0 ~ 0,
           personnes_actives_2015 > 0 ~ emplois_2017 / personnes_actives_2015),
         
         revenu_median = case_when(
           revenu_median == 0 ~ NA_real_,
           revenu_median > 0 ~ as.double(revenu_median)
         ),
         
         # 2009
         nb_communes_sortants_par_sortant_2009 = X2009_sortant_communes / X2009_sortant,
         
         nb_km_sortants_par_sortant_2009 = round(X2009_sortant_km / X2009_sortant),
         
         nb_km_sortants_par_sortant_2009_cat = case_when(
           nb_km_sortants_par_sortant_2009 < 10 ~ "0km-10km",
           between(nb_km_sortants_par_sortant_2009, 10, 19) ~ "10km-19km",
           between(nb_km_sortants_par_sortant_2009, 20, 29) ~ "20km-29km",
           between(nb_km_sortants_par_sortant_2009, 30, 39) ~ "30km-39km",
           nb_km_sortants_par_sortant_2009 > 40 ~ "40km et plus"
         ),
         
         nb_h_par_sortant_2009 = (X2009_sortant_heure / X2009_sortant),
         
         
         
         # 2014
         nb_communes_sortants_par_sortant_2014 = X2014_sortant_communes / X2014_sortant,
         
         nb_km_sortants_par_sortant_2014 = round(X2014_sortant_km / X2014_sortant),
         
         nb_km_sortants_par_sortant_2014_cat = case_when(
           nb_km_sortants_par_sortant_2014 < 10 ~ "0km-10km",
           between(nb_km_sortants_par_sortant_2014, 10, 19) ~ "10km-19km",
           between(nb_km_sortants_par_sortant_2014, 20, 29) ~ "20km-29km",
           between(nb_km_sortants_par_sortant_2014, 30, 39) ~ "30km-39km",
           nb_km_sortants_par_sortant_2014 > 40 ~ "40km et plus"
         ),
         
         nb_h_par_sortant_2014 = (X2014_sortant_heure / X2014_sortant))




# Make population classification as in https://www.insee.fr/fr/statistiques/1280737 + classe de commune

communes <- communes %>% 
  mutate(pop_classification = fct_reorder(pop_classification, 
                                          habitants_2014,
                                          mean, na.rm = TRUE),
         
         type_commune = fct_reorder(type_commune, 
                                    habitants_2014,
                                    mean, na.rm = TRUE))


sf_communes <- sf_communes %>% 
  mutate(pop_classification = fct_reorder(pop_classification, 
                                          habitants_2014,
                                          mean, na.rm = TRUE),
         
         type_commune = fct_reorder(type_commune, 
                                    habitants_2014,
                                    mean, na.rm = TRUE))


         


# Crée des variables pour les flux
communes <- communes %>% 
  mutate(prop_intra_2009   = round(`2009_intra` / personnes_actives_2009, 2),
         prop_sortant_2009 = round(`2009_sortant` / personnes_actives_2009, 2),
         prop_sortant_2009_cat = case_when(
           between(prop_sortant_2009, 0, 0.25) ~"0% à 25%",
           between(prop_sortant_2009, 0.26, 0.5) ~"26% à 50%",
           between(prop_sortant_2009, 0.51, 0.75) ~"51% à 75%",
           between(prop_sortant_2009, 0.76, 1) ~"76% à 100%"
         ),
         
         prop_intra_2014   = round(`2014_intra` / personnes_actives_2014, 2),
         prop_sortant_2014 = round(`2014_sortant` / personnes_actives_2014, 2),
         prop_sortant_2014_cat = case_when(
           between(prop_sortant_2014, 0, 0.25) ~"0% à 25%",
           between(prop_sortant_2014, 0.26, 0.5) ~"26% à 50%",
           between(prop_sortant_2014, 0.51, 0.75) ~"51% à 75%",
           between(prop_sortant_2014, 0.76, 1) ~"76% à 100%")
         )




sf_communes <- sf_communes %>% 
  mutate(prop_intra_2009   = round(X2009_intra / personnes_actives_2009, 2),
         prop_sortant_2009 = round(X2009_sortant / personnes_actives_2009, 2),
         prop_sortant_2009_cat = case_when(
           between(prop_sortant_2009, 0, 0.25) ~"0% à 25%",
           between(prop_sortant_2009, 0.26, 0.5) ~"26% à 50%",
           between(prop_sortant_2009, 0.51, 0.75) ~"51% à 75%",
           between(prop_sortant_2009, 0.76, 1) ~"76% à 100%"),
         
         prop_intra_2014   = round(X2014_intra / personnes_actives_2014, 2),
         prop_sortant_2014 = round(X2014_sortant / personnes_actives_2014, 2),
         prop_sortant_2014_cat = case_when(
           between(prop_sortant_2014, 0, 0.25) ~"0% à 25%",
           between(prop_sortant_2014, 0.26, 0.5) ~"26% à 50%",
           between(prop_sortant_2014, 0.51, 0.75) ~"51% à 75%",
           between(prop_sortant_2014, 0.76, 1) ~"76% à 100%"
         )
         )




# Maps occitanie -----------------------------------------------------------

extraWD <- "."
departements_L93 <- st_read(dsn   = extraWD, 
                            layer = "DEPARTEMENT",
                            quiet = TRUE) %>% 
  st_transform(2154)


occitanie <- departements_L93 %>% 
  filter(NOM_REG == "LANGUEDOC-ROUSSILLON-MIDI-PYRENEES")

# En Lambert 93 (EPSG:2154)
# map_occitanie <- ggplot(occitanie) +
#   geom_sf() +
#   coord_sf(crs = 2154, datum = sf::st_crs(2154)) +
#   guides(fill = FALSE) +
#   theme_minimal()


# En  EPSG:4326 (basé sur le système WGS84 => GPS data)
map_occitanie <- ggplot(occitanie) +
  geom_sf() +
  coord_sf(crs = 4326, datum = sf::st_crs(4326)) +
  # guides(fill = FALSE) +
  theme_minimal()

#map_occitanie


map_occitanie_communes <- ggplot() +
  geom_sf(data = sf_communes,
          colour = "black") +
  coord_sf(crs = 4326, datum = sf::st_crs(4326))  +
  #guides(fill = FALSE) +
  theme_minimal()


map_occitanie_communes_no_border <- ggplot() +
  geom_sf(data = sf_communes,
          colour = NA) +
  coord_sf(crs = 4326, datum = sf::st_crs(4326))  +
  #guides(fill = FALSE) +
  theme_minimal()





