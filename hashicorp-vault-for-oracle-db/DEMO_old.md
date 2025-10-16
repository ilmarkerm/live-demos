[http://localhost:8200]
(https://container-registry.oracle.com/ords/f?p=113:4:115200703853431:::4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:1863,1863,Oracle%20Database%20Free,Oracle%20Database%20Free,1,0)

Everything in API based. GUI added later.
You mount plugins to mount paths.
Authentication plugins authenticate users, but at successful authentication they generate an internal token. API requests need the token.

# What to show

# Setup

```
docker start hashidemo-linux
docker exec -it hashidemo-linux bash
docker exec -it hashidemo-oracle bash
```

install things
```
bash /live-demos/hashicorp-vault-for-oracle-db/install_db.sh
bash /live-demos/hashicorp-vault-for-oracle-db/install_linux.sh
```

## Tokens

Tokens are the primary authentication mechanism. You must include it
It contains roles and capabilities this token can perform.

```
export PS1="[\u@\h \W (vault)]\\$ "
export PS1="[\u@\h \W (database)]\\$ "

export VAULT_TOKEN=root
export VAULT_ADDR=http://172.17.0.2:8200

vault token lookup

# What can a token do on a given path
vault token capabilities secret/
```

## Terraform

```
cd /live-demos/hashicorp-vault-for-oracle-db/terraform
terraform apply -no-color
```

## Exchange approle to token

Other authentication mechanisms can also be used - successful authentication via plugin is exchanged for a token.

List and show all plugins

```
vault plugins list
```

```
vault auth list
vault list auth/approle/role/
# Get approle properties
vault read auth/approle/role/demo-proxy
# Get role_id for approle
vault read -field=role_id auth/approle/role/demo-proxy/role-id

# Generate secret-id (can be multiple) for the same role-id
# This will create a new ACCESSOR for this approle
vault write -field=secret_id -f auth/approle/role/demo-proxy/secret-id

# List accessors for role
vault list auth/approle/role/demo-proxy/secret-id
# Information about an accessor
vault write auth/approle/role/demo-proxy/secret-id-accessor/lookup secret_id_accessor=
```

Login via CLI
To test that role_id + secret_id work

```
vault write auth/approle/login role_id= secret_id=
```

## proxy, agent

Read roleid and generate secret-id for the demo user above and configure proxy in DB server

```
# DB SERVER
docker exec -it hashidemo-oracle bash
export PS1="[\u@\h \W]\\$ "


echo "" > /home/oracle/vault/.roleid
echo "" > /home/oracle/vault/.secretid

/home/oracle/vault/vault proxy -config /home/oracle/vault/proxy_config.hcl
```

Demo that requests via Proxy now do not need authentication

```
export VAULT_ADDR=http://localhost:8200
unset VAULT_TOKEN

./vault token lookup
```

## API

http://localhost:8200/ui/vault/tools/api-explorer
https://developer.hashicorp.com/vault/api-docs

REST API, needs X-Vault-Token header

```
curl \
    -H "X-Vault-Token: f3b09679-3001-009d-2b80-9c306ab81aa6" \
    -X GET \
    http://127.0.0.1:8200/v1/secret/data/foo
```

or via proxy without token

```
curl \
    -X GET \
    http://127.0.0.1:8200/v1/secret/data/foo
```

## Secrets engines

```
vault secrets list
vault plugins list
```

All are plugins, plugins are mounted to a "mount path".
Can add custom plugins.

## key/value

Terraform can add them also.

```
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

## pl/sql

first need to open firewall
```
alter session set container=freepdb1;
begin
    DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
      host => '127.0.0.1',
      lower_port => 8200,
      ace  =>  xs$ace_type(privilege_list => xs$name_list('connect'),
                           principal_name => 'demo',
                           principal_type => xs_acl.ptype_db));
end;
/
```


```
SELECT json_query(
    JSON(
        HttpUriType('http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment').getClob()
    )
, '$' RETURNING clob PRETTY);


select json_query(
    HttpUriType('http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment').getClob(),
    '$.data.data' returning json);

# Read token from sink file
utl_http.set_header()
UTL_HTTP.set_header (req, 'Authorization', 'Basic ' || UTL_ENCODE.base64_encode ('username:password'));

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

## send secrets to other party via Vault

The problem of secret zero! Wrapping solves it.

wrapping demo
instead of returning secret directly, Vault takes the reponse, inserts it into "cubbyhole" and returns a single use token.

```
vault kv get -wrap-ttl=2m demokv/oracle/demodb/deployment
```
This adds
X-Vault-Wrap-Ttl: 2m0s
header to GET request

curl -H "X-Vault-Wrap-Ttl: 15m0s" -X GET http://127.0.0.1:8200/v1/demokv/data/oracle/demodb/deployment

show in Vault GUI "Unwrap data"
but the unwrapper needs to be authenticated

```
curl -H "Content-Type: application/json" \
    -X POST \
    --data '{"token":"hvs.CAESIHzFVPF0nXHKHu6U4UD9VpCsUhHIlCyNKK--owGf98CpGh4KHGh2cy5ocnpDd0d0cldDaGZYb3p2UmxpYjFkUXA"}' \
    http://127.0.0.1:8200/v1/sys/wrapping/unwrap
```


or can wrap any secret you wish (that does not come from Vault) for transport

```
curl -H "Content-Type: application/json" \
    -X POST \
    --data '{"name":"Larry Ellison","salary":1000}' \
    http://127.0.0.1:8200/v1/sys/wrapping/wrap

DECLARE
    req   UTL_HTTP.REQ;
    resp  UTL_HTTP.RESP;
    the_url varchar2(200):= 'http://127.0.0.1:8200/v1/sys/wrapping/wrap';
    value varchar(4000);
BEGIN
    req := UTL_HTTP.BEGIN_REQUEST (url=>the_url, method=>'POST');
    UTL_HTTP.SET_HEADER (r      =>  req, 
                        name   =>  'Content-Type',
                        value  =>  'application/json');
    UTL_HTTP.WRITE_TEXT (r      =>   req, 
                        data   =>   '{"name":"Oracle 26ai","release_date":null}');
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
        p_body => '{"name":"Larry Ellison","salary":1000}'
    )
;
```



## database engine

unique dynamic credentials for database access for every application
for every database - done via plugin mechanism

long list of supported databases, you can also write your own plugin

static roles also supported - one to one mapping of database user to vault role
static role scheduled rotation is supported in enterprise edition

One engine can handle multiple databases
```
vault secrets enable database
```

Vault needs a special admin user that can create/update/revoke database credentials
With initial password fixed, it will be rotated

Passwords are generated via Password Policies.

(https://developer.hashicorp.com/vault/docs/secrets/databases)

```
vault write database/config/my-database \
    plugin_name="..." \
    connection_url="..." \
    allowed_roles="..." \
    username="..." \
    password="..." \

vault write database/config/my-mssql-database \
plugin_name="mssql-database-plugin" \
connection_url='server=localhost;port=1433;user id={{username}};password={{password}};database=mydb;' \
username="root" \
password='your#StrongPassword%' \
disable_escaping="true

# rotate immediately
vault write -force database/rotate-root/my-database


vault write database/roles/my-role \
    db_name=my-database \
    creation_statements="..." \
    default_ttl="1h" \
    max_ttl="24h"

# usage
vault read database/creds/my-role
```

Oracle database plugin

(https://developer.hashicorp.com/vault/docs/secrets/databases/oracle)

Rather complicated setup, not compatible with Vault docker image (since it runs on Alpine Linux) and needs Instant Client and some compilation.

```
export VAULT_ADDR=http://127.0.0.1:8200
sha256sum /root/vault-plugins/vault-plugin-database-oracle
vault plugin register -sha256=3a59f4351f98c11d9d609744b76abd8b584c37a559441aed34544e84313933a3 database vault-plugin-database-oracle

vault secrets enable database


GRANT CREATE USER to vault WITH ADMIN OPTION;
GRANT ALTER USER to vault WITH ADMIN OPTION;
GRANT DROP USER to vault WITH ADMIN OPTION;
GRANT CONNECT to vault WITH ADMIN OPTION;
GRANT CREATE SESSION to vault WITH ADMIN OPTION;
GRANT SELECT on gv_$session to vault;
GRANT SELECT on v_$sql to vault;
GRANT ALTER SYSTEM to vault WITH ADMIN OPTION;

vault write database/config/oracle \
    plugin_name=vault-plugin-database-oracle \
    allowed_roles="*" \
    connection_url='{{username}}/{{password}}@//172.17.0.3:1521/freepdb1' \
    username='vault' \
    password='vault'

# Rotate root password immediately
vault write -force database/rotate-root/oracle


# TTL - application would need to be restarted before it expires to fetch new credentials
# Because on expiration Vault would kill sessions and drop the temporary user
vault write database/roles/app1 \
    db_name=oracle \
    creation_statements='CREATE USER {{username}} IDENTIFIED BY "{{password}}"; GRANT CREATE SESSION TO {{username}}; ALTER USER app1 GRANT CONNECT THROUGH {{username}};' \
    default_ttl="7d" \
    max_ttl="10d"

vault read database/creds/app1

alter session set container=freepdb1;
select username from dba_users where oracle_maintained='N';
```

using vault agent

```
./vault agent -config /live-demos/hashicorp-vault-for-oracle-db/agent_config.hcl
cat /tmp/agent_app1.config
```

## ssh

if you have a lot of servers where you want to control SSH access centrally.
Or only provide firefigher one-time access. OTP requires installing extra Linux PAM module on server.

Here looking at SSH signed certificates. Does not require extra software on server. Just adding CA public key on SSH config.
Use case - DBA-s authenticate to Vault using OIDC and then they can get granted SSH access to database servers as "oracle". For example 24h. Next day need to repeat the process.

```
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

# SSHD server side - Download public key and add to server
curl -o /config/trusted-user-ca-keys.pem http://172.17.0.2:8200/v1/ssh-client-signer/public_key
echo "TrustedUserCAKeys /config/trusted-user-ca-keys.pem" >> /config/sshd/sshd_config
restart container


# Client side
ssh-keygen -t rsa
export VAULT_ADDR=http://127.0.0.1:8200
/home/oracle/vault/vault write ssh-client-signer/sign/oracle public_key=@$HOME/.ssh/id_rsa.pub

# Write the certificate to a file
/home/oracle/vault/vault write -field=signed_key ssh-client-signer/sign/oracle public_key=@$HOME/.ssh/id_rsa.pub > $HOME/.ssh/id_rsa-cert.pub

ssh oracle@172.17.0.4 -p 2222
```

show ssh server log file of successful authentication
NB! Standard OpenSSH functionality. Oracle Key Vault requires an OKV library to be loaded on SSH server side for similar functionality.


For extra security, to avoid clients connecting to a malicious server, server host keys can also be signed.

## API explorer

## PKI

Full PKI engine
Need custom code to build oracle wallet
