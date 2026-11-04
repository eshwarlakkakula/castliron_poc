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
    "ALTER SESSION SET USE_SECONDARY_ROLES = NONE",

    f"CALL samooha_by_snowflake_local_db.provider.cleanroom_init('{CLEANROOM_NAME}', 'INTERNAL')",

    f"""CALL samooha_by_snowflake_local_db.provider.link_datasets('{CLEANROOM_NAME}',
        ['CASTIRON_POC.RAW.AUDIENCE_EVENTS'])""",

    f"""CALL samooha_by_snowflake_local_db.provider.set_join_policy('{CLEANROOM_NAME}',
        ['CASTIRON_POC.RAW.AUDIENCE_EVENTS:HOUSEHOLD_ID'])""",

    f"""CALL samooha_by_snowflake_local_db.provider.add_custom_sql_template(
        '{CLEANROOM_NAME}',
        'castiron_overlap_template',
        $$
        SELECT
          COUNT(*),
          IDENTIFIER({{{{group_by_col | column_policy}}}})
        FROM IDENTIFIER({{{{my_table[0]}}}}) AS C
        INNER JOIN
          IDENTIFIER({{{{source_table[0]}}}}) AS P
          ON IDENTIFIER({{{{consumer_join_col | join_policy}}}}) = IDENTIFIER({{{{provider_join_col | join_policy}}}})
        GROUP BY IDENTIFIER({{{{group_by_col | column_policy}}}});
        $$)""",

    f"""CALL samooha_by_snowflake_local_db.provider.set_column_policy('{CLEANROOM_NAME}',
        ['castiron_overlap_template:CASTIRON_POC.RAW.AUDIENCE_EVENTS:EVENT_TYPE'])""",

    f"CALL samooha_by_snowflake_local_db.provider.set_default_release_directive('{CLEANROOM_NAME}', 'V1_0', '0')",

    "SELECT CURRENT_ACCOUNT()",
    "SELECT CURRENT_ORGANIZATION_NAME() || '.' || CURRENT_ACCOUNT_NAME()",
]

cursor = conn.cursor()
results = {}
for stmt in statements:
    try:
        cursor.execute(stmt)
        rows = cursor.fetchall()
        print(f"OK: {stmt[:90]!r}\n  -> {rows}\n")
        results[stmt] = rows
    except Exception as exc:
        print(f"FAIL: {stmt[:90]!r}\n  -> {exc}\n")

cursor.close()
conn.close()
