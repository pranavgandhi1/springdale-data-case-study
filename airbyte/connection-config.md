# Airbyte Connection Configuration

Reference documentation for the Airbyte Cloud connection that extracts data
from the source Google Sheet and lands it in Snowflake `SPRINGDALE_RAW.IT_SOURCE`.
Re-creating this is a one-time setup; this file captures the settings so anyone
reproducing the case study can configure their own connection.

## Source: Google Sheets

| Setting | Value |
|---|---|
| Type | Google Sheets |
| Source name | Springdale IT Sheet |
| Spreadsheet link | URL to a personal copy of the source spreadsheet (must be a native Google Sheet, not an uploaded .xlsx) |
| Authentication method | Service Account Key Authentication |
| Service account | `airbyte-sheets-reader@<your-gcp-project>.iam.gserviceaccount.com`, granted Viewer access on the spreadsheet |

### Optional source settings enabled

- **Convert Column Names to SQL-Compliant Format**: ON. Source headers like `ID Ticket` become `id_ticket`. Avoids needing to quote column names in dbt.
- **Stream Name Overrides**: rename the sheet tabs to `it_tickets` and `it_agents` so the resulting Snowflake table names are clean.

### Notes on source data prep

The source file was originally an Excel (.xlsx) document that copied into Drive as a non-native file. The Google Sheets API only operates on native Google Sheets documents, so the file must be converted via `File → Save as Google Sheets` before connecting. Sharing a non-native file with the service account produces a 400 error ("This operation is not supported for this document").

## Destination: Snowflake

| Setting | Value |
|---|---|
| Type | Snowflake |
| Destination name | Springdale Snowflake RAW |
| Host | `<account_locator>.snowflakecomputing.com` |
| Role | `LOADER_ROLE` |
| Warehouse | `TRANSFORM_WH` |
| Database | `SPRINGDALE_RAW` |
| Default schema | `IT_SOURCE` |
| Authentication method | Username and Password |
| Username | Snowflake user that holds `LOADER_ROLE` |

The Snowflake objects (database, schema, roles, warehouse) are created by `dbt/setup/snowflake_setup.sql`. Run that first.

## Connection

| Setting | Value |
|---|---|
| Source | Springdale IT Sheet |
| Destination | Springdale Snowflake RAW |
| Streams enabled | `it_tickets`, `it_agents` |
| Sync mode | Full refresh + Overwrite + Deduped (both streams) |
| Primary key | `it_tickets`: `id_ticket`; `it_agents`: `agent_id` |
| Replication frequency | Manual (set to Daily after the first verified sync) |
| Destination namespace | Custom format → `IT_SOURCE` |

## Reproducing this setup

1. Make a personal copy of the source spreadsheet, save as a native Google Sheet
2. Create a GCP service account, enable Sheets API and Drive API, generate a JSON key
3. Share your sheet copy with the service account email (Viewer)
4. Run `dbt/setup/snowflake_setup.sql` in Snowsight as ACCOUNTADMIN
5. In Airbyte Cloud, create the source and destination using the values above
6. Create the connection, enable both streams, trigger a sync
7. Verify in Snowsight: `SELECT count(*) FROM SPRINGDALE_RAW.IT_SOURCE.IT_TICKETS;`
