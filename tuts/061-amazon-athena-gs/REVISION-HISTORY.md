# Revision History: 061-amazon-athena-gs

## Shell (CLI script)

### 2025-08-01 v-b1 initial attempt
- Type: functional
- Initial version

### 2025-10-06 v1 published
- Type: functional
- use specific athena sample data bucket


### 2026-04-22 v2 shared bucket
- Type: functional
- Script checks for prereq bucket stack before creating its own S3 bucket
- Skips bucket deletion if using shared bucket
