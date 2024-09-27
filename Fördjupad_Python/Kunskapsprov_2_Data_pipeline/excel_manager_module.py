import os
import re
import pandas as pd
from logging_module import LoggerSetup  


class ExcelManager:
    """
    Reads new Excel files and saves data to SQL with logging.
    """
    def __init__(self, folder_path, 
                 read_files_log='excel_files_log.txt', 
                 log_file='excel_manager_log.txt'):
        """
        Initializes ExcelManager with folder path and log files.
        
        Args:
            folder_path (str): Path to Excel files folder.
            read_files_log (str): File to log already read files.
            log_file (str): Log file for logging events.
        """
        self.folder_path = folder_path
        self.read_files_log = read_files_log
        
        logger_name = 'ExcelManagerLogger'  
        logger_setup = LoggerSetup(logger_name, log_file)
        self.logger = logger_setup.get_logger()
        
        self.read_files = self._get_read_files()

    def _get_read_files(self):
        """
        Returns a set of already read file names from the log.
        
        Returns:
            set: Set of read file names.
        """
        if os.path.exists(self.read_files_log):
            with open(self.read_files_log, 'r') as f:
                self.logger.info(
                    f'Reading processed files from log: {self.read_files_log}'
                )
                return set(f.read().splitlines())
        else:
            self.logger.info('No log file found.')
            return set()

    def _update_read_files_log(self, file_name):
        """
        Adds a new file name to the log.
        
        Args:
            file_name (str): Name of the file to add.
        """
        with open(self.read_files_log, 'a') as f:
            f.write(f'{file_name}\n')
        self.logger.info(f'Updated log with file: {file_name}')

    def read_new_files(self):
        """
        Reads new Excel files from the folder, skips the first sheet which is
        usually a summary and excludes three other sheets by name. Adds 
        columns for 'kommun', 'year', and 'region'.
        
        Returns:
            Pandas dataframe with combined data from new files.
        """
        new_dataframes = []

        for file_name in os.listdir(self.folder_path):
            if file_name.endswith(('.xlsx', 'xls')) and file_name not in self.read_files:
                file_path = os.path.join(self.folder_path, file_name)
                self.logger.info(f'Processing new file: {file_name}')

                # Extract year and region from the file name
                year_match = re.search(r'-(\d{4})', file_name)
                year = year_match.group(1) if year_match else 'Unknown'
                region_match = re.search(r'_(.+)-\d{4}', file_name)
                region = region_match.group(1) if region_match else 'Unknown'

                self.logger.info(
                    f'Extracted year: {year} and region: {region} from file: '
                    f'{file_name}'
                )

                excel_file = pd.ExcelFile(file_path)
                sheet_names = excel_file.sheet_names
                
                sheets_to_skip = ['Tabell 120-23', 'Information', 'Okänd kommun',
                                  'Tabell 120']
                sheets_to_read = [sheet for sheet in sheet_names[1:] 
                                  if sheet not in sheets_to_skip]

                for sheet in sheets_to_read:
                    try:
                        if 2015 <= int(year) <= 2021:
                            df = pd.read_excel(file_path, sheet_name=sheet, 
                                               header=None, skiprows=10, 
                                               engine='xlrd')
                            df.columns = ['Brottstyp', 'Antal anmälda brott, totalt', 
                                          'Antal brott per 100 000 invånare']
                        else:
                            df = pd.read_excel(file_path, sheet_name=sheet, 
                                               header=1)
                        
                        df['kommun'] = sheet
                        df['year'] = year
                        df['region'] = region
                        new_dataframes.append(df)

                    except Exception as e:
                        self.logger.error(
                            f'Error reading sheet {sheet} in file {file_name}: {e}'
                        )
                        continue
                
                self._update_read_files_log(file_name)

        if new_dataframes:
            combined_df = pd.concat(new_dataframes, ignore_index=True)
            self.logger.info('Successfully combined data from new files.')
            return combined_df
        else:
            self.logger.warning('No new files found or processed.')
            return pd.DataFrame()
