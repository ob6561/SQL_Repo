use ReviewDB
go
CREATE TRIGGER trg_PreventPolicyDelete
ON Policies
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Claims c
        JOIN deleted d ON c.PolicyId=d.PolicyId
        WHERE c.ClaimStatus='APPROVED'
    )
    BEGIN
        RAISERROR('Cannot delete policy with approved claims',16,1);
        RETURN;
    END
    DELETE FROM Policies WHERE PolicyId IN (SELECT PolicyId FROM deleted);
END;
