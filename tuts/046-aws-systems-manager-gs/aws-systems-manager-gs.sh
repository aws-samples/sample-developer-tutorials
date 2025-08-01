#!/bin/bash

# AWS Systems Manager Setup Script
# This script sets up AWS Systems Manager for a single account and region
#
# Version 17 fixes:
# 1. Added cloudformation.amazonaws.com to the IAM role trust policy
# 2. Systems Manager Quick Setup uses CloudFormation for deployments, so the role must trust CloudFormation service

# Initialize log file
LOG_FILE="ssm_setup_$(date +%Y%m%d_%H%M%S).log"
echo "Starting AWS Systems Manager setup at $(date)" > "$LOG_FILE"

# Function to log commands and their outputs with immediate terminal display
log_cmd() {
    echo "$(date): Running command: $1" | tee -a "$LOG_FILE"
    local output
    output=$(eval "$1" 2>&1)
    local status=$?
    echo "$output" | tee -a "$LOG_FILE"
    return $status
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    
    if [[ $cmd_status -ne 0 || "$cmd_output" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
        echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
        echo "Command output: $cmd_output" | tee -a "$LOG_FILE"
        cleanup_on_error
        exit 1
    fi
}

# Array to track created resources for cleanup
declare -a CREATED_RESOURCES

# Function to add a resource to the tracking array
track_resource() {
    local resource_type="$1"
    local resource_id="$2"
    CREATED_RESOURCES+=("$resource_type:$resource_id")
    echo "Tracked resource: $resource_type:$resource_id" | tee -a "$LOG_FILE"
}

# Function to clean up resources on error
cleanup_on_error() {
    echo "" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "ERROR OCCURRED - CLEANING UP RESOURCES" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    echo "The following resources were created:" | tee -a "$LOG_FILE"
    
    # Display resources in reverse order
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        echo "${CREATED_RESOURCES[$i]}" | tee -a "$LOG_FILE"
    done
    
    echo "" | tee -a "$LOG_FILE"
    echo "Attempting to clean up resources..." | tee -a "$LOG_FILE"
    
    # Clean up resources in reverse order
    cleanup_resources
}

# Function to clean up all created resources
cleanup_resources() {
    # Process resources in reverse order (last created, first deleted)
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=':' read -r resource_type resource_id <<< "${CREATED_RESOURCES[$i]}"
        
        echo "Deleting $resource_type: $resource_id" | tee -a "$LOG_FILE"
        
        case "$resource_type" in
            "IAM_POLICY")
                # Delete the policy (detachment should have been handled when the role was deleted)
                log_cmd "aws iam delete-policy --policy-arn $resource_id" || true
                ;;
            "IAM_ROLE")
                # Detach all policies from the role first
                if [[ -n "$POLICY_ARN" ]]; then
                    log_cmd "aws iam detach-role-policy --role-name $resource_id --policy-arn $POLICY_ARN" || true
                fi
                
                # Delete the role
                log_cmd "aws iam delete-role --role-name $resource_id" || true
                ;;
            "SSM_CONFIG_MANAGER")
                log_cmd "aws ssm-quicksetup delete-configuration-manager --manager-arn $resource_id" || true
                ;;
            *)
                echo "Unknown resource type: $resource_type, cannot delete automatically" | tee -a "$LOG_FILE"
                ;;
        esac
    done
    
    echo "Cleanup completed" | tee -a "$LOG_FILE"
    
    # Clean up temporary files
    rm -f ssm-onboarding-policy.json trust-policy.json ssm-config.json 2>/dev/null || true
}

# Main script execution
echo "AWS Systems Manager Setup Script"
echo "================================"
echo "This script will set up AWS Systems Manager for a single account and region."
echo "It will create IAM policies and roles, then enable Systems Manager features."
echo ""

