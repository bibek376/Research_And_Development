



-------------------------------------------------------------------------
--Main Table

CREATE TABLE users(
  id    int PRIMARY KEY,
  email VARCHAR(40) NOT NULL
);

select * from users u ;

-----------------------------------------------------------------------------

--Log Table

CREATE TABLE tbl_LoggedTransactions 
(
	SchemaName CHARACTER VARYING
	,TableName CHARACTER VARYING
	,UserName CHARACTER VARYING    
	,DMLAction CHARACTER VARYING
	,OriginalData TEXT
	,ExecutedNewData TEXT
	,ExecutedSQL TEXT
	,RecordDateTime TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

select * from tbl_LoggedTransactions;

------------------------------------------------------------------------------
--DML Audit Logic 

CREATE OR REPLACE FUNCTION trg_AuditDML() 
RETURNS TRIGGER 
AS $BODY$
DECLARE
    OldData TEXT;
    NewData TEXT;
BEGIN 
 
    IF (TG_OP = 'UPDATE') THEN
        OldData := ROW(OLD.*);
        NewData := ROW(NEW.*);
        INSERT INTO tbl_LoggedTransactions 
	(
		SchemaName
		,TableName
		,UserName
		,DMLAction
		,OriginalData
		,ExecutedNewData
		,ExecutedSQL
	) 
        VALUES 
	(
		TG_TABLE_SCHEMA::TEXT
		,TG_TABLE_NAME::TEXT
		,session_user::TEXT
		,substring(TG_OP,1,1)
		,OldData
		,NewData
		,current_query()
	);
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        OldData := ROW(OLD.*);
        INSERT INTO tbl_LoggedTransactions 
	(
		SchemaName
		,TableName
		,UserName
		,DMLAction
		,OriginalData
		,ExecutedSQL
	)
        VALUES 
	(
		TG_TABLE_SCHEMA::TEXT
		,TG_TABLE_NAME::TEXT
		,session_user::TEXT
		,substring(TG_OP,1,1)
		,OldData
		,current_query()
	);
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        NewData := ROW(NEW.*);
        INSERT INTO tbl_LoggedTransactions 
	(
		SchemaName
		,TableName
		,UserName
		,DMLAction
		,ExecutedNewData
		,ExecutedSQL
	)
        VALUES 
	(
		TG_TABLE_SCHEMA::TEXT
		,TG_TABLE_NAME::TEXT
		,session_user::TEXT
		,substring(TG_OP,1,1)
		,NewData
		,current_query()
	);
        RETURN NEW;
    ELSE
        RAISE WARNING '[AuditTable.trg_AuditDML] - Other action occurred: %, at %',TG_OP,now();
        RETURN NULL;
    END IF;
END;
$BODY$
LANGUAGE plpgsql;


------------------------------------------------------------------------------------------------
--Dynamic Audit Logic

CREATE OR REPLACE FUNCTION public.delete_dynamic_master_data(source VARCHAR)
 RETURNS VARCHAR
 LANGUAGE plpgsql
AS $function$
DECLARE
    tablename    VARCHAR;
    dynamicQuery VARCHAR;
BEGIN
  dynamicQuery ='CREATE TRIGGER tt BEFORE INSERT OR UPDATE OR DELETE ON ' || source ||
' FOR EACH ROW EXECUTE PROCEDURE trg_AuditDML()';
EXECUTE dynamicQuery;
    RETURN 'success';
END;
$function$
;


--------------------------------------------------------------------------------------------------------


SELECT * FROM tbl_LoggedTransactions; 

drop sequence user_mysequence;

------------------------------------------------------------------------------------
--Sequence creation For Fake Data
CREATE SEQUENCE user_mysequence  
INCREMENT 1  
MINVALUE 1   
MAXVALUE 10000000 
START 1 
CYCLE; 

----------------------------------------------------------------------------------------
--Initialize a trigger for users table

select * from delete_dynamic_master_data('users');

----------------------------------------------------------------------------------

select * from users;


----------------------------------------------------------------------------------

--Insert a Data Into Users Table

INSERT INTO users(id,email)
select 
		nextval('user_mysequence'),
  'user_' || seq || '@' || (
    CASE (RANDOM() * 2)::INT
      WHEN 0 THEN 'gmail'
      WHEN 1 THEN 'hotmail'
      WHEN 2 THEN 'yahoo'
    END
  ) || '.com' AS email
FROM GENERATE_SERIES(1, 10000) seq;


--------------------------------------------------------------------------------------
--Trigger Verification

SELECT * FROM tbl_LoggedTransactions; 

------------------------------------------------------------------------------------

SELECT * FROM tbl_LoggedTransactions
where dmlaction ='U'; 

----------------------------------------------------------------------------

--Let's Update a Data For   

update users 
set email='Bibek12@gmail.com'
from users u join (select 
  'user_' || seq || '@' || (
    CASE (RANDOM() * 2)::INT
      WHEN 0 THEN 'gmail'
    END
  ) || '.com' AS email
FROM GENERATE_SERIES(1, 10000) seq) tt 
on u.email=tt.email and u.email is not null
where users.email=u.email;

select * from tbl_LoggedTransactions
where dmlaction='U';

---------------------------------------------------------------------------------

--Let's Delete Data From Users Table

delete from users u using(select 
  'user_' || seq || '@' || (
    CASE (RANDOM() * 2)::INT
      WHEN 0 THEN 'gmail'
    END
  ) || '.com' AS email
FROM GENERATE_SERIES(1, 10000) seq) tt 
where u.email=tt.email and u.email is not null;
















