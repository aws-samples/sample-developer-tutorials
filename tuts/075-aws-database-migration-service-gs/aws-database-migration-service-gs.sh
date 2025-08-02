#!/bin/bash

# AWS DMS Getting Started Tutorial Script
# This script automates the steps in the AWS DMS Getting Started tutorial
# https://docs.aws.amazon.com/dms/latest/userguide/CHAP_GettingStarted.html

# FIXES FOR HIGH SEVERITY ISSUES:
# 1. Added creation of a custom DB subnet group for RDS instances instead of using the default one
# 2. Modified the EC2 connection instructions to avoid displaying the password in plain text
# 3. Updated MariaDB version from 10.6.14 to 10.6.22 (latest available in 10.6 series)
# 4. Made data population and migration steps optional to allow infrastructure-only setup
# 5. Added VPC limit checking with option to use existing VPC when limit is reached
# 6. Moved optional step prompts to be contextual (just before each optional step)
# 7. Fixed password generation to exclude RDS-invalid characters (/, @, ", space)
# 8. Fixed PostgreSQL version from 16.1 to 16.9 (available version)
# 9. Improved VPC and subnet selection with numbered menus
# 10. Added EC2 instance type validation and automatic selection based on AZ availability
# 11. Changed default instance type from t2.xlarge to smaller, more available types

# Set up logging
LOG_FILE="dms_tutorial_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "AWS DMS Getting Started Tutorial"
echo "================================"
echo "This script will create resources for the AWS DMS tutorial."
echo "Log file: $LOG_FILE"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials are not configured or are invalid."
    echo "Please configure your AWS credentials using 'aws configure' command."
    exit 1
fi

# Get the current AWS region
AWS_REGION=$(aws configure get region)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"  # Default to us-east-1 if no region is configured
fi
echo "Using AWS region: $AWS_REGION"

# Get available availability zones in the region
echo "Getting availability zones for region $AWS_REGION..."
AVAILABILITY_ZONES=($(aws ec2 describe-availability-zones \
    --region "$AWS_REGION" \
    --query "AvailabilityZones[?State=='available'].ZoneName" \
    --output text))

