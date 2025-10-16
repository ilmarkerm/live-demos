# Secure secrets management for Oracle Databases using HashiCorp Vault

Ilmar Kerm 2025 ilmar@ilmarkerm.eu https://ilmarkerm.eu

# Setup

vault:
```sh
export PS1="[\u@\h \W (vault)]\\$ "
vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200 -config /live-demos/hashicorp-vault-for-oracle-db/server_config.hcl

cd /live-demos/hashicorp-vault-for-oracle-db/terraform
terraform apply -no-color
```

Database:
```sh
export PS1="[\u@\h \W (database)]\\$ "
```


# DEMO: plugins, tokens

Do setup also.

vault:
```sh
# NB! oracle is not yet here, need to register it first
vault plugin list|less

less /live-demos/hashicorp-vault-for-oracle-db/terraform/backend.tf

vault auth list
vault list auth/approle/role/
# Get approle properties
vault read auth/approle/role/demo-proxy
# Get role_id for approle
vault read -field=role_id auth/approle/role/demo-proxy/role-id

# Generate secret-id (can be multiple) for the same role-id
# This will create a new ACCESSOR for this approle
# NB! Multiple times
vault write -field=secret_id -f auth/approle/role/demo-proxy/secret-id
vault write -field=secret_id -f auth/approle/role/demo-proxy/secret-id

# List accessors for role
vault list auth/approle/role/demo-proxy/secret-id
# Information about an accessor
vault write auth/approle/role/demo-proxy/secret-id-accessor/lookup secret_id_accessor=
```

# DEMO: proxy

vault:
```sh
vault read -field=role_id auth/approle/role/demo-proxy/role-id
vault write -field=secret_id -f auth/approle/role/demo-proxy/secret-id
```

database:
```sh
export PS1="[\u@\h \W (database)]\\$ "
cd /home/oracle/vault

less proxy_config.hcl
echo "" > .roleid
echo "" > .secretid

# NEW TAB
# Do request via proxy and show the token
export PS1="[\u@\h \W (database)]\\$ "
export VAULT_ADDR=http://localhost:8200
unset VAULT_TOKEN

/home/oracle/vault/vault token lookup
```

# DEMO: Secret engines

vault:
```sh
clear
vault secrets list

vault secrets enable -path=demokv -description="Secrets for HROUG demo" -version=2 kv
vault secrets list

# Write secret
vault kv put "demokv/oracle/demodb/deployment" "username=c##deployment" "password=correct horse battery staple"

# Read secret
vault kv get demokv/oracle/demodb/deployment

# In JSON format
export VAULT_FORMAT=json
vault kv get demokv/oracle/demodb/deployment
```

Show GUI! And show created secret in GUI.

Database:
```sh
clear
curl -X GET http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment | python -m json.tool
```

SQL Developer:
NB! Proxy running on database host, connecting locally to Proxy that will silently add token to each request.
```sql
select json_query(
    HttpUriType('http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment').getClob(),
    '$.data.data' returning json);

SELECT json_query(
    JSON(
        HttpUriType('http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment').getClob()
    )
, '$' RETURNING clob PRETTY);

-- Creating a new secret
DECLARE
    req   UTL_HTTP.REQ;
    resp  UTL_HTTP.RESP;
    the_url varchar2(200):= 'http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/newsecret';
    value varchar(4000);
BEGIN
    value:= '{"data": {"secret_key": "ABC1234"},"options": {},"version": 0}';
    req := UTL_HTTP.BEGIN_REQUEST (url=>the_url, method=>'POST');
    UTL_HTTP.SET_HEADER (r      =>  req, 
                        name   =>  'Content-Type',
                        value  =>  'application/json');
    UTL_HTTP.SET_HEADER (r      =>  req,
                        name   =>  'Content-Length', -- Required header, otherwise get 400 "no data provided"
                        value  =>  to_char(length(value)));
    UTL_HTTP.WRITE_TEXT (r      =>   req, 
                        data   =>   value);
    resp := UTL_HTTP.GET_RESPONSE 
                        (r     =>   req);
    dbms_output.put_line(resp.status_code);
    UTL_HTTP.READ_LINE(resp, value, TRUE);
    DBMS_OUTPUT.PUT_LINE(value);
    UTL_HTTP.END_RESPONSE(resp);
end;
/

select json_query(
    HttpUriType('http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/newsecret').getClob(),
    '$.data.data' returning json);
```

