use ReviewDB;
go
SELECT TOP 3 c.City, SUM(p.PremiumAmount) TotalPremium
FROM Customers c
JOIN Policies p ON c.CustomerId=p.CustomerId
GROUP BY c.City
ORDER BY TotalPremium DESC;