if [ ${#AVAILABILITY_ZONES[@]} -lt 2 ]; then
    echo "ERROR: At least 2 availability zones are required in region $AWS_REGION"
    exit 1
fi

AZ1=${AVAILABILITY_ZONES[0]}
AZ2=${AVAILABILITY_ZONES[1]}
echo "Using availability zones: $AZ1 and $AZ2"
# Function to check command status
check_status() {
    if [ $? -ne 0 ]; then
        echo "ERROR: Command failed. Check the log file for details."
        echo "Resources created so far:"
        print_resources
        cleanup_resources
        exit 1
    fi
}

# Function to wait for resource to be available
wait_for_resource() {
    local resource_type=$1
    local resource_id=$2
    local status_field=$3
    local desired_status=$4
    local max_attempts=$5
    local wait_seconds=$6
    
    echo "Waiting for $resource_type $resource_id to be $desired_status..."
    
    local attempts=0
    while [ $attempts -lt $max_attempts ]; do
        local status=$(aws $resource_type describe-$resource_type-instances --$resource_type-instance-identifier $resource_id --query "$status_field" --output text)
        if [ "$status" = "$desired_status" ]; then
            echo "$resource_type $resource_id is now $desired_status"
            return 0
        fi
        echo "Current status: $status. Waiting $wait_seconds seconds..."
        sleep $wait_seconds
        attempts=$((attempts + 1))
    done
    
    echo "ERROR: Timed out waiting for $resource_type $resource_id to be $desired_status"
    return 1
}

# Function to generate a secure password
generate_password() {
    # Generate a random 16-character password with letters, numbers, and RDS-safe special characters
    # Uses only characters that are definitely allowed in RDS passwords
    # Excludes: / @ " (space) and other potentially problematic characters
    local password
    local attempts=0
    local max_attempts=10
    
    while [ $attempts -lt $max_attempts ]; do
        password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!#$%^&*()_+-=' | head -c 16)
        
        # Validate password doesn't contain invalid characters and has good complexity
        if [[ ! "$password" =~ [/@\"\ ] ]] && [[ "$password" =~ [A-Z] ]] && [[ "$password" =~ [a-z] ]] && [[ "$password" =~ [0-9] ]]; then
            echo "$password"
            return 0
        fi
        
        attempts=$((attempts + 1))
    done
    
    # Fallback to a simple but valid password if generation fails
    echo "TempPass123!"
}

# Function to check if instance type is available in availability zone
check_instance_type_availability() {
    local instance_type="$1"
    local availability_zone="$2"
    
    echo "Checking if instance type $instance_type is available in $availability_zone..." >&2
    
    # Get instance type offerings for the specific AZ
    local available=$(aws ec2 describe-instance-type-offerings \
        --location-type availability-zone \
        --filters "Name=location,Values=$availability_zone" "Name=instance-type,Values=$instance_type" \
        --query 'InstanceTypeOfferings[0].InstanceType' \
        --output text 2>/dev/null)
    
    if [ "$available" = "$instance_type" ]; then
        echo "✓ Instance type $instance_type is available in $availability_zone" >&2
        return 0
    else
        echo "✗ Instance type $instance_type is NOT available in $availability_zone" >&2
        return 1
    fi
}

# Function to find a suitable instance type for the availability zone
find_suitable_instance_type() {
    local availability_zone="$1"
    
    # List of instance types to try, in order of preference (smaller to larger)
    local instance_types=("t3.medium" "t3.large" "t2.medium" "t2.large" "m5.large" "m5.xlarge")
    
    echo "Finding suitable instance type for availability zone: $availability_zone" >&2
    
    for instance_type in "${instance_types[@]}"; do
        if check_instance_type_availability "$instance_type" "$availability_zone"; then
            echo "Selected instance type: $instance_type" >&2
            echo "$instance_type"
            return 0
        fi
    done
    
    echo "ERROR: No suitable instance type found for availability zone $availability_zone" >&2
    echo "Available instance types in $availability_zone:" >&2
    aws ec2 describe-instance-type-offerings \
        --location-type availability-zone \
        --filters "Name=location,Values=$availability_zone" \
        --query 'InstanceTypeOfferings[*].InstanceType' \
        --output table >&2
    return 1
}

# Function to print created resources
print_resources() {
    echo "Resources created:"
    if [ -n "$VPC_ID" ]; then echo "- VPC: $VPC_ID"; fi
    if [ -n "$PUBLIC_SUBNET_1_ID" ]; then echo "- Public Subnet 1: $PUBLIC_SUBNET_1_ID"; fi
    if [ -n "$PUBLIC_SUBNET_2_ID" ]; then echo "- Public Subnet 2: $PUBLIC_SUBNET_2_ID"; fi
    if [ -n "$PRIVATE_SUBNET_1_ID" ]; then echo "- Private Subnet 1: $PRIVATE_SUBNET_1_ID"; fi
    if [ -n "$PRIVATE_SUBNET_2_ID" ]; then echo "- Private Subnet 2: $PRIVATE_SUBNET_2_ID"; fi
    if [ -n "$IGW_ID" ]; then echo "- Internet Gateway: $IGW_ID"; fi
    if [ -n "$PUBLIC_RT_ID" ]; then echo "- Public Route Table: $PUBLIC_RT_ID"; fi
    if [ -n "$SG_ID" ]; then echo "- Security Group: $SG_ID"; fi
    if [ -n "$DB_PARAM_GROUP_MARIADB" ]; then echo "- MariaDB Parameter Group: $DB_PARAM_GROUP_MARIADB"; fi
    if [ -n "$DB_PARAM_GROUP_POSTGRES" ]; then echo "- PostgreSQL Parameter Group: $DB_PARAM_GROUP_POSTGRES"; fi
    if [ -n "$DB_SUBNET_GROUP" ]; then echo "- DB Subnet Group: $DB_SUBNET_GROUP"; fi
    if [ -n "$DB_INSTANCE_MARIADB" ]; then echo "- MariaDB Instance: $DB_INSTANCE_MARIADB"; fi
    if [ -n "$DB_INSTANCE_POSTGRES" ]; then echo "- PostgreSQL Instance: $DB_INSTANCE_POSTGRES"; fi
    if [ -n "$KEY_NAME" ]; then echo "- EC2 Key Pair: $KEY_NAME"; fi
    if [ -n "$EC2_INSTANCE_ID" ]; then echo "- EC2 Instance: $EC2_INSTANCE_ID"; fi
    if [ -n "$DMS_SUBNET_GROUP" ]; then echo "- DMS Subnet Group: $DMS_SUBNET_GROUP"; fi
    if [ -n "$DMS_INSTANCE_ARN" ]; then echo "- DMS Replication Instance: $DMS_INSTANCE_ARN"; fi
    if [ -n "$SOURCE_ENDPOINT_ARN" ]; then echo "- DMS Source Endpoint: $SOURCE_ENDPOINT_ARN"; fi
    if [ -n "$TARGET_ENDPOINT_ARN" ]; then echo "- DMS Target Endpoint: $TARGET_ENDPOINT_ARN"; fi
    if [ -n "$TASK_ARN" ]; then echo "- DMS Replication Task: $TASK_ARN"; fi
    if [ -n "$SECRET_ARN" ]; then echo "- Secrets Manager Secret: $SECRET_ARN"; fi
}
# Function to clean up resources
cleanup_resources() {
    echo ""
    echo "==========================================="
    echo "CLEANUP CONFIRMATION"
    echo "==========================================="
    echo "Do you want to clean up all created resources? (y/n): "
    read -r CLEANUP_CHOICE
    
    if [[ "${CLEANUP_CHOICE,,}" != "y" ]]; then
        echo "Skipping cleanup. Resources will remain in your account."
        return 0
    fi
    
    echo "Starting cleanup process..."
    
    # Delete DMS resources in reverse order (only if they were created)
    if [ -n "$TASK_ARN" ]; then
        echo "Deleting DMS replication task..."
        aws dms delete-replication-task --replication-task-arn "$TASK_ARN"
        # Wait for task deletion
        sleep 30
    fi
    
    if [ -n "$SOURCE_ENDPOINT_ARN" ]; then
        echo "Deleting DMS source endpoint..."
        aws dms delete-endpoint --endpoint-arn "$SOURCE_ENDPOINT_ARN"
    fi
    
    if [ -n "$TARGET_ENDPOINT_ARN" ]; then
        echo "Deleting DMS target endpoint..."
        aws dms delete-endpoint --endpoint-arn "$TARGET_ENDPOINT_ARN"
    fi
    
    if [ -n "$DMS_INSTANCE_ARN" ]; then
        echo "Deleting DMS replication instance..."
        aws dms delete-replication-instance --replication-instance-arn "$DMS_INSTANCE_ARN"
        # Wait for instance deletion
        sleep 60
    fi
    
    if [ -n "$DMS_SUBNET_GROUP" ]; then
        echo "Deleting DMS subnet group..."
        aws dms delete-replication-subnet-group --replication-subnet-group-identifier "$DMS_SUBNET_GROUP"
    fi
    
    # Delete EC2 resources
    if [ -n "$EC2_INSTANCE_ID" ]; then
        echo "Terminating EC2 instance..."
        aws ec2 terminate-instances --instance-ids "$EC2_INSTANCE_ID"
        # Wait for instance termination
        echo "Waiting for EC2 instance to terminate..."
        aws ec2 wait instance-terminated --instance-ids "$EC2_INSTANCE_ID"
    fi
    
    if [ -n "$KEY_NAME" ]; then
        echo "Deleting key pair..."
        aws ec2 delete-key-pair --key-name "$KEY_NAME"
        if [ -f "${KEY_NAME}.pem" ]; then
            rm "${KEY_NAME}.pem"
        fi
    fi
    
    # Delete RDS resources
    if [ -n "$DB_INSTANCE_MARIADB" ]; then
        echo "Deleting MariaDB instance..."
        aws rds delete-db-instance --db-instance-identifier "$DB_INSTANCE_MARIADB" --skip-final-snapshot
        # Wait for instance deletion
        echo "Waiting for MariaDB instance to be deleted..."
        aws rds wait db-instance-deleted --db-instance-identifier "$DB_INSTANCE_MARIADB"
    fi
    
    if [ -n "$DB_INSTANCE_POSTGRES" ]; then
        echo "Deleting PostgreSQL instance..."
        aws rds delete-db-instance --db-instance-identifier "$DB_INSTANCE_POSTGRES" --skip-final-snapshot
        # Wait for instance deletion
        echo "Waiting for PostgreSQL instance to be deleted..."
        aws rds wait db-instance-deleted --db-instance-identifier "$DB_INSTANCE_POSTGRES"
    fi
    
    if [ -n "$DB_PARAM_GROUP_MARIADB" ]; then
        echo "Deleting MariaDB parameter group..."
        aws rds delete-db-parameter-group --db-parameter-group-name "$DB_PARAM_GROUP_MARIADB"
    fi
    
    if [ -n "$DB_PARAM_GROUP_POSTGRES" ]; then
        echo "Deleting PostgreSQL parameter group..."
        aws rds delete-db-parameter-group --db-parameter-group-name "$DB_PARAM_GROUP_POSTGRES"
    fi
    
    # FIX: Added cleanup for DB subnet group
    if [ -n "$DB_SUBNET_GROUP" ]; then
        echo "Deleting DB subnet group..."
        aws rds delete-db-subnet-group --db-subnet-group-name "$DB_SUBNET_GROUP"
    fi
    
    # Delete Secret
    if [ -n "$SECRET_ARN" ]; then
        echo "Deleting secret..."
        aws secretsmanager delete-secret --secret-id "$SECRET_ARN" --force-delete-without-recovery
    fi
    
    # Delete VPC resources (only if we created them)
    if [ "$USING_EXISTING_VPC" = false ]; then
        if [ -n "$IGW_ID" ] && [ -n "$VPC_ID" ]; then
            echo "Detaching and deleting internet gateway..."
            aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
            aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
        fi
        
        if [ -n "$PUBLIC_SUBNET_1_ID" ]; then
            echo "Deleting public subnet 1..."
            aws ec2 delete-subnet --subnet-id "$PUBLIC_SUBNET_1_ID"
        fi
        
        if [ -n "$PUBLIC_SUBNET_2_ID" ]; then
            echo "Deleting public subnet 2..."
            aws ec2 delete-subnet --subnet-id "$PUBLIC_SUBNET_2_ID"
        fi
        
        if [ -n "$PRIVATE_SUBNET_1_ID" ]; then
            echo "Deleting private subnet 1..."
            aws ec2 delete-subnet --subnet-id "$PRIVATE_SUBNET_1_ID"
        fi
        
        if [ -n "$PRIVATE_SUBNET_2_ID" ]; then
            echo "Deleting private subnet 2..."
            aws ec2 delete-subnet --subnet-id "$PRIVATE_SUBNET_2_ID"
        fi
        
        if [ -n "$PUBLIC_RT_ID" ]; then
            echo "Deleting route table..."
            aws ec2 delete-route-table --route-table-id "$PUBLIC_RT_ID"
        fi
        
        if [ -n "$VPC_ID" ]; then
            echo "Deleting VPC..."
            aws ec2 delete-vpc --vpc-id "$VPC_ID"
        fi
    else
        echo "Skipping VPC cleanup (using existing VPC: $VPC_ID)"
    fi
    
    echo "Cleanup completed."
}

# Generate a random identifier for resource names
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
DB_PASSWORD=$(generate_password)

# Store password in AWS Secrets Manager
echo "Creating secret for database password..."
SECRET_NAME="dms-tutorial-db-password-$RANDOM_ID"
SECRET_ARN=$(aws secretsmanager create-secret --name "$SECRET_NAME" --secret-string "$DB_PASSWORD" --query 'ARN' --output text)
check_status

echo "Database password stored in Secrets Manager with ARN: $SECRET_ARN"
# Step 1: Create a VPC
echo "Step 1: Creating VPC and networking components..."

# Check current VPC count and limit
echo "Checking VPC limits..."
VPC_COUNT=$(aws ec2 describe-vpcs --query 'length(Vpcs)' --output text)
VPC_LIMIT=$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-F678F1CE --query 'Quota.Value' --output text 2>/dev/null || echo "5")

echo "Current VPCs: $VPC_COUNT, Limit: $VPC_LIMIT"

if [ "$VPC_COUNT" -ge "$VPC_LIMIT" ]; then
    echo ""
    echo "WARNING: You have reached your VPC limit ($VPC_LIMIT VPCs)."
    echo "Would you like to use an existing VPC instead of creating a new one? (y/n): "
    read -r USE_EXISTING_VPC
    
    if [[ "${USE_EXISTING_VPC,,}" == "y" ]]; then
        echo ""
        echo "Available VPCs:"
        
        # Get VPC data and store in arrays
        VPC_DATA=$(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output text)
        
        # Display numbered list
        echo "Number | VPC ID        | CIDR Block    | Name"
        echo "-------|---------------|---------------|-------------"
        
        IFS=$'\n' read -d '' -r -a VPC_LINES <<< "$VPC_DATA"
        VPC_IDS=()
        
        for i in "${!VPC_LINES[@]}"; do
            line="${VPC_LINES[$i]}"
            vpc_id=$(echo "$line" | awk '{print $1}')
            cidr=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | awk '{print $3}')
            if [ "$name" = "None" ] || [ -z "$name" ]; then
                name="(no name)"
            fi
            
            VPC_IDS+=("$vpc_id")
            printf "%-6s | %-13s | %-13s | %s\n" "$((i+1))" "$vpc_id" "$cidr" "$name"
        done
        
        echo ""
        echo "Enter the number of the VPC you want to use (1-${#VPC_IDS[@]}): "
        read -r VPC_CHOICE
        
        # Validate choice
        if ! [[ "$VPC_CHOICE" =~ ^[0-9]+$ ]] || [ "$VPC_CHOICE" -lt 1 ] || [ "$VPC_CHOICE" -gt "${#VPC_IDS[@]}" ]; then
            echo "ERROR: Invalid selection. Please enter a number between 1 and ${#VPC_IDS[@]}."
            exit 1
        fi
        
        VPC_ID="${VPC_IDS[$((VPC_CHOICE-1))]}"
        echo "Using VPC: $VPC_ID"
        
        # Get existing subnets
        echo ""
        echo "Available subnets in VPC $VPC_ID:"
        
        SUBNET_DATA=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output text)
        
        # Display numbered subnet list
        echo "Number | Subnet ID     | CIDR Block    | AZ        | Name"
        echo "-------|---------------|---------------|-----------|-------------"
        
        IFS=$'\n' read -d '' -r -a SUBNET_LINES <<< "$SUBNET_DATA"
        SUBNET_IDS=()
        SUBNET_AZS=()
        
        for i in "${!SUBNET_LINES[@]}"; do
            line="${SUBNET_LINES[$i]}"
            subnet_id=$(echo "$line" | awk '{print $1}')
            cidr=$(echo "$line" | awk '{print $2}')
            az=$(echo "$line" | awk '{print $3}')
            name=$(echo "$line" | awk '{print $4}')
            if [ "$name" = "None" ] || [ -z "$name" ]; then
                name="(no name)"
            fi
            
            SUBNET_IDS+=("$subnet_id")
            SUBNET_AZS+=("$az")
            printf "%-6s | %-13s | %-13s | %-9s | %s\n" "$((i+1))" "$subnet_id" "$cidr" "$az" "$name"
        done
        
        echo ""
        echo "Enter the number of the first subnet (1-${#SUBNET_IDS[@]}): "
        read -r SUBNET1_CHOICE
        
        # Validate first subnet choice
        if ! [[ "$SUBNET1_CHOICE" =~ ^[0-9]+$ ]] || [ "$SUBNET1_CHOICE" -lt 1 ] || [ "$SUBNET1_CHOICE" -gt "${#SUBNET_IDS[@]}" ]; then
            echo "ERROR: Invalid selection. Please enter a number between 1 and ${#SUBNET_IDS[@]}."
            exit 1
        fi
        
        PUBLIC_SUBNET_1_ID="${SUBNET_IDS[$((SUBNET1_CHOICE-1))]}"
        FIRST_AZ="${SUBNET_AZS[$((SUBNET1_CHOICE-1))]}"
        
        echo "Enter the number of the second subnet (must be in different AZ than $FIRST_AZ): "
        read -r SUBNET2_CHOICE
        
        # Validate second subnet choice
        if ! [[ "$SUBNET2_CHOICE" =~ ^[0-9]+$ ]] || [ "$SUBNET2_CHOICE" -lt 1 ] || [ "$SUBNET2_CHOICE" -gt "${#SUBNET_IDS[@]}" ]; then
            echo "ERROR: Invalid selection. Please enter a number between 1 and ${#SUBNET_IDS[@]}."
            exit 1
        fi
        
        PUBLIC_SUBNET_2_ID="${SUBNET_IDS[$((SUBNET2_CHOICE-1))]}"
        SECOND_AZ="${SUBNET_AZS[$((SUBNET2_CHOICE-1))]}"
        
        # Check if subnets are in different AZs
        if [ "$FIRST_AZ" = "$SECOND_AZ" ]; then
            echo "WARNING: Both subnets are in the same availability zone ($FIRST_AZ)."
            echo "This may cause issues with RDS subnet groups which require subnets in different AZs."
            echo "Continue anyway? (y/n): "
            read -r CONTINUE_SAME_AZ
            if [[ "${CONTINUE_SAME_AZ,,}" != "y" ]]; then
                echo "Please restart and select subnets in different availability zones."
                exit 1
            fi
        fi
        
        # Get AZs from selected subnets (already stored)
        AZ1="$FIRST_AZ"
        AZ2="$SECOND_AZ"
        
        # Get default security group
        SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --query "SecurityGroups[0].GroupId" --output text)
        
        echo "Using existing infrastructure:"
        echo "- VPC: $VPC_ID"
        echo "- Public Subnet 1: $PUBLIC_SUBNET_1_ID (AZ: $AZ1)"
        echo "- Public Subnet 2: $PUBLIC_SUBNET_2_ID (AZ: $AZ2)"
        echo "- Security Group: $SG_ID"
        
        # Add security group rules if needed
        echo "Adding security group rules for database access..."
        aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 3306 --source-group "$SG_ID" 2>/dev/null || echo "MariaDB rule may already exist"
        aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 5432 --source-group "$SG_ID" 2>/dev/null || echo "PostgreSQL rule may already exist"
        aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || echo "SSH rule may already exist"
        
        USING_EXISTING_VPC=true
    else
        echo "Cannot proceed without creating a new VPC. Please delete unused VPCs or request a limit increase."
        exit 1
    fi
else
    USING_EXISTING_VPC=false
fi

if [ "$USING_EXISTING_VPC" = false ]; then
    echo "Creating new VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.1.0/24 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DMSVPC}]' --query 'Vpc.VpcId' --output text)
    check_status
    echo "VPC created with ID: $VPC_ID"

    # Enable DNS hostnames for the VPC
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames '{"Value":true}'
    check_status

    echo "Creating subnets..."
    PUBLIC_SUBNET_1_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/26 --availability-zone "$AZ1" --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-public-subnet-1}]' --query 'Subnet.SubnetId' --output text)
    check_status
    echo "Public subnet 1 created with ID: $PUBLIC_SUBNET_1_ID"

    PUBLIC_SUBNET_2_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.64/26 --availability-zone "$AZ2" --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-public-subnet-2}]' --query 'Subnet.SubnetId' --output text)
    check_status
    echo "Public subnet 2 created with ID: $PUBLIC_SUBNET_2_ID"

    PRIVATE_SUBNET_1_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.128/26 --availability-zone "$AZ1" --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-private-subnet-1}]' --query 'Subnet.SubnetId' --output text)
    check_status
    echo "Private subnet 1 created with ID: $PRIVATE_SUBNET_1_ID"

    PRIVATE_SUBNET_2_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.192/26 --availability-zone "$AZ2" --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=DMSVPC-private-subnet-2}]' --query 'Subnet.SubnetId' --output text)
    check_status
    echo "Private subnet 2 created with ID: $PRIVATE_SUBNET_2_ID"

    echo "Creating internet gateway..."
    IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=DMSVPC-igw}]' --query 'InternetGateway.InternetGatewayId' --output text)
    check_status
    echo "Internet gateway created with ID: $IGW_ID"

    echo "Attaching internet gateway to VPC..."
    aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
    check_status

    echo "Creating route table..."
    PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=DMSVPC-public-rt}]' --query 'RouteTable.RouteTableId' --output text)
    check_status
    echo "Route table created with ID: $PUBLIC_RT_ID"

    echo "Adding route to internet gateway..."
    aws ec2 create-route --route-table-id "$PUBLIC_RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"
    check_status

    echo "Associating public subnets with route table..."
    aws ec2 associate-route-table --route-table-id "$PUBLIC_RT_ID" --subnet-id "$PUBLIC_SUBNET_1_ID"
    check_status
    aws ec2 associate-route-table --route-table-id "$PUBLIC_RT_ID" --subnet-id "$PUBLIC_SUBNET_2_ID"
    check_status

    echo "Getting default security group for VPC..."
    SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" --query "SecurityGroups[0].GroupId" --output text)
    check_status
    echo "Default security group ID: $SG_ID"

    echo "Adding security group rules for database access..."
    # Note: In production, you would restrict these to specific IP ranges or security groups
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 3306 --cidr 10.0.1.0/24
    check_status
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 5432 --cidr 10.0.1.0/24
    check_status
    aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
    check_status
    echo "Security group rules added"