# DEMO: Database accounts

vault:
Just show, do not perform.
```sh
# NB! Does not work on Alpine Linux (the default Vault docker image), because Instantclient does not run there
# Instantclient needs to be installed, with header files
# oracle-instantclient19.28-basic-19.28.0.0.0-1.el9.aarch64.rpm
# oracle-instantclient19.28-devel-19.28.0.0.0-1.el9.aarch64.rpm
# GO 1.25.2
cd /root

echo <<EOF
version=19.28
build=client64

libdir=/usr/lib/oracle/\${version}/client64/lib
includedir=/usr/include/oracle/\${version}/client64

Name: oci8
Description: Oracle database engine
Version: \${version}
Libs: -L\${libdir} -lclntsh
Libs.private:
Cflags: -I\${includedir}
EOF > /live-demos/hashicorp-vault-for-oracle-db/oci8.pc

rm -rf /usr/local/go && tar -C /usr/local -xzf /live-demos/go1.25.2.linux-arm64.tar.gz

git clone https://github.com/hashicorp/vault-plugin-database-oracle.git
cd vault-plugin-database-oracle
export PKG_CONFIG_PATH=/live-demos/hashicorp-vault-for-oracle-db
/usr/local/go/bin/go build -o vault-plugin-database-oracle ./plugin
mkdir -p /root/vault-plugins
mv vault-plugin-database-oracle /root/vault-plugins/
```

database (do not perform):
```sql
alter session set container=freepdb1;
CREATE USER vault IDENTIFIED BY vault;
GRANT CREATE USER to vault WITH ADMIN OPTION;
GRANT ALTER USER to vault WITH ADMIN OPTION;
GRANT DROP USER to vault WITH ADMIN OPTION;
GRANT CONNECT to vault WITH ADMIN OPTION;
GRANT CREATE SESSION to vault WITH ADMIN OPTION;
GRANT SELECT on gv_$session to vault;
GRANT SELECT on v_$sql to vault;
GRANT ALTER SYSTEM to vault WITH ADMIN OPTION;
```

vault (register oracle plugin):
```sh
export VAULT_ADDR=http://127.0.0.1:8200
unset VAULT_FORMAT

clear
sha256sum /root/vault-plugins/vault-plugin-database-oracle
vault plugin register -sha256=3a59f4351f98c11d9d609744b76abd8b584c37a559441aed34544e84313933a3 database vault-plugin-database-oracle
vault plugin list | grep oracle

vault secrets enable database
vault secrets list
```

vault (Create database connection):
```sh
vault write database/config/oracle \
    plugin_name=vault-plugin-database-oracle \
    allowed_roles="*" \
    connection_url='{{username}}/{{password}}@//172.17.0.3:1521/freepdb1' \
    username='vault' \
    password='vault'

# When "logon denied", reset vault password back to default
alter user vault identified by vault;

# Rotate root password immediately
vault write -force database/rotate-root/oracle
```

Show connection in GUI.

vault (create database role for application "app1"):
```sh
# TTL - application would need to be restarted before it expires to fetch new credentials
# Because on expiration Vault would kill sessions and drop the temporary user
vault write database/roles/app1 \
    db_name=oracle \
    creation_statements='CREATE USER {{username}} IDENTIFIED BY "{{password}}"; GRANT CREATE SESSION TO {{username}}; ALTER USER app1 GRANT CONNECT THROUGH {{username}};' \
    default_ttl="7d" \
    max_ttl="10d"
```

Show role in GUI.

database (fetch new database credential for "app1"):
```sh
clear
/home/oracle/vault/vault read database/creds/app1
/home/oracle/vault/vault read database/creds/app1
```

SQL Developer (dba):
```sql
select username from dba_users where oracle_maintained='N' and username like 'V%APP1%';
```

# DEMO: Agent

database (writing config file for application using secrets):
```sh
clear
less /live-demos/hashicorp-vault-for-oracle-db/agent_app1.ctmpl
/home/oracle/vault/vault agent -config /live-demos/hashicorp-vault-for-oracle-db/agent_config.hcl
cat /tmp/agent_app1.config
```

# DEMO: SSH certificate authority

