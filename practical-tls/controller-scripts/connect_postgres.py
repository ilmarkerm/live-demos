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


def connect_postgres_password(
    host: str, port: str, dbname: str, user: str, password: str
) -> psycopg.Connection:
    # sslmode=verify-full validates the server certificate against the CA
    # and confirms the certificate's hostname matches the host we connect to.
    return psycopg.connect(
        host=host,
        port=port,
        dbname=dbname,
        user=user,
        password=password,
        sslmode="verify-full",
        # sslrootcert="system" should work, but can't get it to work right now
        sslrootcert=root_cert,
    )


def connect_postgres_mtls(
    host: str,
    port: str,
    dbname: str,
    user: str,
    sslcert: str,
    sslkey: str,
) -> psycopg.Connection:
    # With mTLS the client certificate itself authenticates the connection,
    # so no password is required (the server maps the certificate's CN to
    # a database role via clientcert/cert auth in pg_hba.conf).
    return psycopg.connect(
        host=host,
        port=port,
        user=user,
        dbname=dbname,
        sslmode="verify-full",
        sslrootcert=root_cert,
        sslcert=sslcert,
        sslkey=sslkey,
    )


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
        if args.mtls:
            connection = connect_postgres_mtls(
                args.hostname,
                db_port,
                db_name,
                args.username,
                "/root/user_cert.crt",
                "/root/user_cert.key",
            )
        else:
            connection = connect_postgres_password(
                args.hostname, db_port, db_name, args.username, args.password
            )

        print("Database connection successful, now trying a query")
        with connection.cursor() as cursor:
            cursor.execute("SELECT session_user, current_user")
            rows = cursor.fetchall()

            if rows:
                for session_user, current_user in rows:
                    print(f"  session_user={session_user} current_user={current_user}")

    except psycopg.Error as e:
        print(f"Database connection/query failed: {e}", file=sys.stderr)
        sys.exit(1)