fi
# Step 2: Create Amazon RDS Parameter Groups
echo "Step 2: Creating RDS parameter groups..."

DB_PARAM_GROUP_MARIADB="dms-mariadb-parameters-$RANDOM_ID"
echo "Creating MariaDB parameter group: $DB_PARAM_GROUP_MARIADB"
aws rds create-db-parameter-group \
    --db-parameter-group-name "$DB_PARAM_GROUP_MARIADB" \
    --db-parameter-group-family mariadb10.6 \
    --description "Group for specifying binary log settings for replication"
check_status

echo "Modifying MariaDB parameters..."
aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAM_GROUP_MARIADB" \
    --parameters "ParameterName=binlog_checksum,ParameterValue=NONE,ApplyMethod=immediate" \
                 "ParameterName=binlog_format,ParameterValue=ROW,ApplyMethod=immediate"
check_status

DB_PARAM_GROUP_POSTGRES="dms-postgresql-parameters-$RANDOM_ID"
echo "Creating PostgreSQL parameter group: $DB_PARAM_GROUP_POSTGRES"
aws rds create-db-parameter-group \
    --db-parameter-group-name "$DB_PARAM_GROUP_POSTGRES" \
    --db-parameter-group-family postgres16 \
    --description "Group for specifying role setting for replication"