vault:
```sh
clear
vault secrets enable -path=ssh-client-signer ssh

# Generate CA public key
vault write ssh-client-signer/config/ca generate_signing_key=true

# Create a role in vault for oracle user
vault write ssh-client-signer/roles/oracle -<<"EOH"
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "oracle",
  "allowed_extensions": "permit-pty,permit-port-forwarding",
  "default_extensions": {
    "permit-pty": ""
  },
  "key_type": "ca",
  "default_user": "oracle",
  "ttl": "24h"
}
EOH
```

Spin up SSH server image:
```sh
docker run -it --name hashidemo-sshd -e USER_NAME=oracle -e LOG_STDOUT=true lscr.io/linuxserver/openssh-server:latest

docker exec -it hashidemo-sshd bash
```

SSH server:
```sh
curl -o /config/trusted-user-ca-keys.pem http://172.17.0.2:8200/v1/ssh-client-signer/public_key
cat /config/trusted-user-ca-keys.pem
echo "TrustedUserCAKeys /config/trusted-user-ca-keys.pem" >> /config/sshd/sshd_config

docker restart hashidemo-sshd
```

database:
```sh
clear
cat /home/oracle/.ssh/id_rsa.pub

# Demo the certificate output
/home/oracle/vault/vault write ssh-client-signer/sign/oracle public_key=@$HOME/.ssh/id_rsa.pub

# Write certificate to file
/home/oracle/vault/vault write -field=signed_key ssh-client-signer/sign/oracle public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert.pub

ssh oracle@172.17.0.4 -p 2222
```

Show SSHD container logs to see that last login was done by certificate
```sh
docker logs hashidemo-sshd
```

# DEMO: secret wrapping

database:
```sh
clear
/home/oracle/vault/vault kv get demokv/oracle/demodb/deployment
/home/oracle/vault/vault kv get -wrap-ttl=5m demokv/oracle/demodb/deployment
/home/oracle/vault/vault unwrap tokenhere

# To wrap getting a secret, add X-Vault-Wrap-Ttl header
curl -H "X-Vault-Wrap-Ttl: 5m0s" -X GET http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment | python -m json.tool

# Wrap any data you wish
curl -H "Content-Type: application/json" \
    -X POST \
    --data '{"name":"Oracle 26ai","release_date":null}' \
    http://127.0.0.1:8200/v1/sys/wrapping/wrap | python -m json.tool

curl -H "Content-Type: application/json" \
    -X POST \
    --data '{"token":"tokenhere"}' \
    http://127.0.0.1:8200/v1/sys/wrapping/unwrap | python -m json.tool
```

SQL Developer:
```sql
DECLARE
    req   UTL_HTTP.REQ;
    resp  UTL_HTTP.RESP;
    the_url varchar2(200):= 'http://127.0.0.1:8200/v1/sys/wrapping/wrap';
    value varchar(4000);
BEGIN
    value:= '{"name":"Oracle 26ai","release_date":null}';
    req := UTL_HTTP.BEGIN_REQUEST (url=>the_url, method=>'POST');
    UTL_HTTP.SET_HEADER (r      =>  req, 
                        name   =>  'Content-Type',
                        value  =>  'application/json');
    UTL_HTTP.SET_HEADER (r      =>  req,
                        name   =>  'Content-Length',
                        value  =>  to_char(length(value)));
    UTL_HTTP.WRITE_TEXT (r      =>   req, 
                        data   =>   value);
    resp := UTL_HTTP.GET_RESPONSE 
                        (r     =>   req);
    dbms_output.put_line(resp.status_code);
    UTL_HTTP.READ_LINE(resp, value, TRUE);
    DBMS_OUTPUT.PUT_LINE(value);
    UTL_HTTP.END_RESPONSE(resp);
end;
/

exec APEX_WEB_SERVICE.SET_REQUEST_HEADERS('Content-Type','application/json');
SELECT
    apex_web_service.make_rest_request(
        p_url => 'http://127.0.0.1:8200/v1/sys/wrapping/wrap',
        p_http_method => 'POST',
        p_body => '{"name":"Oracle 26ai","release_date":null}'
    )
;
```

# Cleanup

Database

```sql
alter session set container=freepdb1;

begin
    for rec in (select username from dba_users where username like 'V%APP1%' and oracle_maintained='N') loop
        execute immediate 'drop user "'||rec.username||'" cascade';
    end loop;
end;
/
```
