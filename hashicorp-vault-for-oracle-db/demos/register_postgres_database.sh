#!/bin/bash -x

vault secrets enable database

sleep 5s

vault write database/config/postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url='postgresql://{{username}}:{{password}}@postgres:5432/postgres' \
    password_authentication="scram-sha-256" \
    username='postgres' \
    password='postgres'

sleep 5s

vault write -force database/rotate-root/postgres

sleep 5s

vault write database/roles/pgapp1 \
    db_name=postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="7d" \
    max_ttl="10d"