check_status

echo "Modifying PostgreSQL parameters..."
aws rds modify-db-parameter-group \
    --db-parameter-group-name "$DB_PARAM_GROUP_POSTGRES" \
    --parameters "ParameterName=session_replication_role,ParameterValue=replica,ApplyMethod=immediate"
check_status

# FIX: Create a custom DB subnet group instead of using the default one
echo "Creating DB subnet group..."
DB_SUBNET_GROUP="dms-db-subnet-group-$RANDOM_ID"
aws rds create-db-subnet-group \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --db-subnet-group-description "DB subnet group for DMS tutorial" \
    --subnet-ids "$PUBLIC_SUBNET_1_ID" "$PUBLIC_SUBNET_2_ID"
check_status
echo "DB subnet group created: $DB_SUBNET_GROUP"
# Step 3: Create Your Source Amazon RDS Database (MariaDB)
echo "Step 3: Creating source MariaDB database..."

DB_INSTANCE_MARIADB="dms-mariadb-$RANDOM_ID"
echo "Creating MariaDB instance: $DB_INSTANCE_MARIADB"
echo "Using MariaDB version 10.6.22 (latest available in 10.6 series)"
aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_MARIADB" \
    --engine mariadb \
    --engine-version 10.6.22 \
    --db-instance-class db.m5.large \
    --allocated-storage 20 \
    --master-username admin \
    --master-user-password "$DB_PASSWORD" \
    --vpc-security-group-ids "$SG_ID" \
    --availability-zone "$AZ1" \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --db-parameter-group-name "$DB_PARAM_GROUP_MARIADB" \
    --db-name dms_sample \
    --backup-retention-period 1 \
    --no-auto-minor-version-upgrade \
    --publicly-accessible
