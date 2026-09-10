#!/root/venv_test/bin/python
"""
Connect to Oracle Database over TCPS using the python-oracledb thin driver
and list all object names from USER_OBJECTS.
"""

from ast import Pass
from ssl import create_default_context, TLSVersion, CERT_REQUIRED
from oracledb import connect, Connection

import os
import sys

import oracledb

# oracledb.init_oracle_client()

# --- Connection settings -----------------------------------------------
# Credentials: override via environment variables, or hardcode for a demo.
db_user = os.environ.get("ORACLE_USER", "demo")
db_password = os.environ.get("ORACLE_PASSWORD", "demo123")

# TCPS (TLS) Easy Connect string
#dsn = "tcps://oracledb.practical-tls_demo-net:1522/FREEPDB1"
db_host = "oracledb.practical-tls_demo-net"

def build_dsn() -> str:
    dsn = f"tcps://{args.hostname}:1522/FREEPDB1?SSL_SERVER_DN_MATCH={ 'OFF' if args.server_dn_match_off else 'ON' }"
    print(f"DSN: {dsn}")
    return dsn


def connect_oracledb_password(db_user:str, db_password:str) -> Connection:
    # Create TLS context for encryption and certificate validation
    # This also allows to use system trusted issuers
    tls_ctx = create_default_context()
    tls_ctx.minimum_version = TLSVersion.TLSv1_2
    tls_ctx.verify_mode = CERT_REQUIRED
    tls_ctx.set_ciphers('HIGH')
    #
    # Connect to the database using previously established TLS context
    return connect(
        user = db_user,
        password = db_password,
        dsn = build_dsn(),
        ssl_context = tls_ctx,
    )

def connect_oracledb_mlts(user_certfile:str, user_keyfile:str) -> Connection:
    # Create TLS context for encryption and certificate validation
    # This also allows to use system trusted issuers
    #tls_ctx = create_default_context()
    #tls_ctx.minimum_version = TLSVersion.TLSv1_2
    #tls_ctx.verify_mode = CERT_REQUIRED
    #tls_ctx.set_ciphers('HIGH')
    #tls_ctx.load_cert_chain(certfile=user_certfile, keyfile=user_keyfile)
    #
    # Connect to the database using previously established TLS context
    return connect(
        user = "demo",
        password="demo123",
        #password = db_password,
        dsn = build_dsn(),
        wallet_location="/root/oracledb_thin_wallet",
        #externalauth=True,
    )

def parse_args():
    import argparse
    parser = argparse.ArgumentParser(
        description="Connect to Oracle Database over TCPS using python-oracledb."
    )
    parser.add_argument(
        "--mtls",
        action="store_true",
        help="Enable mutual TLS (mTLS) by presenting a client certificate/key.",
    )
    parser.add_argument(
        "--server-dn-match-off",
        action="store_true",
        help="Disable strict hostname checking.",
    )
    parser.add_argument(
        "--hostname",
        default=db_host,
        help=f"Database hostname to use. Useful for demonstrating hostname mismatch. Default: {db_host}.",
    )
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    try:
        if args.mtls:
            connection = connect_oracledb_mlts("/root/user_cert.crt", "/root/user_cert.key")
        else:
            connection = connect_oracledb_password(db_user, db_password)
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT id, message FROM hello_world ORDER BY id"
            )
            rows = cursor.fetchall()

            if rows:
                for row_id, row_message in rows:
                    print(f"  {row_id} {row_message}")
            else:
                print("HELLO_WORLD table is empty")

    except oracledb.Error as e:
        print(f"Database connection/query failed: {e}", file=sys.stderr)
        sys.exit(1)
