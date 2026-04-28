#!/bin/bash

# CloudFormation Getting Started Script
# This script creates a CloudFormation stack with a web server and security group,
# monitors the stack creation, and provides cleanup options.

# Strict mode: exit on error, undefined variables, pipe failures
set -euo pipefail

# Set up logging with secure permissions
LOG_FILE="cloudformation-tutorial.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "==================================================="
echo "AWS CloudFormation Getting Started Tutorial"
echo "==================================================="
echo "This script will create a CloudFormation stack with:"
echo "- An EC2 instance running a simple web server"
echo "- A security group allowing HTTP access from your IP"
echo ""
echo "Starting at: $(date)"
echo ""

# Function to clean up resources
cleanup() {
    echo ""
    echo "==================================================="
    echo "CLEANING UP RESOURCES"
    echo "==================================================="
    
    if [ -n "${STACK_NAME:-}" ]; then
        echo "Deleting CloudFormation stack: $STACK_NAME"
        aws cloudformation delete-stack --stack-name "$STACK_NAME" || {
            echo "Warning: Failed to delete stack, but continuing with cleanup."
        }
        
        echo "Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" 2>/dev/null || {
            echo "Warning: Stack deletion wait command failed, but continuing."
        }
        
        echo "Stack deletion complete."
    fi
    
    if [ -f "${TEMPLATE_FILE:-}" ]; then
        echo "Removing local template file: $TEMPLATE_FILE"
        rm -f "$TEMPLATE_FILE" || echo "Warning: Could not remove template file."
    fi
    
    echo "Cleanup completed at: $(date)"
}

# Function to handle errors
handle_error() {
    echo ""
    echo "==================================================="
    echo "ERROR: $1"
    echo "==================================================="
    echo "Resources created before error:"
    if [ -n "${STACK_NAME:-}" ]; then
        echo "- CloudFormation stack: $STACK_NAME"
    fi
    echo ""
    
    echo "Would you like to clean up these resources? (y/n): "
    read -r CLEANUP_CHOICE || CLEANUP_CHOICE="n"
    
    if [[ "${CLEANUP_CHOICE}" =~ ^[Yy]$ ]]; then
        cleanup
    else
        echo "Resources were not cleaned up. You may need to delete them manually."
    fi
    
    exit 1
}

# Function to validate IP address format
validate_ip() {
    local ip="$1"
    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 1
    fi
    return 0
}

# Set up trap for script interruption
trap 'handle_error "Script interrupted"' INT TERM EXIT

# Generate a unique stack name with timestamp
TIMESTAMP=$(date +%s)
STACK_NAME="MyTestStack-${TIMESTAMP}"
TEMPLATE_FILE="webserver-template.yaml"

# Step 1: Create the CloudFormation template file
echo "Creating CloudFormation template file: $TEMPLATE_FILE"
cat > "$TEMPLATE_FILE" << 'EOF'
AWSTemplateFormatVersion: 2010-09-09
Description: CloudFormation Template for WebServer with Security Group and EC2 Instance

Parameters:
  LatestAmiId:
    Description: The latest Amazon Linux 2 AMI from the Parameter Store
    Type: 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
    Default: '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2'

  InstanceType:
    Description: WebServer EC2 instance type
    Type: String
    Default: t2.micro
    AllowedValues:
      - t3.micro
      - t2.micro
    ConstraintDescription: must be a valid EC2 instance type.
    
  MyIP:
    Description: Your IP address in CIDR format (e.g 203.0.113.1/32).
    Type: String
    MinLength: '9'
    MaxLength: '18'
    AllowedPattern: '^(\d{1,3}\.){3}\d{1,3}/\d{1,2}$'
    ConstraintDescription: must be a valid IP CIDR range of the form x.x.x.x/x.

Resources:
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow HTTP access via specified IP address
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: !Ref MyIP
      SecurityGroupEgress:
        - IpProtocol: -1
          CidrIp: 0.0.0.0/0
          Description: Allow all outbound traffic
      Tags:
        - Key: project
          Value: doc-smith
        - Key: tutorial
          Value: cloudformation-gs

  WebServer:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref LatestAmiId
      InstanceType: !Ref InstanceType
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      IamInstanceProfile: !Ref EC2InstanceProfile
      UserData: !Base64 |
        #!/bin/bash
        set -euo pipefail
        yum update -y
        yum install -y httpd
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>Hello World!</h1></body></html>" > /var/www/html/index.html
        chmod 644 /var/www/html/index.html
      Tags:
        - Key: project
          Value: doc-smith
        - Key: tutorial
          Value: cloudformation-gs

  EC2Role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

  EC2InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref EC2Role

Outputs:
  WebsiteURL:
    Value: !Join
      - ''
      - - 'http://'
        - !GetAtt WebServer.PublicDnsName
    Description: Website URL

  InstanceId:
    Value: !Ref WebServer
    Description: Instance ID of the web server

  SecurityGroupId:
    Value: !Ref WebServerSecurityGroup
    Description: Security Group ID
