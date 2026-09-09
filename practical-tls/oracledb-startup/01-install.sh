#!/bin/bash

if [ ! -f /home/oracle/install_script_run ]; then
    su - -c "echo '' > /etc/dnf/vars/ociregion"
    su - -c "dnf install yum-utils vim unzip less sudo jq tree"
    su - -c "yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
    su - -c "dnf install vault-1.21.4"
    su - -c "setcap cap_ipc_lock= /usr/bin/vault"
fi
touch /home/oracle/install_script_run
mkdir -p /home/oracle/wallet_root
