EXEC sp_MSforeachdb '
Declare @CMD VARCHAR (MAX)=''''

print ''-- ?''
select @CMD = @CMD 	+ ''ALTER USER '' +quotename (name)+'' WITH NAME = ''+ quotename (REPLACE (NAME,''\'',''''))+'';'' + CHAR(13)
from sysusers where name like ''%'' and ''?'' not in ('''','''',''','''')
PRINT @CMD
EXEC @CMD'
