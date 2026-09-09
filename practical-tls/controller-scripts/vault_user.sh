#!/bin/bash

set -x

export VAULT_TOKEN=demo123
export VAULT_ADDR=http://vault:8200

# Request a certificate (with private key) for "demouser1"
vault write -format=json pki_int/issue/database_user \
  common_name="demouser1" > /tmp/user.json

if [ $? -ne 0 ]; then
    echo "Failed to get user certificate from Vault"
    exit 1
fi

# Extract certs and key to separate files
jq -r '.data.certificate' /tmp/user.json > /root/user_cert.crt
# Append the issuer certificate also (intermediary)
jq -r '.data.issuing_ca' /tmp/user.json >> /root/user_cert.crt
# And the private key
jq -r '.data.private_key' /tmp/user.json > /root/user_cert.key

chmod 600 /root/user_cert.key

echo "Show the received certificate contents"
openssl x509 -text -in /root/user_cert.crt | less

# Displays paths of what files we prepared
echo "User certificate file: /root/user_cert.crt"
echo "User private key: /root/user_cert.key"
