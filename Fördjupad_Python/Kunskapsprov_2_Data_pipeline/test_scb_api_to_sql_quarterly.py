import unittest
from unittest.mock import patch, MagicMock
from SCB_API_to_SQL_Quarterly import main  

class TestSCBMainFunction(unittest.TestCase):

    @patch('SCB_API_to_SQL_Quarterly.SCB_DataFetcher')  
    @patch('SCB_API_to_SQL_Quarterly.SQLManager')  
    @patch('SCB_API_to_SQL_Quarterly.DataCleaner')  
    def test_main_function(self, mock_data_cleaner, mock_sql_manager, mock_scb_fetcher):
        """
        Test the main function with mocked SCB_DataFetcher, SQLManager, and DataCleaner.
        """
        
        
        mock_sql_manager_instance = mock_sql_manager.return_value
        mock_sql_manager_instance.new_engine.return_value = True
        mock_sql_manager_instance.transfer_data.return_value = True

        
        mock_scb_fetcher_instance = mock_scb_fetcher.return_value
        mock_df = MagicMock()
        mock_df.empty = False  

        mock_scb_fetcher_instance.fetch_scb_marital_status_data.return_value = mock_df
        mock_scb_fetcher_instance.fetch_scb_population_education_data.return_value = mock_df
        mock_scb_fetcher_instance.fetch_scb_fetch_households_with_children_data.return_value = mock_df
        mock_scb_fetcher_instance.fetch_scb_social_benefits_data.return_value = mock_df

        
        mock_data_cleaner_instance = mock_data_cleaner.return_value
        mock_data_cleaner_instance.clean_data_from_scb_api.return_value = mock_df

        
        main()

        
        mock_sql_manager_instance.new_engine.assert_called_once_with(
            'mssql', 'NovaNexus', 'crime_data', True
        )

        mock_scb_fetcher_instance.fetch_scb_marital_status_data.assert_called_once_with(['2022'])
        mock_scb_fetcher_instance.fetch_scb_population_education_data.assert_called_once_with(['2022'])
        mock_scb_fetcher_instance.fetch_scb_fetch_households_with_children_data.assert_called_once_with(['2022'])
        mock_scb_fetcher_instance.fetch_scb_social_benefits_data.assert_called_once_with(
            ['2022M01', '2022M02', '2022M03', '2022M04', '2022M05', '2022M06',
             '2022M07', '2022M08', '2022M09', '2022M10', '2022M11', '2022M12']
        )

        
        mock_data_cleaner_instance.clean_data_from_scb_api.assert_called()
        mock_sql_manager_instance.transfer_data.assert_called()

if __name__ == '__main__':
    unittest.main()
