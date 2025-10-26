alter session set container=freepdb1;
--create tablespace users datafile '/opt/oracle/oradata/FREE/FREEPDB1/users.dbf' size 100m autoextend on next 10m maxsize 1g;
alter database default tablespace users;
create user demo identified by demo quota unlimited on users;
grant connect,resource,db_developer_role to demo;

begin
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
      host => '127.0.0.1',
      lower_port => 8200,
      ace  =>  xs$ace_type(privilege_list => xs$name_list('connect'),
                           principal_name => 'demo',
                           principal_type => xs_acl.ptype_db));
end;
/
commit;
