import logging

class LoggerSetup:
    """
    A class to set up and use different loggers for my project.

    This class helps to create separate loggers for different project parts, like:
    - Getting data from websites (APIs).
    - Cleaning and fixing data.
    - Saving data to a database.

    Parameters:
    
    logger_name : str
        The name of the logger. Provide a unique name for different 
        parts of the project.
    log_file : str
        The name of the file where the logs will be saved. Provide a 
        log file name for each logger.

    Methods:
    
    setup_logger(log_file):
        Sets up the logger with a file and a format for the messages.
    get_logger():
        Gives back the logger so you can use it to log messages.
    """
    
    def __init__(self, logger_name, log_file):
        """
        Sets up the logger with the given name and file.

        Parameters:
        
        logger_name : str
            The name of the logger.
        log_file : str
            The name of the log file.
        """
        self.logger = logging.getLogger(logger_name)
        
        if not self.logger.hasHandlers():  
            self.setup_logger(log_file)

    def setup_logger(self, log_file):
        """
        Configures the logger to write messages to a file using basicConfig.

        Parameters:
        
        log_file : str
            The name of the file where logs will be written.
        """
        file_handler = logging.FileHandler(log_file)
        
        file_handler.setLevel(logging.DEBUG)
        
        formatter = logging.Formatter(
            fmt='[%(asctime)s][%(levelname)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M'
        )
        
        file_handler.setFormatter(formatter)
        
        self.logger.addHandler(file_handler)
        self.logger.setLevel(logging.DEBUG)
        

    def get_logger(self):
        """
        Returns the logger that was set up.

        Returns:
        
        logging.Logger
            The logger instance that can be used to log messages.
        """
        return self.logger
