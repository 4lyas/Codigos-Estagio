SET SERVEROUTPUT ON;

--Criar as roles padrao para os usuarios de servico xx*
DECLARE CURSOR C_CREATEROLE IS

select t.* from (
select u.username, 'xx' ||SUBSTR(u.username,4)|| 'xxx' role 
  from dba_users u 
    where username like 'xx%'
  union
  select u.username, 'xx' ||SUBSTR(u.username,4)|| 'xxx' role 
    from dba_users u 
      where username like 'xx'    
  union
  select u.username, 'xxx' ||SUBSTR(u.username,4)|| 'xxx' role 
    from dba_users u 
      where username like 'xx%') t    
    where not exists 
    (select 1  from dba_roles d where d.role = t.role );
    
R_CURCREATEROLE C_CREATEROLE%ROWTYPE;

BEGIN

  OPEN C_CREATEROLE;
  
  LOOP
    
    FETCH C_CREATEROLE INTO R_CURCREATEROLE;
    EXIT WHEN C_CREATEROLE%NOTFOUND;
    
		dbms_output.put_line ('CREATE ROLE ' ||  R_CURCREATEROLE.ROLE);
		EXECUTE IMMEDIATE 'CREATE ROLE ' ||  R_CURCREATEROLE.ROLE;
 
   END LOOP;
  CLOSE C_CREATEROLE;
END;
/

--Dropar tabela temporaria de excecoes
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE DBA_IGNORE_TABLE';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

--Criar tabela temporaria de excecoes
CREATE GLOBAL TEMPORARY TABLE DBA_IGNORE_TABLE (
  NAME     VARCHAR(200),
  DATABASE VARCHAR(20),
  OWNER    VARCHAR(100) );

--Insert das excecoes
INSERT INTO DBA_IGNORE_TABLE (NAME, DATABASE, OWNER) VALUES('NAME','DATABASE','OWNER');
INSERT INTO DBA_IGNORE_TABLE (NAME, DATABASE, OWNER) VALUES('NAME','DATABASE','OWNER');
INSERT INTO DBA_IGNORE_TABLE (NAME, DATABASE, OWNER) VALUES('NAME','DATABASE','OWNER');
INSERT INTO DBA_IGNORE_TABLE (NAME, DATABASE, OWNER) VALUES('NAME','DATABASE','OWNER');
INSERT INTO DBA_IGNORE_TABLE (NAME, DATABASE, OWNER) VALUES('NAME','DATABASE','OWNER');

--PL/SQL para conceder os Grants propriamente ditos
DECLARE
 
CURSOR C_GRANTROLE IS
  
  SELECT t.OWNER,t.TABLE_NAME, d.ROLE
    FROM DBA_TABLES t, DBA_ROLES d
      WHERE OWNER LIKE 'XX%'
      AND  d.role like 'XX' ||SUBSTR(t.OWNER,4)|| 'XX'
      AND d.role not like 'XX' ||SUBSTR(t.OWNER,4)|| 'XX%'
      AND NOT EXISTS 
      (SELECT 1
        FROM DBA_TAB_PRIVS WHERE GRANTEE = d.ROLE
           AND OWNER = t.OWNER 
           AND TABLE_NAME = t.TABLE_NAME)
	   AND NOT EXISTS
		(SELECT MVIEW_NAME
		  FROM DBA_MVIEWS 
			WHERE CONTAINER_NAME = t.TABLE_NAME
			AND OWNER = t.OWNER)
	   AND NOT EXISTS
		  (SELECT 1
			  FROM DBA_IGNORE_TABLE i
				WHERE i.NAME = t.TABLE_NAME
				AND i.OWNER = t.OWNER
				AND i.DATABASE in (select name from v$database))  

  UNION
  
   SELECT v.OWNER, v.MVIEW_NAME, d.ROLE 
      FROM DBA_MVIEWS v, DBA_ROLES d
        WHERE v.OWNER LIKE 'XX%' 
        AND d.ROLE like 'XX' ||SUBSTR(v.OWNER,4)|| 'XX%'
		AND NOT EXISTS 
		(SELECT 1
			FROM DBA_TAB_PRIVS WHERE GRANTEE = d.ROLE
			AND OWNER = v.OWNER 
			AND TABLE_NAME = v.MVIEW_NAME)
        AND NOT EXISTS
		(SELECT 1
		   FROM DBA_IGNORE_TABLE i
			WHERE i.NAME = v.MVIEW_NAME
			AND i.OWNER = v.OWNER
			AND i.DATABASE in (select name from v$database))  
  UNION

  SELECT v.OWNER, v.VIEW_NAME, d.ROLE 
      FROM DBA_VIEWS v, DBA_ROLES d
        WHERE v.OWNER LIKE 'XX%' 
        AND d.ROLE like 'XX' ||SUBSTR(v.OWNER,4)|| 'XX%'
		AND NOT EXISTS 
		(SELECT 1
			FROM DBA_TAB_PRIVS WHERE GRANTEE = d.ROLE
			AND OWNER = v.OWNER 
			AND TABLE_NAME = v.VIEW_NAME)
		AND NOT EXISTS
			(SELECT 1
			   FROM DBA_IGNORE_TABLE i
				WHERE i.NAME = v.VIEW_NAME
				AND i.OWNER = v.OWNER
				AND i.DATABASE in (select name from v$database));
        
R_CURGRANTROLE C_GRANTROLE%ROWTYPE;

V_SQL VARCHAR2(1000);

BEGIN

  OPEN C_GRANTROLE;
  
  LOOP
    
    FETCH C_GRANTROLE INTO R_CURGRANTROLE;
    EXIT WHEN C_GRANTROLE%NOTFOUND;
    
	BEGIN
		IF  REGEXP_LIKE (R_CURGRANTROLE.ROLE, 'XX[A-Za-z0-9]*(XX)?XX') THEN 
			  V_SQL := 'GRANT SELECT ON ' || R_CURGRANTROLE.OWNER|| '.'|| R_CURGRANTROLE.TABLE_NAME || ' TO ' || R_CURGRANTROLE.ROLE;
		ELSE
			  V_SQL := 'GRANT INSERT,UPDATE,DELETE ON ' || R_CURGRANTROLE.OWNER|| '.'|| R_CURGRANTROLE.TABLE_NAME || ' TO ' || R_CURGRANTROLE.ROLE;
		END IF;

		dbms_output.put_line(V_SQL);

		EXECUTE IMMEDIATE V_SQL;

	EXCEPTION
		WHEN OTHERS THEN
			dbms_output.put_line('>    Nao foi possivel conceder grant: '|| V_SQL);
			dbms_output.put_line('>    ' || SQLERRM);

	END;
  END LOOP;
  CLOSE C_GRANTROLE;
END;
/