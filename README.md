# TfL Bikepoint Data Pipeline

An end-to-end pipeline ingesting real-time London bike-share data from the TfL API into a Snowflake data warehouse, modelled into fact and slowly-changing dimension tables.

---

## Architecture

```
TfL BikePoint API     ◄──── extract_and_load.py  ◄──── GitHub Actions (OR Manual run)
        │
        ▼
  AWS S3 Bucket     
        │
 Snowflake Stage     ◄──── Snowpipe (SQS notification)
        │
        ▼
   Raw Table
        │ 
        ▼
        Snowflake Stream     
                       │     ◄──── Stored Procedure  ◄──── Snowflake Task
                       ▼
                  Base Table     
                 /           \     ◄──── Stored Procedure  ◄──── Snowflake Task
                ▼             ▼
          Fact Table    Dimension Table
         (snapshots)      (SCD Type 2)
```

---

## Project Structure

```
├── 1_Extract_and_Load/
│   ├── modules/
│   │   ├── extract_module.py              # TfL API call + retry logic
│   │   ├── load_module.py                 # S3 upload + local cleanup
│   │   └── setup_logging.py              # Shared logging config
│   ├── 0_extract_and_load.py             # Entry point
│   └── 1_github_actions_orchestration.yml
│
├── 2_Transform/
│   ├── 0_load_from_s3_to_snowflake_raw_table.sql
│   ├── 1_create_base_table_from_raw_table.sql
│   ├── 2_create_silver_fact_table_from_base_table.sql
│   └── 3_create_silver_dim_table_from_base_table.sql
│
└── 3_Automation/
    ├── 0_create_snowpipe_and_stream.sql
    ├── 1_insert_data_from_stream_to_base_table.sql
    ├── 2_insert_data_from_base_table_to_silver_fact_table.sql
    ├── 3_insert_data_from_base_table_to_silver_dim_table.sql
    ├── 4_create_stored_procedure_to_automate_stream_to_silver_tables.sql
    └── 5_create_task_to_run_stored_procedure.sql
```

---

## How It Works

**Extract & Load** — GitHub Actions runs the pipeline on a schedule. `extract_module.py` calls the TfL API and saves a timestamped JSON file locally. `load_module.py` uploads it to S3 via `boto3` and deletes the local copy. AWS credentials are injected as GitHub environment secrets.

**Ingestion** — Snowpipe detects new S3 files via SQS and auto-ingests them into the raw table (`json VARIANT`, `filename STRING`). A Snowflake stream on the raw table tracks new rows.

**Transformation** — A stored procedure (triggered every minute by a stream-gated task) runs four steps: parse + flatten + pivot the JSON stream into the base table; incrementally insert new snapshots into the fact table; use a `MERGE` to retire changed dimension records (SCD Type 2); insert the updated active version.

---

## Setup

**Prerequisites:** Python 3.12+, AWS S3 bucket + IAM credentials, Snowflake account, GitHub repo with Actions enabled.

```bash
# Install dependencies
pip install -r requirements.txt

# Create .env for local runs
AWS_ACCESS_KEY=your_key
AWS_SECRET_KEY=your_secret
bucket=your_bucket_name

# Run manually
python 1_Extract_and_Load/0_extract_and_load.py
```

**Snowflake:** Run scripts in `2_Transform/` in order to set up the initial tables, then run `3_Automation/` in order to configure Snowpipe, the stream, stored procedure, and task. Update the IAM role ARN and S3 URL placeholders in `0_load_from_s3_to_snowflake_raw_table.sql` before running.

**GitHub Actions:** Add `AWS_ACCESS_KEY`, `AWS_SECRET_KEY`, and `bucket` as secrets under the `bikepoint-ingestion` environment, then uncomment the `on: schedule` block in `1_github_actions_orchestration.yml`.

---

## Tech Stack

| Layer | Tool |
|-------|------|
| Scheduling | GitHub Actions |
| Source | TfL Unified API |
| Storage | AWS S3 |
| Ingestion | Snowflake Snowpipe + SQS |
| Transformation | Snowflake SQL stored procedure |
| Orchestration | Snowflake Tasks + Streams |
