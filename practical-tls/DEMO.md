# Practical Transport Layer Security

## Author

Ilmar Kerm
ilmar@ilmarkerm.eu
2026

# Prerequisites

Need modern Docker.

# Secrets

All passwords are: demo123

Vault root token is: demo123

# Running

From the "practical-tls" directory (where compose.yaml is located), execute

```
docker compose up
```

After initial setup is done, Oracle DB needs a reboot to activate spfile parameters.

```
docker compose stop
docker compose start
docker compose logs -f
```

NB! Everything with Vault is set up for demo purposes only using a root token and without any access privileges set up. In real deployments you must look into proper authentication (like approles) and access policies.

# Demo setup

![Certification chain](img/demo_setup.png)

# Create Vault structure

First destroy, since the the terraform state is written to a persistent docker volume. If it fails, no problem.

```
docker compose exec controller bash /scripts/vault_setup.sh destroy
```

And create

```
docker compose exec controller bash /scripts/vault_setup.sh
```

Go to [Vault GUI](http://localhost:8200/) and show the Vault structures created.

![Certification chain](img/certification_chain.png)

# One-way TLS

![Certification chain](img/one-way-tls.png)

# OracleDB server configuration

First lets create Oracle Wallet and request certificate from Vault

```
docker compose exec oracledb bash /scripts/wallet_create.sh
```

Wallet was created under /home/oracle/wallet_root

## Listener

Oracle network connections are taken by listener first, so listener needs to be set up for TLS.

Lookig at current listener configuration. No TLS set up initially.

```
docker compose exec oracledb lsnrctl status
```

And configure the listener for TLS.

```
docker compose exec oracledb bash /scripts/configure_listener.sh
```

Verify that listener responds to TLS correcly

```
echo -n | openssl s_client -connect localhost:1522 -showcerts | less
```

## Configure database for TLS

But also how Oracle architecture is set up, configuring TLS on listener is not enough, listener hands over the connection to database, TLS also needs to be configured in database.

```
docker compose exec oracledb sqlplus / as sysdba

sho pdbs
sho parameter wallet_root
```

Show sqlnet.ora

```
docker compose exec oracledb cat /opt/oracle/product/26ai/dbhomeFree/network/admin/sqlnet.ora
```

NB! TLS_CLIENT_AUTHENTICATION = OPTIONAL
Because it is by default TRUE, meaning mTLS is always enabled.

# OracleDB client tests

Download the root certificate from Vault and place it under client system truststore.

```
docker compose exec controller bash /scripts/trust_vault_root.sh
```

## Connect from python thin driver

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle.py
```

## Connect from python thick driver

With recent Oralce Instantclient (>21?) it can use OS system trust store and no need to confiugure Oracle Wallet on client side.

Using the default hostname, which is present in the certificate.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py
```

Using alternate hostname, that is not in certificate, this will fail.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py --hostname oracledb
```

Using alternate hostname, but turning the hostname checking off. This should succeed.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py --hostname oracledb --server-dn-match-off
```

DN matching:
PARTIAL - SSL_SERVER_DN_MATCH=ON - only hostname is checked

FULL - the entire DN is checked against written value
```
finance=
(DESCRIPTION=
(ADDRESS_LIST=
(ADDRESS= (PROTOCOL = tcps) (HOST = finance) (PORT = 1575)))
(CONNECT_DATA=
(SERVICE_NAME= finance.us.example.com))
(SECURITY=
(SSL_SERVER_CERT_DN="cn=finance,cn=OracleContext,c=us,o=example"))
)
```

## mTLS

![Certification chain](img/mutual-tls.png)

Prepare the user wallet

```
docker compose exec controller bash /scripts/vault_user.sh
```

This driver does support mTLS, but not for authentication.
Turn TLS_CLIENT_AUTHENTICATION to TRUE in listener.ora and sqlnet.ora to demonstrate that mTLS is forced then.

```
# This is successful
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle.py --mtls
# This should fail
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle.py
```

## PKI Certificate authentication

Show how demouser1 is created in oracledb-startup/

Create a user wallet file

```
docker compose exec oracledb bash /scripts/wallet_client.sh
```

Test with sqlplus

```
docker compose exec controller bash
export TNS_ADMIN=/scripts/tns_admin
cat $TNS_ADMIN/sqlnet.ora
cat $TNS_ADMIN/tnsnames.ora

sqlplus /@oracledb
```

With Python
but it only works in thick mode

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py --mtls
```


# PostgreSQL

Create server certificates

```
docker compose exec postgres su - postgres -c "bash /scripts/vault_certs.sh"
```

Configure TLS in postgres

```
docker compose exec postgres su - postgres -c "cat /scripts/postgresql.conf ; cat /scripts/postgresql.conf >> /var/lib/postgresql/18/docker/postgresql.conf"
```

Allow TLS for clients

```
docker compose exec postgres su - postgres -c "cat /scripts/pg_hba.conf ; cat /scripts/pg_hba.conf > /var/lib/postgresql/18/docker/pg_hba.conf"
```

Reload config (or rotate certificates) - send SIGHUP to postmaster or patroni - in docker image pid=1

```
docker compose exec postgres kill -SIGHUP 1
```

Show how users and databases are created in postgres-init/02-app.sql

Test with OpenSSL

```
echo -n | openssl s_client -connect localhost:5432 -starttls postgres -showcerts
```

Login to shell

```
docker compose exec postgres su - postgres -c bash
```

# PostgreSQL client tests

One way TLS, with password authentication

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_postgres.py app1 --password demo123
```

Testing with short hostname, that is not part of certificate and sslmode=verify-full

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_postgres.py app1 --password demo123 --hostname postgres --sslmode=verify-full
```

Short hostname with sslmode=require works.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_postgres.py app1 --password demo123 --hostname postgres --sslmode=require
```

## mTLS

If client certificates for Oracle tests were not created earlier, then do it now.

```
docker compose exec controller bash /scripts/vault_user.sh
```

Need to use demouser1 as username, because in pg_hba this user is configured with "cert" authentication.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_postgres.py demouser1 --mtls
```

Can show, that any password value is accepted. Or just remove password.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_postgres.py demouser1 --mtls --password WhatEva
```

# Download

![QR code to repository](img/qr-code.svg)
