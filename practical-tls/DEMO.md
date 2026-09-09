# Author

Ilmar Kerm
ilmar@ilmarkerm.eu
2026

# Prerequisites

Need modern Docker.

# Running

From the "practical-tls" directory (where compose.yaml is located), execute

```
docker compose up
```

After initial setup is done, Oracle DB needs a reboot to activate spfile parameters.

docker compose down
docker compose up

NB! Everything with Vault is set up for demo purposes only using a root token and without any access privileges set up. In real deployments you must look into proper authentication (like approles) and access policies.


pg_hba:
hostssl all +dbcert_users all cert
hostssl all all all scram-sha-256

```
ssl = on
ssl_cert_file = '/var/lib/postgresql/server_cert.pem'
ssl_key_file = '/var/lib/postgresql/server_cert.key'
# For client verification
ssl_ca_file = '/var/lib/postgresql/root.pem'
```

/var/lib/postgresql/18/docker/postgresql.conf
/var/lib/postgresql/18/docker/pg_hba.conf
# /var/lib/postgresql/18/docker/pg_ident.conf
kill -SIGHUP 1
