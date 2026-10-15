#!/bin/bash

# Install software needed for the cryptsetup+vault demo

vaultversion="1.21.4"
goversion="1.26.9"

dnf install cryptsetup unzip e2fsprogs

#systemctl enable remote-cryptsetup.target

# Download go
arch="$(uname -m)"
if [ "$arch" == "aarch64" ]; then
    goarch="arm64"
else
    goarch="$arch"
fi
curl -o /tmp/go.tar.gz "https://dl.google.com/go/go${goversion}.linux-${goarch}.tar.gz"
rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz

# Download vault
curl -o /tmp/vault.zip https://releases.hashicorp.com/vault/${vaultversion}/vault_${vaultversion}_linux_${goarch}.zip
unzip /tmp/vault.zip vault -d /usr/local/bin && rm /tmp/vault.zip

# Initialize vault dir
mkdir vault
touch vault/.roleid
touch vault/.secretid
