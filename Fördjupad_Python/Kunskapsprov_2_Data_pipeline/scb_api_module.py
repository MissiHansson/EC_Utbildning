import requests
import pandas as pd
import time
from logging_module import LoggerSetup  

"""
This module fetches data from the SCB API and processes it into pandas DataFrames. 
It supports retrieving demographic information for Swedish regions, including:

1. Marital status.
2. Education levels.
3. Household types with children.
4. Social benefits received.

External Libraries:
- requests: For making HTTP requests to the SCB API.
- pandas: For data handling and processing.
- time: For adding delays between API requests.
- logging_module (LoggerSetup): For logging API interactions and errors.
"""
class SCB_DataFetcher:
    """ 
    This class helps get data from a website (SCB API) about Swedish regions.
    There are four different types of demographic information that can be fetched:
        1. Marital status in a region.
        2. Education levels of individuals in a region.
        3. Household types with children (e.g., Single mom, Blended family) in a region.
        4. Social benefits received in a region. 
    """
    
    _kommuner = [
        '0114', '0115', '0117', '0120', '0123', '0125', '0126', '0127', '0128', '0136',
        '0138', '0139', '0140', '0160', '0162', '0163', '0180', '0181', '0182', '0183',
        '0184', '0186', '0187', '0188', '0191', '0192', '0305', '0319', '0330', '0331',
        '0360', '0380', '0381', '0382', '0428', '0461', '0480', '0481', '0482', '0483',
        '0484', '0486', '0488', '0509', '0512', '0513', '0560', '0561', '0562', '0563',
        '0580', '0581', '0582', '0583', '0584', '0586', '0604', '0617', '0642', '0643',
        '0662', '0665', '0680', '0682', '0683', '0684', '0685', '0686', '0687', '0760',
        '0761', '0763', '0764', '0765', '0767', '0780', '0781', '0821', '0834', '0840',
        '0860', '0861', '0862', '0880', '0881', '0882', '0883', '0884', '0885', '0980',
        '1060', '1080', '1081', '1082', '1083', '1214', '1230', '1231', '1233', '1256',
        '1257', '1260', '1261', '1262', '1263', '1264', '1265', '1266', '1267', '1270',
        '1272', '1273', '1275', '1276', '1277', '1278', '1280', '1281', '1282', '1283',
        '1284', '1285', '1286', '1287', '1290', '1291', '1292', '1293', '1315', '1380',
        '1381', '1382', '1383', '1384', '1401', '1402', '1407', '1415', '1419', '1421',
        '1427', '1430', '1435', '1438', '1439', '1440', '1441', '1442', '1443', '1444',
        '1445', '1446', '1447', '1452', '1460', '1461', '1462', '1463', '1465', '1466',
        '1470', '1471', '1472', '1473', '1480', '1481', '1482', '1484', '1485', '1486',
        '1487', '1488', '1489', '1490', '1491', '1492', '1493', '1494', '1495', '1496',
        '1497', '1498', '1499', '1715', '1730', '1737', '1760', '1761', '1762', '1763',
        '1764', '1765', '1766', '1780', '1781', '1782', '1783', '1784', '1785', '1814',
        '1860', '1861', '1862', '1863', '1864', '1880', '1881', '1882', '1883', '1884',
        '1885', '1904', '1907', '1960', '1961', '1962', '1980', '1981', '1982', '1983',
        '1984', '2021', '2023', '2026', '2029', '2031', '2034', '2039', '2061', '2062',
        '2080', '2081', '2082', '2083', '2084', '2085', '2101', '2104', '2121', '2132',
        '2161', '2180', '2181', '2182', '2183', '2184', '2260', '2262', '2280', '2281',
        '2282', '2283', '2284', '2303', '2305', '2309', '2313', '2321', '2326', '2361',
        '2380', '2401', '2403', '2404', '2409', '2417', '2418', '2421', '2422', '2425',
        '2460', '2462', '2463', '2480', '2481', '2482', '2505', '2506', '2510', '2513',
        '2514', '2518', '2521', '2523', '2560', '2580', '2581', '2582', '2583', '2584'
    ]

    _marital_status_filters = [
        {
            "code": "Civilstand",
            "filter": "item",
            "values": ["OG", "G", "SK", "ÄNKL"]
        },
        {
            "code": "Alder",
            "filter": "agg:Ålder5år",
            "values": ["15-19", "20-24", "25-29", "30-34", "35-39", "40-44",
                    "45-49", "50-54", "55-59", "60-64", "65-69"]
        },
        {
            "code": "Kon",
            "filter": "item",
            "values": ["1", "2"]
        },
        {
            "code": "ContentsCode",
            "filter": "item",
            "values": ["BE0101N1"]  
        }
    ]

    _family_type_filters = [
        {
            "code": "AlderBarn",
            "filter": "item",
            "values": ["0-21"]
        },
        {
            "code": "Familjetyp",
            "filter": "item",
            "values": ["KarnFam", "NyFam", "EnsamMor", "EnsamFar", "OvrFam"]
        },
        {
            "code": "Barn",
            "filter": "item",
            "values": ["1", "2", "3", "4+"]
        }
    ]

    _education_filters = [
        {
            "code": "UtbildningsNiva",
            "filter": "item",
            "values": ["1", "2", "3", "4", "5", "6", "7"]
        },
        {
            "code": "Alder",
            "filter": "agg:Ålder10år16-95+",
            "values": ["16-24", "25-34", "35-44", "45-54", "55-64", 
                    "65-74", "75-84"]
        },
        {
            "code": "Kon",
            "filter": "item",
            "values": ["1", "2"]
        }
    ]

    _financial_support_filters = [
        {
            "code": "Kon",
            "filter": "item",
            "values": ["1", "2"]
        },
        {
            "code": "Aldersgrupp",
            "filter": "item",
            "values": ["20-64"]
        },
        {
            "code": "ContentsCode",
            "filter": "item",
            "values": ["0000018J", "0000018L", "0000018I", "0000018G"]
        }
    ]

    def __init__(self, logger_name='scb_api_logger', log_file='scb_api.log'):
        """
        Initializes the SCB_DataFetcher with a logger and an API session.

        Args:
            logger_name (str): The name of the logger.
            log_file (str): The file where logs will be saved.
        """
        logger_setup = LoggerSetup(logger_name=logger_name, log_file=log_file)
        self.logger = logger_setup.get_logger()
        self.session = requests.Session()


    def _build_query(self, code_filters, years, region_filter="vs:RegionKommun07"):
        """ 
        Builds a query to request data from the SCB API.

        This private method constructs the query based on the provided filters, years,
        and region. The query is later used for making API requests.

        Args:
            code_filters (list): Filters specifying what kind of data to fetch 
                (e.g., marital status, age).
            years (list): The years for which to retrieve data (e.g., ['2020', '2021']).
            region_filter (str): Filter specifying which municipalities/regions to fetch 
                data for (default is 'vs:RegionKommun07').

        Returns:
            list: A list of dictionaries, each representing a query for one year.

        Example of a generated query:
        {
            'query': [
                {
                    'code': 'Region',
                    'selection': {
                        'filter': 'vs:RegionKommun07',
                        'values': ['0114', '0115']
                    }
                },
                {
                    'code': 'Tid',
                    'selection': {
                        'filter': 'item',
                        'values': ['2020']
                    }
                },
                {
                    'code': 'Civilstand',
                    'selection': {
                        'filter': 'item',
                        'values': ['OG', 'G']
                    }
                },
                {
                    'code': 'Alder',
                    'selection': {
                        'filter': 'agg:Ålder5år',
                        'values': ['20-24']
                    }
                },
                {
                    'code': 'Kon',
                    'selection': {
                        'filter': 'item',
                        'values': ['1', '2']
                    }
                }
            ],
            'response': {
                'format': 'json'
            }
        }
        """
        
        queries = []
        
        for year in years:
            query = {
                'query': [
                    {
                        'code': 'Region',
                        'selection': {
                            'filter': region_filter,
                            'values': self._kommuner
                        }
                    },
                    {
                        'code': 'Tid',
                        'selection': {
                            'filter': 'item',
                            'values': [year]
                        }
                    }
                ],
                'response': {
                    'format': 'json'
                }
            }

            for code_filter in code_filters:
                query['query'].append({
                    'code': code_filter['code'],
                    'selection': {
                        'filter': code_filter['filter'],
                        'values': code_filter['values']
                    }
                })

            queries.append(query)
        
        return queries


    def _retrieve_data(self, url, queries, sleep_time=0.1):
        """
        Sends queries to the API and retrieves the data.

        This method sends a list of queries to the specified URL and retrieves
        the data from the SCB API. Between each request, a delay is added to avoid
        overwhelming the server. Logs the status of each request and handles errors.

        Args:
            url (str): The API endpoint URL to send requests to.
            queries (list): A list of query dictionaries to be sent to the API.
            sleep_time (float): Time (in seconds) to wait between API requests (default: 0.1s).

        Returns:
            A combined DataFrame of all the retrieved data.
        """
        all_dataframes = []

        for query in queries:
            try:
                response = self.session.post(url, json=query)
                status_code = response.status_code

                if status_code == 200:
                    year = query['query'][1]['selection']['values'][0]  
                    self.logger.info(f'{status_code} Data retrieved successfully for year {year}.')
                    response_json = response.json()
                    data = response_json['data']

                    df = pd.json_normalize(data)
                    all_dataframes.append(df)  
                    
                    time.sleep(sleep_time)  

                elif status_code == 301:
                    self.logger.warning(
                        f'{status_code} Redirect: The server is redirecting you.'
                    )
                elif status_code == 400:
                    self.logger.warning(
                        f'{status_code} Bad Request: The request was invalid.'
                    )
                elif status_code == 401:
                    self.logger.warning(
                        f'{status_code} Unauthorized: You are not authenticated.'
                    )
                elif status_code == 403:
                    self.logger.warning(
                        f'{status_code} Forbidden: Access is denied to this resource.'
                    )
                elif status_code == 404:
                    self.logger.warning(
                        f'{status_code} Not Found: Resource not found on the server.'
                    )
                elif status_code == 503:
                    self.logger.warning(
                        f'{status_code} Service Unavailable: The server is overloaded.'
                    )

            except requests.exceptions.RequestException as e:
                self.logger.error(f'Error making the request: {e}')

        if all_dataframes:
            combined_df = pd.concat(all_dataframes, ignore_index=True)
            return combined_df
        else:
            self.logger.warning('No data was retrieved.')
            return pd.DataFrame()


    def _validate_years(self, years):
        """
        Validates that the provided years are in the 'YYYY' format.

        This method checks if each year in the list is a 4-digit string.
        It raises a ValueError if any year is not in the correct format.

        Args:
            years (list of str): A list of years to validate.

        Raises:
            ValueError: If any year is not in the 'YYYY' format.
        """
        for year in years:
            if len(year) != 4 or not year.isdigit():
                raise ValueError(f"Invalid format for year: {year}. Expected format 'YYYY'.")


   
    def fetch_scb_marital_status_data(self, years):
        """
        Fetches marital status data for individuals in different regions.

        This method uses private methods _retrieve_data and _build_query to get
        marital status data for the specified years.

        Args:
            years (list of str): The years to get data for (e.g., ['2020', '2021']).

        Returns:
            A DataFrame containing marital status data for the given years.
        """
        self._validate_years(years)
        
        url = 'https://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101A/BefolkningNy'
        queries = self._build_query(self._marital_status_filters, years)
        df = self._retrieve_data(url=url, queries=queries)

        df[['region', 'marital_status', 'age_group', 'gender', 'year']] = pd.DataFrame(
            df['key'].tolist(), index=df.index
        )
        
        df['num_individuals'] = df['values'].apply(lambda x: x[0])
        df = df.drop(labels=['key', 'values'], axis=1)
        return df


    def fetch_scb_population_education_data(self, years):
        """
        Fetches education level data for individuals in different regions.

        This method uses private methods _retrieve_data and _build_query to get
        education data for the specified years.

        Args:
            years (list of str): The years to get data for (e.g., ['2020', '2021']).

        Returns:
            A pandas dataFrame containing education data for the given years.
        """
        self._validate_years(years)
        
        url = 'https://api.scb.se/OV0104/v1/doris/sv/ssd/START/UF/UF0506/UF0506B/UtbBefRegionR'
        queries = self._build_query(self._education_filters, years)
        df = self._retrieve_data(url=url, queries=queries)

        df[['region', 'gender', 'age_group', 'edu_level', 'year']] = pd.DataFrame(
            df['key'].tolist(), index=df.index
        )
        
        df['num_individuals'] = df['values'].apply(lambda x: x[0])
        df = df.drop(labels=['key', 'values'], axis=1)
        return df


    def fetch_scb_fetch_households_with_children_data(self, years):
        """
        Fetches household type data for families with children in different regions.

        This method uses private methods _retrieve_data and _build_query to get
        household data for the specified years.

        Args:
            years (list of str): The years to get data for (e.g., ['2020', '2021']).

        Returns:
            DataFrame containing household data for families with 
            children for the given years.
        """
        self._validate_years(years)
        
        url = 'https://api.scb.se/OV0104/v1/doris/sv/ssd/START/LE/LE0102/LE0102J/LE0102T19N'
        queries = self._build_query(
            self._family_type_filters, years, region_filter="vs:RegionKommun07EjAggr"
        )
        df = self._retrieve_data(url=url, queries=queries)

        df[['region', 'age_group', 'family_type', 'num_children', 'year']] = pd.DataFrame(
            df['key'].tolist(), index=df.index
        )
        
        df['num_families'] = df['values'].apply(lambda x: x[0])
        df = df.drop(labels=['key', 'values'], axis=1)
        return df


    def fetch_scb_social_benefits_data(self, years):
        """
        Fetches social benefits data received by individuals in different regions.

        This method uses private methods _retrieve_data and _build_query to get
        social benefits data for the specified years.

        Args:
            years (list of str): The years and months (in 'YYYYMmm' format) to get the 
                data for (e.g., ['2020M08', '2020M09']).

        Returns:
           A DataFrame containing social benefits data for the given years.

        Raises:
            ValueError: If the year format is incorrect.
        """
        try:
            for year in years:
                if len(year) != 7 or year[4] != 'M':
                    raise ValueError(f"Invalid format for year: {year}. Expected format 'YYYYMmm'.")
        except ValueError as e:
            self.logger.error(e)
            raise
        
        url = 'https://api.scb.se/OV0104/v1/doris/sv/ssd/START/HE/HE0000/HE0000T02N2'
        queries = self._build_query(
            self._financial_support_filters, years, region_filter="vs:RegionKommun07EjAggr"
        )
        
        df = self._retrieve_data(url=url, queries=queries)

        df[['region', 'gender', 'age_group', 'year_month']] = pd.DataFrame(
            df['key'].tolist(), index=df.index
        )
        
        df[['unemployment', 'economic_assistance', 'establishment_allowance', 
            'porportion_of_population']] = pd.DataFrame(
            df['values'].tolist(), index=df.index
        )
        
        df = df.drop(labels=['key', 'values'], axis=1)
        return df

                    
    