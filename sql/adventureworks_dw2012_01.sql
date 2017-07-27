USE [AdventureworksDW2012]
GO
--Create a bigger table for DimReseller
SELECT 
		Cast(Row_Number() Over(Order by (Select 0)) as int) As [ResellerKey]
		, A.[GeographyKey]
		, Cast('AW' + Format(Row_Number() Over(Order by (Select 0)), '0000000000') as Nvarchar(15)) As [ResellerAlternateKey]
		, A.[Phone]
		, A.[BusinessType]
		, Cast(A.[ResellerName] +  Format(Row_Number() Over(Order by (Select 0)), ' 0000000000') As nvarchar(50)) As ResellerName
		, A.[NumberEmployees]
		, A.[OrderFrequency]
		, A.[OrderMonth]
		, A.[FirstOrderYear]
		, A.[LastOrderYear]
		, A.[ProductLine]
		, A.[AddressLine1]
		, A.[AddressLine2]
		, A.[AnnualSales]
		, A.[BankName]
		, A.[MinPaymentType]
		, A.[MinPaymentAmount]
		, A.[AnnualRevenue]
		, A.[YearOpened]
Into	DimResellerBig
FROM	[dbo].[DimReseller] A
			Cross Join
		Master..spt_values B
Where	B.Type = 'P'
			And
		B.Number Between 1 and 50
GO


--Add indexes and constraints for DimResellerBig
Alter Table dbo.DimResellerBig Alter Column [ResellerKey] Int Not Null;
GO

ALTER TABLE [dbo].[DimResellerBig] ADD  CONSTRAINT [PK_DimResellerBIG_ResellerKey] PRIMARY KEY CLUSTERED 
(
	[ResellerKey] ASC
);

ALTER TABLE [dbo].[DimResellerBig] ADD  CONSTRAINT [AK_DimResellerBig_ResellerAlternateKey] UNIQUE NONCLUSTERED 
(
	[ResellerAlternateKey] ASC
);

CREATE NONCLUSTERED INDEX [IX_DimResellerBig_GeographyKey] ON [dbo].[DimResellerBig]
(
	[GeographyKey] ASC
);

GO