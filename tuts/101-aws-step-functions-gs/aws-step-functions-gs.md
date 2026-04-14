# Create and run a Step Functions state machine

This tutorial shows you how to create an IAM role for Step Functions, define a state machine with Pass, Wait, Choice, and Succeed states, run an execution, and inspect the results.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions for `states:CreateStateMachine`, `states:StartExecution`, `states:DescribeExecution`, `states:GetExecutionHistory`, `states:DeleteStateMachine`, `iam:CreateRole`, `iam:PutRolePolicy`, `iam:DeleteRolePolicy`, `iam:DeleteRole`

## Step 1: Create an IAM role

Create a role that allows the Step Functions service to assume it.

```bash
ROLE_ARN=$(aws iam create-role --role-name sfn-tut-role \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{
            "Effect":"Allow",
            "Principal":{"Service":"states.amazonaws.com"},
            "Action":"sts:AssumeRole"
        }]
    }' --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"
```

Attach a policy for CloudWatch Logs so the state machine can log execution events:

```bash
aws iam put-role-policy --role-name sfn-tut-role --policy-name sfn-logs \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:*"],"Resource":"*"}]}'
```

Wait for the role to propagate before using it:

```bash
sleep 10
```

## Step 2: Create a state machine

Define a state machine with four states: Pass produces a greeting, Wait pauses for 2 seconds, Choice branches on the message value, and Succeed ends the workflow.

```json
{
  "Comment": "A Hello World state machine",
  "StartAt": "Greeting",
  "States": {
    "Greeting": {
      "Type": "Pass",
      "Result": {"message": "Hello from Step Functions!"},
      "Next": "WaitStep"
    },
    "WaitStep": {
      "Type": "Wait",
      "Seconds": 2,
      "Next": "ChoiceStep"
    },
    "ChoiceStep": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.message",
          "StringEquals": "Hello from Step Functions!",
          "Next": "SuccessStep"
        }
      ],
      "Default": "FailStep"
    },
    "SuccessStep": {
      "Type": "Succeed"
    },
    "FailStep": {
      "Type": "Fail",
      "Error": "UnexpectedMessage",
      "Cause": "Message did not match expected value"
    }
  }
}
```

Save this definition to a file and create the state machine:

```bash
SM_ARN=$(aws stepfunctions create-state-machine \
    --name tut-state-machine \
    --definition file://definition.json \
    --role-arn "$ROLE_ARN" \
    --query 'stateMachineArn' --output text)
echo "State machine ARN: $SM_ARN"
```

The Pass state sets `$.message` to a greeting. The Choice state checks this value and routes to Succeed when it matches. If the message were different, the workflow would take the Default branch to Fail.

## Step 3: Start an execution

```bash
EXEC_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn "$SM_ARN" \
    --input '{"key": "value"}' \
    --query 'executionArn' --output text)
echo "Execution ARN: $EXEC_ARN"
```

The input JSON is available to the first state, but this state machine uses a Pass state with a hardcoded `Result`, so the input is replaced.

## Step 4: Wait for execution to complete

Poll the execution status until it reaches a terminal state:

```bash
for i in $(seq 1 15); do
    STATUS=$(aws stepfunctions describe-execution --execution-arn "$EXEC_ARN" \
        --query 'status' --output text)
    echo "Status: $STATUS"
    [ "$STATUS" = "SUCCEEDED" ] || [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "TIMED_OUT" ] && break
    sleep 3
done
```

The Wait state adds a 2-second pause, so the execution typically completes in about 3 seconds.

## Step 5: Get execution results

```bash
aws stepfunctions describe-execution --execution-arn "$EXEC_ARN" \
    --query '{Status:status,Input:input,Output:output,Started:startDate,Stopped:stopDate}' \
    --output table
```

A successful execution shows `SUCCEEDED` status with the greeting message as output.

## Step 6: Get execution history

```bash
aws stepfunctions get-execution-history --execution-arn "$EXEC_ARN" \
    --query 'events[?type!=`TaskStateEntered` && type!=`TaskStateExited`].{Id:id,Type:type}' \
    --output table | head -20
```

The history shows each state transition: `ExecutionStarted`, `PassStateEntered`, `WaitStateEntered`, `ChoiceStateEntered`, `SucceedStateEntered`, and `ExecutionSucceeded`.

## Cleanup

Delete the state machine, then remove the IAM role and its inline policy:

```bash
aws stepfunctions delete-state-machine --state-machine-arn "$SM_ARN"
aws iam delete-role-policy --role-name sfn-tut-role --policy-name sfn-logs
aws iam delete-role --role-name sfn-tut-role
```

## Related resources

- [Getting started with Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/getting-started-with-sfn.html)
- [Amazon States Language](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-amazon-states-language.html)
- [Step Functions API reference](https://docs.aws.amazon.com/step-functions/latest/apireference/Welcome.html)
