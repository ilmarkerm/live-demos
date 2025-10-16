# Unzip 
VAULTHOME=/home/oracle/vault
mkdir -p $VAULTHOME
[ -f "$VAULTHOME/vault" ] || unzip /live-demos/hashicorp-vault-for-oracle-db/vault_1.20.4_linux_arm64.zip vault -d $VAULTHOME

cp /live-demos/hashicorp-vault-for-oracle-db/proxy_config.hcl "$VAULTHOME/"
touch /home/oracle/vault/.roleid
touch /home/oracle/vault/.secretid


su -c "echo '' > /etc/dnf/vars/ociregion"
su -c "dnf install -y vim tcpdump man-db mc tmux"

sqlplus / as sysdba<<EOF
alter session set container=freepdb1;
--create tablespace users datafile '/opt/oracle/oradata/FREE/FREEPDB1/users.dbf' size 100m autoextend on next 10m maxsize 1g;
alter database default tablespace users;
create user demo identified by demo quota unlimited on users;
grant connect,resource,db_developer_role to demo;

begin
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
      host => '127.0.0.1',
      lower_port => 8200,
      ace  =>  xs\$ace_type(privilege_list => xs\$name_list('connect'),
                           principal_name => 'demo',
                           principal_type => xs_acl.ptype_db));
end;
/
commit;

alter session set container=freepdb1;

create user vault identified by vault;

GRANT CREATE USER to vault WITH ADMIN OPTION;
GRANT ALTER USER to vault WITH ADMIN OPTION;
GRANT DROP USER to vault WITH ADMIN OPTION;
GRANT CONNECT to vault WITH ADMIN OPTION;
GRANT CREATE SESSION to vault WITH ADMIN OPTION;
GRANT SELECT on gv_\$session to vault;
GRANT SELECT on v_\$sql to vault;
GRANT ALTER SYSTEM to vault WITH ADMIN OPTION;


create user app1 no authentication;
grant connect,resource to app1;

EOF
