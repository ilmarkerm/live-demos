# Start docker Linux

dnf install gcc make unzip less vim man-db git /live-demos/hashicorp-vault-for-oracle-db/oracle-instantclient19.28-basic-19.28.0.0.0-1.el9.aarch64.rpm /live-demos/hashicorp-vault-for-oracle-db/oracle-instantclient19.28-devel-19.28.0.0.0-1.el9.aarch64.rpm

# Unzip 
[ -f /usr/local/bin/terraform ] || unzip /live-demos/hashicorp-vault-for-oracle-db/terraform_1.13.3_linux_arm64.zip terraform -d /usr/local/bin/
[ -f /usr/local/bin/vault ] || unzip /live-demos/hashicorp-vault-for-oracle-db/vault_1.20.4_linux_arm64.zip vault -d /usr/local/bin/

# Oracle plugin for Vault
cd /root
rm -rf /usr/local/go && tar -C /usr/local -xzf /live-demos/go1.25.2.linux-arm64.tar.gz
git clone https://github.com/hashicorp/vault-plugin-database-oracle.git
cd vault-plugin-database-oracle
export PKG_CONFIG_PATH=/live-demos/hashicorp-vault-for-oracle-db
/usr/local/go/bin/go build -o vault-plugin-database-oracle ./plugin
mkdir -p /root/vault-plugins
mv vault-plugin-database-oracle /root/vault-plugins/

# docker commit hashidemo-vault

# Start Vault
vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200 -config /live-demos/hashicorp-vault-for-oracle-db/server_config.hcl
