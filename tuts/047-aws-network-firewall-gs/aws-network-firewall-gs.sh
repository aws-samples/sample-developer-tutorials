#!/bin/bash

# AWS Network Firewall Getting Started Script v8
# This script creates and configures AWS Network Firewall resources

# FIXES in v8:
# 1. Fixed firewall endpoint ID query - the JSON structure was different than expected
# 2. Added debug output to show the actual firewall describe output
# 3. Fixed the query path based on the actual JSON structure shown in the error output
# 4. Added Priority parameter to StatelessRuleGroupReferences in firewall policy
# 5. Moved cleanup_resources function to top to avoid "command not found" error

# Set up logging
LOG_FILE="network-firewall-script.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting AWS Network Firewall setup script v8 at $(date)"
echo "All commands and outputs will be logged to $LOG_FILE"

# Check AWS CLI configuration
echo "Checking AWS CLI configuration..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "ERROR: AWS CLI is not configured or credentials are invalid"
  echo "Please run 'aws configure' to set up your credentials"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
echo "AWS Account: $ACCOUNT_ID"
echo "AWS Region: $REGION"
echo ""

# Initialize resource tracking
CREATED_RESOURCES=()

# Function to clean up resources - MOVED TO TOP
cleanup_resources() {
  echo ""
  echo "==========================================="
  echo "CLEANUP CONFIRMATION"
  echo "==========================================="
  echo "Do you want to clean up all created resources? (y/n):"
  read -r CLEANUP_CHOICE
  
  if [[ "${CLEANUP_CHOICE,,}" != "y" ]]; then
    echo "Skipping cleanup. Resources will remain in your account."
    return
  fi
  
  echo "Starting cleanup process..."
  
  # Restore original route tables
  echo "Restoring original route tables..."
  
  # Remove firewall routes from IGW route table (if different from customer subnet route table)
  if [ -n "$IGW_ROUTE_TABLE_ID" ] && [ -n "$SUBNET_ROUTE_TABLE_ID" ] && [ "$IGW_ROUTE_TABLE_ID" != "$SUBNET_ROUTE_TABLE_ID" ]; then
    echo "Removing firewall route from internet gateway route table..."
    if ! aws ec2 delete-route \
      --route-table-id "$IGW_ROUTE_TABLE_ID" \
      --destination-cidr-block "$CUSTOMER_SUBNET_CIDR" 2>/dev/null; then
      echo "WARNING: Failed to remove firewall route from IGW route table"
    fi
  fi
  
  # Remove firewall route from customer subnet route table
  if [ -n "$SUBNET_ROUTE_TABLE_ID" ]; then
    echo "Removing firewall route from customer subnet route table..."
    if ! aws ec2 delete-route \
      --route-table-id "$SUBNET_ROUTE_TABLE_ID" \
      --destination-cidr-block "0.0.0.0/0" 2>/dev/null; then
      echo "WARNING: Failed to remove firewall route from customer subnet route table"
    fi
    
    # Add back original route to IGW for customer subnet
    if [ -n "$INTERNET_GATEWAY_ID" ]; then
      echo "Restoring original internet route for customer subnet..."
      if ! aws ec2 create-route \
        --route-table-id "$SUBNET_ROUTE_TABLE_ID" \
        --destination-cidr-block "0.0.0.0/0" \
        --gateway-id "$INTERNET_GATEWAY_ID" 2>/dev/null; then
        echo "WARNING: Failed to restore original internet route"
      fi
    fi
  fi
  
  # Delete the firewall route table
  if [ -n "$FIREWALL_ROUTE_TABLE_ID" ]; then
    echo "Deleting firewall route table..."
    if ! aws ec2 delete-route-table --route-table-id "$FIREWALL_ROUTE_TABLE_ID" 2>/dev/null; then
      echo "WARNING: Failed to delete firewall route table"
    fi
  fi
  
  # Delete the firewall
  if [ -n "$FIREWALL_NAME" ]; then
    echo "Deleting firewall..."
    if ! aws network-firewall delete-firewall --firewall-name "$FIREWALL_NAME" 2>/dev/null; then
      echo "WARNING: Failed to delete firewall"
    fi
    
    # Wait for firewall to be deleted with timeout
    echo "Waiting for firewall to be deleted..."
    MAX_DELETE_WAIT=300  # 5 minutes timeout
    START_DELETE_TIME=$(date +%s)
    DELETED=false
    
    while [ $(($(date +%s) - START_DELETE_TIME)) -lt $MAX_DELETE_WAIT ]; do
      if ! aws network-firewall describe-firewall --firewall-name "$FIREWALL_NAME" 2>/dev/null; then
        DELETED=true
        break
      fi
      echo "Firewall still exists, waiting 10 seconds..."
      sleep 10
    done
    
    if [ "$DELETED" = false ]; then
      echo "WARNING: Firewall deletion is taking longer than expected. Continuing with cleanup..."
    else
      echo "Firewall deleted successfully."
    fi
  fi
  
  # Delete the firewall policy
  if [ -n "$FIREWALL_POLICY_NAME" ]; then
    echo "Deleting firewall policy..."
    if ! aws network-firewall delete-firewall-policy --firewall-policy-name "$FIREWALL_POLICY_NAME" 2>/dev/null; then
      echo "WARNING: Failed to delete firewall policy"
    fi
  fi
  
  # Delete the rule groups
  if [ -n "$STATELESS_RULE_GROUP_NAME" ]; then
    echo "Deleting stateless rule group..."
    if ! aws network-firewall delete-rule-group --rule-group-name "$STATELESS_RULE_GROUP_NAME" --type STATELESS 2>/dev/null; then
      echo "WARNING: Failed to delete stateless rule group"
    fi
  fi
  
  if [ -n "$STATEFUL_RULE_GROUP_NAME" ]; then
    echo "Deleting stateful rule group..."
    if ! aws network-firewall delete-rule-group --rule-group-name "$STATEFUL_RULE_GROUP_NAME" --type STATEFUL 2>/dev/null; then
      echo "WARNING: Failed to delete stateful rule group"
    fi
  fi
  
  echo "Cleanup complete!"
}

