import os
import pathlib

import snowflake.connector

SNOWFLAKE_ACCOUNT = os.environ["SNOWFLAKE_ACCOUNT"]
SNOWFLAKE_USER = os.environ["SNOWFLAKE_USER"]

token = pathlib.Path(__file__).parent.parent.joinpath(".snowflake_pat").read_text().strip()

conn = snowflake.connector.connect(
    account=SNOWFLAKE_ACCOUNT,
    user=SNOWFLAKE_USER,
    token=token,
    role="ACCOUNTADMIN",
    authenticator="PROGRAMMATIC_ACCESS_TOKEN",
)

CLEANROOM_NAME = "CastIron Audience Room"
TEMPLATE_NAME = "castiron_overlap_v2"
DATASET = "CASTIRON_POC.RAW.AUDIENCE_EVENTS"

# provider.set_join_policy / set_column_policy are not used here: this installed
# version has a broken string-parsing implementation (crashes inside the vendor's
# own bundled navlib, reproduced against Snowflake's own sample tables too — see
# POC-Validation-Log.md section 9). The join and grouping column are hardcoded in
# the template below instead; the room still only ever releases the aggregate.
CUSTOM_SQL_TEMPLATE = f"""
SELECT
  COUNT(*) AS match_count,
  P.EVENT_TYPE
FROM IDENTIFIER({{{{my_table[0]}}}}) AS C
INNER JOIN IDENTIFIER({{{{source_table[0]}}}}) AS P
  ON C.HOUSEHOLD_ID = P.HOUSEHOLD_ID
GROUP BY P.EVENT_TYPE;
"""

provider_statements = [
    "USE WAREHOUSE APP_WH",
    "ALTER SESSION SET USE_SECONDARY_ROLES = NONE",
    f"CALL samooha_by_snowflake_local_db.provider.cleanroom_init('{CLEANROOM_NAME}', 'INTERNAL')",
    f"CALL samooha_by_snowflake_local_db.provider.register_db('{DATASET.split('.')[0]}')",
    f"CALL samooha_by_snowflake_local_db.provider.link_datasets('{CLEANROOM_NAME}', ['{DATASET}'])",
    f"CALL samooha_by_snowflake_local_db.provider.add_custom_sql_template('{CLEANROOM_NAME}', '{TEMPLATE_NAME}', $${CUSTOM_SQL_TEMPLATE}$$)",
]

# Single-account "internal testing" pattern: the provider self-invites the same
# account as a consumer, so this demo needs no second Snowflake account.
self_invite_statements = [
    "SELECT CURRENT_ACCOUNT()",
    "SELECT CURRENT_ORGANIZATION_NAME() || '.' || CURRENT_ACCOUNT_NAME()",
]

cursor = conn.cursor()
results = {}
for stmt in provider_statements + self_invite_statements:
    try:
        cursor.execute(stmt)
        rows = cursor.fetchall()
        print(f"OK: {stmt[:90]!r}\n  -> {rows}\n")
        results[stmt] = rows
    except Exception as exc:
        print(f"FAIL: {stmt[:90]!r}\n  -> {exc}\n")

account_locator = results.get("SELECT CURRENT_ACCOUNT()", [[None]])[0][0]
org_account = results.get(
    "SELECT CURRENT_ORGANIZATION_NAME() || '.' || CURRENT_ACCOUNT_NAME()", [[None]]
)[0][0]

finish_statements = [
    f"CALL samooha_by_snowflake_local_db.provider.add_consumers('{CLEANROOM_NAME}', '{account_locator}', '{org_account}')",
    f"CALL samooha_by_snowflake_local_db.provider.create_or_update_cleanroom_listing('{CLEANROOM_NAME}')",
    f"CALL samooha_by_snowflake_local_db.consumer.install_cleanroom('{CLEANROOM_NAME}', '{account_locator}')",
    f"CALL samooha_by_snowflake_local_db.consumer.link_datasets('{CLEANROOM_NAME}', ['{DATASET}'])",
    (
        f"CALL samooha_by_snowflake_local_db.consumer.run_analysis('{CLEANROOM_NAME}', '{TEMPLATE_NAME}', "
        f"['{DATASET}'], ['{DATASET}'], OBJECT_CONSTRUCT())"
    ),
]

for stmt in finish_statements:
    try:
        cursor.execute(stmt)
        rows = cursor.fetchall()
        print(f"OK: {stmt[:90]!r}\n  -> {rows}\n")
    except Exception as exc:
        print(f"FAIL: {stmt[:90]!r}\n  -> {exc}\n")

cursor.close()
conn.close()