check_status

echo "Waiting for MariaDB instance to be available..."
aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_MARIADB"
check_status

# Step 4: Create Your Target Amazon RDS Database (PostgreSQL)
echo "Step 4: Creating target PostgreSQL database..."

DB_INSTANCE_POSTGRES="dms-postgresql-$RANDOM_ID"
echo "Creating PostgreSQL instance: $DB_INSTANCE_POSTGRES"
aws rds create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_POSTGRES" \
    --engine postgres \
    --engine-version 16.9 \
    --db-instance-class db.m5.large \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password "$DB_PASSWORD" \
    --vpc-security-group-ids "$SG_ID" \
    --availability-zone "$AZ1" \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --db-parameter-group-name "$DB_PARAM_GROUP_POSTGRES" \
    --db-name dms_sample \
    --backup-retention-period 0 \
    --no-auto-minor-version-upgrade \
    --publicly-accessible
check_status

echo "Waiting for PostgreSQL instance to be available..."
aws rds wait db-instance-available --db-instance-identifier "$DB_INSTANCE_POSTGRES"
check_status
# Step 5: Create an Amazon EC2 Client
echo "Step 5: Creating EC2 client..."

# Get the latest Amazon Linux 2023 AMI
echo "Getting latest Amazon Linux 2023 AMI..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023*-x86_64" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text)
check_status
echo "Using AMI: $AMI_ID"

