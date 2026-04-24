# Revision History: 074-amazon-textract-gs

## Shell (CLI script)

### 2025-07-31 v-b1 initial attempt
- Type: functional
- Initial version

### 2026-04-13 v1 published
- Type: functional
- security and consistency updates


### 2026-04-22 v2 shared bucket
- Type: functional
- Script checks for prereq bucket stack before creating its own S3 bucket
- Skips bucket deletion if using shared bucket
