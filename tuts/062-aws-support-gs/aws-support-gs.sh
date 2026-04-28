#!/bin/bash

# AWS Support CLI Tutorial Script
# This script demonstrates how to use AWS Support API through AWS CLI

set -o pipefail
set -o errtrace
set -o nounset

# Security: Use absolute paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/aws-support-tutorial.log"
readonly TEMP_DIR=$(mktemp -d)
readonly TEMP_OUTPUT_PREFIX="${TEMP_DIR}/cmd_output_"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=2

# Security: Restrict umask
umask 0077

# Trap to ensure cleanup on exit
trap 'cleanup_on_exit' EXIT INT TERM

cleanup_on_exit() {
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Security: Validate file permissions
setup_log_file() {
    if [[ -e "$LOG_FILE" ]]; then
        local perms
        if perms=$(stat -c %a "$LOG_FILE" 2>/dev/null); then
            :
        elif perms=$(stat -f %A "$LOG_FILE" 2>/dev/null); then
            :
        fi
        if [[ "${perms:-}" != "600" ]]; then
            chmod 600 "$LOG_FILE"
        fi
    fi
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
}

setup_log_file
{
    echo "Starting AWS Support Tutorial at $(date)"
} >> "$LOG_FILE"

# Function to retry commands with exponential backoff
retry_cmd() {
    local cmd="$1"
    local attempt=1
    local status=0
    
    while [[ $attempt -le $MAX_RETRIES ]]; do
        if eval "$cmd"; then
            return 0
        fi
        status=$?
        
        if [[ $attempt -lt $MAX_RETRIES ]]; then
            local wait_time=$((RETRY_DELAY * (2 ** (attempt - 1))))
            {
                echo "Command failed (attempt $attempt/$MAX_RETRIES). Retrying in ${wait_time}s..."
            } >> "$LOG_FILE"
            sleep "$wait_time"
        fi
        ((attempt++))
    done
    
    return $status
}

# Function to log commands and their outputs - optimized for cost
log_cmd() {
    local cmd="$1"
    local output_file="${TEMP_OUTPUT_PREFIX}$$.txt"
    
    {
        echo "$(date): Running command: ${cmd:0:100}..."
    } >> "$LOG_FILE"
    
    touch "$output_file"
    chmod 600 "$output_file"
    
    local status=0
    if ! eval "$cmd" > "$output_file" 2>&1; then
        status=$?
    fi
    
    if [[ -f "$output_file" ]]; then
        cat "$output_file" | tee -a "$LOG_FILE"
        rm -f "$output_file"
    fi
    
    return $status
}

# Function to check for errors in command output
check_error() {
    local cmd_output="$1"
    local cmd_status="$2"
    local error_msg="$3"
    local is_fatal="${4:-true}"
    
    if [[ $cmd_status -ne 0 ]] || echo "$cmd_output" | grep -iq 'error'; then
        {
            echo "ERROR: $error_msg"
            echo "Command output (first 500 chars): ${cmd_output:0:500}"
        } | tee -a "$LOG_FILE"
        
        if echo "$cmd_output" | grep -q "SubscriptionRequiredException"; then
            {
                echo ""
                echo "===================================================="
                echo "IMPORTANT: This account does not have the required AWS Support plan."
                echo "You need a Business, Enterprise On-Ramp, or Enterprise Support plan"
                echo "to use the AWS Support API."
                echo ""
                echo "This script will now demonstrate the commands that would be run"
                echo "if you had the appropriate support plan, but will not execute them."
                echo "===================================================="
            } | tee -a "$LOG_FILE"
            
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
    {
        echo "No persistent resources were created that need cleanup."
    } | tee -a "$LOG_FILE"
}

# Function to run a command in demo mode
demo_cmd() {
    local cmd="$1"
    local description="$2"
    
    {
        echo ""
        echo "DEMO: $description"
        echo "Command that would be executed:"
        echo "$cmd"
        echo ""
    } | tee -a "$LOG_FILE"
}

# Security: Validate email format
validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Security: Sanitize input for use in commands
sanitize_input() {
    local input="$1"
    # Remove potentially dangerous characters, keep only safe ones
    printf '%s\n' "$input" | sed 's/[^a-zA-Z0-9._@-]//g'
}

# Security: Validate AWS CLI is available
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        {
            echo "ERROR: AWS CLI is not installed or not in PATH"
        } | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Security: Check AWS credentials are configured
check_aws_credentials() {
    if ! retry_cmd "aws sts get-caller-identity &> /dev/null"; then
        {
            echo "ERROR: AWS credentials are not properly configured or API is unavailable"
        } | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Function to validate command output is JSON
validate_json_output() {
    local output="$1"
    if ! printf '%s\n' "$output" | grep -q '^{' && ! printf '%s\n' "$output" | grep -q '^\['; then
        return 1
    fi
    return 0
}

# Array to track created resources
declare -a CREATED_RESOURCES

# Initialize demo mode flag
DEMO_MODE=false

check_aws_cli
check_aws_credentials

{
    echo "==================================================="
    echo "AWS Support CLI Tutorial"
    echo "==================================================="
    echo "This script demonstrates how to use AWS Support API"
    echo "Note: You must have a Business, Enterprise On-Ramp,"
    echo "or Enterprise Support plan to use the AWS Support API."
    echo "==================================================="
    echo ""
} | tee -a "$LOG_FILE"

# Step 1: Check available services - cache results to minimize API calls
{
    echo "Step 1: Checking available AWS Support services..."
} | tee -a "$LOG_FILE"

SERVICES_OUTPUT=$(log_cmd "aws support describe-services --language en --max-results 1 2>&1")
SERVICES_STATUS=$?
check_error "$SERVICES_OUTPUT" $SERVICES_STATUS "Failed to retrieve AWS Support services"

# If we're in demo mode, set default values
if [[ "$DEMO_MODE" == "true" ]]; then
    SERVICE_CODE="general-info"
    {
        echo "Using demo service code: $SERVICE_CODE"
    } | tee -a "$LOG_FILE"
else
    if validate_json_output "$SERVICES_OUTPUT"; then
        SERVICE_CODE=$(printf '%s\n' "$SERVICES_OUTPUT" | grep -o '"code": "[^"]*"' | head -1 | cut -d'"' -f4)
    else
        SERVICE_CODE=""
    fi
    
    if [[ -z "$SERVICE_CODE" ]]; then
        SERVICE_CODE="general-info"
        {
            echo "Using default service code: $SERVICE_CODE"
        } | tee -a "$LOG_FILE"
    else
        {
            echo "Found service code: $SERVICE_CODE"
        } | tee -a "$LOG_FILE"
    fi
fi

# Step 2: Check available severity levels - cache results to minimize API calls
{
    echo "Step 2: Checking available severity levels..."
} | tee -a "$LOG_FILE"

if [[ "$DEMO_MODE" == "true" ]]; then
    demo_cmd "aws support describe-severity-levels --language en" "Check available severity levels"
    SEVERITY_CODE="low"
    {
        echo "Using demo severity code: $SEVERITY_CODE"
    } | tee -a "$LOG_FILE"
else
    SEVERITY_OUTPUT=$(log_cmd "aws support describe-severity-levels --language en 2>&1")
    SEVERITY_STATUS=$?
    check_error "$SEVERITY_OUTPUT" $SEVERITY_STATUS "Failed to retrieve severity levels"

    if validate_json_output "$SEVERITY_OUTPUT"; then
        SEVERITY_CODE=$(printf '%s\n' "$SEVERITY_OUTPUT" | grep -o '"code": "[^"]*"' | head -1 | cut -d'"' -f4)
    else
        SEVERITY_CODE=""
    fi
    
    if [[ -z "$SEVERITY_CODE" ]]; then
        SEVERITY_CODE="low"
        {
            echo "Using default severity code: $SEVERITY_CODE"
        } | tee -a "$LOG_FILE"
    else
        {
            echo "Found severity code: $SEVERITY_CODE"
        } | tee -a "$LOG_FILE"
    fi
fi

# Step 3: Create a test support case
{
    echo ""
    echo "==================================================="
    echo "SUPPORT CASE CREATION"
    echo "==================================================="
} | tee -a "$LOG_FILE"

if [[ "$DEMO_MODE" == "true" ]]; then
    {
        echo "DEMO MODE: The following steps would create and manage a support case"
        echo "if you had a Business, Enterprise On-Ramp, or Enterprise Support plan."
        echo ""
        echo "Enter your email address for the demo (leave blank to use example@example.com): "
    } | tee -a "$LOG_FILE"
    read -r USER_EMAIL || USER_EMAIL=""
    
    if [[ -z "$USER_EMAIL" ]]; then
        USER_EMAIL="example@example.com"
    else
        if ! validate_email "$USER_EMAIL"; then
            {
                echo "Invalid email format. Using example@example.com"
            } | tee -a "$LOG_FILE"
            USER_EMAIL="example@example.com"
        else
            USER_EMAIL=$(sanitize_input "$USER_EMAIL")
        fi
    fi
    
    demo_cmd "aws support create-case \
        --subject \"AWS CLI Tutorial Test Case\" \
        --service-code \"$SERVICE_CODE\" \
        --category-code \"using-aws\" \
        --communication-body \"This is a test case created as part of an AWS CLI tutorial.\" \
        --severity-code \"$SEVERITY_CODE\" \
        --language \"en\" \
        --cc-email-addresses \"$USER_EMAIL\" \
        --tags Key=project,Value=doc-smith Key=tutorial,Value=aws-support-gs" "Create a support case"
    
    CASE_ID="case-12345678910-2013-c4c1d2bf33c5cf47"
    {
        echo "Demo case ID: $CASE_ID"
    } | tee -a "$LOG_FILE"
    
    demo_cmd "aws support describe-cases \
        --case-id-list \"$CASE_ID\" \
        --include-resolved-cases false \
        --language \"en\"" "List support cases"
    
    demo_cmd "aws support add-communication-to-case \
        --case-id \"$CASE_ID\" \
        --communication-body \"This is an additional communication for the test case.\" \
        --cc-email-addresses \"$USER_EMAIL\"" "Add communication to case"
    
    demo_cmd "aws support describe-communications \
        --case-id \"$CASE_ID\" \
        --language \"en\" \
        --max-results 10" "View case communications"
    
    demo_cmd "aws support resolve-case \
        --case-id \"$CASE_ID\"" "Resolve the support case"
    
else
    {
        echo "This will create a test support case in your account."
        echo "Do you want to continue? (y/n): "
    } | tee -a "$LOG_FILE"
    read -r CREATE_CASE_CHOICE || CREATE_CASE_CHOICE="n"

    if [[ "$CREATE_CASE_CHOICE" =~ ^[Yy]$ ]]; then
        {
            echo "Creating a test support case..."
            echo "Enter your email address for case notifications (leave blank to skip): "
        } | tee -a "$LOG_FILE"
        read -r USER_EMAIL || USER_EMAIL=""
        
        CC_EMAIL_PARAM=""
        if [[ -n "$USER_EMAIL" ]]; then
            if validate_email "$USER_EMAIL"; then
                USER_EMAIL=$(sanitize_input "$USER_EMAIL")
                CC_EMAIL_PARAM="--cc-email-addresses \"$USER_EMAIL\""
            else
                {
                    echo "Invalid email format. Skipping email parameter."
                } | tee -a "$LOG_FILE"
            fi
        fi
        
        CASE_OUTPUT=$(log_cmd "aws support create-case \
            --subject \"AWS CLI Tutorial Test Case\" \
            --service-code \"$SERVICE_CODE\" \
            --category-code \"using-aws\" \
            --communication-body \"This is a test case created as part of an AWS CLI tutorial.\" \
            --severity-code \"$SEVERITY_CODE\" \
            --language \"en\" \
            --tags Key=project,Value=doc-smith Key=tutorial,Value=aws-support-gs \
            $CC_EMAIL_PARAM 2>&1")
        
        CASE_STATUS=$?
        check_error "$CASE_OUTPUT" $CASE_STATUS "Failed to create support case"
        
        CASE_ID=""
        if validate_json_output "$CASE_OUTPUT"; then
            CASE_ID=$(printf '%s\n' "$CASE_OUTPUT" | grep -o '"caseId": "[^"]*"' | cut -d'"' -f4)
        fi
        
        if [[ -n "$CASE_ID" ]]; then
            {
                echo "Successfully created support case with ID: $CASE_ID"
            } | tee -a "$LOG_FILE"
            CREATED_RESOURCES+=("Support Case: $CASE_ID")
            
            {
                echo ""
                echo "Step 4: Listing the support case we just created..."
            } | tee -a "$LOG_FILE"
            
            CASES_OUTPUT=$(log_cmd "aws support describe-cases \
                --case-id-list \"$CASE_ID\" \
                --include-resolved-cases false \
                --language \"en\" \
                --max-results 1 2>&1")
            
            CASES_STATUS=$?
            check_error "$CASES_OUTPUT" $CASES_STATUS "Failed to retrieve case details"
            
            {
                echo ""
                echo "Step 5: Adding a communication to the support case..."
            } | tee -a "$LOG_FILE"
            
            COMM_OUTPUT=$(log_cmd "aws support add-communication-to-case \
                --case-id \"$CASE_ID\" \
                --communication-body \"This is an additional communication for the test case.\" \
                $CC_EMAIL_PARAM 2>&1")
            
            COMM_STATUS=$?
            check_error "$COMM_OUTPUT" $COMM_STATUS "Failed to add communication to case"
            
            {
                echo ""
                echo "Step 6: Viewing communications for the support case..."
            } | tee -a "$LOG_FILE"
            
            COMMS_OUTPUT=$(log_cmd "aws support describe-communications \
                --case-id \"$CASE_ID\" \
                --language \"en\" \
                --max-results 10 2>&1")
            
            COMMS_STATUS=$?
            check_error "$COMMS_OUTPUT" $COMMS_STATUS "Failed to retrieve case communications"
            
            {
                echo ""
                echo "==================================================="
                echo "CASE RESOLUTION"
                echo "==================================================="
                echo "Do you want to resolve the test support case? (y/n): "
            } | tee -a "$LOG_FILE"
            read -r RESOLVE_CASE_CHOICE || RESOLVE_CASE_CHOICE="n"
            
            if [[ "$RESOLVE_CASE_CHOICE" =~ ^[Yy]$ ]]; then
                {
                    echo "Resolving the support case..."
                } | tee -a "$LOG_FILE"
                
                RESOLVE_OUTPUT=$(log_cmd "aws support resolve-case \
                    --case-id \"$CASE_ID\" 2>&1")
                
                RESOLVE_STATUS=$?
                check_error "$RESOLVE_OUTPUT" $RESOLVE_STATUS "Failed to resolve case"
                {
                    echo "Successfully resolved support case: $CASE_ID"
                } | tee -a "$LOG_FILE"
            else
                {
                    echo "Skipping case resolution. The case will remain open."
                } | tee -a "$LOG_FILE"
            fi
        else
            {
                echo "Could not extract case ID from the response."
            } | tee -a "$LOG_FILE"
        fi
    else
        {
            echo "Skipping support case creation."
        } | tee -a "$LOG_FILE"
    fi
fi

{
    echo ""
    echo "==================================================="
    echo "TUTORIAL SUMMARY"
    echo "==================================================="
} | tee -a "$LOG_FILE"

if [[ "$DEMO_MODE" == "true" ]]; then
    {
        echo "This was a demonstration in DEMO MODE."
        echo "No actual AWS Support cases were created."
        echo "To use the AWS Support API, you need a Business, Enterprise On-Ramp,"
        echo "or Enterprise Support plan."
    } | tee -a "$LOG_FILE"
else
    {
        echo "Resources created during this tutorial:"
        if [[ ${#CREATED_RESOURCES[@]} -eq 0 ]]; then
            echo "No resources were created."
        else
            for resource in "${CREATED_RESOURCES[@]}"; do
                echo "- $resource"
            done
        fi
    } | tee -a "$LOG_FILE"
fi

{
    echo ""
    echo "Tutorial completed successfully!"
    echo "Log file: $LOG_FILE"
    echo "==================================================="
} | tee -a "$LOG_FILE"