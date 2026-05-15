# Resilience Hub Application Creation Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage Resilience Hub applications.

## Steps

1. **Generate a unique suffix**

    ```bash
    $ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    ```

2. **Create a temporary directory**

    ```bash
    $ TEMP_DIR=$(mktemp -d)
    ```

3. **Create the Resilience Hub application**

    ```bash
    $ echo "=== Creating App ==="
    $ APP_ARN=$(aws resiliencehub create-app --name "app-$SUFFIX" --tags '{"project": "doc-smith", "tutorial": "resiliencehub-gs"}' --query 'app.appArn' --output text)
    $ echo "App: $APP_ARN"
    ```

    This command creates a new Resilience Hub application with a unique name and tags it for identification.

4. **Store the application ARN for cleanup**

    ```bash
    $ CREATED_RESOURCES+=("app:$APP_ARN")
    ```

5. **Describe the newly created application**

    ```bash
    $ echo "=== Describing App ==="
    $ aws resiliencehub describe-app --app-arn "$APP_ARN" --query 'app.name' --output text
    ```

    This command retrieves and displays the name of the created application.

6. **List all Resilience Hub applications**

    ```bash
    $ echo "=== Listing Apps ==="
    $ aws resiliencehub list-apps --query 'appSummaries[].name' --output text
    ```

    This command lists the names of all applications in your Resilience Hub.

## Clean up

To clean up the resources created during this tutorial, the script includes a cleanup function that deletes the created application and removes the temporary directory.

```bash
$ trap cleanup_resources EXIT
```

The `cleanup_resources` function iterates through the created resources and deletes them:

```bash
$ cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            app) aws resiliencehub delete-app --app-arn "$id" --force-delete 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
```

## Next steps

- Explore additional Resilience Hub features such as assessing application resilience or creating resiliency policies.
- Review the [AWS Resilience Hub documentation](https://docs.aws.amazon.com/resilience-hub/latest/userguide/what-is.html) for more detailed information and advanced use cases.