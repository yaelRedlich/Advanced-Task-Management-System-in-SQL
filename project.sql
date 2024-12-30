use TaskManagement
use TasksManagementProject

select * from tbl_tasks

create database TasksManagementProjectY
create  table tbl_users
(
userId int identity primary key not null,
userName nvarchar (30) not null,
password nvarchar (30) not null,
managerID int foreign key references tbl_users (userId)
)
create table tbl_taskStatus 
(
statusId int  identity primary key not null,
statusName nvarchar (30)
)
create table tbl_tasks
(
taskId int identity primary key not null,
TaskCreationDate date,
taskContent nvarchar (3000),
taskCreator int foreign key references tbl_users (userId),
taskOperator int foreign key references tbl_users (userId),
taskStatus int foreign key references tbl_taskStatus  (statusId),
DateOfStatusChange date,
taskFather int
)

use TaskManagement
insert into tbl_users  (userName,password,managerID) values ('yael','327804233',4)

ALTER TABLE tbl_tasks
ADD taskFather int

update tbl_tasks set taskFather=8 where taskId=14

select *
from  tbl_tasks

 INSERT INTO tbl_tasks (TaskCreationDate, taskContent, taskCreator, taskOperator, taskStatus, DateOfStatusChange,taskFather)
VALUES ('2024-03-23', ' try', 1, 6, 2, '2023-03-26',30)

select *
from tbl_taskStatus
insert into tbl_taskStatus (statusName) values ('בוטל')

---------------------------------------------------------1---------------------------------------------------------
-- פונקציה לזיהוי משתמש
-- userIDהפונקציה בודקת האם קיים משתמש עם השם הזה בטבלה אם כן היא מכניסה למשתמש את ה
--אח"כ אני בוקדת האם המשתמש ריק אם הוא ריק זה אומר של א נמצא כזה משתמש ומחזירה 0 
alter FUNCTION UserID (@name NVARCHAR(30), @password nvarchar (30))
RETURNS INT
AS
BEGIN
    DECLARE @userID INT;
    select @userID = userID
    from tbl_users
    where userName = @name;

    if @userID IS NULL
    begin
        RETURN 0;
    end
    else
    BEGIN
	DECLARE @pass nvarchar (30);
        select @pass= password
		from tbl_users
		where userId=@userID
		if @pass!=@password
		return -1
		else
		return @userID
    END
	return 0
END;

select dbo.UserID ('יוסי','123456')

select *
from tbl_users 

---------------------------------------------------------2---------------------------------------------------------
--עובדים כפוכים
--עזרת רקורסיה
alter FUNCTION  subordinateEmployee( @id int )
RETURNS TABLE
as
return
with Employees
as(
select *
from tbl_users
where managerID=@id and managerID is not NULL
union all
select u.*
from tbl_users as u
join Employees as e on e.managerID=u.userId
)
select *
from Employees
WHERE userId <> @id AND managerID is not NULL

SELECT *
FROM dbo.subordinateEmployee(2);

select *
from tbl_users
---------------------------------------------------------3---------------------------------------------------------
--פונקציה לשליפת משימה וכל תתי המשימות שלה
create  FUNCTION TasksAndSubtask (@id int)
RETURNS TABLE
as 
return
with taks
as
(
select *
from tbl_tasks
where taskFather=@id
union all
select t.*
from tbl_tasks as t
join taks on t.taskFather=taks.taskId
)
select *
from taks


select * from dbo.TasksAndSubtask(2)
---------------------------------------------------------4---------------------------------------------------------
--פונקציה לשליפת אבות משימה
create  FUNCTION tasksFather (@id int) 
RETURNS TABLE
as 
return
with task
as
(
select *
from tbl_tasks
where taskId=@id
union all
select t.*
from tbl_tasks as t
join task as ta on t.taskId=ta.taskFather
)
select *
from task

select *
from tasksFather(5)
exec taskFather 5

---------------------------------------------------------5---------------------------------------------------------
--פרוצדורת שינוי סטטוס למשימה

create proc updateStatus @idStatus int ,@id int
as
update tbl_tasks set taskStatus=@idStatus,DateOfStatusChange=GETDATE() where taskId=@id

exec updateStatus 3,14

select *
from tbl_tasks
---------------------------------------------------------6---------------------------------------------------------
alter trigger afterUpdateStatus
on tbl_tasks
after update 
as 
begin 
DECLARE @exit int ,@id int
select @id=taskFather
FROM deleted
select @exit =taskId
from tbl_tasks
where taskFather=@id and taskStatus!=3
if
@exit is null
exec updateStatus 3,@id
end

select *
from tbl_tasks

