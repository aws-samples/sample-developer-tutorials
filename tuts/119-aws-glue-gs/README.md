# Glue: Create a Data Catalog database and table

Create an AWS Glue Data Catalog database, upload sample JSON data to S3, create an external table pointing to the data, and query the catalog.

## Source

https://docs.aws.amazon.com/glue/latest/dg/getting-started.html

## Use case

- **ID**: glue/getting-started
- **Level**: beginner
- **Core actions**: `glue:CreateDatabase`, `glue:CreateTable`, `glue:GetTable`, `glue:GetDatabases`, `glue:GetTables`

## Steps

1. Create a Glue database
2. Create an S3 bucket and upload sample data
3. Create an external table with JSON SerDe
4. Describe the table
5. List databases and tables

## Resources created

| Resource | Type |
|----------|------|
| `tut_db_<random>` | Glue database |
| `tut_events` | Glue table |
| `glue-tut-<random>-<account>` | S3 bucket (with sample data) |

## Duration

~12 seconds

## Cost

No charge. The Glue Data Catalog provides a free tier of 1 million objects stored and 1 million requests per month.

## Related docs

- [Getting started with AWS Glue](https://docs.aws.amazon.com/glue/latest/dg/getting-started.html)
- [Defining databases in the Data Catalog](https://docs.aws.amazon.com/glue/latest/dg/define-database.html)
- [Defining tables in the Data Catalog](https://docs.aws.amazon.com/glue/latest/dg/tables-described.html)
- [AWS Glue pricing](https://aws.amazon.com/glue/pricing/)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 104 |
| Exit code | 0 |
| Runtime | 12s |
| Steps | 5 |
| Issues | None |
| Version | v1 |
