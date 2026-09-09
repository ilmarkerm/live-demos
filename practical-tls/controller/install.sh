#!/bin/bash

testroot=/root
venvpath="${testroot}/venv_test"
python3.12 -m venv "$venvpath"
"${venvpath}/bin/pip" install --upgrade pip
"${venvpath}/bin/pip" install psycopg[binary] oracledb

dnf install yum-utils netcat
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install terraform vault-1.21.4
setcap cap_ipc_lock= /usr/bin/vault

goversion="go1.26.8.linux-arm64.tar.gz"
curl -L -o "/root/${goversion}" "https://go.dev/dl/${goversion}"
tar -C /usr/local -xzf "/root/${goversion}"
rm -f "/root/${goversion}"
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bash_profile
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.profile
