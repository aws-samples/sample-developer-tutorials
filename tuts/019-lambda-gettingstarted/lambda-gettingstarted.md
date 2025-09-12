# Creating your first Lambda function with the AWS CLI

This tutorial guides you through creating and testing your first AWS Lambda function using the AWS Command Line Interface (AWS CLI). You'll learn how to create a simple function that calculates the area of a rectangle, test it with sample input, and view the execution results.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Basic understanding of JSON formatting.
4. [Sufficient permissions](https://docs.aws.amazon.com/lambda/latest/dg/security_iam_service-with-iam.html) to create and manage Lambda functions, IAM roles, and CloudWatch logs in your AWS account.

**Time to complete**: Approximately 15-20 minutes

**Cost**: This tutorial uses AWS services that are included in the AWS Free Tier. If you follow the cleanup instructions at the end of the tutorial, you should incur no costs for completing this tutorial. For more information about AWS Free Tier, see [AWS Free Tier](https://aws.amazon.com/free/).

## Create an IAM role for Lambda

Before creating a Lambda function, you need to create an IAM role that grants your function permission to access AWS services and resources. In this case, the role will allow your function to write logs to CloudWatch.

**Create a trust policy document**

First, create a JSON file that defines the trust relationship for your Lambda role. This policy allows the Lambda service to assume the role.

```bash
cat > trust-policy.json << EOF
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

This command creates a file named `trust-policy.json` with the necessary trust policy for Lambda.

**Create the IAM role**

Now, create the IAM role using the trust policy document you just created.

```bash
ROLE_NAME="lambda-tutorial-role"
ROLE_ARN=$(aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json \
  --query 'Role.Arn' \
  --output text)

echo "Created IAM role: $ROLE_ARN"
```

This command creates an IAM role named `lambda-tutorial-role` and captures its ARN (Amazon Resource Name) in the `ROLE_ARN` variable.

**Attach permissions to the role**

Attach the `AWSLambdaBasicExecutionRole` managed policy to your role. This policy grants permissions for your Lambda function to write logs to CloudWatch.

```bash
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
```

After attaching the policy, wait a few seconds for the permissions to propagate through the AWS system.

```bash
echo "Waiting for IAM role to propagate..."
sleep 10
```

## Create function code

Next, you'll create the code for your Lambda function. You can choose between Node.js or Python for this tutorial.

**For Node.js**

Create a file named `index.mjs` with the following content:

```javascript
export const handler = async (event, context) => {

  const length = event.length;
  const width = event.width;
  let area = calculateArea(length, width);
  console.log(`The area is ${area}`);

  console.log('CloudWatch log group: ', context.logGroupName);

  let data = {
    "area": area,
  };
    return JSON.stringify(data);

  function calculateArea(length, width) {
    return length * width;
  }
};
```

This Node.js function takes an event object containing `length` and `width` parameters, calculates the area, and returns the result as a JSON string.

**For Python**

Create a file named `lambda_function.py` with the following content:

```python
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    # Get the length and width parameters from the event object
    length = event['length']
    width = event['width']

    area = calculate_area(length, width)
    print(f"The area is {area}")

    logger.info(f"CloudWatch logs group: {context.log_group_name}")

    # return the calculated area as a JSON string
    data = {"area": area}
    return json.dumps(data)

def calculate_area(length, width):
    return length*width
```

This Python function performs the same calculation as the Node.js version, taking an event object with `length` and `width` parameters and returning the calculated area.

**Create a deployment package**

Lambda requires your code to be packaged as a ZIP file. Create a deployment package containing your function code:

```bash
# For Node.js
zip function.zip index.mjs

# For Python
zip function.zip lambda_function.py
```

This command creates a ZIP file containing your function code.

## Create a Lambda function

Now you'll create the Lambda function using the deployment package and IAM role you created earlier.

**For Node.js**

```bash
FUNCTION_NAME="myLambdaFunction"
aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime nodejs22.x \
  --handler index.handler \
  --role "$ROLE_ARN" \
  --zip-file fileb://function.zip \
  --architectures x86_64
```

**For Python**

```bash
FUNCTION_NAME="myLambdaFunction"
aws lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.13 \
  --handler lambda_function.lambda_handler \
  --role "$ROLE_ARN" \
  --zip-file fileb://function.zip \
  --architectures x86_64
```

This command creates a Lambda function with the specified runtime, handler, and role. The `--zip-file` parameter specifies the deployment package containing your function code.

After creating the function, wait for it to become active before proceeding to the next step.

```bash
echo "Waiting for Lambda function to become active..."
sleep 10
```

You can verify the function's status with the following command:

```bash
aws lambda get-function --function-name "$FUNCTION_NAME" --query 'Configuration.State' --output text
```

The output should be "Active" before you proceed.

## Test your Lambda function

Now that your function is created, you'll create a test event and invoke the function.

**Create a test event**

Create a JSON file containing the test event data:

```bash
cat > test-event.json << EOF
{
  "length": 6,
  "width": 7
}
EOF
```

This creates a file named `test-event.json` with the test event data.

**Invoke the function**

Invoke your Lambda function with the test event:

```bash
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --payload fileb://test-event.json \
  output.json
```

This command invokes your Lambda function with the test event and saves the response to a file named `output.json`.

**View the function response**

Examine the function's response:

```bash
cat output.json
```

You should see output similar to:

```json
{"area": 42}
```

This confirms that your function successfully calculated the area of the rectangle (6 × 7 = 42).

## View CloudWatch logs

When your Lambda function executes, it generates logs that are sent to CloudWatch Logs. You can view these logs to monitor your function's execution and troubleshoot any issues.

**Get the log group name**

The log group for your Lambda function follows the naming pattern `/aws/lambda/[function-name]`:

```bash
LOG_GROUP_NAME="/aws/lambda/$FUNCTION_NAME"
```

**List log streams**

List the log streams for your function:

```bash
aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP_NAME" \
  --order-by LastEventTime \
  --descending \
  --limit 1
```

This command lists the most recent log stream for your function.

**View log events**

View the log events from the most recent log stream:

```bash
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP_NAME" \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

aws logs get-log-events \
  --log-group-name "$LOG_GROUP_NAME" \
  --log-stream-name "$LOG_STREAM"
```

The log events will show details about your function's execution, including:
- The calculated area (42)
- The CloudWatch log group name
- Execution metrics like duration and memory usage

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges.

**Delete the Lambda function**

```bash
aws lambda delete-function --function-name "$FUNCTION_NAME"
```

This command deletes your Lambda function.

**Delete the CloudWatch log group**

```bash
aws logs delete-log-group --log-group-name "$LOG_GROUP_NAME"
```

This command deletes the CloudWatch log group associated with your function.

**Delete the IAM role**

First, detach the policy from the role:

```bash
aws iam detach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
```

Then delete the role:

```bash
aws iam delete-role --role-name "$ROLE_NAME"
```

These commands clean up the IAM role you created for your Lambda function.

**Remove temporary files**

```bash
rm -f function.zip test-event.json output.json trust-policy.json
```

This command removes the temporary files created during this tutorial.

## Going to production

This tutorial is designed to help you learn the basics of AWS Lambda and the AWS CLI. If you're planning to use Lambda in a production environment, consider the following best practices:

### Security considerations

1. **Use custom IAM policies**: Instead of the managed `AWSLambdaBasicExecutionRole` policy, create a custom policy that grants only the specific permissions your function needs.

2. **Implement input validation**: Add validation to your function code to handle unexpected or malicious inputs.

3. **Set CloudWatch Logs retention**: Configure a retention policy for your CloudWatch Logs to manage storage costs and reduce exposure of potentially sensitive information.

4. **Use environment variables**: Store configuration values as environment variables and encrypt sensitive values.

For more information on Lambda security best practices, see [Security in AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/lambda-security.html).

### Architecture considerations

1. **Error handling**: Implement robust error handling in your function code.

2. **Optimize memory allocation**: Test different memory configurations to find the optimal balance between performance and cost.

3. **Consider cold starts**: Implement strategies to mitigate cold start latency, such as provisioned concurrency.

4. **Implement monitoring and alerting**: Set up CloudWatch alarms to monitor your function's performance and errors.

For more information on building production-ready serverless applications, see the [AWS Well-Architected Framework - Serverless Applications Lens](https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/welcome.html).

## Next steps

Now that you've created your first Lambda function using the AWS CLI, you can explore more advanced Lambda features:

1. [Deploy Node.js Lambda functions with .zip file archives](https://docs.aws.amazon.com/lambda/latest/dg/nodejs-package.html) - Learn how to include dependencies in your function.
2. [Using an Amazon S3 trigger to invoke a Lambda function](https://docs.aws.amazon.com/lambda/latest/dg/with-s3-example.html) - Configure your function to respond to S3 events.
3. [Using Lambda with API Gateway](https://docs.aws.amazon.com/lambda/latest/dg/services-apigateway-tutorial.html) - Create a REST API that invokes your Lambda function.
4. [Using a Lambda function to access an Amazon RDS database](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-lambda-tutorial.html) - Connect your Lambda function to a database.
5. [Using an Amazon S3 trigger to create thumbnail images](https://docs.aws.amazon.com/lambda/latest/dg/with-s3-tutorial.html) - Build a more complex application with Lambda and S3.
