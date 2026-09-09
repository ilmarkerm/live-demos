#!/bin/bash

set -x

cat /home/oracle/scripts/listener.ora
read -p "Press Enter to continue..."

echo "Replacing listener.ora to enable TCPS endpoint"
cp /home/oracle/scripts/listener.ora /opt/oracle/product/26ai/dbhomeFree/network/admin/listener.ora

echo "Restarting the listener... reload is not enough"
lsnrctl stop && lsnrctl start
lsnrctl status

sleep 5s

echo "Diagnose the TCPS endpoint with openssl"
echo -n | openssl s_client -connect localhost:1522 -showcerts | less

echo "Replacing sqlnet.ora"

cat /home/oracle/scripts/sqlnet.ora
read -p "Press Enter to continue..."

cp /home/oracle/scripts/sqlnet.ora /opt/oracle/product/26ai/dbhomeFree/network/admin/sqlnet.ora
