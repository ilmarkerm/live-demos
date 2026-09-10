# Author

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

```
docker compose exec controller bash /scripts/vault_setup.sh
```

Go to [Vault GUI](http://localhost:8200/) and show the Vault structures created.

![Certification chain](img/certification_chain.png)

DEBUG: If Vault container is restarted or recreated during the test, then have to run destory first before recreating Vault setup. Because in dev mode Vault does not persist anything, but terraform state file remains in place on controller.

```
docker compose exec controller bash /scripts/vault_setup.sh destroy
```

# OracleDB server configuration

First lets create Oracle Wallet and request certificate from Vault

```
  docker compose exec oracledb bash /scripts/wallet_create.sh
```

Oracle network connections are taken by listener first, so listener needs to be set up for TLS.

```
docker compose exec oracledb lsnrctl status
docker compose exec oracledb cat /opt/oracle/product/26ai/dbhomeFree/network/admin/listener.ora
docker compose exec oracledb bash /scripts/configure_listener.sh
```

Verify that listener responds to TLS correcly

```
echo -n | openssl s_client -connect localhost:1522 -showcerts
```

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

# OracleDB client tests

Download the root certificate from Vault and place it under client system truststore.

```
docker compose exec controller bash /scripts/trust_vault_root.sh
```

Connect from python thin driver

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle.py
```

Connect from python thick driver

With recent Oralce Instantclient (>21?) it can use OS system trust store and no need to confiugure Oracle Wallet on client side.

```
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py --hostname oracledb
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle_thick.py --hostname oracledb --server-dn-match-off
```

DN matching:
PARTIAL - SSL_SERVER_DN_MATCH=ON - only hostname is checked

FULL - the entire DN is checked against written value
finance=
(DESCRIPTION=
(ADDRESS_LIST=
(ADDRESS= (PROTOCOL = tcps) (HOST = finance) (PORT = 1575)))
(CONNECT_DATA=
(SERVICE_NAME= finance.us.example.com))
(SECURITY=
(SSL_SERVER_CERT_DN="cn=finance,cn=OracleContext,c=us,o=example"))


## mTLS

Prepare the user wallet

```
docker compose exec controller bash /scripts/vault_user.sh
```

This driver does support mTLS, but not for authentication.
Turn SSL_CLIENT_AUTHENTICATION to TRUE in listener.ora and sqlnet.ora to demonstrate that mTLS is forced then.

```
# This is successful
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle.py --mtls
# This should fail
docker compose exec controller /root/venv_test/bin/python /scripts/connect_oracle.py
```

# PostgreSQL

```
docker compose exec postgres su - postgres -c "bash /scripts/vault_certs.sh"
docker compose exec postgres su - postgres -c "cat /scripts/postgresql.conf >> /var/lib/postgresql/18/docker/postgresql.conf"
docker compose exec postgres su - postgres -c "cat /scripts/pg_hba.conf >> /var/lib/postgresql/18/docker/pg_hba.conf"
```

Reload config (or rotate certificates) - send SIGHUP to postmaster or patroni - in docker image pid=1

```
docker compose exec postgres kill -SIGHUP 1
```

Test with OpenSSL

```
echo -n | openssl s_client -connect localhost:5432 -starttls postgres -showcerts
```

Login to shell

```
docker compose exec postgres su - postgres -c bash
```

# PostgreSQL client tests

docker compose exec controller /root/venv_test/bin/python /scripts/connect_postgres.py



Also show tests with psql and sqlplus programs



# Download

![QR code to repository](img/qr-code.svg)
