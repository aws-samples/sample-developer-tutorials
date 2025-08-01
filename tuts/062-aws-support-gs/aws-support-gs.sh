#!/bin/bash

# AWS Support CLI Tutorial Script
# This script demonstrates how to use AWS Support API through AWS CLI

# Set up logging
LOG_FILE="aws-support-tutorial.log"
echo "Starting AWS Support Tutorial at $(date)" > "$LOG_FILE"

# Function to log commands and their outputs
log_cmd() {
    echo "$(date): Running command: $1" >> "$LOG_FILE"
    eval "$1" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    local is_fatal="${4:-true}"
    
    if [[ $cmd_status -ne 0 || "$cmd_output" =~ [Ee][Rr][Rr][Oo][Rr] ]]; then
        echo "ERROR: $error_msg" | tee -a "$LOG_FILE"
        echo "Command output: $cmd_output" | tee -a "$LOG_FILE"
        
        # Check for subscription error
        if [[ "$cmd_output" =~ "SubscriptionRequiredException" ]]; then
            echo "" | tee -a "$LOG_FILE"
            echo "====================================================" | tee -a "$LOG_FILE"
            echo "IMPORTANT: This account does not have the required AWS Support plan." | tee -a "$LOG_FILE"
            echo "You need a Business, Enterprise On-Ramp, or Enterprise Support plan" | tee -a "$LOG_FILE"
            echo "to use the AWS Support API." | tee -a "$LOG_FILE"
            echo "" | tee -a "$LOG_FILE"
            echo "This script will now demonstrate the commands that would be run" | tee -a "$LOG_FILE"
            echo "if you had the appropriate support plan, but will not execute them." | tee -a "$LOG_FILE"
            echo "====================================================" | tee -a "$LOG_FILE"
            
            # Switch to demo mode
            DEMO_MODE=true
            return 0
        fi
        
        if [[ "$is_fatal" == "true" ]]; then
            cleanup_resources
            exit 1
        fi
    fi
}

# Function to clean up resources
cleanup_resources() {
    echo "No persistent resources were created that need cleanup." | tee -a "$LOG_FILE"
}

