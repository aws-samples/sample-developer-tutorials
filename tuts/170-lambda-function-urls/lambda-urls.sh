#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/url.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); FUNC="tut-url-${RANDOM_ID}"; ROLE="lambda-url-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws lambda delete-function-url-config --function-name "$FUNC" 2>/dev/null; aws lambda delete-function --function-name "$FUNC" 2>/dev/null && echo "  Deleted function"; aws iam detach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam delete-role --role-name "$ROLE" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
ROLE_ARN=$(aws iam create-role --role-name "$ROLE" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole; sleep 10
echo "Step 1: Creating function"
cat > "$WORK_DIR/index.mjs" << 'EOF'
export const handler = async (event) => ({statusCode: 200, body: JSON.stringify({message: "Hello from Lambda URL!", method: event.requestContext?.http?.method, path: event.rawPath})});
EOF
(cd "$WORK_DIR" && zip func.zip index.mjs > /dev/null)
aws lambda create-function --function-name "$FUNC" --zip-file "fileb://$WORK_DIR/func.zip" --handler index.handler --runtime nodejs22.x --role "$ROLE_ARN" --architectures x86_64 > /dev/null
aws lambda wait function-active-v2 --function-name "$FUNC"
echo "Step 2: Creating function URL"
FUNC_URL=$(aws lambda create-function-url-config --function-name "$FUNC" --auth-type NONE --query 'FunctionUrl' --output text)
aws lambda add-permission --function-name "$FUNC" --statement-id url-invoke --action lambda:InvokeFunctionUrl --principal "*" --function-url-auth-type NONE > /dev/null
echo "  URL: $FUNC_URL"
echo "Step 3: Testing the URL"
sleep 2
curl -s --max-time 10 "$FUNC_URL" | python3 -m json.tool
echo "Step 4: Getting URL config"
aws lambda get-function-url-config --function-name "$FUNC" --query '{URL:FunctionUrl,Auth:AuthType,CORS:Cors}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
