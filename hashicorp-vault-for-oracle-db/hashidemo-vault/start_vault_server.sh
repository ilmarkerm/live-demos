#!/bin/bash

cd /root
vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200 -config vault_server_config.hcl
