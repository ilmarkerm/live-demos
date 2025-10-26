alter session set container=freepdb1;

create user vault identified by vault;
alter user vault identified by vault;

GRANT CREATE USER to vault WITH ADMIN OPTION;
GRANT ALTER USER to vault WITH ADMIN OPTION;
GRANT DROP USER to vault WITH ADMIN OPTION;
GRANT CONNECT to vault WITH ADMIN OPTION;
GRANT CREATE SESSION to vault WITH ADMIN OPTION;
GRANT SELECT on gv_$session to vault;
GRANT SELECT on v_$sql to vault;
GRANT ALTER SYSTEM to vault WITH ADMIN OPTION;


create user app1 no authentication;
grant connect,resource to app1;
