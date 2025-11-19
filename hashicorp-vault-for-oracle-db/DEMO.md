# Secure secrets management for Oracle Databases using HashiCorp Vault

Ilmar Kerm 2025 ilmar@ilmarkerm.eu https://ilmarkerm.eu

# Setup

VS Code change theme: ⌘K ⌘T

Startup
```sh
cd live-demos/hashicorp-vault-for-oracle-db
docker compose up
```

Entrypoints:
```sh
docker exec -it hashicorp-vault-for-oracle-db-oracle-1 bash
docker exec -it hashicorp-vault-for-oracle-db-vault-1 bash
docker exec -it hashicorp-vault-for-oracle-db-sshd-1 bash
```

vault:
```sh
cd /live-demos/hashicorp-vault-for-oracle-db/terraform
terraform apply -no-color
```

# DEMO: plugins, tokens

Do setup also.

vault:
```sh
# NB! oracle is not yet here, need to register it first
vault plugin list|less

# Show in VS code actually
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
less /live-demos/hashicorp-vault-for-oracle-db/proxy_config.hcl
echo "" > /home/oracle/vault/.roleid
echo "" > /home/oracle/vault/.secretid
# Start proxy
unset VAULT_ADDR ; vault proxy -config /live-demos/hashicorp-vault-for-oracle-db/proxy_config.hcl

# NEW TAB
# Do request via proxy and show the token
vault token lookup
```

# DEMO: Secret engines

vault:
```sh
clear
vault secrets list

vault secrets enable -path=demokv -description="Secrets for DOAG demo" -version=2 kv
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

# DEMO: Database accounts ORACLE

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

vault (show script contents):

```sh
/live-demos/hashicorp-vault-for-oracle-db/demos/register_oracle_database.sh
```

Show connection in GUI.
Show role in GUI.

database (fetch new database credential for "app1"):
```sh
clear
vault read database/creds/app1
vault read database/creds/app1
```

SQL Developer (dba):
```sql
select username from dba_users where oracle_maintained='N' and username like 'V%APP1%';
```

# DEMO: Database accounts POSTGRES

vault (also show script):

```sh
/live-demos/hashicorp-vault-for-oracle-db/demos/register_postgres_database.sh
```

Show connection in GUI.
Show role in GUI.

Fetch credentials:

```sh
vault read database/creds/pgapp1
vault read database/creds/pgapp1
```

# DEMO: Agent

database (writing config file for application using secrets):
```sh
clear
less /live-demos/hashicorp-vault-for-oracle-db/agent_app1.ctmpl
vault agent -config /live-demos/hashicorp-vault-for-oracle-db/agent_config.hcl
cat /tmp/agent_app1.config
```

# DEMO: SSH certificate authority

vault:

```sh
/live-demos/hashicorp-vault-for-oracle-db/demos/register_ssh_signer.sh
```

Same commands:

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

SSH server:
```sh
curl -o /config/trusted-user-ca-keys.pem http://vault:8200/v1/ssh-client-signer/public_key
cat /config/trusted-user-ca-keys.pem
echo "TrustedUserCAKeys /config/trusted-user-ca-keys.pem" >> /config/sshd/sshd_config

docker restart hashicorp-vault-for-oracle-db-sshd-1
```

database:
```sh
clear
ssh-keygen -t rsa
cat /home/oracle/.ssh/id_rsa.pub

# Demo the certificate output
vault write ssh-client-signer/sign/oracle public_key=@$HOME/.ssh/id_rsa.pub

# Write certificate to file
vault write -field=signed_key ssh-client-signer/sign/oracle public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert.pub

ssh oracle@sshd -p 2222
```

Show SSHD container logs to see that last login was done by certificate
```sh
docker logs hashicorp-vault-for-oracle-db-sshd-1
```

# DEMO: secret wrapping

database:
```sh
clear
vault kv get demokv/oracle/demodb/deployment
vault kv get -wrap-ttl=5m demokv/oracle/demodb/deployment
vault unwrap tokenhere

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

Database (not really needed, just in case needed between demos)

```sql
alter session set container=freepdb1;

begin
    for rec in (select username from dba_users where username like 'V%APP1%' and oracle_maintained='N') loop
        execute immediate 'drop user "'||rec.username||'" cascade';
    end loop;
end;
/
```

```sh
cd live-demos/hashicorp-vault-for-oracle-db
docker compose down
```
