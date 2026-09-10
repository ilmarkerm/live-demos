#!/bin/bash


# Create python venvh with necessary modules
testroot=/root
venvpath="${testroot}/venv_test"
python3.12 -m venv "$venvpath"
"${venvpath}/bin/pip" install --upgrade pip
"${venvpath}/bin/pip" install psycopg[binary] oracledb cryptography

# Install some useful packages and java
dnf install yum-utils netcat jq oracle-instantclient-release-26ai-el9
dnf install java-17-openjdk java-21-openjdk

# Install Vault
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install terraform vault-1.21.4
setcap cap_ipc_lock= /usr/bin/vault

# Install Oracle Instantclient
dnf install oracle-instantclient-basic oracle-instantclient-jdbc oracle-instantclient-sqlplus oracle-instantclient-tools

# Install Go
if [ "$(uname -m)" = "x86_64" ]; then
    goarch="amd64"
else
    goarch="arm64"
fi
goversion="go1.26.8.linux-${goarch}.tar.gz"
curl -L -o "/root/${goversion}" "https://go.dev/dl/${goversion}"
tar -C /usr/local -xzf "/root/${goversion}"
rm -f "/root/${goversion}"
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bash_profile
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.profile

# Install PostgreSQL client programs
pgarch=`uname -m`
pgmajor="18"
dnf install "https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-${pgarch}/pgdg-redhat-repo-latest.noarch.rpm"
dnf install postgresql${pgmajor}
