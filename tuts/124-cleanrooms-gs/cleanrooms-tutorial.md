# Cleanrooms Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage Cleanrooms resources.

## Steps

1. **Create a collaboration**

    ```bash
    $ aws cleanrooms create-collaboration --name "collab-$SUFFIX" --description "Test" --members '[]' --creator-member-abilities CAN_QUERY CAN_RECEIVE_RESULTS --creator-display-name "DocBabu" --query-log-status DISABLED --query 'collaboration.id' --output text
    ```

    This command creates a new collaboration with a unique name, description, and specified member abilities. The collaboration ID is outputted.

2. **Tag the collaboration**

    ```bash
    $ aws cleanrooms tag-resource --resource-arn "$COLLAB_ARN" --tags project=doc-smith,tutorial=cleanrooms-gs
    ```

    This command tags the created collaboration with specific project and tutorial tags.

3. **Get collaboration details**

    ```bash
    $ aws cleanrooms get-collaboration --collaboration-identifier "$COLLAB_ID" --query 'collaboration.name' --output text
    ```

    This command retrieves and displays the name of the created collaboration.

## Clean up

To clean up the resources created during this tutorial, the script automatically handles the deletion of the collaboration and removal of temporary files. Ensure the script runs to completion to avoid resource accumulation.

## Next steps

- Explore additional Cleanrooms features and configurations.
- Review the [AWS Cleanrooms documentation](https://docs.aws.amazon.com/clean-rooms/latest/userguide/what-is.html) for more advanced use cases and best practices.
