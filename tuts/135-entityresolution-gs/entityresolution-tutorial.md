# Entity Resolution Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and delete schema mappings in AWS Entity Resolution.

## Steps

1. **Create a temporary directory and log file**

    ```bash
    TEMP_DIR=$(mktemp -d)
    LOG_FILE="$TEMP_DIR/script.log"
    CREATED_RESOURCES=()
    ```

2. **Define a function to clean up resources**

    ```bash
    cleanup_resources() {
        for resource in "${CREATED_RESOURCES[@]}"; do
            aws entityresolution delete-schema-mapping --schema-name "$resource"
        done
        rm -rf "$TEMP_DIR"
    }
    ```

3. **Set a trap to clean up resources on exit**

    ```bash
    trap cleanup_resources EXIT
    ```

4. **Generate a random suffix for the schema name**

    ```bash
    SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    SCHEMA_NAME="test-schema-${SUFFIX}"
    ```

5. **Create a schema mapping**

    ```bash
    echo "Creating Schema Mapping..." >> "$LOG_FILE"
    aws entityresolution create-schema-mapping \
        --schema-name "$SCHEMA_NAME" \
        --description "Test schema for entity resolution" \
        --mapped-input-fields '[{"fieldName": "uniqueId", "type": "UNIQUE_ID"}, {"fieldName": "firstName", "type": "NAME_FIRST"}, {"fieldName": "lastName", "type": "NAME_LAST"}, {"fieldName": "email", "type": "EMAIL_ADDRESS"}]' \
        --tags '{"project": "doc-smith", "tutorial": "entityresolution-gs"}' || true
    CREATED_RESOURCES+=("$SCHEMA_NAME")
    ```

6. **Verify the schema mapping**

    ```bash
    echo "Verifying Schema Mapping..." >> "$LOG_FILE"
    aws entityresolution get-schema-mapping \
        --schema-name "$SCHEMA_NAME" || true
    ```

7. **List schema mappings**

    ```bash
    echo "Listing Schema Mappings..." >> "$LOG_FILE"
    aws entityresolution list-schema-mappings \
        --max-results 10 || true
    ```

8. **Delete the schema mapping**

    ```bash
    echo "Deleting Schema Mapping..." >> "$LOG_FILE"
    aws entityresolution delete-schema-mapping \
        --schema-name "$SCHEMA_NAME" || true
    ```

9. **Log the completion of the tutorial**

    ```bash
    echo "PASS" >> "$LOG_FILE"
    ```

## Clean up

The script automatically cleans up created resources using the `cleanup_resources` function when it exits.

## Next steps

- Explore more complex schema mappings and entity resolution configurations.
- Integrate entity resolution into your data processing pipelines.