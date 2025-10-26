#!/bin/bash

# Download software packages here

# go
declare -a gov="1.23.10 1.25.0 1.25.2"
for v in "${gov[@]}"; do
    fn = "go${v}.linux-arm64.tar.gz"
    [ -f "$fn" ] || curl -o "$fn" "https://go.dev/dl/${fn}"
done

# terraform
vers="1.13.4"
fn="terraform_${vers}_linux_arm64.zip"
[ -f "$fn" ] || curl -o "$fn" "https://releases.hashicorp.com/terraform/${vers}/${fn}"
fn="terraform_${vers}_darwin_arm64.zip"
[ -f "$fn" ] || curl -o "$fn" "https://releases.hashicorp.com/terraform/${vers}/${fn}"

# vault
vers="1.20.4"
fn="vault_${vers}_linux_arm64.zip"
[ -f "$fn" ] || curl -o "$fn" "https://releases.hashicorp.com/vault/${vers}/${fn}"
fn="vault_${vers}_darwin_arm64.zip"
[ -f "$fn" ] || curl -o "$fn" "https://releases.hashicorp.com/vault/${vers}/${fn}"

/Users/ilmarkerm/live-demos/software/instantclient-basic-linux.arm64-19.28.0.0.0dbru.zip
/Users/ilmarkerm/live-demos/software/instantclient-sdk-linux.arm64-19.28.0.0.0dbru.zip
/Users/ilmarkerm/live-demos/software/oracle-instantclient19.28-basic-19.28.0.0.0-1.el9.aarch64.rpm
/Users/ilmarkerm/live-demos/software/oracle-instantclient19.28-devel-19.28.0.0.0-1.el9.aarch64.rpm
