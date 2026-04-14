#!/bin/bash
# Tutorial: Request and manage SSL/TLS certificates with AWS Certificate Manager
# Source: https://docs.aws.amazon.com/acm/latest/userguide/gs.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/acm-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
DOMAIN="tutorial-${RANDOM_ID}.example.com"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$CERT_ARN" ] && aws acm delete-certificate --certificate-arn "$CERT_ARN" 2>/dev/null && \
        echo "  Deleted certificate $CERT_ARN"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Request a certificate
echo "Step 1: Requesting a certificate for $DOMAIN"
CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN" \
    --validation-method DNS \
    --query 'CertificateArn' --output text)
echo "  Certificate ARN: $CERT_ARN"

# Step 2: Describe the certificate
echo "Step 2: Describing the certificate"
sleep 2
aws acm describe-certificate --certificate-arn "$CERT_ARN" \
    --query 'Certificate.{Domain:DomainName,Status:Status,Type:Type,Validation:DomainValidationOptions[0].ValidationMethod}' --output table

# Step 3: Show DNS validation record
echo "Step 3: DNS validation record (you would add this to your DNS)"
sleep 3
aws acm describe-certificate --certificate-arn "$CERT_ARN" \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord.{Name:Name,Type:Type,Value:Value}' --output table

# Step 4: List certificates
echo "Step 4: Listing certificates"
aws acm list-certificates \
    --query 'CertificateSummaryList[?contains(DomainName, `tutorial-`)].{Domain:DomainName,Status:Status,ARN:CertificateArn}' --output table

# Step 5: Add tags
echo "Step 5: Adding tags to the certificate"
aws acm add-tags-to-certificate --certificate-arn "$CERT_ARN" \
    --tags Key=Environment,Value=tutorial Key=Project,Value=acm-gs
aws acm list-tags-for-certificate --certificate-arn "$CERT_ARN" \
    --query 'Tags[].{Key:Key,Value:Value}' --output table

echo ""
echo "Tutorial complete."
echo "Note: The certificate will remain in PENDING_VALIDATION status because"
echo "example.com is not a real domain. In production, you would add the DNS"
echo "record from Step 3 to your domain's DNS configuration."
echo ""
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws acm delete-certificate --certificate-arn $CERT_ARN"
fi
