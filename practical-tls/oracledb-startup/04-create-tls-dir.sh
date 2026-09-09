#!/bin/bash

# This creates wallet directories for each PDB
walletroot="/home/oracle/wallet_root"

while IFS= read -r line; do
    if [ -n "$line" ]; then
        pdbwallet="$walletroot/$line/tls"
        mkdir -p "$pdbwallet"
    fi
done < /home/oracle/guid.txt

# Create CDB directory
mkdir -p "$walletroot/tls"
