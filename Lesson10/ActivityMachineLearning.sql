CREATE TABLE [dbo].[MonthlySales](
[year] [smallint] NULL,
[month] [tinyint] NULL,
[Amount] [money] NULL
)
Go
EXECUTE sp_execute_external_script
@language =N'R',
@script=N'print("Hello World")';
GO
DROP PROCEDURE IF EXISTS generate_linear_model;
GO
CREATE PROCEDURE generate_linear_model
AS
BEGIN
EXECUTE sp_execute_external_script @language = N'R',
@script = N'
lrmodel <- rxLinMod(formula = amount ~ (year+month), data = MonthlySales);
trained_model <- data.frame(payload = as.raw(serialize(lrmodel,
connection=NULL)));
' ,
@input_data_1 = N'SELECT
year,month,amount FROM MonthlySales',
@input_data_1_name =
N'MonthlySales',
@output_data_1_name = N'trained_
model'
WITH RESULT SETS
(
(
model VARBINARY(MAX)
)
);
END;
GO

DROP TABLE IF EXISTS dbo.monthly_sales_models
GO
CREATE TABLE dbo.monthly_sales_models

(
model_name VARCHAR(30) NOT NULL
DEFAULT ('default model') PRIMARY KEY,
model VARBINARY(MAX) NOT NULL
);
GO
INSERT INTO dbo.monthly_sales_models
(
model
)
EXECUTE generate_linear_model;
GO

SELECT * FROM monthly_sales_models

GO
INSERT INTO dbo.MonthlySales
(
year,
month
)
VALUES
(2019, 7),
(2019, 8),
(2019, 9),
(2019, 10),
(2019, 11);
GO

DECLARE @salesmodel VARBINARY(MAX) = (
SELECT model FROM dbo.monthly_sales_models
WHERE model_name = 'default
model'
);
EXECUTE sp_execute_external_script @language = N'R',
@script = N'
current_model <- unserialize(as.raw(salesmodel));
new <- data.frame(NewMonthlySalesData);
predicted.amount <- rxPredict(current_model, new);
OutputDataSet <- cbind(new, ceiling(predicted.amount));
',
@input_data_1 = N'SELECT [year],[month]
FROM [dbo].[MonthlySales] where amount is null',
@input_data_1_name =
N'NewMonthlySalesData',
@params = N'@salesmodel
varbinary(max)',
@salesmodel = @salesmodel
WITH RESULT SETS
(
(
[year] INT,
[month] INT,
predicted_sales INT
)
);