#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/alias.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); FUNC="tut-alias-${RANDOM_ID}"; ROLE="lambda-alias-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws lambda delete-alias --function-name "$FUNC" --name live 2>/dev/null; aws lambda delete-function --function-name "$FUNC" 2>/dev/null && echo "  Deleted function"; aws iam detach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam delete-role --role-name "$ROLE" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
ROLE_ARN=$(aws iam create-role --role-name "$ROLE" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole; sleep 10
echo "Step 1: Creating function (v1)"
cat > "$WORK_DIR/v1.py" << 'EOF'
def handler(event, context): return {"version": "1.0", "message": "Hello from v1"}
EOF
(cd "$WORK_DIR" && zip v1.zip v1.py > /dev/null)
aws lambda create-function --function-name "$FUNC" --zip-file "fileb://$WORK_DIR/v1.zip" --handler v1.handler --runtime python3.12 --role "$ROLE_ARN" --architectures x86_64 > /dev/null
aws lambda wait function-active-v2 --function-name "$FUNC"
V1=$(aws lambda publish-version --function-name "$FUNC" --query 'Version' --output text)
echo "  Published version $V1"
echo "Step 2: Creating alias pointing to v1"
aws lambda create-alias --function-name "$FUNC" --name live --function-version "$V1" --query '{Alias:Name,Version:FunctionVersion}' --output table
echo "Step 3: Deploying v2 with canary"
cat > "$WORK_DIR/v2.py" << 'EOF'
def handler(event, context): return {"version": "2.0", "message": "Hello from v2"}
EOF
(cd "$WORK_DIR" && zip v2.zip v2.py > /dev/null)
aws lambda update-function-code --function-name "$FUNC" --zip-file "fileb://$WORK_DIR/v2.zip" > /dev/null
aws lambda wait function-updated-v2 --function-name "$FUNC"
V2=$(aws lambda publish-version --function-name "$FUNC" --query 'Version' --output text)
aws lambda update-alias --function-name "$FUNC" --name live --function-version "$V2" --routing-config "{\"AdditionalVersionWeights\":{\"$V1\":0.1}}" > /dev/null
echo "  Alias 'live' → v2 (90%) + v1 (10%)"
echo "Step 4: Invoking via alias (multiple times)"
for i in $(seq 1 5); do aws lambda invoke --function-name "$FUNC" --qualifier live --cli-binary-format raw-in-base64-out "$WORK_DIR/out.json" > /dev/null; echo "  $(cat $WORK_DIR/out.json)"; done
echo "Step 5: Shifting all traffic to v2"
aws lambda update-alias --function-name "$FUNC" --name live --function-version "$V2" --routing-config '{}' > /dev/null
echo "  Alias 'live' → v2 (100%)"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
