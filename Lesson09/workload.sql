-- Code is reviewed and is in working condition

SELECT a.*
into #t1
	FROM 
	sys.objects a,
	sys.objects b,
	sys.objects c;
SELECT 
a.*
FROM 
Sales.Customers a,
Sales.Orders b 
where customername like '%abel%';
SELECT 
a.* 
into #t2
FROM 
Sales.Customers a,
Sales.Orders b;
SELECT 
c.* FROM 
Sales.Customers c join Sales.Orders o ON 
c.customerid=o.customerid;
