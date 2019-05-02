-- create a new orders table
CREATE TABLE orders 
  ( 
     orderid  INT IDENTITY(1, 1) PRIMARY KEY, 
     quantity INT, 
     sales    MONEY 
  ); 

--populate Orders table with sample data
; 
WITH t1 
     AS (SELECT 1 AS a 
         UNION ALL 
         SELECT 1), 
     t2 
     AS (SELECT 1 AS a 
         FROM   t1 
                CROSS JOIN t1 AS b), 
     t3 
     AS (SELECT 1 AS a 
         FROM   t2 
                CROSS JOIN t2 AS b), 
     t4 
     AS (SELECT 1 AS a 
         FROM   t3 
                CROSS JOIN t3 AS b), 
     t5 
     AS (SELECT 1 AS a 
         FROM   t4 
                CROSS JOIN t4 AS b), 
     nums 
     AS (SELECT Row_number() 
                  OVER ( 
                    ORDER BY (SELECT NULL)) AS n 
         FROM   t5) 
INSERT INTO orders 
SELECT n, 
       n * 10 
FROM   nums;
GO
SELECT TOP 10 * from orders;