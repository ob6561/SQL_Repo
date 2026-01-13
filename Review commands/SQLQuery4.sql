use CustomersDB
go
CREATE TABLE dbo.Policies
(
    PolicyId INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId INT NOT NULL,
    PolicyTypeId INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    PremiumAmt DECIMAL(18,2) NOT NULL,
    PolicyStatus VARCHAR(3) NOT NULL,
    CONSTRAINT FK_Policies_Customers FOREIGN KEY (CustomerId) REFERENCES dbo.Customers(CustomerId),
    CONSTRAINT FK_Policies_PolicyTypes FOREIGN KEY (PolicyTypeId) REFERENCES dbo.PolicyTypes(PolicyTypeId),
    CONSTRAINT CHK_Policies_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
);