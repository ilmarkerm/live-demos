#!/bin/bash -x

clear
vault secrets enable -path=ssh-client-signer ssh

sleep 5s

# Generate CA public key
vault write ssh-client-signer/config/ca generate_signing_key=true

sleep 5s

# Create a role in vault for oracle user
vault write ssh-client-signer/roles/oracle -<<"EOH"
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "oracle",
  "allowed_extensions": "permit-pty,permit-port-forwarding",
  "default_extensions": {
    "permit-pty": ""
  },
  "key_type": "ca",
  "default_user": "oracle",
  "ttl": "24h"
}
EOH
