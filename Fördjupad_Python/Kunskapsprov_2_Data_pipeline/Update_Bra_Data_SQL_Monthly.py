from excel_manager_module import ExcelManager
from data_cleaner_module import DataCleaner
from to_sql_module import SQLManager

def main():
   
    sql_logger_name = 'sql_manager_logger'
    sql_log_file = 'sql_manager.log'
    sql_manager = SQLManager(logger_name=sql_logger_name, log_file=sql_log_file)

    
    dialect = 'mssql'
    server = 'NovaNexus'
    database = 'crime_data'
    integrated_security = True  
    engine = sql_manager.new_engine(
        dialect, server, database, integrated_security
    )

    
    folder_path = 'data_från_brå'
    excel_manager = ExcelManager(folder_path)
    bra_data_df = excel_manager.read_new_files()

    
    data_cleaner_bra = DataCleaner(bra_data_df)
    cleaned_bra_data = data_cleaner_bra.clean_data_from_bra_excel()
    sql_manager.transfer_data(cleaned_bra_data, 'bra_data')


if __name__ == "__main__":
    main()
