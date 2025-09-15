# Using AWS Cloud Map service discovery with custom attributes

This tutorial demonstrates how you can use AWS Cloud Map service discovery with custom attributes. You'll create a microservices application that uses AWS Cloud Map to discover resources dynamically using custom attributes. The application consists of two Lambda functions that write data to and read from a DynamoDB table, with all resources registered in AWS Cloud Map.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You can also use AWS CloudShell, which includes the AWS CLI.
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic familiarity with AWS services including AWS Cloud Map, Lambda, and DynamoDB.
4. Sufficient permissions to create and manage resources in your AWS account.

**Cost**: The resources you create in this tutorial will incur minimal costs if you complete the tutorial in one session and delete the resources afterward. The estimated cost for running all resources for one hour is approximately $0.0014. If resources are not cleaned up, the monthly cost would be approximately $1.00, primarily for the AWS Cloud Map namespace, services, and instances.

**Time to complete**: Approximately 30 minutes.

## Create an AWS Cloud Map namespace

A namespace is a construct used to group services for an application. In this step, you'll create a namespace that allows resources to be discoverable through AWS Cloud Map API calls.

```bash
aws servicediscovery create-http-namespace \
  --name cloudmap-tutorial \
  --creator-request-id cloudmap-tutorial-request
```

The command returns an operation ID. You can check the status of the operation with the following command:

```bash
aws servicediscovery get-operation \
  --operation-id operation-id
```

Once the namespace is created, you can retrieve its ID for use in subsequent commands:

```bash
aws servicediscovery list-namespaces \
  --query "Namespaces[?Name=='cloudmap-tutorial'].Id" \
  --output text
```

Store the namespace ID in a variable for later use:

```bash
NAMESPACE_ID=$(aws servicediscovery list-namespaces \
  --query "Namespaces[?Name=='cloudmap-tutorial'].Id" \
  --output text)
```

## Create a DynamoDB table

Next, create a DynamoDB table that will store data for your application:

```bash
aws dynamodb create-table \
  --table-name cloudmap \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Wait for the table to become active before proceeding:

```bash
aws dynamodb wait table-exists --table-name cloudmap
```

This command waits until the table is fully created and ready to use.

## Create an AWS Cloud Map data service and register the DynamoDB table

Now, create a service in your namespace to represent data storage resources:

```bash
aws servicediscovery create-service \
  --name data-service \
  --namespace-id $NAMESPACE_ID \
  --creator-request-id data-service-request
```

Get the service ID for the data service:

```bash
DATA_SERVICE_ID=$(aws servicediscovery list-services \
  --query "Services[?Name=='data-service'].Id" \
  --output text)
```

Register the DynamoDB table as a service instance with a custom attribute that specifies the table name:

```bash
aws servicediscovery register-instance \
  --service-id $DATA_SERVICE_ID \
  --instance-id data-instance \
  --attributes tablename=cloudmap
```

The custom attribute `tablename=cloudmap` allows other services to discover the DynamoDB table name dynamically.

## Create an IAM role for Lambda functions

Create an IAM role that the Lambda functions will use to access AWS resources:

```bash
cat > lambda-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

Create the IAM role:

```bash
aws iam create-role \
  --role-name cloudmap-tutorial-role \
  --assume-role-policy-document file://lambda-trust-policy.json
```

Create a custom policy with least privilege permissions:

```bash
cat > cloudmap-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "servicediscovery:DiscoverInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/cloudmap"
    }
  ]
}
EOF
```

Create and attach the policy:

```bash
aws iam create-policy \
  --policy-name CloudMapTutorialPolicy \
  --policy-document file://cloudmap-policy.json

POLICY_ARN=$(aws iam list-policies \
  --query "Policies[?PolicyName=='CloudMapTutorialPolicy'].Arn" \
  --output text)

aws iam attach-role-policy \
  --role-name cloudmap-tutorial-role \
  --policy-arn $POLICY_ARN

aws iam attach-role-policy \
  --role-name cloudmap-tutorial-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

Wait for the role to propagate:

```bash
echo "Waiting for IAM role to propagate..."
sleep 10
```

## Create the Lambda function to write data

Create a Python file with the Lambda function code that writes data to the DynamoDB table:

```bash
cat > writefunction.py << EOF
import json
import boto3
import random

def lambda_handler(event, context):
    try:
        serviceclient = boto3.client('servicediscovery')

        response = serviceclient.discover_instances(
            NamespaceName='cloudmap-tutorial',
            ServiceName='data-service')

        if not response.get("Instances"):
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "No instances found"})
            }

        tablename = response["Instances"][0]["Attributes"].get("tablename")
        if not tablename:
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "Table name attribute not found"})
            }

        dynamodbclient = boto3.resource('dynamodb')

        table = dynamodbclient.Table(tablename)

        # Validate input
        if not isinstance(event, str):
            return {
                'statusCode': 400,
                'body': json.dumps({"error": "Input must be a string"})
            }

        response = table.put_item(
            Item={ 'id': str(random.randint(1,100)), 'todo': event })

        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({"error": str(e)})
        }
