# AppConfig Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage AWS AppConfig resources.

## Steps

1. **Create Application**

   ```bash
   $ APPLICATION_NAME="appconfig-app-${SUFFIX}"
   $ APPLICATION_ID=$(aws appconfig create-application --name "${APPLICATION_NAME}" --description "Test Application" --tags '{"project": "doc-smith", "tutorial": "appconfig-gs"}' --query 'Id' --output text)
   ```

   This command creates an AWS AppConfig application with a unique name and stores the application ID.

2. **Create Environment**

   ```bash
   $ ENVIRONMENT_NAME="appconfig-env-${SUFFIX}"
   $ ENVIRONMENT_ID=$(aws appconfig create-environment --application-id "${APPLICATION_ID}" --name "${ENVIRONMENT_NAME}" --description "Test Environment" --tags '{"project": "doc-smith", "tutorial": "appconfig-gs"}' --query 'Id' --output text)
   ```

   This command creates an environment within the application with a unique name and stores the environment ID.

3. **Skip creating Configuration Profile**

   ```bash
   $ CONFIG_PROFILE_NAME="appconfig-config-${SUFFIX}"
   $ LOCATION_URI="ssm-parameter://appconfig-test-parameter"
   ```

   Due to a role assumption error, the configuration profile creation step is skipped.

4. **Verify Application**

   ```bash
   $ GET_APPLICATION_RESPONSE=$(aws appconfig get-application --application-id "${APPLICATION_ID}" --query 'Name' --output text)
   ```

   This command verifies the creation of the application by retrieving its name.

## Clean up

All created resources are automatically cleaned up at the end of the script to avoid unnecessary charges.

## Next steps

- Explore additional AWS AppConfig features.
- Integrate AppConfig with your applications for dynamic configuration management.