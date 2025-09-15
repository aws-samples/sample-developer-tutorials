# Getting started with Amazon MSK using the AWS CLI

This tutorial guides you through creating and managing an Amazon MSK (Managed Streaming for Apache Kafka) cluster using the AWS Command Line Interface (AWS CLI). You'll learn how to create an MSK cluster, set up IAM permissions, create a client machine, create a topic, produce and consume data, and monitor your cluster.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Basic familiarity with Apache Kafka concepts.
3. Basic understanding of AWS services like IAM, EC2, and VPC.
4. [Sufficient permissions](https://docs.aws.amazon.com/msk/latest/developerguide/security_iam_service-with-iam.html) to create and manage MSK clusters, IAM roles, and EC2 instances.

### Cost considerations

This tutorial creates AWS resources that will incur costs while they exist. The estimated cost for running the resources in this tutorial for one hour is approximately $0.76 USD, with the MSK cluster accounting for most of this cost. The costs break down as follows:

- MSK Cluster (3 brokers, kafka.t3.small): approximately $0.45/hour
- MSK Storage (3 GB minimum): approximately $0.30/hour
- EC2 Instance (t3.micro or t2.micro): approximately $0.01/hour

To minimize costs, we'll use the smallest available instance types, and we'll provide instructions for cleaning up resources when you're done. Make sure to follow the cleanup instructions at the end of the tutorial to avoid ongoing charges.

### Using the automated script

This tutorial includes an automated script (`2-cli-script-v8.sh`) that performs all the steps for you. The script includes comprehensive error handling, resource cleanup, and logging. You can run the script directly or follow the manual steps below to understand each component.

## Create an MSK cluster

Amazon MSK is a fully managed service that makes it easy to build and run applications that use Apache Kafka to process streaming data. In this section, you'll create an MSK cluster using the AWS CLI.

**Generate unique resource names**

To avoid naming conflicts, let's generate unique names for our resources:

```bash
# Generate unique identifiers
RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 8 | head -n 1)
CLUSTER_NAME="MSKTutorialCluster-${RANDOM_SUFFIX}"
POLICY_NAME="msk-tutorial-policy-${RANDOM_SUFFIX}"
ROLE_NAME="msk-tutorial-role-${RANDOM_SUFFIX}"
INSTANCE_PROFILE_NAME="msk-tutorial-profile-${RANDOM_SUFFIX}"
SG_NAME="MSKClientSecurityGroup-${RANDOM_SUFFIX}"

echo "Using the following resource names:"
echo "- Cluster Name: $CLUSTER_NAME"
echo "- Policy Name: $POLICY_NAME"
echo "- Role Name: $ROLE_NAME"
echo "- Instance Profile Name: $INSTANCE_PROFILE_NAME"
echo "- Security Group Name: $SG_NAME"
```

**Get available subnets and security group**

First, let's get the subnets and security group we'll use for our MSK cluster. We'll use the default VPC and its subnets for simplicity.

```bash
# Get the default VPC ID
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=is-default,Values=true" \
    --query "Vpcs[0].VpcId" \
    --output text)

if [ -z "$DEFAULT_VPC_ID" ] || [ "$DEFAULT_VPC_ID" = "None" ]; then
    echo "Error: Could not find default VPC. Please ensure you have a default VPC in your region."
    exit 1
fi

echo "Default VPC ID: $DEFAULT_VPC_ID"

# Get available subnets in the default VPC
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" "Name=default-for-az,Values=true" \
    --query "Subnets[0:3].SubnetId" \
    --output text)

# Convert space-separated subnet IDs to an array
read -r -a SUBNET_ARRAY <<< "$SUBNETS"

if [ ${#SUBNET_ARRAY[@]} -lt 3 ]; then
    echo "Error: Not enough subnets available in the default VPC. Need at least 3 subnets, found ${#SUBNET_ARRAY[@]}."
    exit 1
fi

# Get default security group for the default VPC
DEFAULT_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=default" "Name=vpc-id,Values=$DEFAULT_VPC_ID" \
    --query "SecurityGroups[0].GroupId" \
    --output text)

echo "Using subnets: ${SUBNET_ARRAY[0]} ${SUBNET_ARRAY[1]} ${SUBNET_ARRAY[2]}"
echo "Using security group: $DEFAULT_SG"
```

The output will show the subnet IDs and security group ID that will be used for your MSK cluster.

**Create the MSK cluster**

Now, let's create an MSK cluster using the subnets and security group we identified. We'll use the `kafka.t3.small` instance type, which is the smallest available for MSK clusters.

```bash
# Create the MSK cluster with proper error handling
CLUSTER_RESPONSE=$(aws kafka create-cluster \
    --cluster-name "$CLUSTER_NAME" \
    --broker-node-group-info "{\"InstanceType\": \"kafka.t3.small\", \"ClientSubnets\": [\"${SUBNET_ARRAY[0]}\", \"${SUBNET_ARRAY[1]}\", \"${SUBNET_ARRAY[2]}\"], \"SecurityGroups\": [\"$DEFAULT_SG\"]}" \
    --kafka-version "3.6.0" \
    --number-of-broker-nodes 3 \
    --encryption-info "{\"EncryptionInTransit\": {\"InCluster\": true, \"ClientBroker\": \"TLS\"}}" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create MSK cluster: $CLUSTER_RESPONSE"
    exit 1
fi

# Extract the cluster ARN using grep
CLUSTER_ARN=$(echo "$CLUSTER_RESPONSE" | grep -o '"ClusterArn": "[^"]*' | cut -d'"' -f4)

if [ -z "$CLUSTER_ARN" ]; then
    echo "Error: Failed to extract cluster ARN from response: $CLUSTER_RESPONSE"
    exit 1
fi

echo "MSK cluster creation initiated. ARN: $CLUSTER_ARN"
```

The response will include the ARN of your new cluster and its initial state, which will be `CREATING`.

**Get the cluster ARN**

The cluster ARN is already stored in the `CLUSTER_ARN` variable from the previous step. You can verify it:

```bash
echo "MSK cluster ARN: $CLUSTER_ARN"
```

**Wait for the cluster to become active**

Creating an MSK cluster can take 15-20 minutes. You can check the status of your cluster with the following command:

```bash
# Wait for the cluster to become active with proper status checking
echo "Waiting for cluster to become active (this may take 15-20 minutes)..."

while true; do
    CLUSTER_STATUS=$(aws kafka describe-cluster --cluster-arn "$CLUSTER_ARN" --query "ClusterInfo.State" --output text 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "Failed to get cluster status. Retrying in 30 seconds..."
        sleep 30
        continue
    fi

    echo "Current cluster status: $CLUSTER_STATUS"

    if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
        echo "Cluster is now active!"
        break
    elif [ "$CLUSTER_STATUS" = "FAILED" ]; then
        echo "Error: Cluster creation failed"
        exit 1
    fi

    echo "Still waiting for cluster to become active... (checking again in 60 seconds)"
    sleep 60
done
```

When the output shows `ACTIVE`, your cluster is ready to use.

## Create IAM permissions for MSK access

To interact with your MSK cluster, you need appropriate IAM permissions. In this section, you'll create an IAM policy and role that grant access to create topics and send/receive data.

**Create an IAM policy**

First, let's create an IAM policy that grants the necessary permissions:

```bash
# Get account ID and region
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].RegionName' --output text)
fi

if [ -z "$ACCOUNT_ID" ] || [ -z "$REGION" ]; then
    echo "Error: Could not determine AWS account ID or region"
    exit 1
fi

echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"

# Create IAM policy with broader topic and group permissions
POLICY_DOCUMENT="{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
        {
            \"Effect\": \"Allow\",
            \"Action\": [
                \"kafka-cluster:Connect\",
                \"kafka-cluster:AlterCluster\",
                \"kafka-cluster:DescribeCluster\"
            ],
            \"Resource\": [
                \"$CLUSTER_ARN\"
            ]
        },
        {
            \"Effect\": \"Allow\",
            \"Action\": [
                \"kafka-cluster:*Topic*\",
                \"kafka-cluster:WriteData\",
                \"kafka-cluster:ReadData\"
            ],
            \"Resource\": [
                \"arn:aws:kafka:$REGION:$ACCOUNT_ID:topic/$CLUSTER_NAME/*\"
            ]
        },
        {
            \"Effect\": \"Allow\",
            \"Action\": [
                \"kafka-cluster:AlterGroup\",
                \"kafka-cluster:DescribeGroup\"
            ],
            \"Resource\": [
                \"arn:aws:kafka:$REGION:$ACCOUNT_ID:group/$CLUSTER_NAME/*\"
            ]
        }
    ]
}"

POLICY_RESPONSE=$(aws iam create-policy \
    --policy-name "$POLICY_NAME" \
    --policy-document "$POLICY_DOCUMENT" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create IAM policy: $POLICY_RESPONSE"
    exit 1
fi

# Extract the policy ARN using grep
POLICY_ARN=$(echo "$POLICY_RESPONSE" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)

if [ -z "$POLICY_ARN" ]; then
    echo "Error: Failed to extract policy ARN from response: $POLICY_RESPONSE"
    exit 1
fi

echo "IAM policy created. ARN: $POLICY_ARN"
```

This policy grants permissions to connect to the cluster, create and manage topics with any name under the cluster, write and read data, and manage consumer groups.

**Create an IAM role**

Now, let's create an IAM role that can be assumed by EC2 instances:

```bash
# Create IAM role for EC2
TRUST_POLICY="{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"

ROLE_RESPONSE=$(aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create IAM role: $ROLE_RESPONSE"
    exit 1
fi

echo "IAM role created: $ROLE_NAME"

# Attach policy to role
ATTACH_RESPONSE=$(aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY_ARN" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to attach policy to role: $ATTACH_RESPONSE"
    exit 1
fi

echo "Policy attached to role"
```

**Create an instance profile**

Finally, let's create an instance profile and add the role to it:

```bash
# Create instance profile
PROFILE_RESPONSE=$(aws iam create-instance-profile \
    --instance-profile-name "$INSTANCE_PROFILE_NAME" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create instance profile: $PROFILE_RESPONSE"
    exit 1
fi

echo "Instance profile created: $INSTANCE_PROFILE_NAME"

# Add role to instance profile
ADD_ROLE_RESPONSE=$(aws iam add-role-to-instance-profile \
    --instance-profile-name "$INSTANCE_PROFILE_NAME" \
    --role-name "$ROLE_NAME" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to add role to instance profile: $ADD_ROLE_RESPONSE"
    exit 1
fi

echo "Role added to instance profile"

# Wait for the instance profile to propagate
echo "Waiting 10 seconds for IAM propagation..."
sleep 10
```

The instance profile will allow EC2 instances to assume the IAM role and access your MSK cluster. We add a short delay to ensure the instance profile is fully propagated before we use it.

## Create a client machine

To interact with your MSK cluster, you need a client machine. In this section, you'll create an EC2 instance that will serve as your Kafka client.

**Find a suitable subnet and instance type**

Let's find a suitable combination of subnet and instance type that's available in your region:

```bash
# Function to find a suitable subnet and instance type combination
find_suitable_subnet_and_instance_type() {
    local vpc_id="$1"
    local -a subnet_array=("${!2}")

    # List of instance types to try, in order of preference
    local instance_types=("t3.micro" "t2.micro" "t3.small" "t2.small")

    echo "Finding suitable subnet and instance type combination..."

    for instance_type in "${instance_types[@]}"; do
        echo "Trying instance type: $instance_type"

        for subnet_id in "${subnet_array[@]}"; do
            # Get the availability zone for this subnet
            local az=$(aws ec2 describe-subnets \
                --subnet-ids "$subnet_id" \
                --query 'Subnets[0].AvailabilityZone' \
                --output text)

            echo "  Checking subnet $subnet_id in AZ $az"

            # Check if this instance type is available in this AZ
            local available=$(aws ec2 describe-instance-type-offerings \
                --location-type availability-zone \
                --filters "Name=location,Values=$az" "Name=instance-type,Values=$instance_type" \
                --query 'InstanceTypeOfferings[0].InstanceType' \
                --output text 2>/dev/null)

            if [ "$available" = "$instance_type" ]; then
                echo "  ✓ Found suitable combination: $instance_type in $az (subnet: $subnet_id)"
                SELECTED_SUBNET_ID="$subnet_id"
                SELECTED_INSTANCE_TYPE="$instance_type"
                return 0
            else
                echo "  ✗ $instance_type not available in $az"
            fi
        done
    done

    echo "Error: Could not find any suitable subnet and instance type combination"
    return 1
}

# Find a suitable subnet and instance type combination
if ! find_suitable_subnet_and_instance_type "$DEFAULT_VPC_ID" SUBNET_ARRAY[@]; then
    echo "Error: Could not find a suitable subnet and instance type combination"
    exit 1
fi

echo "Selected subnet: $SELECTED_SUBNET_ID"
echo "Selected instance type: $SELECTED_INSTANCE_TYPE"
```

**Get security group information**

Now let's get the security group ID from the MSK cluster:

```bash
# Get security group ID from the MSK cluster
MSK_SG_ID=$(aws kafka describe-cluster \
    --cluster-arn "$CLUSTER_ARN" \
    --query 'ClusterInfo.BrokerNodeGroupInfo.SecurityGroups[0]' \
    --output text)

if [ -z "$MSK_SG_ID" ] || [ "$MSK_SG_ID" = "None" ]; then
    echo "Error: Failed to get security group ID from cluster"
    exit 1
fi

echo "MSK security group ID: $MSK_SG_ID"
```

**Create a security group for the client**

Now, let's create a security group for the client machine:

```bash
# Create security group for client
CLIENT_SG_RESPONSE=$(aws ec2 create-security-group \
    --group-name "$SG_NAME" \
    --description "Security group for MSK client" \
    --vpc-id "$DEFAULT_VPC_ID" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create security group: $CLIENT_SG_RESPONSE"
    exit 1
fi

# Extract the security group ID using grep
CLIENT_SG_ID=$(echo "$CLIENT_SG_RESPONSE" | grep -o '"GroupId": "[^"]*' | cut -d'"' -f4)

if [ -z "$CLIENT_SG_ID" ]; then
    echo "Error: Failed to extract security group ID from response: $CLIENT_SG_RESPONSE"
    exit 1
fi

echo "Client security group created. ID: $CLIENT_SG_ID"

# Allow SSH access to client from your IP only
echo "Getting your public IP address"
MY_IP=$(curl -s https://checkip.amazonaws.com 2>/dev/null)

if [ -z "$MY_IP" ]; then
    echo "Warning: Could not determine your IP address. Using 0.0.0.0/0 (not recommended for production)"
    MY_IP="0.0.0.0/0"
else
    MY_IP="$MY_IP/32"
    echo "Your IP address: $MY_IP"
fi

echo "Adding SSH ingress rule to client security group"
SSH_RULE_RESPONSE=$(aws ec2 authorize-security-group-ingress \
    --group-id "$CLIENT_SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr "$MY_IP" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Warning: Failed to add SSH ingress rule: $SSH_RULE_RESPONSE"
    echo "You may need to manually add SSH access to security group $CLIENT_SG_ID"
fi

echo "SSH ingress rule added"

# Update MSK security group to allow traffic from client security group
echo "Adding ingress rule to MSK security group to allow traffic from client"
MSK_RULE_RESPONSE=$(aws ec2 authorize-security-group-ingress \
    --group-id "$MSK_SG_ID" \
    --protocol all \
    --source-group "$CLIENT_SG_ID" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Warning: Failed to add ingress rule to MSK security group: $MSK_RULE_RESPONSE"
    echo "You may need to manually add ingress rule to security group $MSK_SG_ID"
fi

echo "Ingress rule added to MSK security group"
```

This security group allows SSH access from your IP address and allows the client to communicate with the MSK cluster on all ports (which includes the necessary Kafka ports).

**Create a key pair**

Let's create an SSH key pair to access the client machine:

```bash
# Create key pair with unique name
KEY_NAME="MSKKeyPair-${RANDOM_SUFFIX}"
echo "Creating key pair: $KEY_NAME"
KEY_RESPONSE=$(aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to create key pair: $KEY_RESPONSE"
    exit 1
fi

# Save the private key to a file
KEY_FILE="${KEY_NAME}.pem"
echo "$KEY_RESPONSE" > "$KEY_FILE"
chmod 400 "$KEY_FILE"

echo "Key pair created and saved to $KEY_FILE"
```

The private key is saved to a file with appropriate permissions.

**Launch the EC2 instance**

Now, let's launch an EC2 instance using the security group, key pair, and instance profile we created:

```bash
# Get the latest Amazon Linux 2 AMI
echo "Getting latest Amazon Linux 2 AMI ID"
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text 2>/dev/null)

if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
    echo "Error: Failed to get Amazon Linux 2 AMI ID"
    exit 1
fi

echo "Using AMI ID: $AMI_ID"

# Launch EC2 instance with the selected subnet and instance type
echo "Launching EC2 instance"
echo "Instance type: $SELECTED_INSTANCE_TYPE"
echo "Subnet: $SELECTED_SUBNET_ID"

INSTANCE_RESPONSE=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$SELECTED_INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$CLIENT_SG_ID" \
    --subnet-id "$SELECTED_SUBNET_ID" \
    --iam-instance-profile "Name=$INSTANCE_PROFILE_NAME" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=MSKTutorialClient-${RANDOM_SUFFIX}}]" 2>&1)

# Check if the command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to launch EC2 instance: $INSTANCE_RESPONSE"
    exit 1
fi

# Extract the instance ID using grep
INSTANCE_ID=$(echo "$INSTANCE_RESPONSE" | grep -o '"InstanceId": "[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$INSTANCE_ID" ]; then
    echo "Error: Failed to extract instance ID from response: $INSTANCE_RESPONSE"
    exit 1
fi

echo "EC2 instance launched successfully. ID: $INSTANCE_ID"
echo "Waiting for instance to be running..."

# Wait for the instance to be running
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

if [ $? -ne 0 ]; then
    echo "Error: Instance failed to reach running state"
    exit 1
fi

# Wait a bit more for the instance to initialize
echo "Instance is running. Waiting 30 seconds for initialization..."
sleep 30

# Get public DNS name of instance
CLIENT_DNS=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text)

if [ -z "$CLIENT_DNS" ] || [ "$CLIENT_DNS" = "None" ]; then
    echo "Warning: Could not get public DNS name for instance. Trying public IP..."
    CLIENT_DNS=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)

    if [ -z "$CLIENT_DNS" ] || [ "$CLIENT_DNS" = "None" ]; then
        echo "Error: Failed to get public DNS name or IP address for instance"
        exit 1
    fi
fi

echo "Client instance DNS/IP: $CLIENT_DNS"
```

The output will show the public DNS name or IP address of your client instance, which you'll use to connect via SSH.

## Get bootstrap brokers

To connect to your MSK cluster, you need the bootstrap broker connection string. This string contains the endpoints for the brokers in your cluster.

```bash
# Get bootstrap brokers with improved logic and retry mechanism
echo "Getting bootstrap brokers"
MAX_RETRIES=10
RETRY_COUNT=0
BOOTSTRAP_BROKERS=""
AUTH_METHOD=""

while [ -z "$BOOTSTRAP_BROKERS" ] || [ "$BOOTSTRAP_BROKERS" = "None" ]; do
    # Get the full bootstrap brokers response
    BOOTSTRAP_RESPONSE=$(aws kafka get-bootstrap-brokers \
        --cluster-arn "$CLUSTER_ARN" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$BOOTSTRAP_RESPONSE" ]; then
        # Try to get IAM authentication brokers first using grep
        BOOTSTRAP_BROKERS=$(echo "$BOOTSTRAP_RESPONSE" | grep -o '"BootstrapBrokerStringSaslIam": "[^"]*' | cut -d'"' -f4)
        if [ -n "$BOOTSTRAP_BROKERS" ]; then
            AUTH_METHOD="IAM"
        else
            # Fall back to TLS authentication
            BOOTSTRAP_BROKERS=$(echo "$BOOTSTRAP_RESPONSE" | grep -o '"BootstrapBrokerStringTls": "[^"]*' | cut -d'"' -f4)
            if [ -n "$BOOTSTRAP_BROKERS" ]; then
                AUTH_METHOD="TLS"
            fi
        fi
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))

    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "Warning: Could not get bootstrap brokers after $MAX_RETRIES attempts."
        echo "You may need to manually retrieve them later using:"
        echo "aws kafka get-bootstrap-brokers --cluster-arn $CLUSTER_ARN"
        BOOTSTRAP_BROKERS="BOOTSTRAP_BROKERS_NOT_AVAILABLE"
        AUTH_METHOD="UNKNOWN"
        break
    fi

    if [ -z "$BOOTSTRAP_BROKERS" ] || [ "$BOOTSTRAP_BROKERS" = "None" ]; then
        echo "Bootstrap brokers not available yet. Retrying in 30 seconds... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
        sleep 30
    fi
done

echo "Bootstrap brokers: $BOOTSTRAP_BROKERS"
echo "Authentication method: $AUTH_METHOD"
```

We use a retry mechanism because the bootstrap brokers might not be immediately available after the cluster becomes active. The script will try both IAM and TLS authentication methods and use whichever is available.

## Set up the client machine

Now that you have a client machine and bootstrap brokers, you need to set up the client to interact with your MSK cluster. This involves installing Java, downloading Apache Kafka, and configuring authentication.

**Create a setup script**

Let's create a setup script that you'll run on the client machine. This script will automatically detect the authentication method and configure the client accordingly:

```bash
cat > setup_client.sh << 'EOF'
#!/bin/bash

# Set up logging
LOG_FILE="client_setup_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting client setup"
echo "=============================================="

# Install Java
echo "Installing Java"
sudo yum -y install java-11

# Set environment variables
echo "Setting up environment variables"
export KAFKA_VERSION="3.6.0"
echo "KAFKA_VERSION=$KAFKA_VERSION"

# Download and extract Apache Kafka
echo "Downloading Apache Kafka"
wget https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz
if [ $? -ne 0 ]; then
    echo "Failed to download Kafka. Trying alternative mirror..."
    wget https://www.apache.org/dyn/closer.cgi?path=/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz
fi

echo "Extracting Kafka"
tar -xzf kafka_2.13-$KAFKA_VERSION.tgz
export KAFKA_ROOT=$(pwd)/kafka_2.13-$KAFKA_VERSION
echo "KAFKA_ROOT=$KAFKA_ROOT"

# Download the MSK IAM authentication package (needed for both IAM and TLS)
echo "Downloading MSK IAM authentication package"
cd $KAFKA_ROOT/libs
wget https://github.com/aws/aws-msk-iam-auth/releases/latest/download/aws-msk-iam-auth-1.1.6-all.jar
if [ $? -ne 0 ]; then
    echo "Failed to download specific version. Trying to get latest version..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/aws/aws-msk-iam-auth/releases/latest | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
    wget https://github.com/aws/aws-msk-iam-auth/releases/download/$LATEST_VERSION/aws-msk-iam-auth-$LATEST_VERSION-all.jar
    if [ $? -ne 0 ]; then
        echo "Failed to download IAM auth package. Please check the URL and try again."
        exit 1
    fi
    export CLASSPATH=$KAFKA_ROOT/libs/aws-msk-iam-auth-$LATEST_VERSION-all.jar
else
    export CLASSPATH=$KAFKA_ROOT/libs/aws-msk-iam-auth-1.1.6-all.jar
fi
echo "CLASSPATH=$CLASSPATH"

# Create client properties file based on authentication method
echo "Creating client properties file"
cd $KAFKA_ROOT/config

# The AUTH_METHOD_PLACEHOLDER will be replaced by the script
AUTH_METHOD="AUTH_METHOD_PLACEHOLDER"

if [ "$AUTH_METHOD" = "IAM" ]; then
    echo "Configuring for IAM authentication"
    cat > client.properties << 'EOT'
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
EOT
elif [ "$AUTH_METHOD" = "TLS" ]; then
    echo "Configuring for TLS authentication"
    cat > client.properties << 'EOT'
security.protocol=SSL
EOT
else
    echo "Unknown authentication method. Creating basic TLS configuration."
    cat > client.properties << 'EOT'
security.protocol=SSL
EOT
fi

echo "Client setup completed"
echo "=============================================="

# Create a script to set up environment variables
cat > ~/setup_env.sh << 'EOT'
#!/bin/bash
export KAFKA_VERSION="3.6.0"
export KAFKA_ROOT=~/kafka_2.13-$KAFKA_VERSION
export CLASSPATH=$KAFKA_ROOT/libs/aws-msk-iam-auth-1.1.6-all.jar
export BOOTSTRAP_SERVER="BOOTSTRAP_SERVER_PLACEHOLDER"
export AUTH_METHOD="AUTH_METHOD_PLACEHOLDER"

echo "Environment variables set:"
echo "KAFKA_VERSION=$KAFKA_VERSION"
echo "KAFKA_ROOT=$KAFKA_ROOT"
echo "CLASSPATH=$CLASSPATH"
echo "BOOTSTRAP_SERVER=$BOOTSTRAP_SERVER"
echo "AUTH_METHOD=$AUTH_METHOD"
EOT

chmod +x ~/setup_env.sh

echo "Created environment setup script: ~/setup_env.sh"
echo "Run 'source ~/setup_env.sh' to set up your environment"
EOF

# Replace placeholders in the setup script
if [ -n "$BOOTSTRAP_BROKERS" ] && [ "$BOOTSTRAP_BROKERS" != "None" ] && [ "$BOOTSTRAP_BROKERS" != "BOOTSTRAP_BROKERS_NOT_AVAILABLE" ]; then
    sed -i "s|BOOTSTRAP_SERVER_PLACEHOLDER|$BOOTSTRAP_BROKERS|g" setup_client.sh
else
    # If bootstrap brokers are not available, provide instructions to get them
    sed -i "s|BOOTSTRAP_SERVER_PLACEHOLDER|\$(aws kafka get-bootstrap-brokers --cluster-arn $CLUSTER_ARN --query 'BootstrapBrokerStringTls' --output text)|g" setup_client.sh
fi

# Replace auth method placeholder
sed -i "s|AUTH_METHOD_PLACEHOLDER|$AUTH_METHOD|g" setup_client.sh

echo "Setup script created"
```

This setup script will automatically configure the client for either IAM or TLS authentication based on what's available from your cluster.

**Upload and run the setup script**

Now, upload the setup script to your client machine and run it:

```bash
# Upload the setup script
scp -i "$KEY_FILE" setup_client.sh ec2-user@$CLIENT_DNS:~/

# Run the setup script
ssh -i "$KEY_FILE" ec2-user@$CLIENT_DNS 'chmod +x ~/setup_client.sh && ~/setup_client.sh'
```

This will install Java, download Apache Kafka, and configure the client to use the appropriate authentication method (IAM or TLS) with your MSK cluster.

## Create a topic and produce/consume data

Now that your client is set up, you can create a topic and start producing and consuming data. You'll need to connect to your client machine via SSH.

**Connect to the client machine**

```bash
ssh -i "$KEY_FILE" ec2-user@$CLIENT_DNS
```

**Set up environment variables**

Once connected, source the environment setup script:

```bash
source ~/setup_env.sh
```

**Create a topic**

Now, create a Kafka topic. The commands will vary slightly depending on your authentication method:

```bash
# Create a topic (works for both IAM and TLS authentication)
$KAFKA_ROOT/bin/kafka-topics.sh --create \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --command-config $KAFKA_ROOT/config/client.properties \
  --replication-factor 3 \
  --partitions 1 \
  --topic MSKTutorialTopic
```

We use 1 partition for simplicity in this tutorial, but you can increase this for better scalability and parallelism. If successful, you'll see a message like `Created topic MSKTutorialTopic.`

**Verify the topic was created**

You can verify that the topic was created by listing all topics:

```bash
$KAFKA_ROOT/bin/kafka-topics.sh --list \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --command-config $KAFKA_ROOT/config/client.properties
```

**Produce messages**

Start a console producer to send messages to your topic. The command is the same for both authentication methods:

```bash
$KAFKA_ROOT/bin/kafka-console-producer.sh \
  --broker-list $BOOTSTRAP_SERVER \
  --producer.config $KAFKA_ROOT/config/client.properties \
  --topic MSKTutorialTopic
```

Type a few messages, pressing Enter after each one. For example:
```
Hello, MSK!
This is a test message.
Amazon MSK is awesome!
```

Press Ctrl+C to exit when you're done.

**Consume messages**

Open a new terminal window and connect to your client machine again:

```bash
ssh -i "$KEY_FILE" ec2-user@$CLIENT_DNS
source ~/setup_env.sh
```

Start a console consumer to read messages from your topic:

```bash
$KAFKA_ROOT/bin/kafka-console-consumer.sh \
  --bootstrap-server $BOOTSTRAP_SERVER \
  --consumer.config $KAFKA_ROOT/config/client.properties \
  --topic MSKTutorialTopic \
  --from-beginning
```

You should see the messages you sent with the producer. You can keep the consumer running and send more messages from the producer to see them appear in real-time.

## Monitor your MSK cluster with CloudWatch

Amazon MSK integrates with Amazon CloudWatch, allowing you to monitor the health and performance of your cluster. In this section, you'll learn how to view MSK metrics in CloudWatch.

**List available MSK metrics**

You can list the available metrics for your MSK cluster:

```bash
aws cloudwatch list-metrics \
  --namespace AWS/Kafka \
  --dimensions Name=ClusterName,Value=$CLUSTER_NAME
```

**Get cluster-level metrics**

You can retrieve specific metrics for your cluster:

```bash
# Get ActiveConnectionCount metric for the last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kafka \
  --metric-name ActiveConnectionCount \
  --dimensions Name=ClusterName,Value=$CLUSTER_NAME \
  --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --period 300 \
  --statistics Average
```

**Get broker-level metrics**

You can also retrieve metrics for specific brokers in your cluster:

```bash
# Get a broker ID
BROKER_ID=$(aws kafka list-nodes \
  --cluster-arn $CLUSTER_ARN \
  --query 'NodeInfoList[0].NodeInfo.BrokerNodeInfo.BrokerId' \
  --output text)

# Get BytesInPerSec metric for the broker
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kafka \
  --metric-name BytesInPerSec \
  --dimensions Name=ClusterName,Value=$CLUSTER_NAME Name=BrokerId,Value=$BROKER_ID \
  --start-time $(date -u -d '1 hour ago' +"%Y-%m-%dT%H:%M:%SZ") \
  --end-time $(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --period 300 \
  --statistics Average
```

You can also view these metrics in the CloudWatch console for a more visual representation.

## Going to production

This tutorial is designed to help you learn how to use Amazon MSK with the AWS CLI. For production deployments, consider the following best practices:

### Security best practices

1. **Use least privilege IAM policies**: The IAM policy in this tutorial is more restrictive than the baseline but could be further tightened for production. Define policies that grant only the permissions required for specific applications.

2. **Network isolation**: Consider placing your MSK cluster in private subnets and using VPC endpoints for secure access.

3. **Fine-grained access control**: Implement Kafka ACLs for more granular control over topic and group access.

4. **Encryption**: While this tutorial enables encryption in transit, also consider the encryption at rest options available for MSK.

### Architecture best practices

1. **Right-sizing**: Choose appropriate broker types and sizes based on your workload requirements.

2. **Partition strategy**: Design your topic partitioning strategy based on throughput and parallelism needs.

3. **Monitoring and alerting**: Set up CloudWatch alarms for critical metrics to proactively detect issues.

4. **Backup and disaster recovery**: Implement regular backups and consider multi-region strategies for critical workloads.

For more information on production best practices, refer to:
- [Amazon MSK Best Practices](https://docs.aws.amazon.com/msk/latest/developerguide/bestpractices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Security Best Practices for Amazon MSK](https://docs.aws.amazon.com/msk/latest/developerguide/security-best-practices.html)

## Clean up resources

When you're finished with this tutorial, you should clean up the resources you created to avoid incurring additional charges. The cleanup order is important to avoid dependency issues.

**Terminate the EC2 instance**

```bash
# Terminate the EC2 instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
```

**Delete the MSK cluster**

```bash
# Delete the MSK cluster (this will take several minutes)
aws kafka delete-cluster --cluster-arn $CLUSTER_ARN

# Wait a bit for the cluster deletion to start
echo "Waiting 30 seconds for cluster deletion to begin..."
sleep 30
```

**Delete the security groups**

```bash
# Delete the client security group (may need to wait for dependencies to be removed)
echo "Deleting client security group: $CLIENT_SG_ID"
for i in {1..10}; do
    if aws ec2 delete-security-group --group-id "$CLIENT_SG_ID"; then
        echo "Client security group deleted successfully"
        break
    fi
    echo "Failed to delete security group (attempt $i/10), retrying in 30 seconds..."
    sleep 30
done
```

**Delete the key pair**

```bash
# Delete the key pair
aws ec2 delete-key-pair --key-name $KEY_NAME
rm $KEY_FILE
```

**Delete the IAM resources**

```bash
# Remove role from instance profile
aws iam remove-role-from-instance-profile \
  --instance-profile-name $INSTANCE_PROFILE_NAME \
  --role-name $ROLE_NAME

# Delete instance profile
aws iam delete-instance-profile \
  --instance-profile-name $INSTANCE_PROFILE_NAME

# Detach policy from role
aws iam detach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn $POLICY_ARN

# Delete role
aws iam delete-role \
  --role-name $ROLE_NAME

# Delete policy
aws iam delete-policy \
  --policy-arn $POLICY_ARN
```

**Note on cleanup timing**

Some resources may take time to fully delete, especially the MSK cluster which can take 10-15 minutes. The security group deletion might fail initially due to dependencies, which is why we include retry logic. If you encounter persistent issues with cleanup, wait a few minutes and try again, as AWS resources sometimes have propagation delays.

## Next steps

Now that you've learned the basics of Amazon MSK using the AWS CLI, you can explore more advanced features:

1. [Configure MSK cluster security](https://docs.aws.amazon.com/msk/latest/developerguide/security.html) - Learn about encryption, authentication, and authorization options.
2. [Set up MSK Connect](https://docs.aws.amazon.com/msk/latest/developerguide/msk-connect.html) - Stream data to and from your MSK cluster using connectors.
3. [Configure MSK monitoring](https://docs.aws.amazon.com/msk/latest/developerguide/monitoring.html) - Set up detailed monitoring and alerting for your cluster.
4. [Use MSK with AWS Lambda](https://docs.aws.amazon.com/msk/latest/developerguide/msk-lambda.html) - Process streaming data with serverless functions.
5. [Implement MSK replication](https://docs.aws.amazon.com/msk/latest/developerguide/msk-replication.html) - Replicate data between MSK clusters for disaster recovery or multi-region deployments.