# Create a key pair
KEY_NAME="DMSKeyPair-$RANDOM_ID"
echo "Creating key pair: $KEY_NAME"
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
check_status
chmod 400 "${KEY_NAME}.pem"
echo "Key pair created and saved to ${KEY_NAME}.pem"

# Launch an EC2 instance
echo "Launching EC2 instance..."

# Find a suitable instance type for the availability zone
INSTANCE_TYPE=$(find_suitable_instance_type "$AZ1")
if [ $? -ne 0 ]; then
    echo "ERROR: Could not find a suitable instance type for availability zone $AZ1"
    exit 1
fi

echo "Using instance type: $INSTANCE_TYPE in availability zone: $AZ1"

EC2_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --subnet-id "$PUBLIC_SUBNET_1_ID" \
    --security-group-ids "$SG_ID" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DMSClient}]' \
    --associate-public-ip-address \
    --query 'Instances[0].InstanceId' \
    --output text)
check_status
echo "EC2 instance launched with ID: $EC2_INSTANCE_ID"

echo "Waiting for EC2 instance to be running..."
aws ec2 wait instance-running --instance-ids "$EC2_INSTANCE_ID"
check_status

# Step 6: Get Database Endpoints
echo "Step 6: Getting database endpoints..."

echo "Getting MariaDB endpoint..."
MARIADB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_MARIADB" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
check_status
echo "MariaDB endpoint: $MARIADB_ENDPOINT"

echo "Getting PostgreSQL endpoint..."
POSTGRES_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_INSTANCE_POSTGRES" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
check_status
echo "PostgreSQL endpoint: $POSTGRES_ENDPOINT"

# Get EC2 instance public IP
EC2_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$EC2_INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)
check_status
echo "EC2 instance public IP: $EC2_PUBLIC_IP"

# Step 7: Instructions for populating the source database (optional)
echo ""
echo "Step 7: Database Population"
echo "=========================="
echo "Do you want to populate the source database with sample data now?"
echo "Note: This step takes up to 45 minutes but is required for migration testing."
echo "You can skip this and populate the database later if preferred."
echo ""
echo "Populate source database with sample data? (y/n): "
read -r POPULATE_DATA

if [[ "${POPULATE_DATA,,}" == "y" ]]; then
    echo ""
    echo "✓ Proceeding with data population"
    echo "================================="
    echo "To populate your source database, connect to your EC2 instance using SSH:"
    echo "ssh -i ${KEY_NAME}.pem ec2-user@$EC2_PUBLIC_IP"
    echo ""
    echo "Then run the following commands on the EC2 instance:"
    echo "sudo yum install -y git"
    echo "sudo dnf install -y mariadb105"
    echo "sudo dnf install -y postgresql15"
    echo "git clone https://github.com/aws-samples/aws-database-migration-samples.git"
    echo "cd aws-database-migration-samples/mysql/sampledb/v1/"
    echo ""
    echo "Retrieve the database password from Secrets Manager:"
    echo "aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query 'SecretString' --output text"
    echo ""
    echo "Then use the password to connect to the database and run the installation script:"
    echo "mysql -h $MARIADB_ENDPOINT -P 3306 -u admin -p dms_sample < ~/aws-database-migration-samples/mysql/sampledb/v1/install-rds.sql"
    echo ""
    echo "Note: The database population script may take up to 45 minutes to complete."
    echo ""
    echo "Press Enter when you have completed populating the source database..."
    read -r
