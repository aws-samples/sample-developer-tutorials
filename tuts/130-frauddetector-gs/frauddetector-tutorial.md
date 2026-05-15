# Fraud Detector Variable Creation Tutorial

## Prerequisites

- Install and configure the AWS CLI.
- Ensure you have the necessary permissions to create and manage Amazon Fraud Detector resources.

## Steps

### Step 1: Create a Variable

**Create a variable using the `aws frauddetector create-variable` command.**

```bash
$ aws frauddetector create-variable --name "var_$SUFFIX" --data-type STRING --data-source EVENT --default-value "0.0" --variable-type IP_ADDRESS
```

This command creates a new variable with a unique name, data type `STRING`, data source `EVENT`, default value `0.0`, and variable type `IP_ADDRESS`.

### Step 2: Tag the Created Variable

**Retrieve the ARN of the created variable and tag it.**

```bash
$ ARN=$(aws frauddetector get-variables --name "var_$SUFFIX" --query 'variables[0].arn' --output text)
$ aws frauddetector tag-resource --resource-arn "$ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=frauddetector-gs
```

These commands get the ARN of the variable and then tag it with `project:doc-smith` and `tutorial:frauddetector-gs`.

### Step 3: Get the Created Variable

**Retrieve the name of the created variable to confirm its creation.**

```bash
$ aws frauddetector get-variables --name "var_$SUFFIX" --query 'variables[0].name' --output text
```

This command outputs the name of the variable, confirming that it has been successfully created.

## Clean Up

To clean up the resources created during this tutorial, the script automatically handles the deletion of the variable and removal of temporary files. Ensure the script runs to completion or manually delete the variable using:

```bash
$ aws frauddetector delete-variable --name "var_$SUFFIX"
```

## Next Steps

- Explore more Amazon Fraud Detector features and integrations.
- Review the [Amazon Fraud Detector documentation](https://docs.aws.amazon.com/frauddetector/) for advanced use cases and best practices.