EOF
```

This function uses AWS Cloud Map to discover the DynamoDB table name from the custom attribute, then writes data to the table. It includes error handling and input validation.

Package and deploy the Lambda function:

```bash
zip writefunction.zip writefunction.py

ROLE_ARN=$(aws iam get-role --role-name cloudmap-tutorial-role \
  --query 'Role.Arn' --output text)

aws lambda create-function \
  --function-name writefunction \
  --runtime python3.12 \
  --role $ROLE_ARN \
  --handler writefunction.lambda_handler \
  --zip-file fileb://writefunction.zip \
  --architectures x86_64
```

Update the function timeout to avoid timeout errors:

```bash
aws lambda update-function-configuration \
  --function-name writefunction \
  --timeout 5
```

## Create an AWS Cloud Map app service and register the Lambda write function

Create another service in your namespace to represent application functions:

```bash
aws servicediscovery create-service \
  --name app-service \
  --namespace-id $NAMESPACE_ID \
  --creator-request-id app-service-request
```

Get the service ID for the app service:

```bash
APP_SERVICE_ID=$(aws servicediscovery list-services \
  --query "Services[?Name=='app-service'].Id" \
  --output text)
```

Register the Lambda write function as a service instance with custom attributes:

```bash
aws servicediscovery register-instance \
  --service-id $APP_SERVICE_ID \
  --instance-id write-instance \
  --attributes action=write,functionname=writefunction
```

The custom attributes `action=write` and `functionname=writefunction` allow clients to discover this function based on its purpose.

## Create the Lambda function to read data

Create a Python file with the Lambda function code that reads data from the DynamoDB table:

```bash
cat > readfunction.py << EOF
import json
import boto3

def lambda_handler(event, context):
    try:
        serviceclient = boto3.client('servicediscovery')

        response = serviceclient.discover_instances(
            NamespaceName='cloudmap-tutorial',
            ServiceName='data-service')

        if not response.get("Instances"):
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "No instances found"})
            }

        tablename = response["Instances"][0]["Attributes"].get("tablename")
        if not tablename:
            return {
                'statusCode': 500,
                'body': json.dumps({"error": "Table name attribute not found"})
            }

        dynamodbclient = boto3.resource('dynamodb')

        table = dynamodbclient.Table(tablename)

        # Use pagination for larger tables
        response = table.scan(
            Select='ALL_ATTRIBUTES',
            Limit=50  # Limit results for demonstration purposes
        )

        # For production, you would implement pagination like this:
        # items = []
        # while 'LastEvaluatedKey' in response:
        #     items.extend(response['Items'])
        #     response = table.scan(
        #         Select='ALL_ATTRIBUTES',
        #         ExclusiveStartKey=response['LastEvaluatedKey']
        #     )
        # items.extend(response['Items'])

        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({"error": str(e)})
        }
EOF
```

This function also uses AWS Cloud Map to discover the DynamoDB table name, then reads data from the table. It includes error handling and pagination comments.

Package and deploy the Lambda function:

```bash
zip readfunction.zip readfunction.py

aws lambda create-function \
  --function-name readfunction \
  --runtime python3.12 \
  --role $ROLE_ARN \
  --handler readfunction.lambda_handler \
  --zip-file fileb://readfunction.zip \
  --architectures x86_64
```

Update the function timeout:

```bash
aws lambda update-function-configuration \
  --function-name readfunction \
  --timeout 5
```

## Register the Lambda read function as a service instance

Register the Lambda read function as another service instance in the app service:

```bash
aws servicediscovery register-instance \
  --service-id $APP_SERVICE_ID \
  --instance-id read-instance \
  --attributes action=read,functionname=readfunction
```

The custom attributes `action=read` and `functionname=readfunction` allow clients to discover this function based on its purpose.

## Create and run client applications

Create a Python client application that uses AWS Cloud Map to discover and invoke the write function:

```bash
cat > writeclient.py << EOF
import boto3
import json

try:
    serviceclient = boto3.client('servicediscovery')

    print("Discovering write function...")
    response = serviceclient.discover_instances(
        NamespaceName='cloudmap-tutorial',
        ServiceName='app-service',
        QueryParameters={ 'action': 'write' }
    )

    if not response.get("Instances"):
        print("Error: No instances found")
        exit(1)

    functionname = response["Instances"][0]["Attributes"].get("functionname")
    if not functionname:
        print("Error: Function name attribute not found")
        exit(1)

    print(f"Found function: {functionname}")

    lambdaclient = boto3.client('lambda')

    print("Invoking Lambda function...")
    resp = lambdaclient.invoke(
        FunctionName=functionname,
        Payload='"This is a test data"'
    )

    payload = resp["Payload"].read()
    print(f"Response: {payload.decode('utf-8')}")

except Exception as e:
    print(f"Error: {str(e)}")
EOF
```

This client uses the `QueryParameters` option to find service instances with the `action=write` attribute.

Create a Python client application that uses AWS Cloud Map to discover and invoke the read function:

```bash
cat > readclient.py << EOF
import boto3
import json

