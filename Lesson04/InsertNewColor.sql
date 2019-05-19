-- Code is reviewed and is in working condition

-- Insert a new color 
INSERT INTO [Warehouse].[Colors]
SELECT 
	 37 AS ColorID
	,'Dark Yellow' AS ColorName
	,1 AS LastEditedBy
	,GETUTCDATE() AS ValidFrom
	,'9999-12-31 23:59:59.9999999' As Validto
GO
-- Verify the insert
SELECT [ColorID]
      ,[ColorName]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  FROM [Warehouse].[Colors]
  WHERE ColorID=37
