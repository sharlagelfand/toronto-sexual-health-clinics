library(shinydashboard)
library(leaflet)

header <- dashboardHeader(
  title = "Toronto Sexual Health Clinics",
  titleWidth = 300
)

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("", icon = icon("map"), tabName = "dashboard"),
    menuItem("", icon = icon("info-circle"), tabName = "about")
  ),
  width = 50
)

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "dashboard",
            fluidRow(
              box(width = 8, solidHeader = TRUE,
                  leafletOutput("map", height = 500)),
              column(width = 4, 
                     box(title = "All clinics offer:", width = NULL,
                         tableOutput("services")))
            ),
            
            fluidRow(
              uiOutput("clinic_details_ui"),
              uiOutput("drop_in_hours_ui"),
              uiOutput("appointment_hours_ui"),
              uiOutput("services_unique_ui")
            )
    ),
    tabItem(tabName = "about", includeMarkdown("about.md")
    )
  )
)

dashboardPage(
  header,
  sidebar,
  body
)