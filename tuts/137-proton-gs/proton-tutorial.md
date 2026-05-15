# Proton Environment Template Creation Tutorial

## Prerequisites

- You have AWS CLI installed and configured with the necessary permissions.
- You have a basic understanding of AWS Proton and its components.

## Steps

1. **Generate suffix and setup logging**

    The script generates a random suffix and sets up logging for the process.

2. **List Environment Templates**

    The script lists existing environment templates to ensure the environment is set up correctly.

    ```sh
    $ aws proton list-environment-templates --max-results 10
    ```

    If you encounter an `AccessDeniedException`, the script will inform you to skip the environment template creation step due to insufficient permissions.

3. **Create Environment Template**

    The script creates a new environment template with a unique name and adds tags for organization.

    ```sh
    $ aws proton create-environment-template --name "env-template-xmpl" --tags Key=project,Value=doc-smith Key=tutorial,Value=proton-gs
    ```

    The created template name is stored for cleanup.

4. **Clean up**

    The script includes a cleanup function to delete created resources and remove temporary files.

## Clean up

The script automatically cleans up created resources and temporary files upon completion. You do not need to perform any manual cleanup.

## Next steps

- Explore the created environment template in the AWS Proton console.
- Proceed with further configuration and deployment of your environment using AWS Proton.