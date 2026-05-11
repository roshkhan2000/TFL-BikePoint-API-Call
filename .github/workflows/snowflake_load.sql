// Creating a storage integration for Snowflake to bridge to AWS
CREATE STORAGE INTEGRATION *integration_name*
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = *'insert_aws_iam_arn*'
  STORAGE_ALLOWED_LOCATIONS = (*'insert_buclet_url'*);

// Describe the integration just made to create values
DESC INTEGRATION bikepoint_des6_rk_storage_integration;

// Create an external stage in Snowflake
CREATE STAGE *stage_name*
  URL = *'insert_buclet_url'*
  STORAGE_INTEGRATION = *integration_name*
  FILE_FORMAT = (
  TYPE = 'JSON' 
  STRIP_OUTER_ARRAY = TRUE
);

// List all the items in the s3 bucket (which is in our stage now)
LIST @b*stage_name*;

// Create an empty table with two columns
CREATE OR REPLACE TABLE *table_name*
    (
    json VARIANT
    , filename STRING
    );

// Copy data from stage into this empty table
COPY INTO *table_name*
FROM (
    SELECT
    $1
    , metadata$filename
    FROM @*stage_name*
    )
FILE_FORMAT = (
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE
);

// Select * the data in the table 
SELECT *
FROM *table_name*

// To empty table (if needed)
TRUNCATE TABLE *table_name*
