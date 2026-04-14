#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/cfn.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); STACK_NAME="tut-stack-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws cloudformation delete-stack --stack-name "$STACK_NAME" 2>/dev/null; aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" 2>/dev/null && echo "  Stack deleted"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating a CloudFormation template"
cat > "$WORK_DIR/template.yaml" << 'EOF'
AWSTemplateFormatVersion: '2010-09-09'
Description: Tutorial stack - creates an SQS queue
Parameters:
  QueueName:
    Type: String
    Default: tutorial-queue
Resources:
  TutorialQueue:
    Type: AWS::SQS::Queue
    Properties:
      QueueName: !Ref QueueName
      MessageRetentionPeriod: 86400
Outputs:
  QueueUrl:
    Value: !Ref TutorialQueue
  QueueArn:
    Value: !GetAtt TutorialQueue.Arn
EOF
echo "  Template created"
echo "Step 2: Creating stack: $STACK_NAME"
aws cloudformation create-stack --stack-name "$STACK_NAME" --template-body "file://$WORK_DIR/template.yaml" --parameters "ParameterKey=QueueName,ParameterValue=cfn-tut-${RANDOM_ID}" > /dev/null
echo "  Waiting for stack creation..."
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME"
echo "Step 3: Stack outputs"
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' --output table
echo "Step 4: Listing stack resources"
aws cloudformation list-stack-resources --stack-name "$STACK_NAME" --query 'StackResourceSummaries[].{Type:ResourceType,LogicalId:LogicalResourceId,Status:ResourceStatus}' --output table
echo "Step 5: Stack events"
aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --query 'StackEvents[:5].{Resource:LogicalResourceId,Status:ResourceStatus,Time:Timestamp}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
