// Creating a storage integration for Snowflake to bridge to AWS
CREATE STORAGE INTEGRATION bikepoint_des6_rk_storage_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = *'insert_aws_iam_arn*'
  STORAGE_ALLOWED_LOCATIONS = (*'insert_s3_buclet_url'*);
// Describe the integration to get IAM USER ARN & External ID values from the integration
DESC INTEGRATION bikepoint_des6_rk_storage_integration;
// Input these values in the 'Trust Realtionship' part of IAM role

// Create an external stage in Snowflake
CREATE STAGE @bikepoint_des6_rk_external_stage;
  URL = *'insert_s3_bucket_url'*
  STORAGE_INTEGRATION = bikepoint_des6_rk_storage_integration
  FILE_FORMAT = (
  TYPE = 'JSON' 
  STRIP_OUTER_ARRAY = TRUE
);
// List all the items in the stage to verify you can see the items in S3
LIST @bikepoint_des6_rk_external_stage;

// Create an empty table with two columns
CREATE OR REPLACE TABLE bikepoint_des6_rk_table_raw
    (
    json VARIANT
    , filename STRING
    );

// Copy data from stage into this empty table
COPY INTO bikepoint_des6_rk_table_raw
FROM (
    SELECT
    $1
    , metadata$filename
    FROM @bikepoint_des6_rk_external_stage
    )
FILE_FORMAT = (
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE
);
// Select * to verify that the data has been copied in to this table
SELECT *
FROM bikepoint_des6_rk_table_raw;

// To empty table (if needed)
TRUNCATE TABLE bikepoint_des6_rk_table_raw;
