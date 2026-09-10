#!/root/venv_test/bin/python
"""
Connect to Oracle Database over TCPS using the python-oracledb thin driver
and list all object names from USER_OBJECTS.
"""

import os
import sys

import oracledb

# Initialises the thick client
oracledb.init_oracle_client()

# --- Connection settings -----------------------------------------------
# Credentials: override via environment variables, or hardcode for a demo.
db_user = os.environ.get("ORACLE_USER", "demo")
db_password = os.environ.get("ORACLE_PASSWORD", "demo123")
db_host = "oracledb.practical-tls_demo-net"

def build_dsn() -> str:
    return f"tcps://{args.hostname}:1522/FREEPDB1?SSL_SERVER_DN_MATCH={ 'OFF' if args.server_dn_match_off else 'ON' }"

def connect_oracledb_password(db_user:str, db_password:str) -> oracledb.Connection:
    # Connect to the database using previously established TLS context
    connect_dsn = build_dsn()
    print(f"DSN: {connect_dsn}")
    return oracledb.connect(
        user = db_user,
        password = db_password,
        dsn = connect_dsn,
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
