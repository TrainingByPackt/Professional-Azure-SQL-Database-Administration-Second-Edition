-- Code is reviewed and is in working condition

-- Execute in master database
-- Get utilization in last 6 hours for the toystore database
Declare 
	@StartTime DATETIME = DATEADD(HH,-3,GetUTCDate()),
	@EndTime DATETIME = GetUTCDate()
SELECT 
	database_name,
	start_time,
	end_time,
	avg_cpu_percent,
	avg_data_io_percent,
	avg_log_write_percent,
	(
		SELECT Max(v)    
		FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS    
		value(v)) AS [avg_DTU_percent] 
FROM sys.resource_stats   
WHERE database_name = 'toystore' AND 
start_time BETWEEN @StartTime AND @EndTime
ORDER BY avg_cpu_percent desc
GO

-- Get avg_cpu_utilization across databases in last 14 days
SELECT 
	database_name,
	AVG(avg_cpu_percent) AS avg_cpu_percent
FROM sys.resource_stats   
GROUP BY database_name
ORDER BY avg_cpu_percent DESC
GO
-- Get Average CPU, Data IO, Log IO and Memory utilization
-- Execute in toystore database
SELECT    
    AVG(avg_cpu_percent) AS avg_cpu_percent,   
    AVG(avg_data_io_percent) AS avg_data_io_percent,   
    AVG(avg_log_write_percent) AS avg_log_write_percent,   
    AVG(avg_memory_usage_percent) AS avg_memory_usage_percent
FROM sys.dm_db_resource_stats;
GO
-- Get the Average DTU utilization for toystore database
-- Execute in toystore database
SELECT    
   end_time,   
  (SELECT Max(v)    
   FROM (VALUES (avg_cpu_percent), (avg_data_io_percent), (avg_log_write_percent)) AS    
   value(v)) AS [avg_DTU_percent]   
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC
GO

-- Get all sessions for user sqladmin
-- Execute in master or the user database
SELECT 
	session_id, 
	program_name, 
	status,
	reads, 
	writes,
	logical_reads 
from sys.dm_exec_sessions WHERE login_name='sqladmin'
GO

-- Get all the requests for the login sqladmin
SELECT 
	s.session_id,
	s.status AS session_status,
	r.status AS request_status, 
	r.cpu_time, 
	r.total_elapsed_time,
	r.writes,
	r.logical_reads,
	t.Text AS query_batch_text,
	SUBSTRING(t.text, (r.statement_start_offset/2)+1,   
        ((CASE r.statement_end_offset  
          WHEN -1 THEN DATALENGTH(t.text)  
         ELSE r.statement_end_offset  
         END - r.statement_start_offset)/2) + 1) AS running_query_text 
FROM sys.dm_exec_sessions s join  sys.dm_exec_requests r 
ON r.session_id=s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
WHERE s.login_name='sqladmin'

GO
-- top 5 CPU intensive queries
SELECT 
	TOP 5 
	(total_worker_time/execution_count)/(1000*1000) AS [Avg CPU Time(Seconds)],  
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
        ((CASE qs.statement_end_offset  
          WHEN -1 THEN DATALENGTH(st.text)  
         ELSE qs.statement_end_offset  
         END - qs.statement_start_offset)/2) + 1) AS statement_text,
	qs.execution_count, 
	(qs.total_elapsed_time/execution_count)/(1000*1000) AS [Avg Duration(Seconds)] 
FROM sys.dm_exec_query_stats AS qs  
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st  
ORDER BY total_worker_time/execution_count DESC;  

-- top 5 long running queries
SELECT 
	TOP 5 
	(total_worker_time/execution_count)/(1000*1000) AS [Avg CPU Time(Seconds)],  
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
        ((CASE qs.statement_end_offset  
          WHEN -1 THEN DATALENGTH(st.text)  
         ELSE qs.statement_end_offset  
         END - qs.statement_start_offset)/2) + 1) AS statement_text,
	qs.execution_count, 
	(qs.total_elapsed_time/execution_count)/(1000*1000) AS [Avg Duration(Seconds)] 
FROM sys.dm_exec_query_stats AS qs  
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st  
ORDER BY (qs.total_elapsed_time/execution_count) DESC;  

-- Get blocked queries
SELECT   
  w.session_id
 ,w.wait_duration_ms
 ,w.wait_type
 ,w.blocking_session_id
 ,w.resource_description
 ,t.text
FROM sys.dm_os_waiting_tasks w
INNER JOIN sys.dm_exec_requests r
ON w.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text (r.sql_handle) t
WHERE w.blocking_session_id>0
GO