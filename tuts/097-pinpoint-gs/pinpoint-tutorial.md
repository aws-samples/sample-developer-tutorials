# AWS Pinpoint Tutorial: Creating and Managing Applications

This tutorial guides you through creating, retrieving, and listing Amazon Pinpoint applications using the AWS CLI. You will learn how to manage AWS resources programmatically and understand the basics of Amazon Pinpoint.

## Topics

- [Prerequisites](#aws-pinpoint-tutorial-prerequisites)
- [Generate a unique suffix](#aws-pinpoint-tutorial-generate-unique-suffix)
- [Create a temporary directory](#aws-pinpoint-tutorial-create-temporary-directory)
- [Create a Pinpoint application](#aws-pinpoint-tutorial-create-pinpoint-application)
- [Retrieve the newly created application](#aws-pinpoint-tutorial-retrieve-application)
- [List all Pinpoint applications](#aws-pinpoint-tutorial-list-applications)
- [Clean up resources](#aws-pinpoint-tutorial-clean-up-resources)
- [Next steps](#aws-pinpoint-tutorial-next-steps)

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also [use AWS CloudShell](https://docs.aws.amazon.com/cloudshell/latest/userguide/what-is-cloudshell.html), which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with command line interfaces.
4. [Sufficient permissions](https://docs.aws.amazon.com/pinpoint/latest/developerguide/permissions-actions.html) to create and manage Amazon Pinpoint applications.

## Generate a unique suffix

To ensure our Pinpoint application has a unique name, we generate a random suffix. This helps avoid naming conflicts with other applications.

**Generate Suffix:**

```bash
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
echo "Generated Suffix: ${SUFFIX}"
```

You should see an output similar to:

```
Generated Suffix: abcd1234
```

## Create a temporary directory

We create a temporary directory to store log files and other temporary data. This helps keep our workspace clean and organized.

**Create Temporary Directory:**

```bash
TEMP_DIR=$(mktemp -d)
echo "Temporary Directory: ${TEMP_DIR}"
```

You should see an output similar to:

```
Temporary Directory: /tmp/tmp.abcd1234
```

## Create a Pinpoint application

We will now create a new Amazon Pinpoint application. This application will be used to send messages to users. The application name is unique to avoid conflicts with existing applications.

**Create Pinpoint Application:**

```bash
REGION="us-east-1"
APP_NAME="my-app-${SUFFIX}"
APP_ID=$(aws pinpoint create-app --create-application-request '{"Name":"'${APP_NAME}'"}' --query 'ApplicationResponse.Id' --output text --region ${REGION})
echo "Pinpoint application created with ID: ${APP_ID}"
```

You should see an output similar to:

```
Pinpoint application created with ID: xmpl-app-id
```

## Retrieve the newly created application

Next, we retrieve the details of the newly created Pinpoint application to verify its creation. This step ensures that the application was created successfully and allows us to view its properties.

**Retrieve Pinpoint Application:**

```bash
aws pinpoint get-app --application-id ${APP_ID} --region ${REGION}
```

You should see an output similar to:

```json
{
    "ApplicationResponse": {
        "Arn": "arn:aws:mobiletargeting:us-east-1:123456789012:apps/xmpl-app-id",
        "Id": "xmpl-app-id",
        "Name": "my-app-abcd1234",
        "CreationDate": "Jan 13 current year"
    }
}
```

## List all Pinpoint applications

Finally, we list all Pinpoint applications in the specified region to see the newly created application among others. This helps us understand the overall environment and the applications we have access to.

**List Pinpoint Applications:**

```bash
aws pinpoint get-apps --region ${REGION}
```

You should see an output similar to:

```json
{
    "ApplicationsResponse": {
        "Item": [
            {
                "Arn": "arn:aws:mobiletargeting:us-east-1:123456789012:apps/xmpl-app-id",
                "Id": "xmpl-app-id",
                "Name": "my-app-abcd1234",
                "CreationDate": "Jan 13 current year"
            }
        ]
    }
}
```

## Clean up resources

To avoid unnecessary charges, clean up the resources you created. The script automatically handles this by deleting the Pinpoint application and removing the temporary directory.

**Clean Up Resources:**

The script includes a `cleanup_resources` function that runs when the script exits. This function deletes the Pinpoint application and removes the temporary directory.

## Next steps

Now that you've created and managed an Amazon Pinpoint application, you can explore more features and use cases:

- [Sending messages](https://docs.aws.amazon.com/pinpoint/latest/developerguide/send-messages.html)
- [Segmenting users](https://docs.aws.amazon.com/pinpoint/latest/developerguide/segments.html)
- [Creating campaigns](https://docs.aws.amazon.com/pinpoint/latest/developerguide/campaigns.html)