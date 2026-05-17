// Create a snowpipe which is constantly detecting metadata changes in the stage
// Based on a changed, it copies data into the raw table
CREATE PIPE bikepoint_des6_rk_pipe 
auto_ingest = TRUE AS 
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
// Show pipe to extract notification channel value to inser into S3
SHOW PIPES;

// Create a stream on the raw table
CREATE STREAM bikepoint_des6_rk_stream
ON TABLE bikepoint_des6_rk_table_raw;