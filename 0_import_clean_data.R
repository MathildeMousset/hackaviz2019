library(tidyverse)
library(lubridate)
library(readr)



library(sf)
library(sp)
library(tmap)
library(ggmap)
library(maps)
library(maptools)
library(leaflet)

library(geojsonR)
library(rgdal)
library(geojsonio)
library(geojsonsf)
library(sp)


library(ggrepel)



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
  mutate(log_habitants_2014 = log(habitants_2014),
         prop_habitants_actifs_2014 = personnes_actives_2014 / habitants_2014)






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
         prop_habitants_actifs_2014 = personnes_actives_2014 / habitants_2014)


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





