Here's a simplified Bash script that mimics the functionality of your Python script using AWS CLI commands. Note that some features like tagging and error handling are limited compared to the Python `boto3` library.

```bash
#!/bin/bash
set -e

# Generate a random suffix
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Create a temporary directory and clean up on exit
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# AWS CLI commands
CONTAINER_NAME="example-container"
OBJECT_NAME="example-object"
OBJECT_NAME_WITH_SUFFIX="example-object-${SUFFIX}"

# List items in the container
echo "ListItems:"
aws mediastore-data list-items --container-name $CONTAINER_NAME --endpoint-url https://<mediastore-endpoint>

# Describe an object
echo "DescribeObject:"
aws mediastore-data describe-object --container-name $CONTAINER_NAME --path "/${OBJECT_NAME}" --endpoint-url https://<mediastore-endpoint>

# Get an object
echo "GetObject:"
aws mediastore-data get-object --container-name $CONTAINER_NAME --path "/${OBJECT_NAME}" $TEMP_DIR/example-object.txt --endpoint-url https://<mediastore-endpoint>

# Put an object with a suffix
echo "PutObject:"
aws mediastore-data put-object --container-name $CONTAINER_NAME --path "/${OBJECT_NAME_WITH_SUFFIX}" --body example-file.txt --endpoint-url https://<mediastore-endpoint>

# Describe the new object
echo "DescribeObject (new):"
aws mediastore-data describe-object --container-name $CONTAINER_NAME --path "/${OBJECT_NAME_WITH_SUFFIX}" --endpoint-url https://<mediastore-endpoint>

# Delete the object with a suffix
echo "DeleteObject:"
aws mediastore-data delete-object --container-name $CONTAINER_NAME --path "/${OBJECT_NAME_WITH_SUFFIX}" --endpoint-url https://<mediastore-endpoint>

echo "PASS"
```

### Notes:
1. Replace `<mediastore-endpoint>` with your actual MediaStore endpoint.
2. The script assumes that `example-file.txt` is available in the current directory.
3. Error handling is basic; you may want to add more robust checks depending on your use case.
4. Tagging is not supported directly in the AWS CLI for MediaStore in the same way as in `boto3`.