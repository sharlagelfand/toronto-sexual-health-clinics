library(shinydashboard)
library(leaflet)
library(dplyr)
library(purrr)

# Read in cleaned data
sexual_health_clinics <- readRDS("data/sexual_health_clinics.rds")

# For each clinic, want to form the popup with information about it
# Name
# Address
# Phone number

sexual_health_clinics <- sexual_health_clinics %>%
  group_by(clinic_name) %>%
  mutate(popup_details = pmap(list(clinic_name, 
                                   address,
                                   contact_number),
                              function(clinic_name, address, contact_number)
                                paste("<b>", clinic_name, "</b><br>",
                                      address, "<br>",
                                      contact_number)))

function(input, output, session){
  
  # Generate the map
  
  output$map <- renderLeaflet({
    leaflet(data = sexual_health_clinics) %>% 
      setView(lng = -79.38, lat = 43.73, zoom = 11) %>% 
      addTiles() %>% 
      addMarkers(~longitude, ~latitude, popup = ~popup_details, label = ~clinic_name,
                 labelOptions = labelOptions(direction = "top"))
  })
  
  # List of services that all clinics offer
  
  output$services <- renderTable(
    unlist(sexual_health_clinics[1, "services_all"]),
    colnames = FALSE,
    striped = TRUE
  )
  
  # When a clinic is clicked, show the clinic's hours (drop in and appointment), and unique services
  
  observeEvent(input$map_marker_click, {
    event <- input$map_marker_click
    
    if (is.null(event))
      return()
    
    df <- sexual_health_clinics %>% 
      ungroup() %>%
      filter(latitude == event$lat & longitude == event$lng)
    
    output$clinic_details <- renderTable(
      c(df[["clinic_name"]], unlist(df[["address"]]), unlist(df[["contact_number"]])),
      colnames = FALSE
    )
    
    drop_in_hours <- df %>%
      select(drop_in_hours) %>%
      unlist
    
    drop_in_hours_res <- if(length(drop_in_hours) == 0){"This clinic does not have drop-in hours."}else{drop_in_hours}
    
    appointment_hours <- df %>%
      select(appointment_hours) %>%
      unlist
    
    appointment_hours_res <- if(length(appointment_hours) == 0){"This clinic does not have appointment hours."}else{appointment_hours}
    
    services_unique <- df %>%
      select(services_unique) %>%
      unlist
    
    services_unique_res <- if(length(services_unique) == 0){"No services are offered in addition to those listed above."}else{services_unique}
    
    output$drop_in_hours <- renderTable(
      drop_in_hours_res,
      colnames = FALSE,
      striped = length(drop_in_hours) > 1 # only stripe the table if it's actually a table, not just the statement.
    )
    
    output$appointment_hours <- renderTable(
      appointment_hours_res,
      colnames = FALSE,
      striped = length(appointment_hours) > 1
    )
    
    output$services_unique <- renderTable(
      services_unique_res,
      colnames = FALSE,
      striped = length(services_unique) > 1
    )
    
  })
  
  
}
