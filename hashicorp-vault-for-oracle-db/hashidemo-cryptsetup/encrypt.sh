#!/bin/bash

# generate key
cryptpass=`openssl rand -hex 27`

# Store key in Vault
export VAULT_ADDR=http://localhost:8200
/usr/local/bin/vault

# Format the device
if [ $? -eq 0 ]; then
    cryptsetup luksFormat /dev/loop0 - <<< "$cryptpass"
fi
