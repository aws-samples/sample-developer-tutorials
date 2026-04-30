# Lambda Destinations

An AWS CLI tutorial that demonstrates Iam operations.

## Running

```bash
bash lambda-destinations.sh
```

To auto-run with cleanup:

```bash
echo 'y' | bash lambda-destinations.sh
```

## What it does

1. Creating roles and functions"; RID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); R="dest-role-$RID"; Q="dest-queue-$RID"; F="dest-func-$RID"; ROLE_ARN=$(aws iam create-role --role-name "$R" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text); aws iam attach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole; aws iam attach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess; sleep 10; QU=$(aws sqs create-queue --queue-name "$Q" --query QueueUrl --output text); QA=$(aws sqs get-queue-attributes --queue-url "$QU" --attribute-names QueueArn --query Attributes.QueueArn --output text); D=$(mktemp -d); echo "def handler(e,c): return {\"result\":\"success\"}" > "$D/i.py"; (cd "$D" && zip f.zip i.py > /dev/null); aws lambda create-function --function-name "$F" --zip-file "fileb://$D/f.zip" --handler i.handler --runtime python3.12 --role "$ROLE_ARN" --architectures x86_64 > /dev/null; aws lambda wait function-active-v2 --function-name "$F"; echo "Step 2: Configuring on-success destination"; aws lambda put-function-event-invoke-config --function-name "$F" --destination-config "{\"OnSuccess\":{\"Destination\":\"$QA\"}}" > /dev/null; echo "  On-success -> SQS queue"; echo "Step 3: Invoking async"; aws lambda invoke --function-name "$F" --invocation-type Event --cli-binary-format raw-in-base64-out --payload '{}' "$D/out.json" > /dev/null; echo "  Invoked async"; sleep 10; echo "Step 4: Checking SQS for result"; aws sqs receive-message --queue-url "$QU" --max-number-of-messages 1 --wait-time-seconds 5 --query "Messages[0].Body" --output text 2>/dev/null | python3 -c "import sys,json;d=json.loads(sys.stdin.read());print(f\"  Result: {d.get('requestPayload',{})}\n  Response: {d.get('responsePayload',{})}\")" 2>/dev/null || echo "  No message yet"; echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && { aws lambda delete-function --function-name "$F" 2>/dev/null; aws sqs delete-queue --queue-url "$QU" 2>/dev/null; aws iam detach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam detach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess 2>/dev/null; aws iam delete-role --role-name "$R" 2>/dev/null; rm -rf "$D

## Resources created

- Function
- Queue
- Role
- Function Event Invoke Config

The script prompts you to clean up resources when it finishes.

## Cost

Free tier eligible for most operations. Clean up resources after use to avoid charges.

## Related docs

- [AWS CLI iam reference](https://docs.aws.amazon.com/cli/latest/reference/iam/index.html)
- [AWS CLI lambda reference](https://docs.aws.amazon.com/cli/latest/reference/lambda/index.html)
- [AWS CLI sqs reference](https://docs.aws.amazon.com/cli/latest/reference/sqs/index.html)