# Function to run a command in demo mode
demo_cmd() {
    local cmd="$1"
    local description="$2"
    
    echo "" | tee -a "$LOG_FILE"
    echo "DEMO: $description" | tee -a "$LOG_FILE"
    echo "Command that would be executed:" | tee -a "$LOG_FILE"
    echo "$cmd" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Array to track created resources
declare -a CREATED_RESOURCES

# Initialize demo mode flag
DEMO_MODE=false

echo "==================================================="
echo "AWS Support CLI Tutorial"
echo "==================================================="
echo "This script demonstrates how to use AWS Support API"
echo "Note: You must have a Business, Enterprise On-Ramp,"
echo "or Enterprise Support plan to use the AWS Support API."
echo "==================================================="
echo ""

# Step 1: Check available services
echo "Step 1: Checking available AWS Support services..."
SERVICES_OUTPUT=$(log_cmd "aws support describe-services --language en")
check_error "$SERVICES_OUTPUT" $? "Failed to retrieve AWS Support services"

# If we're in demo mode, set default values
if [[ "$DEMO_MODE" == "true" ]]; then
    SERVICE_CODE="general-info"
    echo "Using demo service code: $SERVICE_CODE" | tee -a "$LOG_FILE"
else
    # Extract a service code for demonstration
    SERVICE_CODE=$(echo "$SERVICES_OUTPUT" | grep -o '"code": "[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -z "$SERVICE_CODE" ]]; then
        SERVICE_CODE="general-info"
        echo "Using default service code: $SERVICE_CODE" | tee -a "$LOG_FILE"
    else
        echo "Found service code: $SERVICE_CODE" | tee -a "$LOG_FILE"
    fi
fi

# Step 2: Check available severity levels
echo "Step 2: Checking available severity levels..."
if [[ "$DEMO_MODE" == "true" ]]; then
    demo_cmd "aws support describe-severity-levels --language en" "Check available severity levels"
    SEVERITY_CODE="low"
    echo "Using demo severity code: $SEVERITY_CODE" | tee -a "$LOG_FILE"
else
    SEVERITY_OUTPUT=$(log_cmd "aws support describe-severity-levels --language en")
    check_error "$SEVERITY_OUTPUT" $? "Failed to retrieve severity levels"

    # Extract a severity code for demonstration
    SEVERITY_CODE=$(echo "$SEVERITY_OUTPUT" | grep -o '"code": "[^"]*"' | head -1 | cut -d'"' -f4)
    if [[ -z "$SEVERITY_CODE" ]]; then
        SEVERITY_CODE="low"
        echo "Using default severity code: $SEVERITY_CODE" | tee -a "$LOG_FILE"
    else
        echo "Found severity code: $SEVERITY_CODE" | tee -a "$LOG_FILE"
    fi
fi

# Step 3: Create a test support case
echo ""
echo "==================================================="
echo "SUPPORT CASE CREATION"
echo "==================================================="
if [[ "$DEMO_MODE" == "true" ]]; then
    echo "DEMO MODE: The following steps would create and manage a support case"
    echo "if you had a Business, Enterprise On-Ramp, or Enterprise Support plan."
    echo ""
    
    # Get user email for demo
    echo "Enter your email address for the demo (leave blank to use example@example.com): "
    read -r USER_EMAIL
    
    if [[ -z "$USER_EMAIL" ]]; then
        USER_EMAIL="example@example.com"
    fi
    
    # Demo create case command
    demo_cmd "aws support create-case \
        --subject \"AWS CLI Tutorial Test Case\" \
        --service-code \"$SERVICE_CODE\" \
        --category-code \"using-aws\" \
        --communication-body \"This is a test case created as part of an AWS CLI tutorial.\" \
        --severity-code \"$SEVERITY_CODE\" \
        --language \"en\" \
        --cc-email-addresses \"$USER_EMAIL\"" "Create a support case"
    
    # Use a fake case ID for demo
    CASE_ID="case-12345678910-2013-c4c1d2bf33c5cf47"
    echo "Demo case ID: $CASE_ID" | tee -a "$LOG_FILE"
    
    # Demo list cases command
    demo_cmd "aws support describe-cases \
        --case-id-list \"$CASE_ID\" \
        --include-resolved-cases false \
        --language \"en\"" "List support cases"
    
    # Demo add communication command
    demo_cmd "aws support add-communication-to-case \
        --case-id \"$CASE_ID\" \
        --communication-body \"This is an additional communication for the test case.\" \
        --cc-email-addresses \"$USER_EMAIL\"" "Add communication to case"
    
    # Demo view communications command
    demo_cmd "aws support describe-communications \
        --case-id \"$CASE_ID\" \
        --language \"en\"" "View case communications"
    
    # Demo resolve case command
    demo_cmd "aws support resolve-case \
        --case-id \"$CASE_ID\"" "Resolve the support case"
    
else
    echo "This will create a test support case in your account."
    echo "Do you want to continue? (y/n): "
    read -r CREATE_CASE_CHOICE

    if [[ "$CREATE_CASE_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Creating a test support case..."
        
        # Get user email for CC
        echo "Enter your email address for case notifications (leave blank to skip): "
        read -r USER_EMAIL
        
        CC_EMAIL_PARAM=""
        if [[ -n "$USER_EMAIL" ]]; then
            CC_EMAIL_PARAM="--cc-email-addresses $USER_EMAIL"
        fi
        
        # Create the case
        CASE_OUTPUT=$(log_cmd "aws support create-case \
            --subject \"AWS CLI Tutorial Test Case\" \
            --service-code \"$SERVICE_CODE\" \
            --category-code \"using-aws\" \
            --communication-body \"This is a test case created as part of an AWS CLI tutorial.\" \
            --severity-code \"$SEVERITY_CODE\" \
            --language \"en\" \
            $CC_EMAIL_PARAM")
        
        check_error "$CASE_OUTPUT" $? "Failed to create support case"
        
        # Extract the case ID
        CASE_ID=$(echo "$CASE_OUTPUT" | grep -o '"caseId": "[^"]*"' | cut -d'"' -f4)
        
        if [[ -n "$CASE_ID" ]]; then
            echo "Successfully created support case with ID: $CASE_ID" | tee -a "$LOG_FILE"
            CREATED_RESOURCES+=("Support Case: $CASE_ID")
            
            # Step 4: List the case we just created
            echo ""
            echo "Step 4: Listing the support case we just created..."
            CASES_OUTPUT=$(log_cmd "aws support describe-cases \
                --case-id-list \"$CASE_ID\" \
                --include-resolved-cases false \
                --language \"en\"")
            
            check_error "$CASES_OUTPUT" $? "Failed to retrieve case details"
            
            # Step 5: Add a communication to the case
            echo ""
            echo "Step 5: Adding a communication to the support case..."
            COMM_OUTPUT=$(log_cmd "aws support add-communication-to-case \
                --case-id \"$CASE_ID\" \
                --communication-body \"This is an additional communication for the test case.\" \
                $CC_EMAIL_PARAM")
            
            check_error "$COMM_OUTPUT" $? "Failed to add communication to case"
            
            # Step 6: View communications for the case
            echo ""
            echo "Step 6: Viewing communications for the support case..."
            COMMS_OUTPUT=$(log_cmd "aws support describe-communications \
                --case-id \"$CASE_ID\" \
                --language \"en\"")
            
            check_error "$COMMS_OUTPUT" $? "Failed to retrieve case communications"
            
            # Step 7: Resolve the case
            echo ""
            echo "==================================================="
            echo "CASE RESOLUTION"
            echo "==================================================="
            echo "Do you want to resolve the test support case? (y/n): "
            read -r RESOLVE_CASE_CHOICE
            
            if [[ "$RESOLVE_CASE_CHOICE" =~ ^[Yy]$ ]]; then
                echo "Resolving the support case..."
                RESOLVE_OUTPUT=$(log_cmd "aws support resolve-case \
                    --case-id \"$CASE_ID\"")
                
                check_error "$RESOLVE_OUTPUT" $? "Failed to resolve case"
                echo "Successfully resolved support case: $CASE_ID" | tee -a "$LOG_FILE"
            else
                echo "Skipping case resolution. The case will remain open." | tee -a "$LOG_FILE"
            fi
        else
            echo "Could not extract case ID from the response." | tee -a "$LOG_FILE"
        fi
    else
        echo "Skipping support case creation." | tee -a "$LOG_FILE"
    fi
fi

# Display summary of created resources
echo ""
echo "==================================================="
echo "TUTORIAL SUMMARY"
echo "==================================================="
if [[ "$DEMO_MODE" == "true" ]]; then
    echo "This was a demonstration in DEMO MODE."
    echo "No actual AWS Support cases were created."
    echo "To use the AWS Support API, you need a Business, Enterprise On-Ramp,"
    echo "or Enterprise Support plan."
else
    echo "Resources created during this tutorial:"
    if [[ ${#CREATED_RESOURCES[@]} -eq 0 ]]; then
        echo "No resources were created."
    else
        for resource in "${CREATED_RESOURCES[@]}"; do
            echo "- $resource"
        done
    fi
fi

echo ""
echo "Tutorial completed successfully!"
echo "Log file: $LOG_FILE"
echo "==================================================="
