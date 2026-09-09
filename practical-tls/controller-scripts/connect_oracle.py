#!/root/venv_test/bin/python
"""
Connect to Oracle Database over TCPS using the python-oracledb thin driver
and list all object names from USER_OBJECTS.
"""

from ssl import create_default_context, TLSVersion, CERT_REQUIRED
from oracledb import connect, Connection

import os
import sys

import oracledb

# --- Connection settings -----------------------------------------------
# Credentials: override via environment variables, or hardcode for a demo.
db_user = os.environ.get("ORACLE_USER", "demo")
db_password = os.environ.get("ORACLE_PASSWORD", "demo123")

# TCPS (TLS) Easy Connect string
dsn = "tcps://oracledb.practical-tls_demo-net:1522/FREEPDB1"

def connect_oracledb(db_dsn:str, db_user:str, db_password:str) -> Connection:
    ''' Connect to Oracle DB using TLS, with support for LDAPS lookups

    Parameters:
        db_dsn(str): Database connection DNS. Can also be LDAP string.
        db_user(str): Database username for login
        db_password(str): Database password

    Returns:
        (oracledb.Connection): Connection object to the database
    '''
    from importlib.metadata import version

    # Check that oracledb module is updated. It must be at least version 3 to have DNS lookups working properly.
    oracledb_version = version('oracledb')
    if oracledb_version[1] == '.' and int(oracledb_version[0]) < 3:
        raise Exception("oracledb module is too old, please upgrade")
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
        dsn = db_dsn,
        ssl_context = tls_ctx,
    )


if __name__ == "__main__":
    try:
        with connect_oracledb(dsn, db_user, db_password) as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT object_name, object_type FROM user_objects ORDER BY object_name"
                )
                rows = cursor.fetchall()

                if rows:
                    print(f"Found {len(rows)} object(s):")
                    for object_name, object_type in rows:
                        print(f"  {object_name} ({object_type})")
                else:
                    print("No objects found in user_objects.")

    except oracledb.Error as e:
        print(f"Database connection/query failed: {e}", file=sys.stderr)
        sys.exit(1)
