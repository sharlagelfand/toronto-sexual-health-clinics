library(shinydashboard)
library(leaflet)

header <- dashboardHeader(
  title = "Toronto Sexual Health Clinics",
  titleWidth = 300
)

body <- dashboardBody(
  fluidRow(
    box(width = 8, solidHeader = TRUE,
        leafletOutput("map", height = 500)),
    column(width = 4, 
           box(title = "All clinics offer:", width = NULL,
               tableOutput("services")),
           box(width = NULL, tableOutput("clinic_details")))
  ),
  
  fluidRow(
    box(title = "Drop-in hours", width = 4,
        tableOutput("drop_in_hours")),
    box(title = "Appointment hours", width = 4,
        tableOutput("appointment_hours")),
    box(title = "Additional services", width = 4, 
        tableOutput("services_unique"))
  )
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)