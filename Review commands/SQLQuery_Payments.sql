use CustomersDB
go

CREATE TABLE dbo.Payments
(
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,
    PolicyId INT NULL,
    PaymentDate DATE NOT NULL,
    PaymentAmt DECIMAL(18,2) NOT NULL CONSTRAINT CHK_Payments_PaymentAmt_NonNeg CHECK (PaymentAmt >= 0),
    PaymentMode VARCHAR(3) NOT NULL
);


IF OBJECT_ID('dbo.Policies','U') IS NOT NULL
BEGIN
    DECLARE @Orphans INT = 0;
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT @o = COUNT(1)
        FROM dbo.Payments pay
        LEFT JOIN dbo.Policies p ON pay.PolicyId = p.PolicyId
        WHERE pay.PolicyId IS NOT NULL AND p.PolicyId IS NULL;';
    EXEC sp_executesql @sql, N'@o INT OUTPUT', @o=@Orphans OUTPUT;

    IF @Orphans = 0
    BEGIN
        EXEC(N'ALTER TABLE dbo.Payments ADD CONSTRAINT FK_Payments_Policies FOREIGN KEY (PolicyId) REFERENCES dbo.Policies(PolicyId);');
        PRINT 'FK_Payments_Policies created.';
    END
    ELSE
    BEGIN
        RAISERROR('Cannot add FK FK_Payments_Policies: %d orphaned PolicyId values exist in dbo.Payments.',16,1,@Orphans);
    END
END

ELSE

BEGIN
    PRINT 'Referenced table dbo.Policies not found; add FK later when it exists.';
END;