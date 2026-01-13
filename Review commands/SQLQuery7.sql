use CustomersDB;
go
CREATE OR ALTER PROCEDURE dbo.usp_InsertClaim
    @PolicyId INT,
    @ClaimDate DATE,
    @ClaimAmt DECIMAL(18,2),
    @ClaimStatus VARCHAR(3) = NULL,
    @NewClaimId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('dbo.Policies','U') IS NULL
    BEGIN
        RAISERROR('Required table dbo.Policies does not exist.',16,1);
        RETURN -1;
    END

    IF OBJECT_ID('dbo.PolicyTypes','U') IS NULL
    BEGIN
        RAISERROR('Required table dbo.PolicyTypes does not exist.',16,1);
        RETURN -1;
    END

    IF OBJECT_ID('dbo.Claims','U') IS NULL
    BEGIN
        RAISERROR('Required table dbo.Claims does not exist.',16,1);
        RETURN -1;
    END

    DECLARE @hasStatus BIT =
        CASE WHEN EXISTS (
            SELECT 1
            FROM sys.columns
            WHERE object_id = OBJECT_ID('dbo.Policies')
              AND name = 'PolicyStatus'
        ) THEN 1 ELSE 0 END;

    DECLARE @hasDates BIT =
        CASE WHEN EXISTS (
            SELECT 1
            FROM sys.columns
            WHERE object_id = OBJECT_ID('dbo.Policies')
              AND name IN ('StartDate','EndDate')
        ) THEN 1 ELSE 0 END;

    DECLARE
        @PolicyTypeId INT,
        @PolicyStatus VARCHAR(200),
        @StartDate DATE,
        @EndDate DATE,
        @CoverageAmount DECIMAL(18,2),
        @MaxClaimsAllowed INT,
        @CurrentClaims INT = 0,
        @StartDateStr VARCHAR(10),
        @EndDateStr VARCHAR(10),
        @ClaimAmtStr VARCHAR(30),
        @CoverageAmtStr VARCHAR(30),
        @ErrMsg NVARCHAR(4000);

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX) = N'SELECT @PolicyTypeId = PolicyTypeId';
        DECLARE @params NVARCHAR(4000) = N'@pId INT, @PolicyTypeId INT OUTPUT';

        IF @hasStatus = 1
        BEGIN
            SET @sql += N', @PolicyStatus = PolicyStatus';
            SET @params += N', @PolicyStatus VARCHAR(200) OUTPUT';
        END

        IF @hasDates = 1
        BEGIN
            SET @sql += N', @StartDate = StartDate, @EndDate = EndDate';
            SET @params += N', @StartDate DATE OUTPUT, @EndDate DATE OUTPUT';
        END

        SET @sql += N' FROM dbo.Policies WHERE PolicyId = @pId;';

        EXEC sp_executesql
            @sql, @params,
            @pId = @PolicyId,
            @PolicyTypeId = @PolicyTypeId OUTPUT,
            @PolicyStatus = @PolicyStatus OUTPUT,
            @StartDate = @StartDate OUTPUT,
            @EndDate = @EndDate OUTPUT;

        IF @PolicyTypeId IS NULL
        BEGIN
            RAISERROR('Policy %d not found.',16,1,@PolicyId);
            ROLLBACK;
            RETURN -1;
        END

        IF @hasDates = 1
        BEGIN
            IF @StartDate IS NOT NULL AND @ClaimDate < @StartDate
            BEGIN
                SET @StartDateStr = CONVERT(VARCHAR(10), @StartDate, 120);
                RAISERROR(
                    'Policy %d is not yet effective (StartDate: %s).',
                    16,1,
                    @PolicyId,
                    @StartDateStr
                );
                ROLLBACK;
                RETURN -1;
            END

            IF @EndDate IS NOT NULL AND @ClaimDate > @EndDate
            BEGIN
                SET @EndDateStr = CONVERT(VARCHAR(10), @EndDate, 120);
                RAISERROR(
                    'Policy %d has expired (EndDate: %s).',
                    16,1,
                    @PolicyId,
                    @EndDateStr
                );
                ROLLBACK;
                RETURN -1;
            END
        END

        SELECT
            @CoverageAmount = TRY_CAST(CoverageAmount AS DECIMAL(18,2)),
            @MaxClaimsAllowed = MaxClaimsAllowed
        FROM dbo.PolicyTypes
        WHERE PolicyTypeId = @PolicyTypeId;

        IF @ClaimAmt > @CoverageAmount
        BEGIN
            SET @ClaimAmtStr = CONVERT(VARCHAR(30), @ClaimAmt);
            SET @CoverageAmtStr = CONVERT(VARCHAR(30), @CoverageAmount);
            RAISERROR(
                'Claim amount (%s) exceeds coverage (%s) for PolicyTypeId %d.',
                16,1,
                @ClaimAmtStr,
                @CoverageAmtStr,
                @PolicyTypeId
            );
            ROLLBACK;
            RETURN -1;
        END

        SELECT @CurrentClaims = COUNT(1)
        FROM dbo.Claims
        WHERE PolicyId = @PolicyId;

        IF @MaxClaimsAllowed IS NOT NULL AND @CurrentClaims >= @MaxClaimsAllowed
        BEGIN
            RAISERROR(
                'Policy %d already has %d claims; MaxClaimsAllowed = %d.',
                16,1,
                @PolicyId,
                @CurrentClaims,
                @MaxClaimsAllowed
            );
            ROLLBACK;
            RETURN -1;
        END

        INSERT INTO dbo.Claims (PolicyId, ClaimDate, ClaimAmt, ClaimStatus)
        VALUES (@PolicyId, @ClaimDate, @ClaimAmt, @ClaimStatus);

        SET @NewClaimId = SCOPE_IDENTITY();
        COMMIT;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        SET @ErrMsg = ERROR_MESSAGE();
        RAISERROR('InsertClaim failed: %s',16,1,@ErrMsg);
        RETURN -1;
    END CATCH
END;
GO
