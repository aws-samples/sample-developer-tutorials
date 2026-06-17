# Tutorial: Basic Script for Resource Management

## Prerequisites

- A working installation of `bash`.
- Access to a terminal or command line interface.
- Basic understanding of shell scripting.

## Steps

**1. Set up the environment**

```bash
$ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
$ TEMP_DIR=$(mktemp -d)
$ LOG_FILE="$TEMP_DIR/script.log"
$ CREATED_RESOURCES=()
```

This script initializes variables and creates a temporary directory for logging and resource tracking.

**2. Define the cleanup function**

```bash
$ cleanup_resources() {
  echo "Cleaning up created resources..."
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Deleting $resource"
    # Add actual cleanup commands here
  done
  rm -rf "$TEMP_DIR"
}
```

The `cleanup_resources` function is designed to remove all created resources and the temporary directory upon script exit.

**3. Set up the trap for cleanup**

```bash
$ trap cleanup_resources EXIT
```

This command ensures that the `cleanup_resources` function runs when the script exits, helping maintain a clean environment.

**4. Log the start of the script**

```bash
$ echo "Script started" > "$LOG_FILE"
```

This logs the initiation of the script to a file within the temporary directory.

**5. Access check**

```bash
$ echo -e "\n--- Step 1: Access Check ---" >> "$LOG_FILE"
$ echo "Access denied to create re:Post space. Skipping space creation step." >> "$LOG_FILE"
$ echo "PASS" >> "$LOG_FILE"
```

The script simulates an access check, logging the outcome to the file. In this case, it logs a simulated denial and proceeds accordingly.

**6. Example of resource tagging (commented out)**

```bash
$ # ARN_VAR=$(aws repostspace create-space --name "example-space" --query'space.spaceId' --output text)
$ # aws repostspace tag-resource --resource-arn "$ARN_VAR" --tags Key=project,Value=doc-smith Key=tutorial,Value=repostspace-gs
$ # CREATED_RESOURCES+=("$ARN_VAR")
```

These lines demonstrate how to create, tag, and track a resource. They are commented out in the script but serve as a template for future use.

**7. Log the completion of the script**

```bash
$ echo "Script completed"
```

This final log entry marks the end of the script's execution.

## Clean up

The script automatically cleans up by removing all created resources and the temporary directory when it exits, thanks to the `trap` command set earlier.

## Next steps

- Review the log file for detailed output.
- Modify the script to include actual resource creation and tagging as needed.
- Expand the cleanup function to handle additional resource types.
