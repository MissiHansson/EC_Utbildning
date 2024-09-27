import unittest
from unittest.mock import patch, MagicMock
from Update_Bra_Data_SQL_Monthly import main

class TestExcelToSQLMainFunction(unittest.TestCase):

    @patch('Update_Bra_Data_SQL_Monthly.ExcelManager')  
    @patch('Update_Bra_Data_SQL_Monthly.SQLManager')    
    @patch('Update_Bra_Data_SQL_Monthly.DataCleaner')
    def test_main_function(self, mock_data_cleaner, mock_sql_manager, mock_excel_manager):
        """
        Test the main function with mocked ExcelManager, SQLManager, and DataCleaner.
        """

        
        mock_sql_manager_instance = mock_sql_manager.return_value
        mock_sql_manager_instance.new_engine.return_value = True
        mock_sql_manager_instance.transfer_data.return_value = True

        
        mock_excel_manager_instance = mock_excel_manager.return_value
        mock_df = MagicMock()  
        mock_df.empty = False  
        
        
        mock_excel_manager_instance._get_read_files.return_value = set()  
        mock_excel_manager_instance.read_new_files.return_value = mock_df

        
        mock_data_cleaner_instance = mock_data_cleaner.return_value
        mock_data_cleaner_instance.clean_data_from_bra_excel.return_value = mock_df

        
        main()

        
        mock_sql_manager_instance.new_engine.assert_called_once_with(
            'mssql', 'NovaNexus', 'crime_data', True
        )
        mock_excel_manager_instance.read_new_files.assert_called_once()
        mock_data_cleaner_instance.clean_data_from_bra_excel.assert_called_once_with()
        mock_sql_manager_instance.transfer_data.assert_called_once_with(
            mock_df, 'bra_data'
        )


if __name__ == '__main__':
    unittest.main()
