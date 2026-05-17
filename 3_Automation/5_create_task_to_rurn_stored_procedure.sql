// create a task to run the procedure on schedule
CREATE TASK bikepoint_des6_rk_task
WAREHOUSE = dataschool_wh
SCHEDULE = '1 minute'
WHEN system$stream_has_data('bikepoint_des6_rk_stream')
AS 
CALL bikepoint_des6_rk_procedure();

// turn task on as it is automatically suspended upon creation
ALTER TASK bikepoint_des6_rk_task resume;