update tbl_tasks set taskStatus=3 where taskId=33
---------------------------------------------------------7---------------------------------------------------------
-- פרוצדורת הוספה לטבלת משימות
alter proc addTask @taskDate date,@taskContent nvarchar (3000),@taskCreator int,@taskOpearator int ,@taskFather int
as
BEGIN
    DECLARE @exit  INT
    SELECT @exit = userId
    FROM dbo.subordinateEmployee (@taskCreator)
    WHERE userId=@taskOpearator or userId=@taskCreator
	if
    @exit is null 
	throw 50000, 'העובד לא כפוף למנהל',1
	else
	insert into tbl_tasks (TaskCreationDate,taskContent,taskCreator, taskOperator,taskStatus,taskFather)
    values (@taskDate,@taskContent,@taskCreator,@taskOpearator,1,@taskFather)
END

exec addTask '2024-03-22','לקרוא לטכנאי מחשבים',1,2,null

select *
from tbl_tasks
---------------------------------------------------------8---------------------------------------------------------
--פרוצדורה להוספת משימות כלליות
--מעבר בסממן על כל העובדים של המנהל 
--ושליחה לפרצדורה שמבצעת הוספת משימה חדשה 
alter proc AddingGeneralTask @id int,@taskContent nvarchar (3000)
as
begin 
DECLARE @idWorker int
DECLARE @datee date
SET @datee = '2024-03-22'
begin transaction
begin try
DECLARE Add_CURSOR CURSOR FOR
select userId
from tbl_users
where managerID=@id
open Add_CURSOR
FETCH NEXT FROM Add_CURSOR INTO @idWorker
WHILE @@FETCH_STATUS = 0
BEGIN
print @idWorker
EXEC addTask @datee, @taskContent, @id, @idWorker, NULL
FETCH NEXT FROM Add_CURSOR INTO @idWorker
	end
	CLOSE Add_CURSOR
DEALLOCATE Add_CURSOR
 commit
    end try
    begin catch
	print @@ERROR 
        rollback
    end catch
end

exec AddingGeneralTask 50,'להגיש דו"ח שעות'

select *
from tbl_tasks
delete from tbl_tasks
where taskId=16 or taskId=17 or taskId=20 or taskId=21 or taskId=22

update tbl_users set managerID=5 where userId=4

select userId
from tbl_users
where managerID=1
---------------------------------------------------------9---------------------------------------------------------
--טריגר למחיקת משימות ישנות
--מספור שורות לפי מבצע המשימה ומיון עפ"י תאריך  וסינון רק למי שהטסטוס שלו בוצע 
--אז לצבע מחיקה לכל מי שהמספר של גדול מ3 
go
alter VIEW OldTasks
AS
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY taskOperator ORDER BY DateOfStatusChange desc) AS RowNumber
FROM tbl_tasks
WHERE taskStatus = 3;

select *
from tbl_tasks

go
alter trigger DeletingOldTasks
on tbl_tasks
after insert
as 
begin 
delete from OldTasks where RowNumber>3
end
---------------------------------------------------------10---------------------------------------------------------
--ןין המציג סיגום מישימות לפי סטטוסים


---------------------------------------------------------11---------------------------------------------------------
--שלחה לפונקציה שבודקת האם השם והססימא תקינים אם אכן הם תקינים יוצג הסימון המבוקש לפני התאנים הנדרשים


alter FUNCTION taskCase (@name NVARCHAR(30), @password nvarchar(30))
RETURNS table
AS
RETURN 
(
    SELECT *,
        CASE

		   WHEN taskStatus = 3 THEN 'v'
            WHEN taskStatus = 4 THEN 'x'
            WHEN (taskStatus = 1 OR (taskStatus = 2 AND DATEDIFF(month, DateOfStatusChange, GETDATE()) > 1 AND DATEDIFF(month, DateOfStatusChange, GETDATE()) < 3)) THEN '!'
            WHEN (taskStatus = 2 AND DATEDIFF(month, DateOfStatusChange, GETDATE()) > 3) THEN '!!!'
            WHEN (taskStatus = 1 AND DATEDIFF(month, DateOfStatusChange, GETDATE()) > 3) THEN '!!!'
			else '!'
        END AS Situation
    FROM tbl_tasks
    WHERE dbo.UserID(@name, @password) NOT IN (0, -1) and taskOperator=dbo.UserID(@name, @password)
)

select * from dbo.taskCase ('יוסי','123456')
select * from tbl_taskStatus

select *
from tbl_taskStatus

SELECT DATEDIFF(month, '2022-05-15', '2022-06-16') AS MonthDifference

