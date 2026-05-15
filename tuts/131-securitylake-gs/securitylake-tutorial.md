# Tutorial: Listing AWS Security Lake Data Lakes and Sources

## Prerequisites

- An AWS account.
- AWS CLI installed and configured with appropriate permissions.

## Steps

1. **Create a temporary directory**

   ```bash
   $ TEMP_DIR=$(mktemp -d)
   ```

2. **List Data Lakes**

   ```bash
   $ aws securitylake list-data-lakes --query 'dataLakes[].dataLakeArn' --output text || echo "No data lakes"
   ```

   This command lists all data lakes in your AWS Security Lake. If no data lakes are found, it outputs "No data lakes".

3. **List Sources**

   ```bash
   $ aws securitylake list-log-sources --query 'account' --output text 2>/dev/null || echo "No sources"
   ```

   This command lists all log sources in your AWS Security Lake. If no sources are found, it outputs "No sources".

4. **View Tutorial Completion Message**

   ```bash
   $ echo "=== Tutorial Complete ==="
   ```

   This indicates that the tutorial steps have been completed.

## Clean up

The script automatically cleans up the temporary directory created during execution. No manual clean-up is required.

## Next steps

- Explore creating and configuring data lakes in AWS Security Lake.
- Set up log sources to start collecting data.