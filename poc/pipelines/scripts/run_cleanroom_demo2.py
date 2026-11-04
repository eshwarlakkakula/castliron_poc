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

CLEANROOM_NAME = "CastIron Audience Room"

statements = [
    "USE WAREHOUSE APP_WH",

    "CALL samooha_by_snowflake_local_db.provider.register_db('CASTIRON_POC')",

    f"""CALL samooha_by_snowflake_local_db.provider.link_datasets('{CLEANROOM_NAME}',
        ['CASTIRON_POC.RAW.AUDIENCE_EVENTS'])""",

    f"""CALL samooha_by_snowflake_local_db.provider.set_join_policy('{CLEANROOM_NAME}',
        ['CASTIRON_POC.RAW.AUDIENCE_EVENTS:HOUSEHOLD_ID'])""",

    f"""CALL samooha_by_snowflake_local_db.provider.set_column_policy('{CLEANROOM_NAME}',
        ['castiron_overlap_template:CASTIRON_POC.RAW.AUDIENCE_EVENTS:EVENT_TYPE'])""",

    f"CALL samooha_by_snowflake_local_db.provider.view_cleanrooms()",
]

cursor = conn.cursor()
for stmt in statements:
    try:
        cursor.execute(stmt)
        rows = cursor.fetchall()
        print(f"OK: {stmt[:90]!r}\n  -> {rows}\n")
    except Exception as exc:
        print(f"FAIL: {stmt[:90]!r}\n  -> {exc}\n")

cursor.close()
conn.close()
