import requests
import pandas as pd

from logging_module import LoggerSetup


logger_polisen_setup = LoggerSetup(
    logger_name='crime_data_logger', log_file='crime_data.log'
)
logger_polisen = logger_polisen_setup.get_logger()

def fetch_recent_crime_data():
    """
    Fetch recent crime data from the Swedish Police API.

    This function sends a GET request to the Polisen API to fetch data
    about recent crimes. The data is returned in JSON format, which is 
    then converted into a Pandas DataFrame.

    Returns:
        A pandas dataFrame with the normalized crime data.
    """
    try:
        response = requests.get('https://polisen.se/api/events')
        status_code = response.status_code
        
        if status_code == 200:
            logger_polisen.info(f'{status_code} Request successful.')
            response_data = response.json()
            polis_df = pd.json_normalize(response_data, sep='_')
            return polis_df
        
        elif status_code == 301:
            logger_polisen.warning(
                f'{status_code} Redirect: The server is redirecting you.'
            )
        elif status_code == 400:
            logger_polisen.warning(f'{status_code} Bad Request.')
        elif status_code == 401:
            logger_polisen.warning(f'{status_code} Unauthorized.')
        elif status_code == 403:
            logger_polisen.warning(f'{status_code} Forbidden access.')
        elif status_code == 404:
            logger_polisen.warning(f'{status_code} Resource not found.')
        elif status_code == 503:
            logger_polisen.warning(f'{status_code} Service Unavailable.')
    
    except requests.exceptions.RequestException as e:
        logger_polisen.error(f'Request error: {e}')