try:
    serviceclient = boto3.client('servicediscovery')

    print("Discovering read function...")
    response = serviceclient.discover_instances(
        NamespaceName='cloudmap-tutorial',
        ServiceName='app-service',
        QueryParameters={ 'action': 'read' }
    )

    if not response.get("Instances"):
        print("Error: No instances found")
        exit(1)

    functionname = response["Instances"][0]["Attributes"].get("functionname")
    if not functionname:
        print("Error: Function name attribute not found")
        exit(1)

    print(f"Found function: {functionname}")

    lambdaclient = boto3.client('lambda')

    print("Invoking Lambda function...")
    resp = lambdaclient.invoke(
        FunctionName=functionname,
        InvocationType='RequestResponse'
    )

    payload = resp["Payload"].read()
    print(f"Response: {payload.decode('utf-8')}")

except Exception as e:
    print(f"Error: {str(e)}")
EOF
```

Run the write client to add data to the DynamoDB table:

```bash
python3 writeclient.py
```

The output should show a successful response with HTTP status code 200.

Run the read client to retrieve data from the DynamoDB table:

```bash
python3 readclient.py
```

The output should show the data that was written to the table, including the randomly generated ID and the "This is a test data" value.

## Going to production

This tutorial demonstrates the basic concepts of AWS Cloud Map service discovery with custom attributes in a simplified environment. For production deployments, consider the following improvements:

### Security Considerations

1. **Least Privilege Access**: The tutorial now uses a custom IAM policy with least privilege permissions, but you should further refine these permissions for your specific use case.

2. **Network Security**: Consider deploying Lambda functions within a VPC and using VPC endpoints for AWS services to restrict network access.

3. **Encryption**: Enable encryption at rest for DynamoDB tables and use AWS KMS for encrypting sensitive data.

4. **Input Validation**: Implement comprehensive input validation for all user inputs.

### Architecture Best Practices

1. **Error Handling**: Implement comprehensive error handling and retry logic for all service calls.

2. **Caching**: Cache service discovery results to reduce API calls and improve performance.

3. **Pagination**: Implement proper pagination for DynamoDB queries and scans when dealing with large datasets.

4. **Monitoring and Logging**: Set up CloudWatch alarms and logs to monitor application health and performance.

5. **High Availability**: Deploy resources across multiple Availability Zones for high availability.

For more information on building production-ready applications, refer to:

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Security Best Practices](https://docs.aws.amazon.com/whitepapers/latest/aws-security-best-practices/welcome.html)
- [Implementing Microservices on AWS](https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/microservices-on-aws.html)

## Clean up resources

When you're finished with the tutorial, clean up the resources to avoid incurring additional charges.

First, deregister the service instances:

```bash
aws servicediscovery deregister-instance \
  --service-id $APP_SERVICE_ID \
  --instance-id read-instance

aws servicediscovery deregister-instance \
  --service-id $APP_SERVICE_ID \
  --instance-id write-instance

aws servicediscovery deregister-instance \
  --service-id $DATA_SERVICE_ID \
  --instance-id data-instance
```

Delete the services:

```bash
aws servicediscovery delete-service \
  --id $APP_SERVICE_ID

aws servicediscovery delete-service \
  --id $DATA_SERVICE_ID
```

Delete the namespace:

```bash
aws servicediscovery delete-namespace \
  --id $NAMESPACE_ID
```

Delete the Lambda functions:

```bash
aws lambda delete-function --function-name writefunction
aws lambda delete-function --function-name readfunction
```

Delete the IAM role and policy:

```bash
aws iam detach-role-policy \
  --role-name cloudmap-tutorial-role \
  --policy-arn $POLICY_ARN

aws iam detach-role-policy \
  --role-name cloudmap-tutorial-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam delete-policy \
  --policy-arn $POLICY_ARN

aws iam delete-role --role-name cloudmap-tutorial-role
```

Delete the DynamoDB table:

```bash
aws dynamodb delete-table --table-name cloudmap
```

Clean up temporary files:

```bash
rm -f lambda-trust-policy.json cloudmap-policy.json writefunction.py readfunction.py writefunction.zip readfunction.zip writeclient.py readclient.py
```

## Next steps

Now that you've learned how to use AWS Cloud Map service discovery with custom attributes, explore these related topics:

1. [Creating health checks in AWS Cloud Map](https://docs.aws.amazon.com/cloud-map/latest/dg/health-checks.html) to ensure your services are healthy.
2. [Using DNS-based service discovery](https://docs.aws.amazon.com/cloud-map/latest/dg/dns-configuring.html) for applications that can use DNS queries.
3. [Integrating AWS Cloud Map with Amazon ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html) for container-based applications.
4. [Using AWS Cloud Map with AWS App Mesh](https://docs.aws.amazon.com/app-mesh/latest/userguide/service-discovery.html) for service mesh architectures.
5. [Implementing service discovery patterns](https://docs.aws.amazon.com/whitepapers/latest/microservices-on-aws/service-discovery.html) in microservices architectures.

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.