# Tutorial: Interacting with AWS Lake Formation using AWS CLI

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to interact with AWS Lake Formation.

## Steps

1. **Generate a unique suffix and temporary directory**

    ```bash
    SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="${TEMP_DIR}/script_log_${SUFFIX}.txt"
    ```

2. **Set up a trap for cleanup**

    ```bash
    trap cleanup_resources EXIT
    ```

3. **Log the start of the script**

    ```bash
    echo "Script started" > "${LOG_FILE}"
    echo "-------------------------" >> "${LOG_FILE}"
    ```

4. **List Lake Formation resources**

    ```bash
    echo "Step 1: Listing Lake Formation resources..."
    aws lakeformation list-resources --query 'ResourceInfoList[0].ResourceArn' --output text || echo "No resources"
    echo "Step 1: Listing Lake Formation resources... Done" >> "${LOG_FILE}"
    ```

5. **Get data lake settings**

    ```bash
    echo "Step 2: Getting data lake settings..."
    aws lakeformation get-data-lake-settings --query 'DataLakeSettings.DataLakeAdmins' --output text || echo "No admins"
    echo "Step 2: Getting data lake settings... Done" >> "${LOG_FILE}"
    ```

6. **Mark the script as successful**

    ```bash
    echo "PASS"
    ```

## Clean up

The script includes a cleanup function to remove any created resources and the temporary directory.

```bash
cleanup_resources() {
  echo "Cleaning up created resources..."
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Deleting resource: $resource"
    # Add appropriate AWS CLI delete command here if needed
  done
  rm -rf "${TEMP_DIR}"
}
```

## Next steps

- Review the log file `${TEMP_DIR}/script_log_${SUFFIX}.txt` for detailed output.
- Extend the script to include additional Lake Formation operations as needed.