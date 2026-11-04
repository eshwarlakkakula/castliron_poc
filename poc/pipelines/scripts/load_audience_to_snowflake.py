import pathlib

import snowflake.connector

token = pathlib.Path(__file__).parent.parent.joinpath(".snowflake_pat").read_text().strip()
csv_path = pathlib.Path(__file__).parent.joinpath("downloaded", "castiron_audience_export.csv").resolve()

conn = snowflake.connector.connect(
    account="zmxpezl-wu66003",
    user="VEERA664",
    token=token,
    role="ACCOUNTADMIN",
    authenticator="PROGRAMMATIC_ACCESS_TOKEN",
)

statements = [
    "CREATE DATABASE IF NOT EXISTS CASTIRON_POC",
    "CREATE SCHEMA IF NOT EXISTS CASTIRON_POC.RAW",
    """CREATE OR REPLACE TABLE CASTIRON_POC.RAW.AUDIENCE_EVENTS (
        request_id STRING,
        event_type STRING,
        event_timestamp STRING,
        device_id STRING,
        household_id STRING,
        ip_address STRING
    )""",
    "CREATE OR REPLACE STAGE CASTIRON_POC.RAW.LOAD_STAGE",
    f"PUT file://{csv_path.as_posix()} @CASTIRON_POC.RAW.LOAD_STAGE OVERWRITE=TRUE",
    """COPY INTO CASTIRON_POC.RAW.AUDIENCE_EVENTS
       FROM @CASTIRON_POC.RAW.LOAD_STAGE/castiron_audience_export.csv
       FILE_FORMAT = (TYPE=CSV SKIP_HEADER=1 FIELD_OPTIONALLY_ENCLOSED_BY='"')""",
    "SELECT COUNT(*) FROM CASTIRON_POC.RAW.AUDIENCE_EVENTS",
]

cursor = conn.cursor()
for stmt in statements:
    try:
        cursor.execute(stmt)
        rows = cursor.fetchall()
        print(f"OK: {stmt[:80]!r}\n  -> {rows}\n")
    except Exception as exc:
        print(f"FAIL: {stmt[:80]!r}\n  -> {exc}\n")

cursor.close()
conn.close()
