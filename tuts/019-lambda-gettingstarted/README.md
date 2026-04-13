# Lambda: Create your first function

Create a Lambda function, invoke it with a test event, and view the results in CloudWatch Logs.

## Source

https://docs.aws.amazon.com/lambda/latest/dg/getting-started.html

## Use case

- ID: lambda/getting-started
- Phase: create
- Complexity: beginner
- Core actions: lambda:CreateFunction, lambda:Invoke

## What it does

1. Creates an IAM execution role for Lambda
2. Creates a Lambda function (Python or Node.js — you choose)
3. Invokes the function with a test event (`{"length": 6, "width": 7}`)
4. Retrieves and displays CloudWatch log output
5. Cleans up all resources

## Running

```bash
bash lambda-gettingstarted.sh
```

The script prompts you to choose a runtime and confirms before cleanup. To auto-run with cleanup:

```bash
echo '1
y' | bash lambda-gettingstarted.sh
```

## Resources created

- IAM role (with AWSLambdaBasicExecutionRole policy)
- Lambda function
- CloudWatch log group (created automatically by Lambda)

## Estimated time

- Run: ~1 minute
- Cleanup: ~30 seconds

## Cost

Free tier eligible. No charges expected for a single invocation.
