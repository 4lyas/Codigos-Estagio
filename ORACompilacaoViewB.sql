BEGIN
  FOR cur_rec IN (SELECT owner,
                         object_name,
                         object_type
                  FROM   dba_objects
                  WHERE  object_type = 'VIEW' AND status != 'VALID'
                  ORDER BY 1, 2)
  LOOP
    BEGIN
      IF LEFT(cur_rec.owner, 1)='U' THEN
      EXECUTE IMMEDIATE 'ALTER ' || cur_rec.object_type || 
            ' "' || cur_rec.owner || '"."' || cur_rec.object_name || '" COMPILE';
    END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line(cur_rec.object_type || ' : ' || cur_rec.owner || 
                             ' : ' || cur_rec.object_name);
    END;
  END LOOP;
END;