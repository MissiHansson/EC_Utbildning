# Automated Data Processing Pipeline

This project is an automated data pipeline for fetching, cleaning, and updating data in an SQL database. The pipeline processes data from multiple sources: an Excel file, the SCB API, and the Polisen API. The pipeline uses Windows Task Scheduler to run the scripts at predefined intervals.

## Table of Contents
1. [Project Overview](#project-overview)
2. [Features](#features)
3. [Usage](#usage)
4. [Modules](#modules)
5. [Testing](#testing)
6. [Logging](#logging)

## Project Overview
The project is designed to:
- Fetch data from multiple sources (Excel, SCB API, Polisen API).
- Clean and standardize the data using a custom DataCleaner module.
- Insert or update the cleaned data into an SQL database.
- Automatically schedule the tasks to run periodically using Windows Task Scheduler.

## Features
- **Automated Data Retrieval**: Data is fetched from three different sources at scheduled intervals.
- **Data Cleaning**: Custom data cleaning methods to handle duplicates, missing values, and data standardization for SQL.
- **Error Handling & Logging**: Comprehensive logging and exception handling in all modules.
- **Scheduling**: The pipeline runs automatically based on predefined schedules:
    - **Polisen API**: Once daily.
    - **Excel file**: Once a month.
    - **SCB API**: Once every quarter.

## Usage
The pipeline is designed to run automatically via Windows Task Scheduler. Here's how the scheduling works:
- **Polisen API**: Fetches data once daily.
- **Excel File**: Checks for new data once a month.
- **SCB API**: Fetches data once every quarter.

To run the scripts manually, use the following commands:

- Fetch and clean data from Polisen API:
    
    python fetch_polis_data.py
    

- Fetch and clean data from SCB API:
    
    python fetch_scb_data.py
    

- Fetch data from Excel and update SQL:
    
    python fetch_excel_data.py
    

## Modules
1. **Data Cleaning Module**
   - Handles data cleaning tasks such as removing duplicates, filling missing values, standardizing column names, dropping columns and converting data types.

2. **Logging Module**
   - Each module in the project has its own logging mechanism to track errors and execution details. Logs are written to separate log files for easier debugging.

3. **SQL Module**
   - Manages the connection to the SQL database and handles the insertion or updating of data.

4. **Excel Manager Module**
   - Responsible for handling Excel file reading, checking for new data, and passing it to the data cleaning module.

5. **API Modules**
   - **Polisen API Module**: Fetches crime data from the Polisen API.
   - **SCB API Module**: Fetches demographic data from the SCB API.

## Testing
The project includes automated tests for the SQL module and SCB API module. To run the tests, use:

pytest tests/

 - test_main_polisen_api.py
 - test_scb_api_to_sql_quarterly.py
 - test_update_bra_data_sql_monthly-py

## Logging
Logging is handled separately for each module, with log files created for the following:

 - data_cleaner.log
 - sql_module.log
 - polis_api.log
 - scb_api.log
 
 This approach allows easier tracking of errors and issues specific to each component of the pipeline.