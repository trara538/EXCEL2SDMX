
# Transforming Excel tables into SDMX tables

The goal of IMTS2SDMX package is to allow users to be able to generate International Merchandise Trade (IMTS) SDMX files out from published IMTS excel files. 

Before using the IMTS2SDMX R package, you will need to reorganize your IMTS published tables as follows:

1. Create an excel file
2. Add the necessary worksheets in the excel file:

### IMTS excel to SDMX conversion

The IMTS excel should be re-organised according steps: 

1. Create an excel file
2. Add the following worksheets in the excel file:
    
    1. **bot** – Balance of trade table  
    2. **imports** – Imports table  
    3. **exports** – Domestic exports table  
    4. **reexports** – Re-exports table  
    5. **bot_cty** – Balance of trade by partner countries table  
    6. **trade_reg** – Trade by region table  
    7. **mode_trspt** – Trade by mode of transport table

#### IMTS template example

This is a basic example which shows you how to organize your imts excel worksheet tables:

[Download sample IMTS file](https://github.com/trara538/EXCEL2SDMX/blob/main/inst/extdata/sample_IMTS.xlsx)

### CPI excel to SDMX conversion

### Visitor arrivals excel to SDMX conversion

## Installation of EXCEL2SDMX package

You can install and execute the EXCEL2SDMX package as per the following steps:

``` r
# **************** How to install the package from R console ******************** #

install.packages("remotes") # Ensure remotes package is installed before proceeding
library(remotes) # load the remotes package
remotes::install_github("https://github.com/trara538/EXCEL2SDMX") # Install the EXCEL2SDMX package
# if "remotes::install_github("https://github.com/trara538/EXCEL2SDMX")" does not work. try the following
remotes::install_github("https://github.com/trara538/EXCEL2SDMX", force = TRUE)

# **************** How to run the imtshiny app from R console ******************** #
library(EXCEL2SDMX) # Load the EXCEL2SDMX package
EXCEL2SDMX::run_app() # Execute the EXCEL2SDMX package 

```