# Get the current AWS region
CURRENT_REGION=$(aws configure get region)
if [[ -z "$CURRENT_REGION" ]]; then
    echo "No AWS region configured. Please specify a region:"
    read -r CURRENT_REGION
    if [[ -z "$CURRENT_REGION" ]]; then
        echo "ERROR: A region must be specified" | tee -a "$LOG_FILE"
        exit 1
    fi
fi

echo "Using AWS region: $CURRENT_REGION" | tee -a "$LOG_FILE"

# Step 1: Create IAM policy for Systems Manager onboarding
echo "Step 1: Creating IAM policy for Systems Manager onboarding..."

# Create policy document
cat > ssm-onboarding-policy.json << 'EOF'
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Sid": "QuickSetupActions",
       "Effect": "Allow",
       "Action": [
         "ssm-quicksetup:*"
       ],
       "Resource": "*"
     },
     {
       "Sid": "SsmReadOnly",
       "Effect": "Allow",
       "Action": [
         "ssm:DescribeAutomationExecutions",
         "ssm:GetAutomationExecution",
         "ssm:ListAssociations",
         "ssm:DescribeAssociation",
         "ssm:ListDocuments",
         "ssm:ListResourceDataSync",
         "ssm:DescribePatchBaselines",
         "ssm:GetPatchBaseline",
         "ssm:DescribeMaintenanceWindows",
         "ssm:DescribeMaintenanceWindowTasks"
       ],
       "Resource": "*"
     },
     {
       "Sid": "SsmDocument",
       "Effect": "Allow",
       "Action": [
         "ssm:GetDocument",
         "ssm:DescribeDocument"
       ],
       "Resource": [
         "arn:aws:ssm:*:*:document/AWSQuickSetupType-*",
         "arn:aws:ssm:*:*:document/AWS-EnableExplorer"
       ]
     },
     {
       "Sid": "SsmEnableExplorer",
       "Effect": "Allow",
       "Action": "ssm:StartAutomationExecution",
       "Resource": "arn:aws:ssm:*:*:automation-definition/AWS-EnableExplorer:*"
     },
     {
       "Sid": "SsmExplorerRds",
       "Effect": "Allow",
       "Action": [
         "ssm:GetOpsSummary",
         "ssm:CreateResourceDataSync",
         "ssm:UpdateResourceDataSync"
       ],
       "Resource": "arn:aws:ssm:*:*:resource-data-sync/AWS-QuickSetup-*"
     },
     {
       "Sid": "OrgsReadOnly",
       "Effect": "Allow",
       "Action": [
         "organizations:DescribeAccount",
         "organizations:DescribeOrganization",
         "organizations:ListDelegatedAdministrators",
         "organizations:ListRoots",
         "organizations:ListParents",
         "organizations:ListOrganizationalUnitsForParent",
         "organizations:DescribeOrganizationalUnit",
         "organizations:ListAWSServiceAccessForOrganization"
       ],
       "Resource": "*"
     },
     {
       "Sid": "OrgsAdministration",
       "Effect": "Allow",
       "Action": [
         "organizations:EnableAWSServiceAccess",
         "organizations:RegisterDelegatedAdministrator",
         "organizations:DeregisterDelegatedAdministrator"
       ],
       "Resource": "*",
       "Condition": {
         "StringEquals": {
           "organizations:ServicePrincipal": [
             "ssm.amazonaws.com",
             "ssm-quicksetup.amazonaws.com",
             "member.org.stacksets.cloudformation.amazonaws.com",
             "resource-explorer-2.amazonaws.com"
           ]
         }
       }
     },
     {
       "Sid": "CfnReadOnly",
       "Effect": "Allow",
       "Action": [
         "cloudformation:ListStacks",
         "cloudformation:DescribeStacks",
         "cloudformation:ListStackSets",
         "cloudformation:DescribeOrganizationsAccess"
       ],
       "Resource": "*"
     },
     {
       "Sid": "OrgCfnAccess",
       "Effect": "Allow",
       "Action": [
         "cloudformation:ActivateOrganizationsAccess"
       ],
       "Resource": "*"
     },
     {
       "Sid": "CfnStackActions",
       "Effect": "Allow",
       "Action": [
         "cloudformation:CreateStack",
         "cloudformation:DeleteStack",
         "cloudformation:DescribeStackResources",
         "cloudformation:DescribeStackEvents",
         "cloudformation:GetTemplate",
         "cloudformation:RollbackStack",
         "cloudformation:TagResource",
         "cloudformation:UntagResource",
         "cloudformation:UpdateStack"
       ],
       "Resource": [
         "arn:aws:cloudformation:*:*:stack/StackSet-AWS-QuickSetup-*",
         "arn:aws:cloudformation:*:*:stack/AWS-QuickSetup-*",
         "arn:aws:cloudformation:*:*:type/resource/*"
       ]
     },
     {
       "Sid": "CfnStackSetActions",
       "Effect": "Allow",
       "Action": [
         "cloudformation:CreateStackInstances",
         "cloudformation:CreateStackSet",
         "cloudformation:DeleteStackInstances",
         "cloudformation:DeleteStackSet",
         "cloudformation:DescribeStackInstance",
         "cloudformation:DetectStackSetDrift",
         "cloudformation:ListStackInstanceResourceDrifts",
         "cloudformation:DescribeStackSet",
         "cloudformation:DescribeStackSetOperation",
         "cloudformation:ListStackInstances",
         "cloudformation:ListStackSetOperations",
         "cloudformation:ListStackSetOperationResults",
         "cloudformation:TagResource",
         "cloudformation:UntagResource",
         "cloudformation:UpdateStackSet"
       ],
       "Resource": [
         "arn:aws:cloudformation:*:*:stackset/AWS-QuickSetup-*",
         "arn:aws:cloudformation:*:*:type/resource/*",
         "arn:aws:cloudformation:*:*:stackset-target/AWS-QuickSetup-*:*"
       ]
     },
     {
       "Sid": "ValidationReadonlyActions",
       "Effect": "Allow",
       "Action": [
         "iam:ListRoles",
         "iam:GetRole"
       ],
       "Resource": "*"
     },
     {
       "Sid": "IamRolesMgmt",
       "Effect": "Allow",
       "Action": [
         "iam:CreateRole",
         "iam:DeleteRole",
         "iam:GetRole",
         "iam:AttachRolePolicy",
         "iam:DetachRolePolicy",
         "iam:GetRolePolicy",
         "iam:ListRolePolicies"
       ],
       "Resource": [
         "arn:aws:iam::*:role/AWS-QuickSetup-*",
         "arn:aws:iam::*:role/service-role/AWS-QuickSetup-*"
       ]
     },
     {
       "Sid": "IamPassRole",
       "Effect": "Allow",
       "Action": [
         "iam:PassRole"
       ],
       "Resource": [
         "arn:aws:iam::*:role/AWS-QuickSetup-*",
         "arn:aws:iam::*:role/service-role/AWS-QuickSetup-*"
       ],
       "Condition": {
         "StringEquals": {
           "iam:PassedToService": [
             "ssm.amazonaws.com",
             "ssm-quicksetup.amazonaws.com",
             "cloudformation.amazonaws.com"
           ]
         }
       }
     },
     {
       "Sid": "IamRolesPoliciesMgmt",
       "Effect": "Allow",
       "Action": [
         "iam:AttachRolePolicy",
         "iam:DetachRolePolicy"
       ],
       "Resource": [
         "arn:aws:iam::*:role/AWS-QuickSetup-*",
         "arn:aws:iam::*:role/service-role/AWS-QuickSetup-*"
       ],
       "Condition": {
         "ArnEquals": {
           "iam:PolicyARN": [
             "arn:aws:iam::aws:policy/AWSSystemsManagerEnableExplorerExecutionPolicy",
             "arn:aws:iam::aws:policy/AWSQuickSetupSSMDeploymentRolePolicy"
           ]
         }
       }
     },
     {
       "Sid": "CfnStackSetsSLR",
       "Effect": "Allow",
       "Action": [
         "iam:CreateServiceLinkedRole"
       ],
       "Resource": [
         "arn:aws:iam::*:role/aws-service-role/stacksets.cloudformation.amazonaws.com/AWSServiceRoleForCloudFormationStackSetsOrgAdmin",
         "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM",
         "arn:aws:iam::*:role/aws-service-role/accountdiscovery.ssm.amazonaws.com/AWSServiceRoleForAmazonSSM_AccountDiscovery",
         "arn:aws:iam::*:role/aws-service-role/ssm-quicksetup.amazonaws.com/AWSServiceRoleForSSMQuickSetup",
         "arn:aws:iam::*:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
       ]
     }
   ]
}
EOF

