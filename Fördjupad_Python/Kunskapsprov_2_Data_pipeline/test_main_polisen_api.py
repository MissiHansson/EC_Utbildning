import unittest
from unittest.mock import patch, MagicMock
from Polisen_API_to_SQL_Daily import main  


class TestMainPolisenAPI(unittest.TestCase):
    
    @patch('Polisen_API_to_SQL_Daily.fetch_recent_crime_data')
    @patch('Polisen_API_to_SQL_Daily.SQLManager')
    @patch('Polisen_API_to_SQL_Daily.DataCleaner')
    def test_main_polisen_api(self, mock_data_cleaner, mock_sql_manager, 
                              mock_fetch_recent_crime_data):
        """
        Tests the main function for Polisen API processing.
        Mocks the fetch, clean, and SQL transfer steps.
        """
        
        mock_df = MagicMock()
        mock_df.empty = False
        mock_fetch_recent_crime_data.return_value = mock_df

        
        mock_cleaned_data = MagicMock()
        mock_data_cleaner_instance = mock_data_cleaner.return_value
        mock_data_cleaner_instance.clean_data_from_polis_api.return_value = mock_cleaned_data

        
        mock_sql_manager_instance = mock_sql_manager.return_value
        mock_sql_manager_instance.transfer_data.return_value = True

        
        main()

        
        mock_fetch_recent_crime_data.assert_called_once()  
        mock_data_cleaner.assert_called_once_with(mock_df)  
        mock_data_cleaner_instance.clean_data_from_polis_api.assert_called_once()
        mock_sql_manager_instance.transfer_data.assert_called_once_with(
            mock_cleaned_data, 'polis_data'
        )

if __name__ == '__main__':
    unittest.main()
