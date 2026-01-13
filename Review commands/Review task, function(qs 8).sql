use ReviewDB
go
CREATE FUNCTION fn_PolicyHealthScore(@PolicyId INT)
RETURNS INT
AS
BEGIN
    DECLARE @Claims INT,@TotalClaim DECIMAL(10,2),@Coverage DECIMAL(10,2)

    SELECT 
        @Claims=COUNT(*),
        @TotalClaim=ISNULL(SUM(ClaimAmount),0)
    FROM Claims WHERE PolicyId=@PolicyId;

    SELECT @Coverage=pt.CoverageAmount
    FROM Policies p JOIN PolicyTypes pt ON p.PolicyTypeId=pt.PolicyTypeId
    WHERE p.PolicyId=@PolicyId;

    RETURN 100 - (@Claims*10) - ((@TotalClaim/@Coverage)*50);
END;
