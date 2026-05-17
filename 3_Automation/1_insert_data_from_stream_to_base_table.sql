// Insert data from stream to bikepoint base
INSERT INTO bikepoint_des6_rk_table_base
WITH json_parse1 AS (
        SELECT 
            json:id::STRING AS bike_point_id
            , json:lat::FLOAT AS lat
            , json:lon::FLOAT AS lon
            , json:commonName::STRING AS common_name
            , json:additionalProperties::Variant AS additional_properties
            -- Extracting date from filename (e.g., '2026-05-04_12-00-00.json')
            , to_timestamp(REPLACE(filename, '.json', ''), 'yyyy-mm-dd_hh-mi-ss') AS extract_timestamp
        FROM bikepoint_des6_rk_stream
    )
    
    -- CTE 2: Flatten the 'additionalProperties' array into Key/Value rows
    , json_parse2 AS (
        SELECT
            bike_point_id
            , lat
            , lon
            , common_name
            , extract_timestamp
            , value:key::STRING AS key
            , value:value::STRING AS value
            , value:modified::TIMESTAMP AS modified
        FROM json_parse1
        , LATERAL FLATTEN(
            input => additional_properties
            , outer => true
            )
        -- Filtering out noise; only keeping the status and count properties
        WHERE value:key NOT IN ('NbBikes', 'TerminalName')
    )
    
    -- Final SELECT: Pivot the keys into actual columns for analysis
    SELECT 
        bike_point_id
        , lat
        , lon
        , common_name
        , extract_timestamp
        , modified
        -- Casting pivoted strings to appropriate booleans, dates, and integers
        , "'Installed'"::BOOLEAN AS installed
        , "'Locked'"::BOOLEAN AS locked
        , TRY_TO_DATE("'InstallDate'") AS install_date
        , TRY_TO_DATE("'RemovalDate'") AS removal_date
        , "'Temporary'"::BOOLEAN AS Temporary
        , "'NbEmptyDocks'"::INTEGER AS nb_empty_docks
        , "'NbDocks'"::INTEGER AS nb_docks
        , "'NbStandardBikes'"::INTEGER AS nb_standard_bikes
        , "'NbEBikes'"::INTEGER AS nb_e_bikes
    FROM json_parse2
    PIVOT (MAX(value) FOR key IN (
        'Installed', 'Locked', 'InstallDate', 'RemovalDate', 
        'Temporary', 'NbEmptyDocks', 'NbDocks', 'NbStandardBikes', 'NbEBikes'
    ));