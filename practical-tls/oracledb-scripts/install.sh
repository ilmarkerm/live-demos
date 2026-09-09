#!/bin/bash

su - -c "echo '' > /etc/dnf/vars/ociregion"
su - -c "dnf install yum-utils vim unzip less sudo jq"
su - -c "yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
su - -c "dnf install vault-1.21.4"
su - -c "setcap cap_ipc_lock= /usr/bin/vault"
