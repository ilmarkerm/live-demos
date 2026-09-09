#!/bin/bash

echo '' > /etc/dnf/vars/ociregion
dnf install yum-utils vim unzip less sudo jq tree
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install vault-1.21.4
setcap cap_ipc_lock= /usr/bin/vault
mkdir -p /home/oracle/wallet_root
chown oracle:oinstall /home/oracle/wallet_root
