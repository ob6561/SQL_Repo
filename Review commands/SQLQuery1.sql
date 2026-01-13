use EmployeeProjectsDB;
GO
create or alter procedure sp_AllocateEmployeeProject
	@EmpId int,
	@ProjectId int,
	@Hours int
as
begin
	set NOCOUNT on;
	begin try
		begin transaction;
		if @Hours<=0 or @Hours>60
			throw 50001, 'Hours must be between 1 and 60',1;
		if exists(
			select 1
			from EmployeeProjectAllocation
			where EmpId=@EmpId and ProjectId=@ProjectId
		)
		begin
			update EmployeeProjectAllocation
			set Hours=@Hours
			where EmpId=@EmpId and ProjectId=@ProjectId;
		end
		else
		begin
			insert into EmployeeProjectAllocation(EmpId,ProjectId,Hours)
			values(@EmpId,@ProjectId,@Hours);
		end
		commit transaction;
	end try
	begin catch
		rollback transaction;
		throw;
	end catch
end
GO