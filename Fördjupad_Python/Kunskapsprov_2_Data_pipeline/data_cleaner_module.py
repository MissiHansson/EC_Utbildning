import pandas as pd
from logging_module import LoggerSetup 

class DataCleaner:
    """
    A class to perform data cleaning on DataFrames.
    """
    
    def __init__(self, df, logger_name='data_cleaner_logger', log_file='data_cleaner.log'):
        """
        Initializes the DataCleaner with a DataFrame and it sets up a log to keep track of data transformation.

        Parameters:
        df: The DataFrame to be cleaned.
        logger_name: The name of the logger.
        log_file: The file where the log output will be saved.
        """
        self.df = df
        logger_setup = LoggerSetup(logger_name=logger_name, log_file=log_file)
        self.logger = logger_setup.get_logger()
                        
        
    def _remove_duplicates(self, subset=None, keep='first'):
        """
        Removes duplicate rows from the DataFrame.

        Parameters:
        subset (list or str, optional): Column(s) to consider for identifying duplicates.
        keep (str, optional): Which duplicates to keep - 'first', 'last', or False (drop all).

        Returns:
        DataFrame: A DataFrame with duplicates removed.
        """
        original_rows = len(self.df)
        self.df = self.df.drop_duplicates(subset=subset, keep=keep)
        final_rows = len(self.df)
        duplicates_removed = original_rows - final_rows
        self.logger.info(f'Number of rows dropped: {duplicates_removed}.')
        return self.df

    def _fill_missing_values(self, method='ffill', columns=None):
        """
        Fill all empty spots in the table with 0.
    
         Returns:
        DataFrame: The table with all empty spots filled with 0.
        """
        
        num_missing_values = self.df.isnull().sum().sum()
        self.df.fillna(0, inplace=True)
        self.logger.info(f"Missing values filled. Total missing values after filling: {num_missing_values}.")
        return self.df

    
    def reset_index(self):
        """
        Resets the index of the DataFrame, removing any existing index.

        Returns:
        DataFrame: The DataFrame with the index reset.
        """
        self.df.reset_index(drop=True, inplace=True)
        self.logger.info("Index has been reset. Now the rows are numbered from 0 again.")
        return self.df
    
    
    def _standardize_column_names(self):
        """
        Standardizes column names by converting them to lowercase.

        Returns:
        A DataFrame with standardized column names.
        """
        self.logger.info(
        "Standardizing column names by converting to lowercase, removing spaces, "
        "and special characters for SQL formatting."
        )
        self.df.columns = self.df.columns.str.lower().str.replace(' ', '_').str.replace(r'[^a-z0-9_]', '', regex=True)
        self.logger.info(f"Column names after standardization: {list(self.df.columns)}")
    
        return self.df
    
    def _reorder_columns(self, new_order):
        """
        Reorders the columns in the DataFrame according to the specified order.

        Parameters:
        new_order (list): List of column names in the order desired.

        Returns:
        The DataFrame with columns reordered.
        """
        try:
            self.df = self.df.reindex(columns=new_order)
            self.logger.info(f"Columns reordered to: {new_order}")
        except KeyError as e:
            self.logger.error(f"Error: Could not reorder columns. {e}")
        
        return self.df
      

    def _change_column_dtypes(self):
        """
        This function updates the type of data in each column of the DataFrame
        in preparation for SQL.

        It works like this:
        - If the column name includes 'year':
            - If the year is written with a month (like '2023M01'), it turns it into a 'YYYY-MM' format (like '2023-01').
            - If it's just a year (like '2023'), it changes it to show only the year.
        - If the column contains only numbers, it converts everything to integers (whole numbers).
        - For any other columns, it converts the data to strings (text).

        Parameters:
        - self (object): This refers to the object that contains the DataFrame.

        Returns:
        The DataFrame with all the columns converted to the correct data type.
        """

        for column in self.df.columns:
            
            if 'year' in column.lower():
                try:
                    if self.df[column].str.contains('M').any():
                        self.df[column] = self.df[column].str.replace('M', '')
                        self.df[column] = pd.to_datetime(self.df[column], format='%Y%m').dt.to_period('M')
                        self.df[column] = self.df[column].astype(str)
                        self.logger.info(f"Successfully converted '{column}' to datetime with format 'YYYYmm'.")
                    else:
                        self.df[column] = pd.to_datetime(self.df[column]).dt.year
                        self.logger.info(f"Successfully converted '{column}' to datetime with format 'YYYY'.")
                except ValueError as e:
                    self.logger.error(f"Could not convert '{column}' to datetime: {e}")

            
            elif 'datetime' in column.lower():
                try:
                    self.df[column] = pd.to_datetime(self.df[column], errors='coerce')
                    self.df['date'] = self.df[column].dt.date
                    self.df['time'] = self.df[column].dt.strftime('%H:%M')
                    self.df = self.df.drop(columns=[column])
                    self.logger.info(f"Successfully split '{column}' into 'date' and 'time' columns.")
                except Exception as e:
                    self.logger.error(f"Could not split '{column}' into date and time: {e}")

           
            else:
                converted_col = pd.to_numeric(self.df[column], errors='coerce')

                if converted_col.notna().all():  
                    if (converted_col % 1 == 0).all():
                        try:
                            self.df[column] = converted_col.astype(int)
                            self.logger.info(f"Successfully converted '{column}' to integer.")
                        except ValueError as e:
                            self.logger.error(f"Could not convert '{column}' to integer: {e}")
                    else:
                        try:
                            self.df[column] = converted_col.astype(float)
                            self.logger.info(f"Successfully converted '{column}' to float.")
                        except ValueError as e:
                            self.logger.error(f"Could not convert '{column}' to float: {e}")

                else:
                    self.df[column] = self.df[column].astype(str)
                    self.logger.info(f"Successfully converted '{column}' to string.")

        return self.df

    def _split_coordinates(self, coord_column):
        """
        Splits a column that hold both 'latitude' and 'longitude' into two seperate columns.

        Parameters:
        coord_column (str): The name of the column containing the coordinate values.

        Returns:
        The updated DataFrame with separate 'latitude' and 'longitude' columns.
        """
        try:
            self.df[['latitude', 'longitude']] = self.df[coord_column].str.split(',', expand=True)
            
            
            self.df['latitude'] = self.df['latitude'].astype(float)
            self.df['longitude'] = self.df['longitude'].astype(float)

            self.df = self.df.drop(columns=[coord_column])

            self.logger.info(f"Successfully split '{coord_column}' into 'latitude' and 'longitude'.")
        except Exception as e:
            self.logger.error(f"Error in splitting '{coord_column}': {e}")
        
        return self.df

        
    def _map_scb_values(self, column_name, mapping_dict=None):
        """
        Maps SCB 'kommun' codes in the 'kommun' column to their respective municipality names.

        Returns:
        pd.DataFrame: The DataFrame with the 'kommun' column values mapped.
        """
        
        # Define a mapping dictionary specific to SCB 'kommun' codes
        scb_kommun_mapping = {
        '0114': 'Upplands Väsby', '0115': 'Vallentuna', '0117': 'Österåker', '0120': 'Värmdö',
        '0123': 'Järfälla', '0125': 'Ekerö', '0126': 'Huddinge', '0127': 'Botkyrka', '0128': 'Salem',
        '0136': 'Haninge', '0138': 'Tyresö', '0139': 'Upplands-Bro', '0140': 'Nykvarn', '0160': 'Täby',
        '0162': 'Danderyd', '0163': 'Sollentuna', '0180': 'Stockholm', '0181': 'Södertälje', '0182': 'Nacka',
        '0183': 'Sundbyberg', '0184': 'Solna', '0186': 'Lidingö', '0187': 'Vaxholm', '0188': 'Norrtälje',
        '0191': 'Sigtuna', '0192': 'Nynäshamn', '0305': 'Håbo', '0319': 'Älvkarleby', '0330': 'Knivsta',
        '0331': 'Heby', '0360': 'Tierp', '0380': 'Uppsala', '0381': 'Enköping', '0382': 'Östhammar',
        '0428': 'Vingåker', '0461': 'Gnesta', '0480': 'Nyköping', '0481': 'Oxelösund', '0482': 'Flen',
        '0483': 'Katrineholm', '0484': 'Eskilstuna', '0486': 'Strängnäs', '0488': 'Trosa', '0509': 'Ödeshög',
        '0512': 'Ydre', '0513': 'Kinda', '0560': 'Boxholm', '0561': 'Åtvidaberg', '0562': 'Finspång',
        '0563': 'Valdemarsvik', '0580': 'Linköping', '0581': 'Norrköping', '0582': 'Söderköping',
        '0583': 'Motala', '0584': 'Vadstena', '0586': 'Mjölby', '0604': 'Aneby', '0617': 'Gnosjö',
        '0642': 'Mullsjö', '0643': 'Habo', '0662': 'Gislaved', '0665': 'Vaggeryd', '0680': 'Jönköping',
        '0682': 'Nässjö', '0683': 'Värnamo', '0684': 'Sävsjö', '0685': 'Vetlanda', '0686': 'Eksjö',
        '0687': 'Tranås', '0760': 'Uppvidinge', '0761': 'Lessebo', '0763': 'Tingsryd', '0764': 'Alvesta',
        '0765': 'Älmhult', '0767': 'Markaryd', '0780': 'Växjö', '0781': 'Ljungby', '0821': 'Högsby',
        '0834': 'Torsås', '0840': 'Mörbylånga', '0860': 'Hultsfred', '0861': 'Mönsterås', '0862': 'Emmaboda',
        '0880': 'Kalmar', '0881': 'Nybro', '0882': 'Oskarshamn', '0883': 'Västervik', '0884': 'Vimmerby',
        '0885': 'Borgholm', '0980': 'Gotland', '1060': 'Olofström', '1080': 'Karlskrona', '1081': 'Ronneby',
        '1082': 'Karlshamn', '1083': 'Sölvesborg', '1214': 'Svalöv', '1230': 'Staffanstorp', '1231': 'Burlöv',
        '1233': 'Vellinge', '1256': 'Östra Göinge', '1257': 'Örkelljunga', '1260': 'Bjuv', '1261': 'Kävlinge',
        '1262': 'Lomma', '1263': 'Svedala', '1264': 'Skurup', '1265': 'Sjöbo', '1266': 'Hörby', '1267': 'Höör',
        '1270': 'Tomelilla', '1272': 'Bromölla', '1273': 'Osby', '1275': 'Perstorp', '1276': 'Klippan',
        '1277': 'Åstorp', '1278': 'Båstad', '1280': 'Malmö', '1281': 'Lund', '1282': 'Landskrona',
        '1283': 'Helsingborg', '1284': 'Höganäs', '1285': 'Eslöv', '1286': 'Ystad', '1287': 'Trelleborg',
        '1290': 'Kristianstad', '1291': 'Simrishamn', '1292': 'Ängelholm', '1293': 'Hässleholm',
        '1315': 'Hylte', '1380': 'Halmstad', '1381': 'Laholm', '1382': 'Falkenberg', '1383': 'Varberg',
        '1384': 'Kungsbacka', '1401': 'Härryda', '1402': 'Partille', '1407': 'Öckerö', '1415': 'Stenungsund',
        '1419': 'Tjörn', '1421': 'Orust', '1427': 'Sotenäs', '1430': 'Munkedal', '1435': 'Tanum',
        '1438': 'Dals-Ed', '1439': 'Färgelanda', '1440': 'Ale', '1441': 'Lerum', '1442': 'Vårgårda',
        '1443': 'Bollebygd', '1444': 'Grästorp', '1445': 'Essunga', '1446': 'Karlsborg', '1447': 'Gullspång',
        '1452': 'Tranemo', '1460': 'Bengtsfors', '1461': 'Mellerud', '1462': 'Lilla Edet', '1463': 'Mark',
        '1465': 'Svenljunga', '1466': 'Herrljunga', '1470': 'Vara', '1471': 'Götene', '1472': 'Tibro',
        '1473': 'Töreboda', '1480': 'Göteborg', '1481': 'Mölndal', '1482': 'Kungälv', '1484': 'Lysekil',
        '1485': 'Uddevalla', '1486': 'Strömstad', '1487': 'Vänersborg', '1488': 'Trollhättan', '1489': 'Alingsås',
        '1490': 'Borås', '1491': 'Ulricehamn', '1492': 'Åmål', '1493': 'Mariestad', '1494': 'Lidköping',
        '1495': 'Skara', '1496': 'Skövde', '1497': 'Hjo', '1498': 'Tidaholm', '1499': 'Falköping',
        '1715': 'Kil', '1730': 'Eda', '1737': 'Torsby', '1760': 'Storfors', '1761': 'Hammarö', '1762': 'Munkfors',
        '1763': 'Forshaga', '1764': 'Grums', '1765': 'Årjäng', '1766': 'Sunne', '1780': 'Karlstad',
        '1781': 'Kristinehamn', '1782': 'Filipstad', '1783': 'Hagfors', '1784': 'Arvika', '1785': 'Säffle',
        '1814': 'Lekeberg', '1860': 'Laxå', '1861': 'Hallsberg', '1862': 'Degerfors', '1863': 'Hällefors',
        '1864': 'Ljusnarsberg', '1880': 'Örebro', '1881': 'Kumla', '1882': 'Askersund', '1883': 'Karlskoga',
        '1884': 'Nora', '1885': 'Lindesberg', '1904': 'Skinnskatteberg', '1907': 'Surahammar',
        '1960': 'Kungsör', '1961': 'Hallstahammar', '1962': 'Norberg', '1980': 'Västerås', '1981': 'Sala',
        '1982': 'Fagersta', '1983': 'Köping', '1984': 'Arboga', '2021': 'Vansbro', '2023': 'Malung-Sälen',
        '2026': 'Gagnef', '2029': 'Leksand', '2031': 'Rättvik', '2034': 'Orsa', '2039': 'Älvdalen',
        '2061': 'Smedjebacken', '2062': 'Mora', '2080': 'Falun', '2081': 'Borlänge', '2082': 'Säter',
        '2083': 'Hedemora', '2084': 'Avesta', '2085': 'Ludvika', '2101': 'Ockelbo', '2104': 'Hofors',
        '2121': 'Ovanåker', '2132': 'Nordanstig', '2161': 'Ljusdal', '2180': 'Gävle', '2181': 'Sandviken',
        '2182': 'Söderhamn', '2183': 'Bollnäs', '2184': 'Hudiksvall', '2260': 'Ånge', '2262': 'Timrå',
        '2280': 'Härnösand', '2281': 'Sundsvall', '2282': 'Kramfors', '2283': 'Sollefteå', '2284': 'Örnsköldsvik',
        '2303': 'Ragunda', '2305': 'Bräcke', '2309': 'Krokom', '2313': 'Strömsund', '2321': 'Åre',
        '2326': 'Berg', '2361': 'Härjedalen', '2380': 'Östersund', '2401': 'Nordmaling', '2403': 'Bjurholm',
        '2404': 'Vindeln', '2409': 'Robertsfors', '2417': 'Norsjö', '2418': 'Malå', '2421': 'Storuman',
        '2422': 'Sorsele', '2425': 'Dorotea', '2460': 'Vännäs', '2462': 'Vilhelmina', '2463': 'Åsele',
        '2480': 'Umeå', '2481': 'Lycksele', '2482': 'Skellefteå', '2505': 'Arvidsjaur', '2506': 'Arjeplog',
        '2510': 'Jokkmokk', '2513': 'Överkalix', '2514': 'Kalix', '2518': 'Övertorneå', '2521': 'Pajala',
        '2523': 'Gällivare', '2560': 'Älvsbyn', '2580': 'Luleå', '2581': 'Piteå', '2582': 'Boden',
        '2583': 'Haparanda', '2584': 'Kiruna'
    }

        if column_name == 'region':
            mapping_dict = scb_kommun_mapping

        if column_name not in self.df.columns:
            self.logger.error(f"Column '{column_name}' not found in the DataFrame.")
            return self.df

        if column_name != 'region' and mapping_dict is None:
            self.logger.error(f"No mapping dictionary provided for '{column_name}' column.")
            return self.df
        
        self.df[column_name] = self.df[column_name].map(mapping_dict)

        unmapped_values = self.df[self.df[column_name].isnull()]
        if not unmapped_values.empty:
            self.logger.warning(f"Some values in '{column_name}' could not be mapped: {unmapped_values[column_name].unique()}")

        self.logger.info(f"Mapping applied to '{column_name}' column.")
        
        return self.df
                
    def _drop_rows_with_summary_in_type(self):
        
        self.df = self.df[~self.df['type'].str.contains('sammanfattning', case=False, na=False)]
        self.df = self.df[~self.df['type'].str.contains('övrigt', case=False, na=False)]
        
        
    def _drop_column(self, columns_to_drop):
        """
        This function removes the specified columns from the DataFrame, but only if they exist.
        
        Parameters:
        - columns_to_drop (str or list): Name or list of column names to drop.

        Returns:
        - The updated DataFrame without the specified column(s), if they existed.
        """
        
        self.df.columns = self.df.columns.str.strip()  # För att ta bort onödiga mellanslag runt kolumnnamnen
        if isinstance(columns_to_drop, str):
            columns_to_drop = [columns_to_drop]
            
        # Kolla vilka kolumner som faktiskt finns
        existing_columns_to_drop = [col for col in columns_to_drop if col in self.df.columns]
        missing_columns = [col for col in columns_to_drop if col not in self.df.columns]

        if existing_columns_to_drop:
            self.df = self.df.drop(columns=existing_columns_to_drop, axis=1)
            self.logger.info(f"Dropped unwanted column(s): {existing_columns_to_drop}")
        
        if missing_columns:
            self.logger.warning(f"These columns were not found in the DataFrame: {missing_columns}")
        
        return self.df

    
    def clean_data_from_polis_api(self):
        """
        Cleans data retrieved from the Polisen API.

        This method applies a series of data cleaning steps to prepare the data for further use.
        It includes the following actions:
        
        1. Removes duplicate rows from the DataFrame to ensure unique records.
        2. Drops unnecessary columns based on their indices (0, 2, 4).
        3. Splits the 'locationgps' column into separate latitude and longitude columns.
        4. Changes the data types of columns (e.g., converts date-related columns to datetime, 
                                                integers where applicable).
        5. Standardizes column names by converting them to lowercase and 
        removing spaces and special characters.
        
        Returns:
        The cleaned DataFrame with necessary transformations applied.
        """              
        self._remove_duplicates()
        
        columns_to_drop = ['id', 'name', 'url']
        self._drop_column(columns_to_drop)
        
        self._split_coordinates('location_gps')
        
        self._change_column_dtypes()
        
        self._standardize_column_names()
        
        new_order = [
            'date', 'time','location_name', 'type', 
            'summary', 'longitude', 'latitude'
            ]
        self._reorder_columns(new_order)
        
        self._drop_rows_with_summary_in_type()
        
        return self.df

    
    def clean_data_from_scb_api(self, new_order=None):
            """
            
            """              
            
            
            self._remove_duplicates()
            
            self._map_scb_values(column_name='region')
            
            gender_map = {'1': 'male', '2': 'female'}
            self._map_scb_values(column_name='gender', mapping_dict=gender_map)
            
            marital_status_map = {'OG': 'Single', 'G': 'Married', 
                                  'SK': 'Divorced', 'ÄNKL' : 'Widow'}
            self._map_scb_values(column_name='marital_status', mapping_dict=marital_status_map)
            
            edu_level_map = {
                '1': 'Less than 9 years', '2': '9-10 years', '3': '2 years high school',
                '4': '3 years high school', '5': 'Post-secondary < 3 years',
                '6': 'Post-secondary > 3 years', '7': 'Unknown'
            }
            self._map_scb_values(column_name='edu_level', mapping_dict=edu_level_map)
            
            family_type_map = {
                'EnsamMor': 'Single Mom', 'EnsamFar': 'Single Father',
                'KarnFam': 'cohabitting original parents',
                'NyFam': 'cohabbiting with a stepparent',
                'OvrFam' : 'lives wit another person other than parents'
            }
            
            self._change_column_dtypes()
            
            self._standardize_column_names()
            
           
           # new_order = ['region', 'gender','age_group']
            #self._reorder_columns(new_order)
            
            return self.df
    
    def clean_data_from_bra_excel(self, new_order=None):
        self.logger.info("Running clean_data_from_bra_excel...")
        
        self._remove_duplicates()
        
        self._change_column_dtypes()       
        
        
        self._fill_missing_values()
        
        columns_to_drop =['lagrum', 
                          'Antal brott i regionen där uppgift om kommun saknas']
        self._drop_column(columns_to_drop=columns_to_drop)
        
        return self.df
