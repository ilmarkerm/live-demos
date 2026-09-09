#!/bin/bash

set -x

walletpath=/home/oracle/wallet
walletpwd=demo123DEMO123demo123
certdn="CN=oracledb.practical-tls_demo-net"

vault_root_path="pki_root/issuer/root-issuer-2026"
vault_signing_path="pki_int/issuer/intermediate-server-issuer-2026/sign/database_server"

# This is very insecure, but using it for demonstration purposes only
# In production use better authentication methods to access Vault, like approles
export VAULT_TOKEN=demo123
export VAULT_ADDR=http://vault:8200

rm -rf $walletpath
mkdir -p $walletpath
# Creating an empty wallet
echo "Creating empty wallet..."
orapki wallet create -wallet $walletpath -pwd $walletpwd -auto_login -nologo

echo
echo "Adding certificate to wallet..."
orapki wallet add -wallet $walletpath -pwd $walletpwd \
  -keysize 4096 -dn "$certdn" -addext_san DNS:oracledb.practical-tls_demo-net \
  -nologo
orapki wallet export -wallet $walletpath -pwd $walletpwd -dn "$certdn" \
  -request /tmp/cert.req \
  -nologo

echo "Signing certificate request with Vault..."
vault write -format=json "$vault_signing_path" csr=@/tmp/cert.req > /tmp/vault_sign_response.json
if [ $? -ne 0 ]; then
    echo "Failed to sign certificate request"
    exit 1
fi


echo "Saving signed certificate..."
jq -r '.data.certificate' /tmp/vault_sign_response.json > /tmp/cert.cer

echo "Saving issuer certificate..."
jq -r '.data.issuing_ca' /tmp/vault_sign_response.json > /tmp/issuer.cer


echo
echo "Fetching trusted root certificate from Vault..."
vault read -field=certificate "$vault_root_path" > /tmp/root.pem

# Add trusted root certificate to wallet
echo "Adding trusted root certificate to wallet..."
orapki wallet add -wallet $walletpath -pwd $walletpwd -cert /tmp/root.pem -trusted_cert -nologo
orapki wallet add -wallet $walletpath -pwd $walletpwd -cert /tmp/issuer.cer -trusted_cert -nologo

# Add server certificate to wallet
echo "Adding server certificate to wallet..."
orapki wallet add -wallet $walletpath -pwd $walletpwd -cert /tmp/cert.cer -user_cert -nologo


# Display wallet contents
echo
echo "Wallet contents:"
orapki wallet display -wallet $walletpath -pwd $walletpwd -nologo


# Distribute wallet
echo
echo "Copy wallet to wallet_root for each PDB"
find /home/oracle/wallet_root -name tls -type d -exec cp $walletpath/ewallet.p12 $walletpath/cwallet.sso {} \;
tree /home/oracle/wallet_root
