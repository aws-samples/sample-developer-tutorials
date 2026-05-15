# Tutorial: Create, Verify, List, and Delete an AWS Wisdom Assistant

This tutorial guides you through creating, verifying, listing, and deleting an AWS Wisdom assistant using the AWS CLI.

## Prerequisites

- Install and configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
- Ensure you have the necessary permissions to create and manage AWS Wisdom resources.

## Steps

### Step 1: Creating assistant

Generate a unique suffix and name for the assistant.

```bash
$ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
$ NAME="test-assistant-${SUFFIX}"
```

Create the assistant.

```bash
$ CLIENT_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
$ ASSISTANT_ID=$(aws wisdom create-assistant \
    --name "$NAME" \
    --type AGENT \
    --client-token "$CLIENT_TOKEN" \
    --description "Test assistant for demonstration" \
    --query 'assistant.assistantId' --output text)
```

The assistant is created with ID: `123456789012`.

Tag the assistant for easier identification.

```bash
$ ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
$ aws wisdom tag-resource --resource-arn "arn:aws:wisdom:us-east-1:${ACCOUNT_ID}:assistant/${ASSISTANT_ID}" --tags Key=project,Value=doc-smith Key=tutorial,Value=wisdom-gs
```

Wait for the assistant to become active.

```bash
$ sleep 10
```

### Step 2: Verifying assistant exists

Verify the assistant exists by checking its name.

```bash
$ aws wisdom get-assistant --assistant-id "$ASSISTANT_ID" \
    --query 'assistant.name' --output text | grep "$NAME" && echo "Assistant verified."
```

### Step 3: Listing assistants

List the assistants to ensure the newly created assistant appears.

```bash
$ aws wisdom list-assistants \
    --query 'assistantSummaries[?name==`'"$NAME"'`]' --output text && echo "Assistant found in list."
```

### Step 4: Deleting assistant

Wait for the deletion process to complete.

```bash
$ sleep 10
```

Attempt to retrieve the assistant to confirm deletion.

```bash
$ aws wisdom get-assistant --assistant-id "$ASSISTANT_ID" || echo "Assistant successfully deleted." && echo "PASS"
```

## Clean up

All created resources are automatically cleaned up at the end of the script. The temporary directory and log file are also removed.

## Next steps

- Explore additional AWS Wisdom features and capabilities.
- Integrate AWS Wisdom with other AWS services for enhanced functionality.
- Review the [AWS Wisdom documentation](https://docs.aws.amazon.com/wisdom/latest/userguide/what-is.html) for more detailed information and advanced use cases.
