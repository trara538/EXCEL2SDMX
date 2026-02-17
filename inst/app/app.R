# -------------------------------------------------
# Load libraries
# -------------------------------------------------
library(shiny)
library(shinydashboard)
library(readxl)
library(dplyr)
library(tidyr)
library(shinymanager) #main library used for this package

# -------------------------------------------------
# USER CREDENTIALS
# -------------------------------------------------
credentials <- data.frame(
  user = c("user"),
  password = c("password"),
  stringsAsFactors = FALSE
)

# -------------------------------------------------
# ALLOWED WORKSHEETS (IMTS)
# -------------------------------------------------
allowed_sheets <- c(
  "bot",
  "imports",
  "exports",
  "reexports",
  "totexports",
  "bot_cty",
  "trade_reg",
  "mode_trspt",
  "x_sitc",
  "m_sitc"
)

# -------------------------------------------------
# UI
# -------------------------------------------------
ui <- secure_app(
  dashboardPage(

    dashboardHeader(
      title = tags$span(
        tags$img(
          src = "logo.png",
          height = "40px",
          style = "
        margin-right:10px;
        padding:0;
        display:inline-block;
        vertical-align:middle;
      "
        ),
        tags$span(
          "XLS to SDMX",
          style = "vertical-align:middle;"
        )
      )
    ),

    dashboardSidebar(
      sidebarMenu(
        menuItem("IMTS to SDMX", tabName = "imts", icon = icon("exchange-alt")),
        menuItem("CPI to SDMX", tabName = "cpi", icon = icon("chart-line")),
        menuItem("Visitor Arrivals to SDMX", tabName = "visitor", icon = icon("plane-arrival"))
      )
    ),

    dashboardBody(
      tabItems(

        # ---------------- IMTS TAB ----------------
        tabItem(
          tabName = "imts",
          h2("IMTS Excel to SDMX Converter"),

          box(
            width = 4,
            fileInput(
              "excel_file",
              "Upload IMTS Excel file",
              accept = ".xlsx"
            ),
            actionButton("process", "Process file"),
            br(), br(),
            downloadButton("download_csv", "Download SDMX CSV")
          ),

          box(
            width = 8,
            title = "Processing log",
            verbatimTextOutput("log"),
            tableOutput("preview")
          )
        ),

        # ---------------- CPI TAB ----------------
        tabItem(
          tabName = "cpi",
          h2("CPI to SDMX"),
          p("CPI conversion logic to be added")
        ),

        # ------------- VISITOR TAB ---------------
        tabItem(
          tabName = "visitor",
          h2("Visitor Arrivals to SDMX"),
          p("Visitor arrivals conversion logic to be added")
        )
      )
    )
  )
)