# Function to check for errors in command output
check_error() {
  local output=$1
  local cmd=$2
  
  if echo "$output" | grep -i "error" > /dev/null; then
    echo "ERROR: Command failed: $cmd"
    echo "Output: $output"
    cleanup_resources
    exit 1
  fi
}

# Function to generate random identifier
generate_random_id() {
  echo "nfw$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 8 | head -n 1)"
}
# Function to select VPC from list
select_vpc() {
  echo ""
  echo "==========================================="
  echo "VPC SELECTION"
  echo "==========================================="
  echo "Fetching available VPCs..."
  
  # Get VPC list with names and IDs
  VPC_LIST=$(aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock,State]' --output table)
  
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to fetch VPC list"
    exit 1
  fi
  
  echo "$VPC_LIST"
  echo ""
  
  # Get VPC data for selection
  VPC_DATA=$(aws ec2 describe-vpcs --query 'Vpcs[?State==`available`].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' --output text)
  
  if [ -z "$VPC_DATA" ]; then
    echo "ERROR: No available VPCs found"
    exit 1
  fi
  
  # Create numbered list
  echo "Available VPCs:"
  IFS=$'\n'
  VPC_ARRAY=()
  counter=1
  
  while IFS=$'\t' read -r vpc_id vpc_name cidr_block; do
    if [ -z "$vpc_name" ] || [ "$vpc_name" = "None" ]; then
      vpc_name="(no name)"
    fi
    echo "$counter. $vpc_id - $vpc_name ($cidr_block)"
    VPC_ARRAY+=("$vpc_id")
    ((counter++))
  done <<< "$VPC_DATA"
  
  echo ""
  echo "Enter the number of the VPC you want to use:"
  read -r VPC_CHOICE
  
  # Validate choice
  if ! [[ "$VPC_CHOICE" =~ ^[0-9]+$ ]] || [ "$VPC_CHOICE" -lt 1 ] || [ "$VPC_CHOICE" -gt ${#VPC_ARRAY[@]} ]; then
    echo "ERROR: Invalid selection. Please enter a number between 1 and ${#VPC_ARRAY[@]}"
    exit 1
  fi
  
  # Set selected VPC
  VPC_ID="${VPC_ARRAY[$((VPC_CHOICE-1))]}"
  echo "Selected VPC: $VPC_ID"
  
  # Get VPC CIDR for subnet creation
  VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query 'Vpcs[0].CidrBlock' --output text)
  echo "VPC CIDR: $VPC_CIDR"
}

# Function to select subnet from list
select_subnet() {
  echo ""
  echo "==========================================="
  echo "SUBNET SELECTION"
  echo "==========================================="
  echo "Fetching available subnets in VPC $VPC_ID..."
  
  # Get subnet list for the selected VPC
  SUBNET_LIST=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock,AvailabilityZone,State]' --output table)
  
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to fetch subnet list"
    exit 1
  fi
  
  echo "$SUBNET_LIST"
  echo ""
  
  # Get subnet data for selection
  SUBNET_DATA=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0],CidrBlock,AvailabilityZone]' --output text)
  
  if [ -z "$SUBNET_DATA" ]; then
    echo "ERROR: No available subnets found in VPC $VPC_ID"
    exit 1
  fi
  
  # Create numbered list
  echo "Available subnets in VPC $VPC_ID:"
  IFS=$'\n'
  SUBNET_ARRAY=()
  SUBNET_CIDR_ARRAY=()
  counter=1
  
  while IFS=$'\t' read -r subnet_id subnet_name cidr_block az; do
    if [ -z "$subnet_name" ] || [ "$subnet_name" = "None" ]; then
      subnet_name="(no name)"
    fi
    echo "$counter. $subnet_id - $subnet_name ($cidr_block) in $az"
    SUBNET_ARRAY+=("$subnet_id")
    SUBNET_CIDR_ARRAY+=("$cidr_block")
    ((counter++))
  done <<< "$SUBNET_DATA"
  
  echo ""
  echo "Enter the number of the subnet for the firewall:"
  read -r SUBNET_CHOICE
  
  # Validate choice
  if ! [[ "$SUBNET_CHOICE" =~ ^[0-9]+$ ]] || [ "$SUBNET_CHOICE" -lt 1 ] || [ "$SUBNET_CHOICE" -gt ${#SUBNET_ARRAY[@]} ]; then
    echo "ERROR: Invalid selection. Please enter a number between 1 and ${#SUBNET_ARRAY[@]}"
    exit 1
  fi
  
  # Set selected subnet
  SUBNET_ID="${SUBNET_ARRAY[$((SUBNET_CHOICE-1))]}"
  CUSTOMER_SUBNET_CIDR="${SUBNET_CIDR_ARRAY[$((SUBNET_CHOICE-1))]}"
  echo "Selected subnet: $SUBNET_ID ($CUSTOMER_SUBNET_CIDR)"
}

# Function to select route tables
select_route_tables() {
  echo ""
  echo "==========================================="
  echo "ROUTE TABLE SELECTION"
  echo "==========================================="
  echo "Fetching available route tables in VPC $VPC_ID..."
  
  # Get route table list for the selected VPC
  RT_LIST=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0],Associations[0].Main]' --output table)
  
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to fetch route table list"
    exit 1
  fi
  
  echo "$RT_LIST"
  echo ""
  
  # Get route table data for selection
  RT_DATA=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0],Associations[0].Main]' --output text)
  
  if [ -z "$RT_DATA" ]; then
    echo "ERROR: No route tables found in VPC $VPC_ID"
    exit 1
  fi
  
  # Create numbered list for IGW route table
  echo "Available route tables in VPC $VPC_ID:"
  echo "(Select the route table associated with your Internet Gateway)"
  IFS=$'\n'
  RT_ARRAY=()
  counter=1
  
  while IFS=$'\t' read -r rt_id rt_name is_main; do
    if [ -z "$rt_name" ] || [ "$rt_name" = "None" ]; then
      rt_name="(no name)"
    fi
    main_indicator=""
    if [ "$is_main" = "True" ]; then
      main_indicator=" [MAIN]"
    fi
    echo "$counter. $rt_id - $rt_name$main_indicator"
    RT_ARRAY+=("$rt_id")
    ((counter++))
  done <<< "$RT_DATA"
  
  echo ""
  echo "Enter the number of the Internet Gateway route table:"
  read -r IGW_RT_CHOICE
  
  # Validate choice
  if ! [[ "$IGW_RT_CHOICE" =~ ^[0-9]+$ ]] || [ "$IGW_RT_CHOICE" -lt 1 ] || [ "$IGW_RT_CHOICE" -gt ${#RT_ARRAY[@]} ]; then
    echo "ERROR: Invalid selection. Please enter a number between 1 and ${#RT_ARRAY[@]}"
    exit 1
  fi
  
  IGW_ROUTE_TABLE_ID="${RT_ARRAY[$((IGW_RT_CHOICE-1))]}"
  echo "Selected IGW route table: $IGW_ROUTE_TABLE_ID"
  
  echo ""
  echo "Enter the number of the customer subnet route table:"
  read -r SUBNET_RT_CHOICE
  
  # Validate choice
  if ! [[ "$SUBNET_RT_CHOICE" =~ ^[0-9]+$ ]] || [ "$SUBNET_RT_CHOICE" -lt 1 ] || [ "$SUBNET_RT_CHOICE" -gt ${#RT_ARRAY[@]} ]; then
    echo "ERROR: Invalid selection. Please enter a number between 1 and ${#RT_ARRAY[@]}"
    exit 1
  fi
  
  SUBNET_ROUTE_TABLE_ID="${RT_ARRAY[$((SUBNET_RT_CHOICE-1))]}"
  echo "Selected subnet route table: $SUBNET_ROUTE_TABLE_ID"
}

# Function to select Internet Gateway
select_internet_gateway() {
  echo ""
  echo "==========================================="
  echo "INTERNET GATEWAY SELECTION"
  echo "==========================================="
  echo "Fetching available Internet Gateways..."
  
  # Get IGW list attached to the selected VPC
  IGW_LIST=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].[InternetGatewayId,Tags[?Key==`Name`].Value|[0],State]' --output table)
  
  if [ $? -ne 0 ]; then
    echo "ERROR: Failed to fetch Internet Gateway list"
    exit 1
  fi
  
  echo "$IGW_LIST"
  echo ""
  
  # Get IGW data for selection
  IGW_DATA=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].[InternetGatewayId,Tags[?Key==`Name`].Value|[0]]' --output text)
  
  if [ -z "$IGW_DATA" ]; then
    echo "ERROR: No Internet Gateways found attached to VPC $VPC_ID"
    exit 1
  fi
  
  # Create numbered list
  echo "Available Internet Gateways attached to VPC $VPC_ID:"
  IFS=$'\n'
  IGW_ARRAY=()
  counter=1
  
  while IFS=$'\t' read -r igw_id igw_name; do
    if [ -z "$igw_name" ] || [ "$igw_name" = "None" ]; then
      igw_name="(no name)"
    fi
    echo "$counter. $igw_id - $igw_name"
    IGW_ARRAY+=("$igw_id")
    ((counter++))
  done <<< "$IGW_DATA"
  
  echo ""
  echo "Enter the number of the Internet Gateway:"
  read -r IGW_CHOICE
  
  # Validate choice
  if ! [[ "$IGW_CHOICE" =~ ^[0-9]+$ ]] || [ "$IGW_CHOICE" -lt 1 ] || [ "$IGW_CHOICE" -gt ${#IGW_ARRAY[@]} ]; then
    echo "ERROR: Invalid selection. Please enter a number between 1 and ${#IGW_ARRAY[@]}"
    exit 1
  fi
  
  # Set selected IGW
  INTERNET_GATEWAY_ID="${IGW_ARRAY[$((IGW_CHOICE-1))]}"
  echo "Selected Internet Gateway: $INTERNET_GATEWAY_ID"
}
# Generate unique names for resources
STATELESS_RULE_GROUP_NAME="StatelessRuleGroup-$(generate_random_id)"
STATEFUL_RULE_GROUP_NAME="StatefulRuleGroup-$(generate_random_id)"
FIREWALL_POLICY_NAME="FirewallPolicy-$(generate_random_id)"
FIREWALL_NAME="Firewall-$(generate_random_id)"

echo "Resource names:"
echo "- Stateless Rule Group: $STATELESS_RULE_GROUP_NAME"
echo "- Stateful Rule Group: $STATEFUL_RULE_GROUP_NAME"
echo "- Firewall Policy: $FIREWALL_POLICY_NAME"
echo "- Firewall: $FIREWALL_NAME"

# Step 1: Create rule groups
echo ""
echo "==========================================="
echo "STEP 1: CREATING RULE GROUPS"
echo "==========================================="

# Create stateless rule group
echo "Creating stateless rule group..."
STATELESS_RULE_GROUP_ARN=$(aws network-firewall create-rule-group \
  --rule-group-name "$STATELESS_RULE_GROUP_NAME" \
  --type STATELESS \
  --capacity 10 \
  --rule-group '{"RulesSource": {"StatelessRulesAndCustomActions": {"StatelessRules": [{"RuleDefinition": {"MatchAttributes": {"Sources": [{"AddressDefinition": "192.0.2.0/24"}], "Destinations": [], "SourcePorts": [], "DestinationPorts": [], "Protocols": []}, "Actions": ["aws:drop"]}, "Priority": 10}]}}}' \
  --description "Stateless rule group example" \
  --query 'RuleGroupResponse.RuleGroupArn' \
  --output text)

if [ $? -ne 0 ] || [ -z "$STATELESS_RULE_GROUP_ARN" ]; then
  echo "ERROR: Failed to create stateless rule group"
  cleanup_resources
  exit 1
fi

echo "Created stateless rule group: $STATELESS_RULE_GROUP_ARN"
CREATED_RESOURCES+=("Stateless Rule Group: $STATELESS_RULE_GROUP_NAME ($STATELESS_RULE_GROUP_ARN)")

# Create stateful rule group
echo "Creating stateful rule group..."
STATEFUL_RULE_GROUP_ARN=$(aws network-firewall create-rule-group \
  --rule-group-name "$STATEFUL_RULE_GROUP_NAME" \
  --type STATEFUL \
  --capacity 10 \
  --rule-group '{"RulesSource": {"RulesString": "drop tls $HOME_NET any -> $EXTERNAL_NET any (ssl_state:client_hello; tls.sni; content:\"evil.com\"; startswith; nocase; endswith; msg:\"matching TLS denylisted FQDNs\"; priority:1; flow:to_server, established; sid:1; rev:1;)"}}' \
  --description "Stateful rule group example" \
  --query 'RuleGroupResponse.RuleGroupArn' \
  --output text)

if [ $? -ne 0 ] || [ -z "$STATEFUL_RULE_GROUP_ARN" ]; then
  echo "ERROR: Failed to create stateful rule group"
  cleanup_resources
  exit 1
fi

echo "Created stateful rule group: $STATEFUL_RULE_GROUP_ARN"
CREATED_RESOURCES+=("Stateful Rule Group: $STATEFUL_RULE_GROUP_NAME ($STATEFUL_RULE_GROUP_ARN)")

# Step 2: Create a firewall policy
echo ""
echo "==========================================="
echo "STEP 2: CREATING FIREWALL POLICY"
echo "==========================================="

# Verify rule group ARNs were captured
if [ -z "$STATELESS_RULE_GROUP_ARN" ] || [ -z "$STATEFUL_RULE_GROUP_ARN" ]; then
  echo "ERROR: Failed to capture rule group ARNs"
  cleanup_resources
  exit 1
fi

# FIXED: Added Priority parameter to StatelessRuleGroupReferences
# Create firewall policy
FIREWALL_POLICY_ARN=$(aws network-firewall create-firewall-policy \
  --firewall-policy-name "$FIREWALL_POLICY_NAME" \
  --firewall-policy '{
    "StatelessDefaultActions": ["aws:forward_to_sfe"],
    "StatelessFragmentDefaultActions": ["aws:forward_to_sfe"],
    "StatelessRuleGroupReferences": [
      {
        "ResourceArn": "'"$STATELESS_RULE_GROUP_ARN"'",
        "Priority": 100
      }
    ],
    "StatefulRuleGroupReferences": [
      {
        "ResourceArn": "'"$STATEFUL_RULE_GROUP_ARN"'"
      }
    ]
  }' \
  --description "Firewall policy example" \
  --query 'FirewallPolicyResponse.FirewallPolicyArn' \
  --output text)

if [ $? -ne 0 ] || [ -z "$FIREWALL_POLICY_ARN" ]; then
  echo "ERROR: Failed to create firewall policy"
  cleanup_resources
  exit 1
fi

echo "Created firewall policy: $FIREWALL_POLICY_ARN"
CREATED_RESOURCES+=("Firewall Policy: $FIREWALL_POLICY_NAME ($FIREWALL_POLICY_ARN)")

# Verify all ARNs were captured successfully
echo ""
echo "Verifying resource ARNs..."
echo "Stateless Rule Group ARN: $STATELESS_RULE_GROUP_ARN"
echo "Stateful Rule Group ARN: $STATEFUL_RULE_GROUP_ARN"
echo "Firewall Policy ARN: $FIREWALL_POLICY_ARN"

if [ -z "$STATELESS_RULE_GROUP_ARN" ] || [ -z "$STATEFUL_RULE_GROUP_ARN" ] || [ -z "$FIREWALL_POLICY_ARN" ]; then
  echo "ERROR: One or more resource ARNs are missing"
  cleanup_resources
  exit 1
fi

# Step 3: Create a firewall
echo ""
echo "==========================================="
echo "STEP 3: CREATING FIREWALL"
echo "==========================================="

# Interactive resource selection
select_vpc
select_subnet

# Display selected configuration
echo ""
echo "==========================================="
echo "SELECTED CONFIGURATION SUMMARY"
echo "==========================================="
echo "VPC ID: $VPC_ID"
echo "VPC CIDR: $VPC_CIDR"
echo "Firewall Subnet ID: $SUBNET_ID"
echo "Customer Subnet CIDR: $CUSTOMER_SUBNET_CIDR"
echo ""
echo "Press Enter to continue with firewall creation, or Ctrl+C to abort..."
read -r

# Create firewall
FIREWALL_OUTPUT=$(aws network-firewall create-firewall \
  --firewall-name "$FIREWALL_NAME" \
  --firewall-policy-arn "$FIREWALL_POLICY_ARN" \
  --vpc-id "$VPC_ID" \
  --subnet-mappings "SubnetId=$SUBNET_ID")

check_error "$FIREWALL_OUTPUT" "Create firewall"
echo "$FIREWALL_OUTPUT"

CREATED_RESOURCES+=("Firewall: $FIREWALL_NAME")

# Wait for firewall to be ready with timeout
echo "Waiting for firewall to be ready..."
MAX_WAIT_TIME=600  # 5 minutes timeout
START_TIME=$(date +%s)
READY=false

while [ $(($(date +%s) - START_TIME)) -lt $MAX_WAIT_TIME ]; do
  STATUS=$(aws network-firewall describe-firewall --firewall-name "$FIREWALL_NAME" --query "FirewallStatus.Status" --output text)
  if [ "$STATUS" = "READY" ]; then
    READY=true
    break
  fi
  echo "Firewall not ready yet (status: $STATUS), waiting 20 seconds..."
  sleep 20
done

if [ "$READY" = false ]; then
  echo "ERROR: Firewall did not become ready within $MAX_WAIT_TIME seconds"
  cleanup_resources
  exit 1
fi

echo "Firewall is ready!"

# Step 4: Update route tables
echo ""
echo "==========================================="
echo "STEP 4: SETTING UP ROUTE TABLES"
echo "==========================================="

# FIXED: Get firewall endpoint ID with correct query path based on actual JSON structure
echo "Getting firewall endpoint information..."

# First, let's get the full firewall description to debug
echo "DEBUG: Getting full firewall description..."
FIREWALL_FULL_OUTPUT=$(aws network-firewall describe-firewall --firewall-name "$FIREWALL_NAME")
echo "DEBUG: Full firewall output:"
echo "$FIREWALL_FULL_OUTPUT"

# Based on the JSON structure shown in the error, the correct path is:
# FirewallStatus.SyncStates.<availability-zone>.Attachment.EndpointId
# Since we don't know the AZ name, we need to get the first one

# Get all availability zones that have endpoints
AZ_LIST=$(echo "$FIREWALL_FULL_OUTPUT" | grep -o '"us-[^"]*"' | head -1 | tr -d '"')
echo "DEBUG: Found availability zone: $AZ_LIST"

if [ -n "$AZ_LIST" ]; then
  # Use the specific AZ to get the endpoint ID
  FIREWALL_ENDPOINT=$(aws network-firewall describe-firewall \
    --firewall-name "$FIREWALL_NAME" \
    --query "FirewallStatus.SyncStates.\"$AZ_LIST\".Attachment.EndpointId" \
    --output text)
else
  # Fallback: try to extract endpoint ID from the full output using grep
  FIREWALL_ENDPOINT=$(echo "$FIREWALL_FULL_OUTPUT" | grep -o '"EndpointId": "[^"]*"' | head -1 | cut -d'"' -f4)
fi

echo "DEBUG: Extracted endpoint ID: $FIREWALL_ENDPOINT"

if [ -z "$FIREWALL_ENDPOINT" ] || [ "$FIREWALL_ENDPOINT" = "None" ]; then
  echo "ERROR: Failed to get firewall endpoint ID"
  echo "Full firewall output for debugging:"
  echo "$FIREWALL_FULL_OUTPUT"
  cleanup_resources
  exit 1
fi

echo "Firewall endpoint ID: $FIREWALL_ENDPOINT"

# Interactive resource selection for route tables and IGW
select_route_tables
select_internet_gateway

# Display route table configuration summary
echo ""
echo "==========================================="
echo "ROUTE TABLE CONFIGURATION SUMMARY"
echo "==========================================="
echo "Internet Gateway Route Table ID: $IGW_ROUTE_TABLE_ID"
echo "Customer Subnet Route Table ID: $SUBNET_ROUTE_TABLE_ID"
echo "Customer Subnet CIDR: $CUSTOMER_SUBNET_CIDR"
echo "Internet Gateway ID: $INTERNET_GATEWAY_ID"
echo "Firewall Endpoint ID: $FIREWALL_ENDPOINT"
echo ""
echo "Press Enter to continue with route table updates, or Ctrl+C to abort..."
read -r

# Create a route table for the firewall endpoint
echo "Creating route table for firewall endpoint..."
FIREWALL_ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)

if [ $? -ne 0 ] || [ -z "$FIREWALL_ROUTE_TABLE_ID" ]; then
  echo "ERROR: Failed to create firewall route table"
  cleanup_resources
  exit 1
fi

echo "Created firewall route table: $FIREWALL_ROUTE_TABLE_ID"
CREATED_RESOURCES+=("Firewall Route Table: $FIREWALL_ROUTE_TABLE_ID")

# Add routes to the firewall route table
echo "Adding routes to firewall route table..."
if ! aws ec2 create-route \
  --route-table-id "$FIREWALL_ROUTE_TABLE_ID" \
  --destination-cidr-block "$CUSTOMER_SUBNET_CIDR" \
  --vpc-endpoint-id "$FIREWALL_ENDPOINT"; then
  echo "ERROR: Failed to create route to customer subnet"
  cleanup_resources
  exit 1
fi

if ! aws ec2 create-route \
  --route-table-id "$FIREWALL_ROUTE_TABLE_ID" \
  --destination-cidr-block "0.0.0.0/0" \
  --gateway-id "$INTERNET_GATEWAY_ID"; then
  echo "ERROR: Failed to create route to internet"
  cleanup_resources
  exit 1
fi

# Update the internet gateway route table
echo "Updating internet gateway route table..."
if ! aws ec2 create-route \
  --route-table-id "$IGW_ROUTE_TABLE_ID" \
  --destination-cidr-block "$CUSTOMER_SUBNET_CIDR" \
  --vpc-endpoint-id "$FIREWALL_ENDPOINT"; then
  echo "ERROR: Failed to update internet gateway route"
  cleanup_resources
  exit 1
fi

# Update the customer subnet route table
echo "Updating customer subnet route table..."
if ! aws ec2 create-route \
  --route-table-id "$SUBNET_ROUTE_TABLE_ID" \
  --destination-cidr-block "0.0.0.0/0" \
  --vpc-endpoint-id "$FIREWALL_ENDPOINT"; then
  echo "ERROR: Failed to update customer subnet route"
  cleanup_resources
  exit 1
fi

echo ""
echo "==========================================="
echo "SETUP COMPLETE!"
echo "==========================================="
echo "Network Firewall setup complete!"
echo ""
echo "The following resources were created:"
for resource in "${CREATED_RESOURCES[@]}"; do
  echo "- $resource"
done

echo ""
echo "Traffic flow:"
echo "1. Customer subnet ($CUSTOMER_SUBNET_CIDR) -> Firewall -> Internet"
echo "2. Internet -> Firewall -> Customer subnet ($CUSTOMER_SUBNET_CIDR)"

# Ask if user wants to clean up resources
cleanup_resources

echo ""
echo "Script completed at $(date)"
