USE [AdventureWorksDW2012]
GO
--The script is used to make a bigger FactResellerSales table, called FactResellerSalesBig.
--When a RowMultiplier 180 is used the FactResellerSalesBig table will be 10,953,900 rows
--The query takes 25 minutes to run in my laptop with a 4-core processor, a 7200 rpm hard disk and 8 GB RAM


Declare		@OrderCountTable Table (OrderDateKey INT, OrderCount Int)
Declare		@OrderDateKey Int = 2012
			, @OrderCount int
			, @RowMultiplier int = 180	--180 times more rows than the original FactResellerSales Table
										--you can make it bigger or smaller by change this number

Insert Into	@OrderCountTable
SELECT		Distinct [OrderDateKey]
			, Count(Distinct SalesOrderNumber) As OrderCount
FROM		[dbo].[FactResellerSales]
Group by	[OrderDateKey];


If Object_ID('[dbo].[FactResellerSalesBig]') Is Not Null
		Drop Table [dbo].[FactResellerSalesBig];

Select	Top(0) *
Into	FactResellerSalesBig
From	[dbo].[FactResellerSales];

While Exists (Select * From @OrderCountTable)
	Begin
		Select	Top(1) 
				@OrderDateKey = OrderDateKey
				,  @OrderCount =  OrderCount
		From	@OrderCountTable;

		Insert into FactResellerSalesBig with(Tablock)
		Select
				R.[ProductKey]
				, R.[OrderDateKey]
				, R.[DueDateKey]
				, R.[ShipDateKey]
				, Y.[ResellerKey]
				, R.[EmployeeKey]
				, R.[PromotionKey]
				, R.[CurrencyKey]
				, Y.[SalesTerritoryKey]
				, Cast(R.[SalesOrderNumber] + Format(Y.RowNum, '000') AS nvarchar(20)) As SalesOrderNumber
				, R.[SalesOrderLineNumber]
				, R.[RevisionNumber]
				, Ceiling(R.[OrderQuantity] * Y.QuantityMultiplier) As OrderQuantity
				, R.[UnitPrice]
				, Ceiling(R.[OrderQuantity] * Y.QuantityMultiplier) * R.[UnitPrice] As ExtendedAmount
				, R.[UnitPriceDiscountPct]
				, Ceiling(R.[OrderQuantity] * Y.QuantityMultiplier) * R.[UnitPrice] * R.[UnitPriceDiscountPct] As DiscountAmount
				, R.[ProductStandardCost]
				, Ceiling(R.[OrderQuantity] * Y.QuantityMultiplier) *  R.[ProductStandardCost] As TotalProductCost
				, Ceiling(R.[OrderQuantity] * Y.QuantityMultiplier) * R.[UnitPrice] * (1 - R.[UnitPriceDiscountPct]) As SalesAmount
				, Ceiling(R.[OrderQuantity] * Y.QuantityMultiplier) * R.[UnitPrice] * (1 - R.[UnitPriceDiscountPct]) * 0.08 As TaxAmt
				, R.[Freight]
				, Cast(R.[CarrierTrackingNumber] +  Format(Y.RowNum, '-000') As nvarchar(25)) As CarrierTrackingNumber
				, Cast(R.[CustomerPONumber] + Format(Y.RowNum, '000') AS nvarchar(25)) As CustomerPONumber
				, R.[OrderDate]
				, R.[DueDate]
				, R.[ShipDate]
		From
			(
				SELECT 
						[ProductKey]
						,[OrderDateKey]
						,[DueDateKey]
						,[ShipDateKey]
						,[ResellerKey]
						,[EmployeeKey]
						,[PromotionKey]
						,[CurrencyKey]
						,[SalesTerritoryKey]
						,[SalesOrderNumber]
						,[SalesOrderLineNumber]
						,[RevisionNumber]
						,[OrderQuantity]
						,[UnitPrice]
						,[ExtendedAmount]
						,[UnitPriceDiscountPct]
						,[DiscountAmount]
						,[ProductStandardCost]
						,[TotalProductCost]
						,[SalesAmount]
						,[TaxAmt]
						,[Freight]
						,[CarrierTrackingNumber]
						,[CustomerPONumber]
						,[OrderDate]
						,[DueDate]
						,[ShipDate]
						, Dense_Rank() Over(Partition by [OrderDateKey] Order by SalesOrderNumber) As OrderNumber
				FROM	[dbo].[FactResellerSales] 
				Where	OrderDateKey =  @OrderDateKey
			) R
					Cross Apply
			(

				SELECT	TOP (@RowMultiplier) 
						A.[ResellerKey]
						, B.SalesTerritoryKey
						, Row_Number() Over(Order by Checksum(newid())) As RowNum
						, RAND(CHECKSUM(NEWID())) * 2 As QuantityMultiplier
				FROM	[DimResellerBig] A
							Inner join
						[dbo].[DimGeography] B
							on A.[GeographyKey] = B.GeographyKey
							Cross Join
						Master..spt_values C
				Where	C.Type = 'P'
							And
						C.Number Between 1 and @OrderCount
						and R.OrderNumber = C.number		
			) Y

		Print 'The records for the order date: ' + Cast(@OrderDateKey as nvarchar(8)) + ' has multiplied ' + Cast(@RowMultiplier as nvarchar(6)) + ' times';

		Delete Top(1) From	@OrderCountTable;

	End

Go

Create Clustered Index IX_FactResellerSalesBig_1 On [dbo].[FactResellerSalesBig] ([OrderDateKey] ASC, [ResellerKey] Asc);
GO

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_CurrencyKey] ON [dbo].[FactResellerSalesBig]
(
	[CurrencyKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_DueDateKey] ON [dbo].[FactResellerSalesBig]
(
	[DueDateKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_EmployeeKey] ON [dbo].[FactResellerSalesBig]
(
	[EmployeeKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_ProductKey] ON [dbo].[FactResellerSalesBig]
(
	[ProductKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_PromotionKey] ON [dbo].[FactResellerSalesBig]
(
	[PromotionKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_ShipDateKey] ON [dbo].[FactResellerSalesBig]
(
	[ShipDateKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_FactResellerSalesBig_CarrierTrackingNumber] ON [dbo].[FactResellerSalesBig]
(
	[CarrierTrackingNumber] ASC
);


Create NonClustered Columnstore Index IX_FactResellerSalesBig_NCI On [dbo].[FactResellerSalesBig]
(
[ProductKey]
,[OrderDateKey]
,[DueDateKey]
,[ShipDateKey]
,[ResellerKey]
,[EmployeeKey]
,[PromotionKey]
,[CurrencyKey]
,[SalesTerritoryKey]
,[SalesOrderNumber]
,[SalesOrderLineNumber]
,[RevisionNumber]
,[OrderQuantity]
,[UnitPrice]
,[ExtendedAmount]
,[UnitPriceDiscountPct]
,[DiscountAmount]
,[ProductStandardCost]
,[TotalProductCost]
,[SalesAmount]
,[TaxAmt]
,[Freight]
,[CarrierTrackingNumber]
,[CustomerPONumber]
,[OrderDate]
,[DueDate]
,[ShipDate]
)

GO