# Create the IAM policy
POLICY_OUTPUT=$(log_cmd "aws iam create-policy --policy-name SSMOnboardingPolicy --policy-document file://ssm-onboarding-policy.json --output json")
POLICY_STATUS=$?
check_error "$POLICY_OUTPUT" $POLICY_STATUS "Failed to create IAM policy"

# Extract the policy ARN
POLICY_ARN=$(echo "$POLICY_OUTPUT" | grep -o 'arn:aws:iam::[0-9]*:policy/SSMOnboardingPolicy')
if [[ -z "$POLICY_ARN" ]]; then
    echo "ERROR: Failed to extract policy ARN" | tee -a "$LOG_FILE"
    exit 1
fi

# Track the created policy
track_resource "IAM_POLICY" "$POLICY_ARN"

echo "Created policy: $POLICY_ARN" | tee -a "$LOG_FILE"

# Step 2: Create and configure IAM role for Systems Manager
echo ""
echo "Step 2: Creating IAM role for Systems Manager..."

# Get current user name
USER_OUTPUT=$(log_cmd "aws sts get-caller-identity --output json")
USER_STATUS=$?
check_error "$USER_OUTPUT" $USER_STATUS "Failed to get caller identity"

# Extract account ID
ACCOUNT_ID=$(echo "$USER_OUTPUT" | grep -o '"Account": "[0-9]*"' | cut -d'"' -f4)
if [[ -z "$ACCOUNT_ID" ]]; then
    echo "ERROR: Failed to extract account ID" | tee -a "$LOG_FILE"
    exit 1
