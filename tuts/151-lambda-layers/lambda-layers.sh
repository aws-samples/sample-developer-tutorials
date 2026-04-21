#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/lambda-layers.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); LAYER_NAME="tut-layer-${RANDOM_ID}"; FUNC_NAME="tut-layer-func-${RANDOM_ID}"; ROLE_NAME="lambda-layer-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws lambda delete-function --function-name "$FUNC_NAME" 2>/dev/null && echo "  Deleted function"; aws lambda delete-layer-version --layer-name "$LAYER_NAME" --version-number 1 2>/dev/null && echo "  Deleted layer"; aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating a layer"
mkdir -p "$WORK_DIR/python"
cat > "$WORK_DIR/python/helpers.py" << 'EOF'
def greet(name): return f"Hello, {name}! (from layer)"
def add(a, b): return a + b
EOF
(cd "$WORK_DIR" && zip -r layer.zip python > /dev/null)
LAYER_ARN=$(aws lambda publish-layer-version --layer-name "$LAYER_NAME" --zip-file "fileb://$WORK_DIR/layer.zip" --compatible-runtimes python3.12 --query 'LayerVersionArn' --output text)
echo "  Layer ARN: $LAYER_ARN"
echo "Step 2: Creating function that uses the layer"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
sleep 10
cat > "$WORK_DIR/index.py" << 'EOF'
from helpers import greet, add
def handler(event, context):
    return {"greeting": greet(event.get("name", "World")), "sum": add(3, 4)}
EOF
(cd "$WORK_DIR" && zip func.zip index.py > /dev/null)
aws lambda create-function --function-name "$FUNC_NAME" --zip-file "fileb://$WORK_DIR/func.zip" --handler index.handler --runtime python3.12 --role "$ROLE_ARN" --layers "$LAYER_ARN" --architectures x86_64 > /dev/null
aws lambda wait function-active-v2 --function-name "$FUNC_NAME"
echo "Step 3: Invoking function"
aws lambda invoke --function-name "$FUNC_NAME" --payload '{"name":"Tutorial"}' --cli-binary-format raw-in-base64-out "$WORK_DIR/response.json" > /dev/null
cat "$WORK_DIR/response.json" | python3 -m json.tool
echo "Step 4: Listing layers"
aws lambda list-layers --query 'Layers[?starts_with(LayerName, `tut-`)].{Name:LayerName,Version:LatestMatchingVersion.Version}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
