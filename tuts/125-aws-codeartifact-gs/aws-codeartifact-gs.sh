#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/codeartifact-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
DOMAIN="tut-domain-${RANDOM_ID}"
REPO="tut-repo-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws codeartifact delete-repository --domain "$DOMAIN" --repository "$REPO" > /dev/null 2>&1 && echo "  Deleted repo"; aws codeartifact delete-domain --domain "$DOMAIN" > /dev/null 2>&1 && echo "  Deleted domain"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating domain: $DOMAIN"
aws codeartifact create-domain --domain "$DOMAIN" --query 'domain.{Name:name,Status:status}' --output table
echo "Step 2: Creating repository: $REPO"
aws codeartifact create-repository --domain "$DOMAIN" --repository "$REPO" --query 'repository.{Name:name,DomainName:domainName}' --output table
echo "Step 3: Getting authorization token"
TOKEN=$(aws codeartifact get-authorization-token --domain "$DOMAIN" --query 'authorizationToken' --output text)
echo "  Token: ${TOKEN:0:20}..."
echo "Step 4: Getting repository endpoint"
aws codeartifact get-repository-endpoint --domain "$DOMAIN" --repository "$REPO" --format npm --query 'repositoryEndpoint' --output text
echo "Step 5: Listing repositories"
aws codeartifact list-repositories --query 'repositories[?starts_with(name, `tut-`)].{Name:name,Domain:domainName}' --output table
echo ""
echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "
read -r CHOICE
[[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup || echo "Manual: aws codeartifact delete-repository --domain $DOMAIN --repository $REPO && aws codeartifact delete-domain --domain $DOMAIN"
