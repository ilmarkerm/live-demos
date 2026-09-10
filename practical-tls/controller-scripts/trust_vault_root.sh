#!/bin/bash

set -x

export VAULT_TOKEN=demo123
export VAULT_ADDR=http://vault:8200

vault_root_path="pki_root/issuer/root-issuer-2026"

echo "Fetching trusted root certificate from Vault..."
vault read -field=certificate "$vault_root_path" > /etc/pki/ca-trust/source/anchors/vault_demo_root.pem
# Update system truststore with the new root certificate
update-ca-trust

#echo -n | openssl s_client -connect oracledb:1522 -showcerts | less