fi

# Generate a unique role name
ROLE_NAME="SSMTutorialRole-$(openssl rand -hex 4)"

# Create trust policy for the role - FIXED: Added cloudformation.amazonaws.com
cat > trust-policy.json << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ssm.amazonaws.com",
                    "ssm-quicksetup.amazonaws.com",
                    "cloudformation.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::ACCOUNT_ID:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# Replace ACCOUNT_ID placeholder in trust policy
sed -i "s/ACCOUNT_ID/$ACCOUNT_ID/g" trust-policy.json

# Create the IAM role
ROLE_OUTPUT=$(log_cmd "aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json --description 'Role for Systems Manager tutorial' --output json")
ROLE_STATUS=$?
check_error "$ROLE_OUTPUT" $ROLE_STATUS "Failed to create IAM role"

# Extract the role ARN
ROLE_ARN=$(echo "$ROLE_OUTPUT" | grep -o 'arn:aws:iam::[0-9]*:role/[^"]*')
if [[ -z "$ROLE_ARN" ]]; then
    echo "ERROR: Failed to extract role ARN" | tee -a "$LOG_FILE"
    cleanup_on_error
    exit 1
fi

# Track the created role
track_resource "IAM_ROLE" "$ROLE_NAME"

echo "Created IAM role: $ROLE_NAME" | tee -a "$LOG_FILE"
echo "Role ARN: $ROLE_ARN" | tee -a "$LOG_FILE"

