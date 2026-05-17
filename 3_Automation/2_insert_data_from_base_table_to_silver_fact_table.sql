// Insert data from base table to FACT table using the WHERE clause 
INSERT INTO bikepoint_des6_rk_table_fact
    SELECT 
        bike_point_id      
        , extract_timestamp
        , nb_empty_docks
        , nb_e_bikes
        , nb_standard_bikes
    FROM bikepoint_des6_rk_table_base
    WHERE extract_timestamp > (SELECT MAX(extract_timestamp) FROM bikepoint_des6_rk_table_fact);