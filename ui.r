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
               tableOutput("services")))
  ),
  
  fluidRow(
    box(width = 3, tableOutput("clinic_details")),
    box(title = "Drop-in hours", width = 3,
        tableOutput("drop_in_hours")),
    box(title = "Appointment hours", width = 3,
        tableOutput("appointment_hours")),
    box(title = "Additional services", width = 3, 
        tableOutput("services_unique"))
  )
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)