# Set identity variables for cleanup
IDENTITY_TYPE="role"
IDENTITY_NAME="$ROLE_NAME"

# Attach the policy to the role
ATTACH_OUTPUT=$(log_cmd "aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN")
ATTACH_STATUS=$?
check_error "$ATTACH_OUTPUT" $ATTACH_STATUS "Failed to attach policy to role $ROLE_NAME"

echo "Policy attached to role: $ROLE_NAME" | tee -a "$LOG_FILE"

# Step 3: Create Systems Manager configuration using Host Management
echo ""
echo "Step 3: Creating Systems Manager configuration..."

# Generate a random identifier for the configuration name
CONFIG_NAME="SSMSetup-$(openssl rand -hex 4)"

# Create configuration file for Systems Manager setup using Host Management
# Added both required parameters for single account deployment based on CloudFormation documentation
cat > ssm-config.json << EOF
[
  {
    "Type": "AWSQuickSetupType-SSMHostMgmt",
    "LocalDeploymentAdministrationRoleArn": "$ROLE_ARN",
    "LocalDeploymentExecutionRoleName": "$ROLE_NAME",
    "Parameters": {
      "TargetAccounts": "$ACCOUNT_ID",
      "TargetRegions": "$CURRENT_REGION"
    }
  }
]
EOF

echo "Configuration file created:" | tee -a "$LOG_FILE"
cat ssm-config.json | tee -a "$LOG_FILE"

# Create the configuration manager
CONFIG_OUTPUT=$(log_cmd "aws ssm-quicksetup create-configuration-manager --name \"$CONFIG_NAME\" --configuration-definitions file://ssm-config.json --region $CURRENT_REGION")
CONFIG_STATUS=$?
check_error "$CONFIG_OUTPUT" $CONFIG_STATUS "Failed to create Systems Manager configuration"

# Extract the manager ARN
MANAGER_ARN=$(echo "$CONFIG_OUTPUT" | grep -o 'arn:aws:ssm-quicksetup:[^"]*')
if [[ -z "$MANAGER_ARN" ]]; then
    echo "ERROR: Failed to extract manager ARN" | tee -a "$LOG_FILE"
    exit 1
fi

# Track the created configuration manager
track_resource "SSM_CONFIG_MANAGER" "$MANAGER_ARN"

echo "Created Systems Manager configuration: $MANAGER_ARN" | tee -a "$LOG_FILE"

# Step 4: Verify the setup
echo ""
echo "Step 4: Verifying the setup..."

# Wait for the configuration to be fully deployed
echo "Waiting for the configuration to be deployed (this may take a few minutes)..."
sleep 30

# Check the configuration manager status
VERIFY_OUTPUT=$(log_cmd "aws ssm-quicksetup get-configuration-manager --manager-arn $MANAGER_ARN --region $CURRENT_REGION")
VERIFY_STATUS=$?
check_error "$VERIFY_OUTPUT" $VERIFY_STATUS "Failed to verify configuration manager"

echo "Systems Manager setup completed successfully!" | tee -a "$LOG_FILE"

# List the created resources
echo ""
echo "==========================================="
echo "CREATED RESOURCES"
echo "==========================================="
for resource in "${CREATED_RESOURCES[@]}"; do
    echo "$resource"
done

# Prompt for cleanup
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Cleaning up resources..." | tee -a "$LOG_FILE"
    cleanup_resources
    echo "Cleanup completed." | tee -a "$LOG_FILE"
else
    echo "Resources will not be cleaned up. You can manually clean them up later." | tee -a "$LOG_FILE"
fi

echo ""
echo "Script execution completed. See $LOG_FILE for details."

# Clean up temporary files
rm -f ssm-onboarding-policy.json trust-policy.json ssm-config.json 2>/dev/null || true
