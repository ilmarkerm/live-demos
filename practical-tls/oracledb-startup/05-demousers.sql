alter session set container=freepdb1;

create user if not exists demo identified by demo123 quota unlimited on users;
grant connect,resource to demo;

create table if not exists demo.hello_world (
    id number primary key,
    message varchar2(100)
);

begin
    insert into demo.hello_world (id, message) values (1, 'This is a regular password authenticated database user.');
    commit;
exception when DUP_VAL_ON_INDEX then
    null;
end;
/

create user if not exists demouser1
    identified externally as 'CN=demouser1'
    quota unlimited on users;
grant connect,resource to demouser1;

create table if not exists demouser1.hello_world (
    id number primary key,
    message varchar2(100)
);

begin
    insert into demouser1.hello_world (id, message) values (1, 'This is a mTLS authenticated database user.');
    commit;
exception when DUP_VAL_ON_INDEX then
    null;
end;
/
