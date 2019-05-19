-- Code is reviewed and is in working condition

EXEC	[Website].[SearchForPeople]
		@SearchText = N'a',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForPeople]
		@SearchText = N'abc',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForPeople]
		@SearchText = N'john',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForPeople]
		@SearchText = N'joh',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForStockItems]
		@SearchText = N'a',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForStockItems]
		@SearchText = N'afr',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForStockItems]
		@SearchText = N'leg',
		@MaximumRowsToReturn = 1000
GO

EXEC	[Website].[SearchForSuppliers]
		@SearchText = N'a',
		@MaximumRowsToReturn = 1000
GO

EXEC	[Website].[SearchForSuppliers]
		@SearchText = N'b',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForSuppliers]
		@SearchText = N'c',
		@MaximumRowsToReturn = 1000

GO
EXEC	[Website].[SearchForCustomers]
		@SearchText = N'c',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForCustomers]
		@SearchText = N'b',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForCustomers]
		@SearchText = N'a',
		@MaximumRowsToReturn = 1000
GO
EXEC	[Website].[SearchForCustomers]
		@SearchText = N'd',
		@MaximumRowsToReturn = 1000


