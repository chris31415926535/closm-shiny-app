# TO BUILD DOCKER IMAGE:
#   docker build -t closm-shiny-app .
# TO DEPLOY DOCKER IMAGE:
#   fly deploy --local-only --image closm-shiny-app
library(shiny)
library(DT)
library(readr)
library(dplyr)

.data <- rlang::.data
set.seed(1)

ui <- fluidPage(
  shiny::titlePanel(
    shiny::tagList(
      "CLOSM - Data Catalogue",
      shiny::em("Beta Demo -- Not All Data Included")
    )
  ),

  # Create a new Row in the UI for selectInputs
  # Populate the select inputs with placeholder values. We will update them
  #   in the server() function below once the data is loaded

  fluidRow(
    column(
      4,
      selectInput("data_holding",
        "Data Holding",
        choices = "Loading..."
      )
    ),
    column(
      4,
      selectInput("lib",
        "Library",
        choices = "Loading..."
      )
    ),
    column(
      4,
      selectInput("dataset",
        "Dataset",
        choices = "Loading..."
      )
    ),

    # FIXME -- commenting these out for now pending advice from Vincent
    # column(4,
    #        selectInput("lang_var",
    #                    "Language variable",
    #                    choices = "Loading...")
    # ),
    # column(4,
    #        selectInput("lang_off",
    #                    "Official Language",
    #                    choices = "Loading...")
    # ),
    # Create a new row for the table.
    DT::dataTableOutput("table")
  ),
  shiny::downloadButton("downloadData", "Download")
)





server <- function(input, output, session) {
  # Load the pre-processed data:
  metadata_raw <- readr::read_csv(
    "data/var-trimmed-2026-01-30.csv"
  )
  warning("Demo -- only loading 25000 entries")


  # Update the select inputs once the data is loaded
  shiny::updateSelectInput(
    inputId = "data_holding",
    label = "Data Holding",
    choices = c(
      "All",
      unique(as.character(metadata_raw$var_data_holding))
    )
  )

  shiny::updateSelectInput(
    inputId = "lib",
    label = "Library",
    choices = c(
      "All",
      unique(as.character(metadata_raw$var_lib))
    )
  )


  shiny::updateSelectInput(
    inputId = "dataset",
    label = "Dataset",
    choices = c(
      "All",
      unique(as.character(metadata_raw$var_ds))
    )
  )


  shiny::updateSelectInput(
    inputId = "lang_var",
    label = "Language variable",
    choices = c(
      "All",
      unique(as.character(metadata_raw$lang_var_confirmed_VMS))
    )
  )


  shiny::updateSelectInput(
    inputId = "lang_off",
    label = "Official Language",
    choices = c(
      "All",
      unique(as.character(metadata_raw$lang_var_confirmed_VMS))
    )
  )

  # create a reactive object to hold the filtered data.
  # this logic used to be inside DT::renderDataTable(), but we move it outside
  # so that the filtered data can be re-used in the downloadHandler()
  reactive_filtered_data <- shiny::reactive({
    data <- metadata_raw

    if (input$data_holding != "All") {
      data <- data[data$var_data_holding == input$data_holding, ]
    }
    if (input$lib != "All") {
      # use dplyr::filter, the base R approach was not working
      data <- dplyr::filter(data, .data$var_lib == input$lib)
    }
    if (input$dataset != "All") {
      data <- data[data$var_ds == input$dataset, ]
    }

    # nolint start
    # FIXME -- Commenting these out for now pending advice from Vincent
    # if (input$lang_var != "All") {
    #   data <- data[data$lang_var_confirmed_VMS == input$lang_var,]
    # }
    # if (input$lang_off != "All") {
    #   data <- data[data$official_lang_var_VMS == input$lang_off,]
    # }
    # nolint end

    data
  }) # end reactive_filtered_data()


  # Filter data based on selections
  output$table <- DT::renderDataTable(DT::datatable(
    {
      reactive_filtered_data()
    },
    options = list(
      pageLength = 10, # Set number of rows per page
      autoWidth = TRUE, # Adjust column width automatically
      searchHighlight = TRUE, # Highlight search results
      # Enable regex, case-insensitive search
      search = list(regex = TRUE, caseInsensitive = TRUE),
      scrollX = TRUE # Enable horizontal scrolling
    ),
    filter = "top"
  ))



  output$downloadData <- downloadHandler(
    filename = function() {
      paste("data-", Sys.Date(), ".csv", sep = "")
    },
    content = function(con) {
      write.csv(reactive_filtered_data(), con)
    }
  )
}




# Run the application
shinyApp(
  ui = ui,
  server = server,
  options = list(
    port = 8080,
    host = "0.0.0.0"
  )
)
