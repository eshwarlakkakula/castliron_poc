import pathlib

import snowflake.connector

token = pathlib.Path(__file__).parent.parent.joinpath(".snowflake_pat").read_text().strip()

conn = snowflake.connector.connect(
    account="zmxpezl-wu66003",
    user="VEERA664",
    token=token,
    role="ACCOUNTADMIN",
    authenticator="PROGRAMMATIC_ACCESS_TOKEN",
)

statements = [
    "SHOW ROLES LIKE 'SAMOOHA%'",
    "USE ROLE SAMOOHA_APP_ROLE",
    "USE WAREHOUSE APP_WH",
    "SELECT CURRENT_ROLE()",
    "CALL SAMOOHA_BY_SNOWFLAKE_LOCAL_DB.LIBRARY.CHECK_MOUNT_STATUS()",
]

cursor = conn.cursor()
for stmt in statements:
    try:
        cursor.execute(stmt)
        rows = cursor.fetchall()
        print(f"OK: {stmt}\n  -> {rows}\n")
    except Exception as exc:
        print(f"FAIL: {stmt}\n  -> {exc}\n")

cursor.close()
conn.close()
