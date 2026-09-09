#!/bin/bash

set -x

#vault_signing_path="pki_int/issuer/intermediate-server-issuer-2026/issue/database_server"

# This is very insecure, but using it for demonstration purposes only
# In production use better authentication methods to access Vault, like approles
export VAULT_TOKEN=demo123
export VAULT_ADDR=http://vault:8200

serverhost="postgres"
certcn="${serverhost}.practical-tls_demo-net"
vault_root_path="pki_root/issuer/root-issuer-2026"

certfilepath="/var/lib/postgresql"

vault write -format=json pki_int/issue/database_server \
  common_name="$certcn" alt_names="$certcn" ip_sans="$(hostname -I)" > /tmp/server.json

jq -r '.data.certificate' /tmp/server.json > "$certfilepath/server_cert.pem"
# Append the issuer certificate also (intermediary)
jq -r '.data.issuing_ca' /tmp/server.json >> "$certfilepath/server_cert.pem"
# And the private key
jq -r '.data.private_key' /tmp/server.json > "$certfilepath/server_cert.key"
chmod 600 "$certfilepath/server_cert.key"

# Saving root CA cert
vault read -field=certificate "$vault_root_path" > "$certfilepath/root.pem"

echo "Files created:"
echo "Server certificate: $certfilepath/server_cert.pem"
echo "Private key: $certfilepath/server_cert.key"
echo "CA certificate: $certfilepath/root.pem"
