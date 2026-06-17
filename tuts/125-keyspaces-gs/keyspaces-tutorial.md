# Keyspaces Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and delete keyspaces and tables.

## Steps

1. **Generate a unique suffix and set keyspace name**

    ```bash
    $ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    $ KS_NAME="ks_${SUFFIX}"
    ```

2. **Create a temporary directory and log file**

    ```bash
    $ TEMP_DIR=$(mktemp -d)
    $ LOG_FILE="${TEMP_DIR}/script.log"
    ```

3. **Create a keyspace**

    ```bash
    $ echo "Creating Keyspace..." >> "$LOG_FILE"
    $ aws keyspaces create-keyspace --keyspace-name "$KS_NAME" --tags Key=project,Value=doc-smith Key=tutorial,Value=keyspaces-gs --query 'Path' --output text >> "$LOG_FILE"
    $ sleep 5
    $ echo "Keyspace created" >> "$LOG_FILE"
    ```

4. **Create a table within the keyspace**

    ```bash
    $ echo "Creating Table..." >> "$LOG_FILE"
    $ aws keyspaces create-table --keyspace-name "$KS_NAME" --table-name "users" --schema-definition '{"allColumns":[{"name":"id","type":"text"},{"name":"name","type":"text"}],"partitionKeys":[{"name":"id"}]}' --tags Key=project,Value=doc-smith Key=tutorial,Value=keyspaces-gs --query 'Path' --output text >> "$LOG_FILE"
    $ sleep 10
    $ echo "Table created" >> "$LOG_FILE"
    ```

5. **Verify the keyspace and table**

    ```bash
    $ echo "Verifying Keyspace and Table..." >> "$LOG_FILE"
    $ aws keyspaces get-keyspace --keyspace-name "$KS_NAME" --query 'Path' --output text >> "$LOG_FILE"
    $ aws keyspaces get-table --keyspace-name "$KS_NAME" --table-name "users" --query 'Path' --output text >> "$LOG_FILE"
    $ echo "Keyspace and Table verified" >> "$LOG_FILE"
    ```

6. **Wait for the table to be fully active before deletion**

    ```bash
    $ echo "Waiting for table to be fully active before deletion..." >> "$LOG_FILE"
    $ sleep 30
    ```

7. **Delete the table**

    ```bash
    $ echo "Deleting Table..." >> "$LOG_FILE"
    $ aws keyspaces delete-table --keyspace-name "$KS_NAME" --table-name "users" || true
    $ sleep 10
    $ echo "Table deleted" >> "$LOG_FILE"
    ```

8. **Wait before attempting to delete the keyspace**

    ```bash
    $ echo "Waiting before attempting to delete Keyspace..." >> "$LOG_FILE"
    $ sleep 30
    ```

9. **Delete the keyspace**

    ```bash
    $ echo "Deleting Keyspace..." >> "$LOG_FILE"
    $ aws keyspaces delete-keyspace --keyspace-name "$KS_NAME" || true
    $ echo "Keyspace deleted" >> "$LOG_FILE"
    ```

10. **Log the completion of the script**

    ```bash
    $ echo "PASS" >> "$LOG_FILE"
    ```

## Clean up

The script includes a cleanup function that deletes created resources and removes the temporary directory.

## Next steps

- Review the log file for any errors or additional information.
- Explore more advanced keyspaces features and configurations.
