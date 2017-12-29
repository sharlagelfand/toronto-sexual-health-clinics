library(readxl)
library(dplyr)
library(janitor)
library(tidyr)
library(stringr)
library(rvest)
library(purrr)

sexual_health_clinics <- read_excel("data/Sexual Health Clinics Data Set.xlsx")

# tidy up names and remove first row, which contains subheadings of drop-in/appointment hours

sexual_health_clinics <- sexual_health_clinics %>%
  clean_names() %>%
  rename(drop_in_hours = operational_hours,
         appointment_hours = x_1)

sexual_health_clinics <- sexual_health_clinics[-1,]

# drop rows that have no data

sexual_health_clinics <- sexual_health_clinics %>%
  remove_empty_rows

# if the clinic_name is split onto multiple lines, combine it into one line

sexual_health_clinics <- sexual_health_clinics %>%
  mutate(previous_clinic_name = lag(clinic_name),
         next_clinic_name = lead(clinic_name),
         clinic_name = if_else(!is.na(clinic_name) & !is.na(next_clinic_name), 
                               paste(clinic_name, next_clinic_name), 
                               clinic_name), # appending the next line, if there is one
         clinic_name = if_else(!is.na(previous_clinic_name), NA_character_, clinic_name)) %>% # removing the clinic name if it *is* the one on the second line 
  select(-previous_clinic_name, -next_clinic_name)

# doing the same for the address 

sexual_health_clinics <- sexual_health_clinics %>%
  mutate(previous_address = lag(address),
         next_address = lead(address),
         address = if_else(!is.na(address) & !is.na(next_address), 
                           paste(address, next_address), 
                           address), # appending the next line, if there is one
         address = if_else(!is.na(previous_address), NA_character_, address)) %>% # removing the clinic name if it *is* the one on the second line 
  select(-previous_address, -next_address)

# fill in clinic_name. NA's should be filled with the value from above, so direction is "down"

sexual_health_clinics <- sexual_health_clinics %>%
  fill(clinic_name)

# find what services are offered by *all* clinics -- we will want a list of unique services for each clinic

services_df <- sexual_health_clinics %>%
  mutate(n_clinics_total = n_distinct(clinic_name)) %>%
  group_by(services) %>%
  mutate(n_clinics_offer = n_distinct(clinic_name),
         all_clinics_offer = n_clinics_offer == n_clinics_total) %>%
  distinct(services, all_clinics_offer)

# get into a tidy format -- create list cols where needed, so there is only one row per clinic

services_all <- sexual_health_clinics %>%
  inner_join(services_df %>% 
               filter(all_clinics_offer), by = "services") %>%
  group_by(clinic_name) %>%
  summarise(services_all = list(services[!is.na(services)]))

services_unique <- sexual_health_clinics %>%
  inner_join(services_df %>% 
               filter(!all_clinics_offer), by = "services") %>%
  group_by(clinic_name) %>%
  summarise(services_unique = list(services[!is.na(services)]))

sexual_health_clinics <- sexual_health_clinics %>%
  group_by(clinic_name) %>%
  summarise_all(funs(list(.[!is.na(.)]))) %>%
  left_join(services_all, by = "clinic_name") %>%
  left_join(services_unique, by = "clinic_name")

# now that it's tidy... let's do more with it.

# parse out the postal code, which should be the last 7 characters of each address string

sexual_health_clinics <- sexual_health_clinics %>%
  mutate(address = str_trim(address), # strip whitespace first
         postal_code = substr(address, start = nchar(address) - 6, stop = nchar(address)),
         postal_code = gsub(" ", "", postal_code))

# check that it is a valid postal code, matching canadian postal code regex

sexual_health_clinics %>% 
  filter(postal_code != str_extract(postal_code, regex("[ABCEGHJKLMNPRSTVXY][0-9][ABCEGHJKLMNPRSTVWXYZ] ?[0-9][ABCEGHJKLMNPRSTVWXYZ][0-9]"))) %>%
  nrow == 0

# there's no R package for getting latitude and longitude by postal code... so we'll have to scrape for it

coordinates_by_postal_code <- function(postal_code){
  coordinates_url <- paste0("http://geolytica.com/?locate=", postal_code)
  
  coordinates_url_text <- coordinates_url %>%
    read_html() %>%
    html_nodes("strong") %>%
    html_text()
  
  coordinates <- coordinates_url_text[[2]] %>%
    str_split(", ") %>% 
    unlist
  
  latitude <- coordinates[[1]] %>%
    as.numeric
  
  longitude <- coordinates[[2]] %>%
    as.numeric
  
  return(c(latitude, longitude))
}

sexual_health_clinics <- sexual_health_clinics %>%
  mutate(coordinates = map(postal_code, coordinates_by_postal_code),
         latitude = map_dbl(coordinates, 1),
         longitude = map_dbl(coordinates, 2))

saveRDS(sexual_health_clinics, "data/sexual_health_clinics.rds")
