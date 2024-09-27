from scb_api_module import SCB_DataFetcher
from to_sql_module import SQLManager
from data_cleaner_module import DataCleaner

def main():
    try:
        # Set up SQLManager 
        sql_logger_name = 'sql_manager_logger'
        sql_log_file = 'sql_manager.log'
        sql_manager = SQLManager(logger_name=sql_logger_name, log_file=sql_log_file)

        # Create a new engine for database connection
        dialect = 'mssql'
        server = 'NovaNexus'
        database = 'crime_data'
        integrated_security = True  
        engine = sql_manager.new_engine(dialect, server, database, integrated_security)
        
        scb_fetcher = SCB_DataFetcher()

        # Years desired to fetch data from.
        years = ['2022']

        # Fetch marital status data from SCB.
        scb_marital_status_data = scb_fetcher.fetch_scb_marital_status_data(years)
        if not scb_marital_status_data.empty:
            data_cleaner_scb = DataCleaner(scb_marital_status_data)
            new_order = ['region', 'year', 'age_group', 'marital_status', 'num_individuals']
            cleaned_scb_marital_status_data = data_cleaner_scb.clean_data_from_scb_api(new_order=new_order)
            sql_manager.transfer_data(cleaned_scb_marital_status_data, 'scb_marital_status_data')

        # Fetch education data from SCB.
        scb_education_data = scb_fetcher.fetch_scb_population_education_data(years)
        if not scb_education_data.empty:
            data_cleaner_scb = DataCleaner(scb_education_data)
            new_order = ['region', 'gender', 'age_group', 'edu_level', 'year', 'num_individuals']
            cleaned_scb_education_data = data_cleaner_scb.clean_data_from_scb_api(new_order=new_order)
            sql_manager.transfer_data(cleaned_scb_education_data, 'scb_education_data')

        # Fetch household data from SCB.
        scb_household_data = scb_fetcher.fetch_scb_fetch_households_with_children_data(years)
        if not scb_household_data.empty:
            data_cleaner_scb = DataCleaner(scb_household_data)
            new_order = ['region', 'age_group', 'family_type', 'num_children', 'year', 'num_families']
            cleaned_scb_household_data = data_cleaner_scb.clean_data_from_scb_api(new_order=new_order)
            sql_manager.transfer_data(cleaned_scb_household_data, 'scb_household_data')

        # Year and month desired to fetch data from.
        years_month = [
            '2022M01', '2022M02', '2022M03', '2022M04', '2022M05', '2022M06', 
            '2022M07', '2022M08', '2022M09', '2022M10', '2022M11', '2022M12', 
        ]

        # Fetch social benefits data from SCB.
        scb_social_benefits_data = scb_fetcher.fetch_scb_social_benefits_data(years_month)
        if not scb_social_benefits_data.empty:
            data_cleaner_scb = DataCleaner(scb_social_benefits_data)
            new_order = ['region', 'gender', 'age_group', 'year_month', 'unemployment', 
                        'economic_assistance', 'establishment', 'proportion_of_population']
            cleaned_scb_social_benefits_data = data_cleaner_scb.clean_data_from_scb_api(new_order=new_order)
            sql_manager.transfer_data(cleaned_scb_social_benefits_data, 'scb_social_benefits_data')
    
    except Exception as e:    
        sql_manager.logger.error(f'Error processing SCB API data: {e}')  

if __name__ == "__main__":
    main()
