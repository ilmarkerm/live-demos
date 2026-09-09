docker compose up


After initial setup is done, Oracle DB needs a reboot to activate spfile parameters.

docker compose down
docker compose up

NB! Everything with Vault is set up for demo purposes only using a root token and without any access privileges set up. In real deployments you must look into proper authentication (like approles) and access policies.


pg_ident:
- dn "/^CN=demouser1$" demouser1

ssl=on
ssl_cert_file
ssl_key_file

# For client verification
ssl_ca_file
