SET LINESIZE 300;
SET PAGESIZE 50000;

WHENEVER SQLERROR EXIT FAILURE;

COLUMN owner HEADING Owner FORMAT a20
COLUMN object_name HEADING View FORMAT a60

SELECT owner, object_name
FROM dba_objects
WHERE object_type = 'VIEW' AND status = 'INVALID' 
AND SUBSTR(owner, 1, 2)='XX' 
AND SUBSTR(owner, 1, 13)<>'XX' 
ORDER BY owner, object_type, object_name;
