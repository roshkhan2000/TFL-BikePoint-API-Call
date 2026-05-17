
import boto3
import logging
import os

logger = logging.getLogger(__name__)

def load(aws_key, aws_secret, bucket, dir_to_upload):
    """
    This will load any json files in the data directory to a specified S3 bucket

    Args:
        aws_key (string): aws access key ID attached to an IAM user
        aws_secret (string): aws secret key ID attached to an IAM user
        bucket (string): s3 bucket name to upload JSON to
        dir_to_upload (string): must be a complete filepath for the directory where the data is location .e.g., Path('JSON_Files')
    """    
    s3_client = boto3.client(
        "s3",
        aws_access_key_id=aws_key,
        aws_secret_access_key=aws_secret
    )

    files_to_upload = os.listdir(dir_to_upload)

    files_processed = 0

    for file in files_to_upload:
        if file.endswith("json"):

            full_path = os.path.join(dir_to_upload, file)
            
            try:
                s3_client.upload_file(full_path, bucket, file)
                logger.info(f"{file} uploaded to S3")
                
                os.remove(full_path)
                logger.info(f"{file} deleted locally")
                files_processed += 1
            
            except Exception as e:
                logger.error(f"Failed to process {file}: {e}")

    logger.info(f'Processed {files_processed} files')