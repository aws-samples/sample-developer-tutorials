#!/bin/bash

# VPC Lattice Service Network Tutorial Script
# This script demonstrates how to create and manage a VPC Lattice service network

# Set up logging
LOG_FILE="vpc-lattice-tutorial.log"
echo "Starting VPC Lattice tutorial script at $(date)" > $LOG_FILE

# Function to log commands and their output
log_command() {
    echo "$(date): Running command: $1" >> $LOG_FILE
    eval "$1" 2>&1 | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Function to check for errors
check_error() {
    if [ $1 -ne 0 ]; then
        echo "ERROR: Command failed with exit code $1" | tee -a $LOG_FILE
        echo "See $LOG_FILE for details"
        exit $1
    fi
}

# Function to wait for a resource to be in the desired state
wait_for_resource() {
    local resource_type=$1
    local resource_id=$2
    local desired_status=$3
    local command=$4
    local max_attempts=30
    local attempt=1
    local status=""

    echo "Waiting for $resource_type $resource_id to be in state $desired_status..." | tee -a $LOG_FILE
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..." >> $LOG_FILE
        
        # Run the command to get the status and capture the output
        status_output=$(eval "$command")
        echo "$status_output" >> $LOG_FILE
        
        # For service networks, they don't have a status field in the output
        # We'll consider them active if we can retrieve them
        if [[ "$resource_type" == "Service Network" ]]; then
            if [[ "$status_output" == *"$resource_id"* ]]; then
                echo "$resource_type $resource_id is now active" | tee -a $LOG_FILE
                return 0
            fi
        else
            # For other resources, extract the status field
            status=$(echo "$status_output" | grep -i "status" | awk -F'"' '{print $4}')
            echo "Current status: $status" >> $LOG_FILE
            
            if [[ "$status" == "$desired_status" ]]; then
                echo "$resource_type $resource_id is now in state $desired_status" | tee -a $LOG_FILE
                return 0
            elif [[ "$status" == *"FAIL"* ]]; then
                echo "ERROR: $resource_type $resource_id failed to reach desired state. Current status: $status" | tee -a $LOG_FILE
                return 1
            fi
        fi
        
        echo "Waiting for status change... (attempt $attempt/$max_attempts)" >> $LOG_FILE
        sleep 10
        ((attempt++))
    done
    
    echo "ERROR: Timed out waiting for $resource_type $resource_id to reach state $desired_status" | tee -a $LOG_FILE
    return 1
}

# Generate a random identifier for resource names
RANDOM_ID=$(openssl rand -hex 4)
SERVICE_NETWORK_NAME="lattice-network-${RANDOM_ID}"
SERVICE_NAME="lattice-service-${RANDOM_ID}"

# Store created resources for cleanup
CREATED_RESOURCES=()

echo "=== VPC Lattice Service Network Tutorial ===" | tee -a $LOG_FILE
echo "Random ID for this session: ${RANDOM_ID}" | tee -a $LOG_FILE

# Step 1: Create a VPC Lattice service network
echo -e "\n=== Step 1: Creating a VPC Lattice service network ===" | tee -a $LOG_FILE
echo "Creating service network: $SERVICE_NETWORK_NAME" | tee -a $LOG_FILE

SERVICE_NETWORK_OUTPUT=$(log_command "aws vpc-lattice create-service-network --name $SERVICE_NETWORK_NAME --tags Key=tutorial,Value=amazon-vpc-lattice-gs")
check_error $?

# Extract the service network ID
SERVICE_NETWORK_ID=$(echo "$SERVICE_NETWORK_OUTPUT" | grep -o '"id": "[^"]*' | cut -d'"' -f4)
if [ -z "$SERVICE_NETWORK_ID" ]; then
    echo "ERROR: Failed to extract service network ID" | tee -a $LOG_FILE
    exit 1
fi

echo "Service network created with ID: $SERVICE_NETWORK_ID" | tee -a $LOG_FILE
CREATED_RESOURCES+=("Service Network: $SERVICE_NETWORK_ID")

# Wait for the service network to be active
wait_for_resource "Service Network" "$SERVICE_NETWORK_ID" "ACTIVE" "aws vpc-lattice get-service-network --service-network-identifier $SERVICE_NETWORK_ID"
check_error $?

# Step 2: Create a VPC Lattice service
echo -e "\n=== Step 2: Creating a VPC Lattice service ===" | tee -a $LOG_FILE
echo "Creating service: $SERVICE_NAME" | tee -a $LOG_FILE

SERVICE_OUTPUT=$(log_command "aws vpc-lattice create-service --name $SERVICE_NAME --tags Key=tutorial,Value=amazon-vpc-lattice-gs")
check_error $?

# Extract the service ID
SERVICE_ID=$(echo "$SERVICE_OUTPUT" | grep -o '"id": "[^"]*' | cut -d'"' -f4)
if [ -z "$SERVICE_ID" ]; then
    echo "ERROR: Failed to extract service ID" | tee -a $LOG_FILE
    exit 1
fi

echo "Service created with ID: $SERVICE_ID" | tee -a $LOG_FILE
CREATED_RESOURCES+=("Service: $SERVICE_ID")

# Wait for the service to be active
wait_for_resource "Service" "$SERVICE_ID" "ACTIVE" "aws vpc-lattice get-service --service-identifier $SERVICE_ID"
check_error $?

# Step 3: Associate the service with the service network
echo -e "\n=== Step 3: Associating service with service network ===" | tee -a $LOG_FILE

SERVICE_ASSOC_OUTPUT=$(log_command "aws vpc-lattice create-service-network-service-association --service-identifier $SERVICE_ID --service-network-identifier $SERVICE_NETWORK_ID --tags Key=tutorial,Value=amazon-vpc-lattice-gs")
check_error $?

# Extract the service association ID
SERVICE_ASSOC_ID=$(echo "$SERVICE_ASSOC_OUTPUT" | grep -o '"id": "[^"]*' | cut -d'"' -f4)
if [ -z "$SERVICE_ASSOC_ID" ]; then
    echo "ERROR: Failed to extract service association ID" | tee -a $LOG_FILE
    exit 1
fi

echo "Service association created with ID: $SERVICE_ASSOC_ID" | tee -a $LOG_FILE
CREATED_RESOURCES+=("Service Association: $SERVICE_ASSOC_ID")

# Wait for the service association to be active
wait_for_resource "Service Association" "$SERVICE_ASSOC_ID" "ACTIVE" "aws vpc-lattice get-service-network-service-association --service-network-service-association-identifier $SERVICE_ASSOC_ID"
check_error $?

# Step 4: List available VPCs to associate with the service network
echo -e "\n=== Step 4: Listing available VPCs ===" | tee -a $LOG_FILE

VPC_LIST=$(log_command "aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==\`Name\`].Value|[0]]' --output text")
check_error $?

echo "Available VPCs:" | tee -a $LOG_FILE
echo "$VPC_LIST" | tee -a $LOG_FILE

# Step 5: Prompt user to select a VPC to associate
echo -e "\n=== Step 5: Associate a VPC with the service network ===" | tee -a $LOG_FILE
echo ""
echo "==========================================="
echo "VPC SELECTION"
echo "==========================================="
echo "Please enter the VPC ID you want to associate with the service network:"
if [ -t 0 ]; then
    read -r VPC_ID
else
    VPC_ID=""
fi

if [ -z "$VPC_ID" ]; then
    echo "ERROR: No VPC ID provided" | tee -a $LOG_FILE
    echo "Skipping VPC association step" | tee -a $LOG_FILE
else
    # Step 6: List security groups for the selected VPC
    echo -e "\n=== Step 6: Listing security groups for VPC $VPC_ID ===" | tee -a $LOG_FILE
    
    SG_LIST=$(log_command "aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID --query 'SecurityGroups[*].[GroupId,GroupName]' --output text")
    check_error $?
    
    echo "Available Security Groups for VPC $VPC_ID:" | tee -a $LOG_FILE
    echo "$SG_LIST" | tee -a $LOG_FILE
    
    # Step 7: Prompt user to select a security group
    echo -e "\n=== Step 7: Select a security group for the VPC association ===" | tee -a $LOG_FILE
    echo ""
    echo "==========================================="
    echo "SECURITY GROUP SELECTION"
    echo "==========================================="
    echo "Please enter the Security Group ID you want to use for the VPC association:"
    if [ -t 0 ]; then
        read -r SG_ID
    else
        SG_ID=""
    fi
    
    if [ -z "$SG_ID" ]; then
        echo "ERROR: No Security Group ID provided" | tee -a $LOG_FILE
        echo "Skipping VPC association step" | tee -a $LOG_FILE
    else
        # Step 8: Associate the VPC with the service network
        echo -e "\n=== Step 8: Associating VPC with service network ===" | tee -a $LOG_FILE
        
        VPC_ASSOC_OUTPUT=$(log_command "aws vpc-lattice create-service-network-vpc-association --vpc-identifier $VPC_ID --service-network-identifier $SERVICE_NETWORK_ID --security-group-ids $SG_ID --tags Key=tutorial,Value=amazon-vpc-lattice-gs")
        check_error $?
        
        # Extract the VPC association ID
        VPC_ASSOC_ID=$(echo "$VPC_ASSOC_OUTPUT" | grep -o '"id": "[^"]*' | cut -d'"' -f4)
        if [ -z "$VPC_ASSOC_ID" ]; then
            echo "ERROR: Failed to extract VPC association ID" | tee -a $LOG_FILE
        else
            echo "VPC association created with ID: $VPC_ASSOC_ID" | tee -a $LOG_FILE
            CREATED_RESOURCES+=("VPC Association: $VPC_ASSOC_ID")
            
            # Wait for the VPC association to be active
            wait_for_resource "VPC Association" "$VPC_ASSOC_ID" "ACTIVE" "aws vpc-lattice get-service-network-vpc-association --service-network-vpc-association-identifier $VPC_ASSOC_ID"
            check_error $?
        fi
    fi
fi

# Step 9: Display information about the created resources
echo -e "\n=== Step 9: Displaying information about created resources ===" | tee -a $LOG_FILE

echo "Service Network Details:" | tee -a $LOG_FILE
log_command "aws vpc-lattice get-service-network --service-network-identifier $SERVICE_NETWORK_ID"

echo "Service Details:" | tee -a $LOG_FILE
log_command "aws vpc-lattice get-service --service-identifier $SERVICE_ID"

echo "Service Network Service Associations:" | tee -a $LOG_FILE
log_command "aws vpc-lattice list-service-network-service-associations --service-network-identifier $SERVICE_NETWORK_ID"

echo "Service Network VPC Associations:" | tee -a $LOG_FILE
log_command "aws vpc-lattice list-service-network-vpc-associations --service-network-identifier $SERVICE_NETWORK_ID"

# Step 10: Cleanup confirmation
echo -e "\n=== Step 10: Resource Cleanup ===" | tee -a $LOG_FILE
echo "Resources created in this tutorial:" | tee -a $LOG_FILE
for resource in "${CREATED_RESOURCES[@]}"; do
    echo "- $resource" | tee -a $LOG_FILE
done

echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
if [ -t 0 ]; then
    read -rp '' CLEANUP_CHOICE
else
    CLEANUP_CHOICE=y
fi

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Starting cleanup process..." | tee -a $LOG_FILE
    
    # Delete resources in reverse order
    
    # Delete VPC association if it was created
    if [[ -n "$VPC_ASSOC_ID" ]]; then
        echo "Deleting VPC association: $VPC_ASSOC_ID" | tee -a $LOG_FILE
        log_command "aws vpc-lattice delete-service-network-vpc-association --service-network-vpc-association-identifier $VPC_ASSOC_ID"
        
        # Wait for the VPC association to be deleted
        echo "Waiting for VPC association to be deleted..." | tee -a $LOG_FILE
        sleep 30
    fi
    
    # Delete service association
    echo "Deleting service association: $SERVICE_ASSOC_ID" | tee -a $LOG_FILE
    log_command "aws vpc-lattice delete-service-network-service-association --service-network-service-association-identifier $SERVICE_ASSOC_ID"
    
    # Wait for the service association to be deleted
    echo "Waiting for service association to be deleted..." | tee -a $LOG_FILE
    sleep 30
    
    # Delete service
    echo "Deleting service: $SERVICE_ID" | tee -a $LOG_FILE
    log_command "aws vpc-lattice delete-service --service-identifier $SERVICE_ID"
    
    # Wait for the service to be deleted
    echo "Waiting for service to be deleted..." | tee -a $LOG_FILE
    sleep 30
    
    # Delete service network
    echo "Deleting service network: $SERVICE_NETWORK_ID" | tee -a $LOG_FILE
    log_command "aws vpc-lattice delete-service-network --service-network-identifier $SERVICE_NETWORK_ID"
    
    echo "Cleanup completed successfully!" | tee -a $LOG_FILE
else
    echo "Skipping cleanup. Resources will remain in your account." | tee -a $LOG_FILE
    echo "To clean up resources later, use the AWS CLI or console." | tee -a $LOG_FILE
fi

echo -e "\n=== Tutorial completed! ===" | tee -a $LOG_FILE
echo "Log file: $LOG_FILE" | tee -a $LOG_FILE