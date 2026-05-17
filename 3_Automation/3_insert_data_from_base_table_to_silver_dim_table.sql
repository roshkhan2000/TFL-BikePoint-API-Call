// Step 1: Handle existing record retirement and brand new record insertion
MERGE INTO bikepoint_des6_rk_table_dimension AS d
USING (
    // Prepare the latest state of each bike point from the base table
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
        // Aggregate to ensure we only process the most recent 'modified' timestamp per bike point
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
        )
    ) AS n
ON d.bike_point_id = n.bike_point_id
// If data has changed, "close" the current version by setting valid_to to the new update time
WHEN MATCHED AND (d.locked IS DISTINCT FROM n.locked OR d.nb_docks IS DISTINCT FROM n.nb_docks OR d.removal_date IS DISTINCT FROM n.removal_date)
    THEN UPDATE SET 
    d.valid_to = n.valid_from
// If the bike_point_id is entirely new, insert it as the first active record
WHEN NOT MATCHED THEN 
    INSERT ALL BY NAME 
    ;

// Step 2: Insert the "New Version" for records that were just retired in Step 1
INSERT INTO bikepoint_des6_rk_table_dimension
    WITH most_recent AS (
        // Re-calculate or pull the latest state from the base table
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
        )
    )
    // Only insert the new state if it differs from the current record in the dimension table
    SELECT 
        n.*
    FROM bikepoint_des6_rk_table_dimension AS d
    INNER JOIN most_recent AS n
        ON d.bike_point_id = n.bike_point_id
    WHERE d.locked IS DISTINCT FROM n.locked
        OR d.nb_docks IS DISTINCT FROM n.nb_docks  // Fixed: Previously compared docks to locked
        OR d.removal_date IS DISTINCT FROM n.removal_date;