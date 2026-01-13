use ReviewDB
go
CREATE VIEW vw_PolicyFinance AS
SELECT 
    p.PolicyId,
    c.CustomerName,
    ISNULL(SUM(pay.Amount),0) TotalPaid,
    ISNULL(SUM(cl.ClaimAmount),0) TotalClaimed,
    ISNULL(SUM(pay.Amount),0) - ISNULL(SUM(cl.ClaimAmount),0) BalanceAmount
FROM Policies p
JOIN Customers c ON p.CustomerId=c.CustomerId
LEFT JOIN Payments pay ON p.PolicyId=pay.PolicyId
LEFT JOIN Claims cl ON p.PolicyId=cl.PolicyId
GROUP BY p.PolicyId,c.CustomerName;

