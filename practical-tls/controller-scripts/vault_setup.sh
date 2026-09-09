#!/bin/bash

rootpath="/root/vault_terraform"
mkdir -p "$rootpath"
export TF_DATA_DIR="$rootpath/.terraform"

cd /root/vault
[ -d "$rootpath/.terraform" ] || terraform init
terraform plan
read -p "Press enter to continue"
terraform apply
