#!/bin/bash

rootpath="/root/vault_terraform"
mkdir -p "$rootpath"
export TF_DATA_DIR="$rootpath/.terraform"

cd /root/vault
[ -d "$rootpath/.terraform" ] || terraform init


if [[ -z "$1" || "$1" == "apply" ]]; then
    #terraform plan
    #read -p "Press enter to continue"
    terraform apply
elif [ "$1" == "destroy" ]; then
    terraform destroy
fi
