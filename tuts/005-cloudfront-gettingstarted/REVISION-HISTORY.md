# Revision History: 005-cloudfront-gettingstarted

## Shell (CLI script)

### 2025-07-29 v-b1 initial attempt
- Type: functional
- Initial version

### 2026-04-21 v1 published
- Type: functional
- Remove SDK content from CFN branch (belongs on SDK branches)


### 2026-04-22 v2 shared bucket
- Type: functional
- Script checks for prereq bucket stack before creating its own S3 bucket
- Skips bucket deletion if using shared bucket

### 2026-04-27 v-tag1 resource tagging
- Type: functional
- Added resource tagging (project + tutorial tags) to all created resources
