#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); ACCOUNT=$(aws sts get-caller-identity --query Account --output text); B="cors-tut-${RANDOM_ID}-${ACCOUNT}"
cleanup() { aws s3 rb "s3://$B" 2>/dev/null; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating bucket"; aws s3api create-bucket --bucket "$B" > /dev/null
echo "Step 2: Setting CORS"; aws s3api put-bucket-cors --bucket "$B" --cors-configuration '{"CORSRules":[{"AllowedOrigins":["https://example.com"],"AllowedMethods":["GET","PUT"],"AllowedHeaders":["*"],"MaxAgeSeconds":3600}]}'
echo "Step 3: Getting CORS"; aws s3api get-bucket-cors --bucket "$B" --query 'CORSRules[0].{Origins:AllowedOrigins,Methods:AllowedMethods}' --output table
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