EOF

chmod 600 "$TEMPLATE_FILE"

if [ ! -f "$TEMPLATE_FILE" ]; then
    handle_error "Failed to create template file"
fi

# Step 2: Validate the template
echo ""
echo "Validating CloudFormation template..."
VALIDATION_RESULT=$(aws cloudformation validate-template --template-body "file://$TEMPLATE_FILE" 2>&1) || {
    handle_error "Template validation failed: $VALIDATION_RESULT"
}
echo "Template validation successful."

# Step 3: Get the user's public IP address
echo ""
echo "Retrieving your public IP address..."
MY_IP=$(curl -s --max-time 5 https://checkip.amazonaws.com || echo "")
if [ -z "$MY_IP" ]; then
    handle_error "Failed to retrieve public IP address"
fi
MY_IP="${MY_IP}/32"
MY_IP=$(echo "$MY_IP" | xargs)

# Validate IP format
if ! validate_ip "$MY_IP"; then
    handle_error "Invalid IP address format: $MY_IP"
fi
echo "Your public IP address: $MY_IP"

# Step 4: Create the CloudFormation stack
echo ""
echo "Creating CloudFormation stack: $STACK_NAME"
echo "This will create an EC2 instance and security group."
CREATE_RESULT=$(aws cloudformation create-stack \
  --stack-name "$STACK_NAME" \
  --template-body "file://$TEMPLATE_FILE" \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t2.micro \
    ParameterKey=MyIP,ParameterValue="$MY_IP" \
  --tags Key=project,Value=doc-smith Key=tutorial,Value=cloudformation-gs \
  --output text 2>&1) || {
    handle_error "Stack creation failed: $CREATE_RESULT"
}

STACK_ID=$(echo "$CREATE_RESULT" | tr -d '\r\n')
echo "Stack creation initiated. Stack ID: $STACK_ID"

# Step 5: Monitor stack creation
echo ""
echo "Monitoring stack creation..."
echo "This may take a few minutes."

# Wait for stack creation to complete
if ! aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" 2>/dev/null; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].StackStatus" --output text 2>/dev/null || echo "UNKNOWN")
    if [[ "$STACK_STATUS" == "ROLLBACK_COMPLETE" ]] || [[ "$STACK_STATUS" == "ROLLBACK_IN_PROGRESS" ]] || [[ "$STACK_STATUS" == "CREATE_FAILED" ]]; then
        handle_error "Stack creation failed. Status: $STACK_STATUS"
    fi
fi

echo "Stack creation completed successfully."

# Step 6: List stack resources
echo ""
echo "Resources created by the stack:"
aws cloudformation list-stack-resources --stack-name "$STACK_NAME" --query "StackResourceSummaries[*].{LogicalID:LogicalResourceId, Type:ResourceType, Status:ResourceStatus}" --output table || echo "Warning: Could not retrieve stack resources."

# Step 7: Get stack outputs
echo ""
echo "Stack outputs:"
OUTPUTS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs" --output json 2>/dev/null) || {
    handle_error "Failed to retrieve stack outputs"
}

# Extract the WebsiteURL
WEBSITE_URL=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" --output text 2>/dev/null) || WEBSITE_URL=""
if [ -z "$WEBSITE_URL" ]; then
    handle_error "Failed to extract WebsiteURL from stack outputs"
fi

echo "WebsiteURL: $WEBSITE_URL"
echo ""
echo "You can access the web server by opening the above URL in your browser."
echo "You should see a simple 'Hello World!' message."

# Step 8: Test the connection via CLI
echo ""
echo "Testing connection to the web server..."
sleep 5
HTTP_RESPONSE=$(curl -s -m 10 -o /dev/null -w "%{http_code}" "$WEBSITE_URL" 2>/dev/null || echo "000")
if [ "$HTTP_RESPONSE" == "200" ]; then
    echo "Connection successful! HTTP status code: $HTTP_RESPONSE"
else
    echo "Warning: Connection test returned HTTP status code: $HTTP_RESPONSE"
    echo "The web server might not be ready yet or there might be connectivity issues."
fi

# Disable the exit trap before cleanup prompt
trap - EXIT

# Step 9: Prompt for cleanup
echo ""
echo "==================================================="
echo "CLEANUP CONFIRMATION"
echo "==================================================="
echo "Resources created:"
echo "- CloudFormation stack: $STACK_NAME"
echo "  - EC2 instance"
echo "  - Security group"
echo "  - IAM role and instance profile"
echo ""
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE || CLEANUP_CHOICE="n"

if [[ "${CLEANUP_CHOICE}" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo ""
    echo "Resources were not cleaned up. You can delete them later with:"
    echo "aws cloudformation delete-stack --stack-name $STACK_NAME"
    echo ""
    echo "Note: You may be charged for AWS resources as long as they exist."
fi

echo ""
echo "==================================================="
echo "Tutorial completed at: $(date)"
echo "Log file: $LOG_FILE"
echo "==================================================="