else
    echo ""
    echo "✗ Skipping data population"
    echo "========================="
    echo "You can populate the database later by following these steps:"
    echo "1. SSH to EC2 instance: ssh -i ${KEY_NAME}.pem ec2-user@$EC2_PUBLIC_IP"
    echo "2. Install required packages and clone the sample data repository"
    echo "3. Run the population script against the MariaDB endpoint: $MARIADB_ENDPOINT"
    echo ""
fi
# Step 8: Create a Replication Instance (optional)
echo ""
echo "Step 8: DMS Migration Setup"
echo "=========================="
echo "Do you want to create DMS resources and run a migration task now?"
echo "This includes creating a replication instance, endpoints, and migration task."
echo "You can skip this and set up DMS migration later if preferred."
echo ""
echo "Create and run DMS migration task? (y/n): "
read -r RUN_MIGRATION

if [[ "${RUN_MIGRATION,,}" == "y" ]]; then
    echo ""
    echo "✓ Proceeding with DMS migration setup"
    echo "====================================="
    echo "Creating DMS replication instance..."

    # Create a replication subnet group
    DMS_SUBNET_GROUP="dms-subnet-group-$RANDOM_ID"
    echo "Creating DMS subnet group: $DMS_SUBNET_GROUP"
    aws dms create-replication-subnet-group \
        --replication-subnet-group-identifier "$DMS_SUBNET_GROUP" \
        --replication-subnet-group-description "DMS subnet group" \
        --subnet-ids "$PUBLIC_SUBNET_1_ID" "$PUBLIC_SUBNET_2_ID"
    check_status

    # Create a replication instance
    DMS_INSTANCE="DMS-instance-$RANDOM_ID"
    echo "Creating DMS replication instance: $DMS_INSTANCE"
    aws dms create-replication-instance \
        --replication-instance-identifier "$DMS_INSTANCE" \
        --replication-instance-class dms.t3.medium \
        --allocated-storage 50 \
        --vpc-security-group-ids "$SG_ID" \
        --replication-subnet-group-identifier "$DMS_SUBNET_GROUP" \
        --availability-zone "$AZ1" \
        --no-publicly-accessible
    check_status

    echo "Waiting for DMS replication instance to be available..."
    # Wait for the replication instance to be available
    while true; do
        STATUS=$(aws dms describe-replication-instances \
            --filters Name=replication-instance-id,Values="$DMS_INSTANCE" \
            --query 'ReplicationInstances[0].Status' \
            --output text)
        
        if [ "$STATUS" = "available" ]; then
            echo "DMS replication instance is now available"
            break
        fi
        
        echo "Current status: $STATUS. Waiting 30 seconds..."
        sleep 30
    done

    # Get the replication instance ARN
    DMS_INSTANCE_ARN=$(aws dms describe-replication-instances \
        --filters Name=replication-instance-id,Values="$DMS_INSTANCE" \
        --query 'ReplicationInstances[0].ReplicationInstanceArn' \
        --output text)
    check_status
    echo "DMS replication instance ARN: $DMS_INSTANCE_ARN"
else
    echo ""
    echo "✗ Skipping DMS migration setup"
    echo "=============================="
    echo "Infrastructure is ready. You can create DMS resources later as needed."
    echo ""
fi

# Step 9: Specify Source and Target Endpoints (optional)
if [[ "${RUN_MIGRATION,,}" == "y" ]]; then
    echo "Step 9: Creating DMS endpoints..."

    # Create source endpoint
    SOURCE_ENDPOINT="dms-mysql-source-$RANDOM_ID"
    echo "Creating source endpoint: $SOURCE_ENDPOINT"
    SOURCE_ENDPOINT_ARN=$(aws dms create-endpoint \
        --endpoint-identifier "$SOURCE_ENDPOINT" \
        --endpoint-type source \
        --engine-name mysql \
        --username admin \
        --password "$DB_PASSWORD" \
        --server-name "$MARIADB_ENDPOINT" \
        --port 3306 \
        --database-name dms_sample \
        --query 'Endpoint.EndpointArn' \
        --output text)
    check_status
    echo "Source endpoint ARN: $SOURCE_ENDPOINT_ARN"

    # Create target endpoint
    TARGET_ENDPOINT="dms-postgresql-target-$RANDOM_ID"
    echo "Creating target endpoint: $TARGET_ENDPOINT"
    TARGET_ENDPOINT_ARN=$(aws dms create-endpoint \
        --endpoint-identifier "$TARGET_ENDPOINT" \
        --endpoint-type target \
        --engine-name postgres \
        --username postgres \
        --password "$DB_PASSWORD" \
        --server-name "$POSTGRES_ENDPOINT" \
        --port 5432 \
        --database-name dms_sample \
        --query 'Endpoint.EndpointArn' \
        --output text)
    check_status
    echo "Target endpoint ARN: $TARGET_ENDPOINT_ARN"

    # Test the source endpoint connection
    echo "Testing source endpoint connection..."
    aws dms test-connection \
        --replication-instance-arn "$DMS_INSTANCE_ARN" \
        --endpoint-arn "$SOURCE_ENDPOINT_ARN"
    check_status

    # Test the target endpoint connection
    echo "Testing target endpoint connection..."
    aws dms test-connection \
        --replication-instance-arn "$DMS_INSTANCE_ARN" \
        --endpoint-arn "$TARGET_ENDPOINT_ARN"
    check_status
else
    echo "Step 9: Skipping DMS endpoint creation (as requested)"
    echo "=================================================="
    echo "Database endpoints are available at:"
    echo "- MariaDB: $MARIADB_ENDPOINT:3306"
    echo "- PostgreSQL: $POSTGRES_ENDPOINT:5432"
    echo ""
fi