# -------------------------------------------------
# SERVER
# -------------------------------------------------
server <- function(input, output, session) {

  # ---- Authentication ----
  secure_server(check_credentials = check_credentials(credentials))

  log_messages <- reactiveVal("")
  final_data   <- reactiveVal(NULL)

  add_log <- function(msg) {
    log_messages(paste(log_messages(), msg, sep = "\n"))
  }

  # -------------------------------------------------
  # PROCESS IMTS FILE
  # -------------------------------------------------
  observeEvent(input$process, {

    req(input$excel_file)

    log_messages("")
    add_log("Starting IMTS processing...")

    filePath <- input$excel_file$datapath
    wsheets  <- excel_sheets(filePath)

    # ---- Validate worksheet names ----
    invalid_sheets <- setdiff(wsheets, allowed_sheets)

    if (length(invalid_sheets) > 0) {

      msg <- paste(
        "Unsupported worksheet(s):",
        paste(invalid_sheets, collapse = ", "),
        "\n\nAllowed worksheet names:",
        paste(allowed_sheets, collapse = ", ")
      )

      showNotification(msg, type = "error", duration = NULL)
      add_log("ERROR: Unsupported worksheet(s) detected")
      add_log(msg)

      return(NULL)  # ⛔ Stop safely
    }

    add_log(paste("Valid worksheets detected:", paste(wsheets, collapse = ", ")))

    final_df <- data.frame()

    for (sheetname in wsheets) {

      df <- read_excel(filePath, sheet = sheetname)

      if (sheetname == "bot") {

        table_long <- df |>
          pivot_longer(
            cols = -c(DATAFLOW:OBS_COMMENT),
            names_to = "TRADE_FLOW",
            values_to = "OBS_VALUE"
          ) |>
          mutate(TIME_PERIOD = as.character(TIME_PERIOD))

        final_df <- table_long

      } else if (sheetname %in% c("imports", "exports", "reexports", "totexports")) {

        table_long <- df |>
          pivot_longer(
            cols = -c(DATAFLOW:OBS_COMMENT),
            names_to = "COMMODITY",
            values_to = "OBS_VALUE"
          ) |>
          mutate(TIME_PERIOD = as.character(TIME_PERIOD))

        final_df <- bind_rows(final_df, table_long)

      } else if (sheetname == "bot_cty") {

        table_long <- df |>
          pivot_longer(
            cols = -c(DATAFLOW:OBS_COMMENT),
            names_to = "TIME_PERIOD",
            values_to = "OBS_VALUE"
          ) |>
          mutate(
            FREQ = ifelse(nchar(TIME_PERIOD) > 4, "M", "A"),
            TIME_PERIOD = as.character(TIME_PERIOD)
          )

        final_df <- bind_rows(final_df, table_long)

      } else if (sheetname == "mode_trspt") {

        table_long <- df |>
          pivot_longer(
            cols = -c(DATAFLOW:OBS_COMMENT),
            names_to = "TRANSPORT",
            values_to = "OBS_VALUE"
          ) |>
          mutate(TIME_PERIOD = as.character(TIME_PERIOD))

        final_df <- bind_rows(final_df, table_long)

      } else if (sheetname == "trade_reg") {

        table_long <- df |>
          pivot_longer(
            cols = -c(DATAFLOW:OBS_COMMENT),
            names_to = "TIME_PERIOD",
            values_to = "OBS_VALUE"
          ) |>
          mutate(
            FREQ = ifelse(nchar(TIME_PERIOD) > 4, "M", "A"),
            TIME_PERIOD = as.character(TIME_PERIOD)
          )

        final_df <- bind_rows(final_df, table_long)
      } else if (sheetname %in% c("x_sitc", "m_sitc")) {

        table_long <- df |>
          pivot_longer(
            cols = -c(DATAFLOW:OBS_COMMENT),
            names_to = "COMMODITY",
            values_to = "OBS_VALUE"
          ) |>
          mutate(TIME_PERIOD = as.character(TIME_PERIOD))

        final_df <- bind_rows(final_df, table_long)

      }
    }

    # ---- Final cleaning ----
    final_df <- final_df |>
      filter(!is.na(OBS_VALUE))

    final_df[is.na(final_df)] <- ""

    final_df <- final_df |>
      mutate(OBS_VALUE = round(as.numeric(OBS_VALUE), 0)) |>
      select(
        DATAFLOW, FREQ, TIME_PERIOD, GEO_PICT, INDICATOR,
        TRADE_FLOW, COMMODITY, COUNTERPART, TRANSPORT, CURRENCY,
        OBS_VALUE, UNIT_MEASURE, UNIT_MULT, OBS_STATUS,
        DATA_SOURCE, OBS_COMMENT
      )

    final_data(final_df)
    add_log("Processing completed successfully ✔")
  })

  # -------------------------------------------------
  # OUTPUTS
  # -------------------------------------------------
  output$preview <- renderTable({
    req(final_data())
    head(final_data(), 10)
  })

  output$log <- renderText({
    log_messages()
  })

  output$download_csv <- downloadHandler(
    filename = function() paste0("IMTS_sdmx_data_", Sys.Date(), ".csv"),
    content  = function(file) {
      write.csv(final_data(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)
