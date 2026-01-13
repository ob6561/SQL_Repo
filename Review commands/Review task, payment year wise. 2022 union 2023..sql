use ReviewDB;
go

select distinct c.CustomerName
from Customers c
join Policies p on c.CustomerId = p.CustomerId
join Payments pay on p.PolicyId = pay.PolicyId
where year(pay.PaymentDate) = 2022
union
select distinct c.CustomerName
from Customers c
join Policies p on c.CustomerId = p.CustomerId
join Payments pay on p.PolicyId = pay.PolicyId
where year(pay.PaymentDate) = 2023;