# Kendra Intelligent Ranking Tutorial

## Prerequisites

- An AWS account.
- AWS CLI installed and configured with appropriate permissions.
- `jq` command-line JSON processor installed (optional, for better JSON output formatting).

## Steps

1. **Set up environment variables**

    ```bash
    $ export REGION="us-east-1"
    $ export SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
    $ export TEMP_DIR=$(mktemp -d)
    $ export LOG_FILE="$TEMP_DIR/script.log"
    ```

2. **Create a Rescore Execution Plan**

    ```bash
    $ export NAME="test-execution-plan-${SUFFIX}"
    $ export DESCRIPTION="Test execution plan for Kendra Intelligent Ranking"
    $ export CAPACITY_UNITS='{"RescoreCapacityUnits": 1}'
    $ export CLIENT_TOKEN=$(head -c 16 /dev/urandom | base64 | tr -dc a-zA-Z0-9 | head -c 16 || true)

    $ echo "Creating Rescore Execution Plan..." 
    $ EXECUTION_PLAN_ID=$(aws kendra-ranking create-rescore-execution-plan \
        --name "$NAME" \
        --description "$DESCRIPTION" \
        --capacity-units "$CAPACITY_UNITS" \
        --client-token "$CLIENT_TOKEN" \
        --query 'Id' --output text)
    $ echo "Created Rescore Execution Plan with ID: $EXECUTION_PLAN_ID" 
    ```

3. **Tag the Rescore Execution Plan**

    ```bash
    $ ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    $ aws kendra-ranking tag-resource --resource-arn "arn:aws:kendra-ranking:us-east-1:${ACCOUNT_ID}:rescore-execution-plan/${EXECUTION_PLAN_ID}" --tags Key=project,Value=doc-smith Key=tutorial,Value=kendra-ranking-gs
    ```

4. **Wait for the Execution Plan to become active**

    ```bash
    $ sleep 10
    ```

5. **Describe the Rescore Execution Plan**

    ```bash
    $ echo "Describing Rescore Execution Plan..." 
    $ DESCRIBE_RESPONSE=$(aws kendra-ranking describe-rescore-execution-plan \
        --id "$EXECUTION_PLAN_ID")
    $ echo "Described Rescore Execution Plan: $DESCRIBE_RESPONSE" 
    ```

6. **List Rescore Execution Plans**

    ```bash
    $ echo "Listing Rescore Execution Plans..." 
    $ LIST_RESPONSE=$(aws kendra-ranking list-rescore-execution-plans)
    $ echo "Listed Rescore Execution Plans: $LIST_RESPONSE" 
    ```

## Clean up

To clean up the resources created by this script, the script includes a trap to delete the Rescore Execution Plan and remove temporary files.

```bash
$ trap cleanup_resources EXIT
```

The `cleanup_resources` function is defined as follows:

```bash
$ cleanup_resources() {
    for id in "${CREATED_RESOURCES[@]}"; do
        echo "Deleting Rescore Execution Plan with ID: $id"
        aws kendra-ranking delete-rescore-execution-plan --id "$id" || true
    done
    rm -rf "$TEMP_DIR"
}
```

## Next steps

- Explore additional Kendra Intelligent Ranking features.
- Integrate Kendra Intelligent Ranking with your applications.
- Review the [AWS Kendra Intelligent Ranking documentation](https://docs.aws.amazon.com/kendra/latest/dg/ranking.html) for more details.
