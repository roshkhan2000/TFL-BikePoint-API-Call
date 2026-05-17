CREATE OR REPLACE TABLE *silver_layer_fact* AS (
    SELECT 
        bike_point_id      -- FK to Dimension
        , extract_timestamp -- Time of the snapshot
        , nb_empty_docks
        , nb_e_bikes
        , nb_standard_bikes
    FROM *silver_layer_name*
);