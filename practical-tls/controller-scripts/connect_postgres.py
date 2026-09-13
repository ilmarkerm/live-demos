#!/root/venv_test/bin/python
"""
Connect to PostgreSQL over TLS using the psycopg (v3) driver and list all
rows from the hello_world table.
"""

import sys

import psycopg

# --- Connection settings -----------------------------------------------
db_host = "postgres.practical-tls_demo-net"
db_port = "5432"
db_name = "app1"

# CA certificate used to verify the server's certificate (verify-full).
# It is in system store, but somehow didn't get system store to work here
root_cert = "/etc/pki/ca-trust/source/anchors/vault_demo_root.pem"

def build_dsn() -> str:
    from urllib.parse import quote
    dsn = f"host={args.hostname} port={db_port} dbname={db_name} sslmode={args.sslmode} sslrootcert={root_cert} user={args.username}"
    if args.password:
        dsn += f" password={quote(args.password, safe='')}"
    if args.mtls:
        dsn += " sslcert=/root/user_cert.crt sslkey=/root/user_cert.key"
    print(f"\n\nDSN: {dsn}\n\n")
    return dsn


def parse_args():
    import argparse

    parser = argparse.ArgumentParser(
        description="Connect to PostgreSQL over TLS using psycopg3."
    )
    parser.add_argument(
        "username",
        help="Database username to connect as.",
    )
    parser.add_argument(
        "--mtls",
        action="store_true",
        help="Enable mutual TLS (mTLS) by presenting a client certificate/key.",
    )
    parser.add_argument(
        "--password",
        help="Database user password, if mTLS is not used.",
    )
    parser.add_argument(
        "--hostname",
        default=db_host,
        help=f"Database hostname to use. Useful for demonstrating hostname mismatch. Default: {db_host}.",
    )
    parser.add_argument(
        "--sslmode",
        default="verify-full",
        help="SSLMODE. Default: verify-full.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    try:
        connection = psycopg.connect(build_dsn())

        print("\n\nDatabase connection successful, now trying a query")
        with connection.cursor() as cursor:
            cursor.execute("SELECT session_user, current_user")
            rows = cursor.fetchall()

            if rows:
                for session_user, current_user in rows:
                    print(f"  session_user={session_user} current_user={current_user}")

    except psycopg.Error as e:
        print(f"Database connection/query failed: {e}", file=sys.stderr)
        sys.exit(1)
