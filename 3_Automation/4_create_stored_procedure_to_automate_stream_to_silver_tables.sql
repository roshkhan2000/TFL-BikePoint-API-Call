// Create a stored procedure to trigger our data to go from stream to base then from base to fact and dim tables
CREATE OR REPLACE PROCEDURE bikepoint_des6_rk_procedure()
    RETURNS STRING 
    LANGUAGE SQL 
AS 
$$
BEGIN
// Step 1: Parse JSON from the stream, flatten properties, pivot into columns, and insert into the base table
INSERT INTO bikepoint_des6_rk_table_base
WITH json_parse1 AS (
        SELECT 
            json:id::STRING AS bike_point_id
            , json:lat::FLOAT AS lat
            , json:lon::FLOAT AS lon
            , json:commonName::STRING AS common_name
            , json:additionalProperties::Variant AS additional_properties
            , to_timestamp(REPLACE(filename, '.json', ''), 'yyyy-mm-dd_hh-mi-ss') AS extract_timestamp
        FROM bikepoint_des6_rk_stream
    )
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
        , LATERAL FLATTEN(input => additional_properties, outer => true)
        WHERE value:key NOT IN ('NbBikes', 'TerminalName')
    )
    SELECT 
        bike_point_id
        , lat
        , lon
        , common_name
        , extract_timestamp
        , modified
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

// Step 2: Insert new snapshots into the FACT table using incremental loading logic
INSERT INTO bikepoint_des6_rk_table_fact
    SELECT 
        bike_point_id      
        , extract_timestamp
        , nb_empty_docks
        , nb_e_bikes
        , nb_standard_bikes
    FROM bikepoint_des6_rk_table_base
    WHERE extract_timestamp > (SELECT COALESCE(MAX(extract_timestamp), '1900-01-01'::TIMESTAMP) FROM bikepoint_des6_rk_table_fact);

// Step 3: Retire old versions of records in the DIM table if values have changed
MERGE INTO bikepoint_des6_rk_table_dimension AS d
USING (
    SELECT 
        bike_point_id      
        , lat
        , lon
        , common_name
        , nb_docks
        , installed
        , locked
        , install_date
        , removal_date
        , modified AS valid_from
        , NULL AS valid_to
    FROM (
        SELECT 
            bike_point_id      
            , lat
            , lon
            , common_name
            , nb_docks
            , installed
            , locked
            , install_date
            , removal_date
            , MAX(modified) AS modified
        FROM bikepoint_des6_rk_table_base
        GROUP BY bike_point_id, lat, lon, common_name, nb_docks, installed, locked, install_date, removal_date
        )
    ) AS n
ON d.bike_point_id = n.bike_point_id
WHEN MATCHED AND (d.locked IS DISTINCT FROM n.locked OR d.nb_docks IS DISTINCT FROM n.nb_docks OR d.removal_date IS DISTINCT FROM n.removal_date)
    THEN UPDATE SET d.valid_to = n.valid_from
WHEN NOT MATCHED THEN 
    INSERT ALL BY NAME;

// Step 4: Insert the brand new current version for the records we just retired
INSERT INTO bikepoint_des6_rk_table_dimension
    WITH most_recent AS (
        SELECT 
            bike_point_id      
            , lat
            , lon
            , common_name
            , nb_docks
            , installed
            , locked
            , install_date
            , removal_date
            , modified AS valid_from
            , NULL AS valid_to
        FROM (
            SELECT 
                bike_point_id      
                , lat
                , lon
                , common_name
                , nb_docks
                , installed
                , locked
                , install_date
                , removal_date
                , MAX(modified) AS modified
            FROM bikepoint_des6_rk_table_base
            GROUP BY bike_point_id, lat, lon, common_name, nb_docks, installed, locked, install_date, removal_date
        )
    )
    SELECT n.*
    FROM bikepoint_des6_rk_table_dimension AS d
    INNER JOIN most_recent AS n ON d.bike_point_id = n.bike_point_id
    WHERE d.locked IS DISTINCT FROM n.locked
        OR d.nb_docks IS DISTINCT FROM n.nb_docks  // Fixed: Corrected comparison from n.locked to n.nb_docks
        OR d.removal_date IS DISTINCT FROM n.removal_date;
        
RETURN 'Data from Stream entered into Base. Data from Base entered into Fact and Dim tables';

END;
$$;

// Manually call the procesdure if needed
CALL bikepoint_des6_rk_procedure();