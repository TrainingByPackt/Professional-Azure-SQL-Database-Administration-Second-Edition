-- Code is reviewed and is in working condition

-- Get the target data into temporary table
SELECT
    se.name   AS [XEventSession],
    ev.event_name,
    ac.action_name,
    st.target_name,
    se.session_source,
    st.target_data,
    CAST(st.target_data AS XML)  AS [target_data_XML]
into #XEventData
FROM
               sys.dm_xe_database_session_event_actions  AS ac

    INNER JOIN sys.dm_xe_database_session_events         AS ev  ON ev.event_name = ac.event_name
        AND CAST(ev.event_session_address AS BINARY(8)) = CAST(ac.event_session_address AS BINARY(8))

    INNER JOIN sys.dm_xe_database_session_object_columns AS oc
         ON CAST(oc.event_session_address AS BINARY(8)) = CAST(ac.event_session_address AS BINARY(8))

    INNER JOIN sys.dm_xe_database_session_targets        AS st
         ON CAST(st.event_session_address AS BINARY(8)) = CAST(ac.event_session_address AS BINARY(8))

    INNER JOIN sys.dm_xe_database_sessions               AS se
         ON CAST(ac.event_session_address AS BINARY(8)) = CAST(se.address AS BINARY(8))
WHERE
        oc.column_name = 'occurrence_number'
    AND
        se.name        = 'LongRunningQueries'
    AND
        ac.action_name = 'sql_text'
ORDER BY
    se.name,
    ev.event_name,
    ac.action_name,
    st.target_name,
    se.session_source
;
GO
-- Parse the target xml xevent into table
SELECT * FROM 
(
SELECT 
	xed.event_data.value('(data[@name="statement"]/value)[1]', 'nvarchar(max)') AS sqltext,
	xed.event_data.value('(data[@name="cpu_time"]/value)[1]', 'int') AS cpu_time,
	xed.event_data.value('(data[@name="duration"]/value)[1]', 'int') AS duration,
	xed.event_data.value('(data[@name="logical_reads"]/value)[1]', 'int') AS logical_reads
FROM #XEventData
 CROSS APPLY target_data_XML.nodes('//RingBufferTarget/event') AS xed (event_data)
) As xevent
WHERE duration > = 10000000
GO
DROP TABLE #XEventData