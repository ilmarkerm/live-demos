cd /root
git clone https://github.com/hashicorp/vault-plugin-database-oracle.git
cd vault-plugin-database-oracle
export PKG_CONFIG_PATH=/root/pkgconfig
/usr/local/go/bin/go build -o vault-plugin-database-oracle ./plugin
mv vault-plugin-database-oracle /root/vault-plugins/
