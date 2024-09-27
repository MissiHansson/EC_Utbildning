from sqlalchemy import create_engine, inspect
import pandas as pd
from logging_module import LoggerSetup

"""
SQLManager Module

This module helps you work with databases. It has a class called SQLManager that
lets you:
1. Connect to a database.
2. Get data from the database.
3. Save data to the database.

Steps to use:
1. Make an SQLManager object.
2. Connect to your database using new_engine().
3. Use fetch_data() to get data from the database.
4. Use transfer_data() to save data to the database.

External libraries: 
- sqlalchemy: Used to connect to and interact with SQL databases.
- pandas: Used to handle and process data.
- logging_module (LoggerSetup): For logging API interactions and errors.
"""


class SQLManager:
    """
    SQLManager class handles connection to a SQL database, fetching data,
    and saving data to the database.
    """

    def __init__(self, logger_name, log_file):
        """
        Initializes the SQLManager class by setting up the logger.

        Parameters:
        logger_name (str): The name of the logger.
        log_file (str): The file where logs are written.
        """
        logger_setup = LoggerSetup(logger_name, log_file)
        self.logger = logger_setup.get_logger()
        self.engine = None

    def new_engine(self, dialect, server, database, user=None,
                   password=None, integrated_security=True):
        """
        Creates a SQLAlchemy engine for a database connection.

        Parameters:
        dialect (str): The type of database (e.g., 'mssql' for Microsoft SQL Server).
        server (str): The server or computer where the database is hosted.
        database (str): The name of the database.
        user (str, optional): The username for authentication 
                              (if not using Windows login).
        password (str, optional): The password for authentication 
                                  (if not using Windows login).
        integrated_security (bool): Set to True for Windows authentication; 
                                    False for username/password authentication.

        Returns:
        A SQLAlchemy engine connected to the specified database.
        """
        try:
            if integrated_security:
                # For Windows authentication
                eng = (f'{dialect}://{server}/{database}'
                       '?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server')
            else:
                # For SQL Server authentication
                eng = (f'{dialect}://{user}:{password}@{server}/{database}'
                       '?driver=ODBC+Driver+17+for+SQL+Server')

            # Log the connection string
            self.logger.info(f'{dialect} Engine created with connection string: {eng}')
            self.engine = create_engine(eng)
            return self.engine

        except Exception as e:
            self.logger.error(f'Failed to create engine: {e}')
            raise

    def fetch_data(self, query):
        """
        Fetches data from the connected database using a provided SQL query.

        Parameters:
        query (str): The SQL query to execute.

        Returns:
        The resulting data from the query in a pandas DataFrame.
        """
        if self.engine is None:
            self.logger.error('No engine created. Call new_engine() first.')
            raise Exception('No engine created. Call new_engine() first.')

        try:
            with self.engine.connect() as connection:
                df = pd.read_sql(query, connection)
            self.logger.info('Data received from query.')
            return df
        except Exception as e:
            self.logger.error(f'There was an error in fetching data: {e}')
            raise

    def transfer_data(self, df, table_name):
        """
        Transfers a pandas dataframe to the connected database table.

        Parameters:
        Pandas DataFrame (df): The DataFrame containing data to save.
        table_name (str): The name of the table where the data will be saved.

        If the table already exists, the data will be appended. Otherwise, 
        a new table will be created.
        """
        if self.engine is None:
            self.logger.error('No engine created. Call new_engine() first.')
            raise Exception('No engine created. Call new_engine() first.')

        try:
            inspector = inspect(self.engine)
            if table_name in inspector.get_table_names():
                self.logger.info(f'Table "{table_name}" exists. Appending data.')
                df.to_sql(table_name, con=self.engine, if_exists='append', index=False)
            else:
                self.logger.info(f'Table "{table_name}" does not exist. Creating a new table.')
                df.to_sql(table_name, con=self.engine, if_exists='append', index=False)
        except Exception as e:
            self.logger.error(f'Error transferring data to table named "{table_name}": {e}')
            raise
