#!/bin/bash

set -x

export VAULT_TOKEN=demo123
export VAULT_ADDR=http://vault:8200

vault_root_path="pki_root/issuer/root-issuer-2026"
#vault_signing_path="pki_int/issuer/intermediate-server-issuer-2026/sign/database_server"

echo "Fetching trusted root certificate from Vault..."
vault read -field=certificate "$vault_root_path" > /etc/pki/ca-trust/source/anchors/vault_demo_root.pem
update-ca-trust

echo -n | openssl s_client -connect oracledb:1522 -showcerts | less