# Step 10: Create a Migration Task (optional)
if [[ "${RUN_MIGRATION,,}" == "y" ]]; then
    echo "Step 10: Creating DMS migration task..."

    # Create table mappings JSON
    TABLE_MAPPINGS='{
      "rules": [
        {
          "rule-type": "selection",
          "rule-id": "1",
          "rule-name": "1",
          "object-locator": {
            "schema-name": "dms_sample",
            "table-name": "%"
          },
          "rule-action": "include"
        }
      ]
    }'

    # Create task settings JSON
    TASK_SETTINGS='{
      "TargetMetadata": {
        "TargetSchema": "",
        "SupportLobs": true,
        "FullLobMode": false,
        "LobChunkSize": 64,
        "LimitedSizeLobMode": true,
        "LobMaxSize": 32
      },
      "FullLoadSettings": {
        "TargetTablePrepMode": "DO_NOTHING",
        "CreatePkAfterFullLoad": false,
        "StopTaskCachedChangesApplied": false,
        "StopTaskCachedChangesNotApplied": false,
        "MaxFullLoadSubTasks": 8,
        "TransactionConsistencyTimeout": 600,
        "CommitRate": 10000
      },
      "Logging": {
        "EnableLogging": true
      }
    }'

    # Create a migration task
    TASK_NAME="dms-task-$RANDOM_ID"
    echo "Creating migration task: $TASK_NAME"
    TASK_ARN=$(aws dms create-replication-task \
        --replication-task-identifier "$TASK_NAME" \
        --source-endpoint-arn "$SOURCE_ENDPOINT_ARN" \
        --target-endpoint-arn "$TARGET_ENDPOINT_ARN" \
        --replication-instance-arn "$DMS_INSTANCE_ARN" \
        --migration-type full-load-and-cdc \
        --table-mappings "$TABLE_MAPPINGS" \
        --replication-task-settings "$TASK_SETTINGS" \
        --query 'ReplicationTask.ReplicationTaskArn' \
        --output text)
    check_status
    echo "Migration task ARN: $TASK_ARN"

    echo "Waiting for migration task to be ready..."
    # Wait for the task to be ready
    while true; do
        STATUS=$(aws dms describe-replication-tasks \
            --filters Name=replication-task-arn,Values="$TASK_ARN" \
            --query 'ReplicationTasks[0].Status' \
            --output text)
        
        if [ "$STATUS" = "ready" ]; then
            echo "Migration task is now ready"
            break
        fi
        
        echo "Current status: $STATUS. Waiting 30 seconds..."
        sleep 30
    done

    # Start the migration task
    echo "Starting migration task..."
    aws dms start-replication-task \
        --replication-task-arn "$TASK_ARN" \
        --start-replication-task-type start-replication
    check_status

    echo "Migration task started. Initial replication will take some time to complete."
else
    echo "Step 10: Skipping DMS migration task creation (as requested)"
    echo "========================================================"
    echo "Infrastructure is ready. You can create migration tasks later as needed."
    echo ""
fi

# Step 11: Test Replication (optional)
if [[ "${RUN_MIGRATION,,}" == "y" ]]; then
    echo ""
    echo "Step 11: Test Replication"
    echo "========================="
    echo "To test replication, connect to your EC2 instance using SSH:"
    echo "ssh -i ${KEY_NAME}.pem ec2-user@$EC2_PUBLIC_IP"
    echo ""
    echo "Retrieve the database password from Secrets Manager:"
    echo "aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query 'SecretString' --output text"
    echo ""
    echo "Then run the following commands on the EC2 instance to insert data into the source database:"
    echo "mysql -h $MARIADB_ENDPOINT -P 3306 -u admin -p dms_sample"
    echo "insert person (full_name, last_name, first_name) VALUES ('Test User1', 'User1', 'Test');"
    echo "exit"
    echo ""
    echo "To verify replication, connect to the target database:"
    echo "psql --host=$POSTGRES_ENDPOINT --port=5432 --username=postgres --password --dbname=dms_sample"
    echo "When prompted, enter the password from Secrets Manager"
    echo ""
    echo "Then run the following query to check for the replicated data:"
    echo "select * from dms_sample.person where first_name = 'Test';"
    echo "quit"
    echo ""
    echo "You can monitor the migration task status with:"
    echo "aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=$TASK_ARN --query 'ReplicationTasks[0].Status'"
    echo ""
    echo "You can view table statistics with:"
    echo "aws dms describe-table-statistics --replication-task-arn $TASK_ARN"
    echo ""
else
    echo ""
    echo "Step 11: Infrastructure Setup Complete"
    echo "====================================="
    echo "Your AWS DMS infrastructure is ready. You can:"
    echo ""
    echo "1. Connect to databases directly:"
    echo "   - MariaDB: $MARIADB_ENDPOINT:3306 (username: admin)"
    echo "   - PostgreSQL: $POSTGRES_ENDPOINT:5432 (username: postgres)"
    echo ""
    echo "2. SSH to EC2 instance for database management:"
    echo "   ssh -i ${KEY_NAME}.pem ec2-user@$EC2_PUBLIC_IP"
    echo "   (Instance type: $INSTANCE_TYPE in AZ: $AZ1)"
    echo ""
    echo "3. Retrieve database password from Secrets Manager:"
    echo "   aws secretsmanager get-secret-value --secret-id $SECRET_ARN --query 'SecretString' --output text"
    echo ""
    if [[ "${POPULATE_DATA,,}" != "y" ]]; then
        echo "4. Populate source database when ready (see earlier instructions)"
        echo ""
    fi
    echo "5. Create DMS migration tasks later as needed"
    echo ""
fi

# Print summary of created resources
echo ""
echo "Summary of Created Resources"
echo "==========================="
print_resources

# Prompt for cleanup
cleanup_resources

echo "Script completed successfully."
exit 0
