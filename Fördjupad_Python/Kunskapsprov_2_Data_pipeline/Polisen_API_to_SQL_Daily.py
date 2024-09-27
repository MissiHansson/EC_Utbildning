from to_sql_module import SQLManager
from data_cleaner_module import DataCleaner
from polisen_api_module import fetch_recent_crime_data


def main():
    """
    Main script for fetching recent crime data from the Polisen API,
    cleaning the data, and transferring it to the SQL database.

    This script is scheduled to run automatically using Task Scheduler.
    It:
        Fetches the latest crime data from the Polisen API.
        Cleans the data using DataCleaner.
        Transfers the cleaned data to the 'polis_data' table in the SQL database.
    """
    
    
    sql_logger_name = 'sql_manager_logger'
    sql_log_file = 'sql_manager.log'
    sql_manager = SQLManager(logger_name=sql_logger_name, log_file=sql_log_file)

   
    dialect = 'mssql'
    server = 'NovaNexus'
    database = 'crime_data'
    integrated_security = True  
    engine = sql_manager.new_engine(dialect, server, database, integrated_security)

    try:
        
        polisen_api_data_df = fetch_recent_crime_data()
        data_cleaner = DataCleaner(polisen_api_data_df)
        cleaned_polis_api_data = data_cleaner.clean_data_from_polis_api()
        sql_manager.transfer_data(cleaned_polis_api_data, 'polis_data')
    except Exception as e:
        sql_manager.logger.error(f'Error processing Polisen API data: {e}')   

         
if __name__ == "__main__":
    main()
