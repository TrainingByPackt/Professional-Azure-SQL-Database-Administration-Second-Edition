-- Code is reviewed and is in working condition

-- Create Extended Event to record queries greater than 10 seconds
CREATE EVENT SESSION [LongRunningQueries] ON DATABASE 
ADD EVENT sqlserver.sql_statement_completed
	(
    ACTION
		(
			sqlserver.database_name,
			sqlserver.query_hash,
			sqlserver.query_plan_hash,
			sqlserver.sql_text,
			sqlserver.username
		)
    WHERE ([sqlserver].[database_name]=N'toystore')
	)
ADD TARGET package0.ring_buffer
WITH (STARTUP_STATE=OFF)
GO

-- Start the Event Session
ALTER EVENT SESSION [LongRunningQueries]
    ON DATABASE
    STATE = START;

-- Stop the Event Session
ALTER EVENT SESSION [LongRunningQueries]
    ON DATABASE
    STATE = STOP;

-- Drop the Event Target
ALTER EVENT SESSION [LongRunningQueries]
    ON DATABASE
    DROP TARGET package0.ring_buffer;
GO
-- Drop the Event Session
DROP EVENT SESSION [LongRunningQueries]
    ON DATABASE;
GO

