CREATE OR REPLACE TABLE bikepoint_des6_rk_table_dimension AS (
    SELECT 
        bike_point_id      -- Primary Key
        , lat
        , lon
        , common_name
        , nb_docks
        , installed
        , locked
        , install_date
        , removal_date
        -- Tracking when this specific configuration was last modified
        , MIN(modified) AS valid_from
        , NULL AS valid_to
    FROM bikepoint_des6_rk_table_base
    GROUP BY
        bike_point_id
        , lat
        , lon
        , common_name      
        , nb_docks
        , installed
        , locked
        , install_date
        , removal_date
);
