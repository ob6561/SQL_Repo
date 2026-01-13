use ReviewDB;
go
SELECT c.RiskCategory, SUM(cl.ClaimAmount) TotalClaims
FROM Customers c
JOIN Policies p ON c.CustomerId=p.CustomerId
JOIN Claims cl ON p.PolicyId=cl.PolicyId
GROUP BY c.RiskCategory;

