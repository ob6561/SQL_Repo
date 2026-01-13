use ReviewDB
go
CREATE TRIGGER trg_HighRiskPolicy
ON Claims
AFTER INSERT
AS
BEGIN
    UPDATE Policies
    SET RiskFlag='HIGH_RISK'
    WHERE PolicyId IN (
        SELECT i.PolicyId
        FROM inserted i
        JOIN Policies p ON i.PolicyId=p.PolicyId
        JOIN PolicyTypes pt ON p.PolicyTypeId=pt.PolicyTypeId
        GROUP BY i.PolicyId,pt.MaxClaimsAllowed
        HAVING COUNT(*) > pt.MaxClaimsAllowed
    );
END;
