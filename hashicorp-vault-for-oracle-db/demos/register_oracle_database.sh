#!/bin/bash -x

clear
vault plugin register -sha256=`sha256sum /root/vault-plugins/vault-plugin-database-oracle|cut -d' ' -f1` database vault-plugin-database-oracle
vault plugin list | grep oracle

sleep 5s

vault secrets enable database

sleep 5s

vault write database/config/oracle \
    plugin_name=vault-plugin-database-oracle \
    allowed_roles="*" \
    connection_url='{{username}}/{{password}}@//oracle:1521/freepdb1' \
    username='vault' \
    password='vault'

sleep 5s

vault write -force database/rotate-root/oracle

sleep 5s

vault write database/roles/app1 \
    db_name=oracle \
    creation_statements='CREATE USER {{username}} IDENTIFIED BY "{{password}}"; GRANT CREATE SESSION TO {{username}}; ALTER USER app1 GRANT CONNECT THROUGH {{username}};' \
    default_ttl="7d" \
    max_ttl="10d"
