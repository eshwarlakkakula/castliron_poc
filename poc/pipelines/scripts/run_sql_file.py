import argparse
import os
import pathlib

import snowflake.connector


def main() -> None:
    parser = argparse.ArgumentParser(description="Execute a multi-statement .sql file against Snowflake using a PAT")
    parser.add_argument("sql_file")
    args = parser.parse_args()

    token = pathlib.Path(__file__).parent.parent.joinpath(".snowflake_pat").read_text().strip()
    sql_text = pathlib.Path(args.sql_file).read_text(encoding="utf-8")

    conn = snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        token=token,
        role="ACCOUNTADMIN",
        authenticator="PROGRAMMATIC_ACCESS_TOKEN",
    )

    for cursor in conn.execute_string(sql_text):
        try:
            rows = cursor.fetchall()
        except Exception:
            rows = None
        print(f"OK: {cursor.query[:120]!r}\n  -> {rows}\n")

    conn.close()


if __name__ == "__main__":
    main()
