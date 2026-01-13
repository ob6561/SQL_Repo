use ReviewDB;
go
SELECT CustomerName
FROM Customers c
WHERE EXISTS (
    SELECT 1 FROM Payments p JOIN Policies po ON p.PolicyId=po.PolicyId
    WHERE po.CustomerId=c.CustomerId AND YEAR(p.PaymentDate)=2022
)
AND EXISTS (
    SELECT 1 FROM Payments p JOIN Policies po ON p.PolicyId=po.PolicyId
    WHERE po.CustomerId=c.CustomerId AND YEAR(p.PaymentDate)=2023
);
