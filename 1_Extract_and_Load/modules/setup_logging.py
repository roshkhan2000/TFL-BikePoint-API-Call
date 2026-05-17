import os 
import logging
import datetime as dt

def setup_logging(log_dir):
    """
    This function sets up the logging for all modules- less repetiton setting up logs
    
    Args:
        log_dir (string): the filepath that you want the logs file to sit in

    Returns:
        _type_: _description_
    """
    log_dir = f"{os.getcwd()}/logs"
    os.makedirs(log_dir, exist_ok=True)
    timestamp = dt.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    log_filename = f"{log_dir}/{timestamp}.log"

    logging.basicConfig(
        filename=log_filename,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        level=logging.INFO
    )

    return logging.getLogger('main')