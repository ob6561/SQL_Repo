use CustomersDB
go

CREATE TABLE dbo.Claims
(
    ClaimId INT IDENTITY(1,1) PRIMARY KEY,
    PolicyId INT NULL,
    ClaimDate DATE NOT NULL,
    ClaimAmt DECIMAL(18,2) NOT NULL CONSTRAINT CHK_Claims_ClaimAmt_NonNeg CHECK (ClaimAmt >= 0),
    ClaimStatus VARCHAR(3) NOT NULL
);

IF OBJECT_ID('dbo.Policies','U') IS NOT NULL
BEGIN
    DECLARE @Orphans INT = 0;
    DECLARE @sql NVARCHAR(MAX) = N'
        SELECT @o = COUNT(1)
        FROM dbo.Claims c
        LEFT JOIN dbo.Policies p ON c.PolicyId = p.PolicyId
        WHERE c.PolicyId IS NOT NULL AND p.PolicyId IS NULL;';
    EXEC sp_executesql @sql, N'@o INT OUTPUT', @o=@Orphans OUTPUT;

    IF @Orphans = 0
    BEGIN
        EXEC(N'ALTER TABLE dbo.Claims ADD CONSTRAINT FK_Claims_Policies FOREIGN KEY (PolicyId) REFERENCES dbo.Policies(PolicyId);');
        PRINT 'FK_Claims_Policies created.';
    END
    ELSE
    BEGIN
        RAISERROR('Cannot add FK FK_Claims_Policies: %d orphaned PolicyId values exist in dbo.Claims.',16,1,@Orphans);
    END
END
ELSE
BEGIN
    PRINT 'Referenced table dbo.Policies not found; add FK later when it exists.';
END;