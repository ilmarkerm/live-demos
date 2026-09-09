alter session set container=freepdb1;

create user if not exists demo identified by demo123 quota unlimited on users;
grant connect,resource to demo;

create table if not exists demo.hello_world (
    id number primary key,
    message varchar2(40)
);
