#!/bin/bash
# Tutorial: Create a chatbot with Amazon Lex V2
# Source: https://docs.aws.amazon.com/lexv2/latest/dg/getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/lex-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
BOT_NAME="tut-bot-${RANDOM_ID}"
ROLE_NAME="lex-tut-role-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$BOT_ID" ] && aws lexv2-models delete-bot --bot-id "$BOT_ID" --skip-resource-in-use-check > /dev/null 2>&1 && \
        echo "  Deleted bot $BOT_NAME"
    aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name lex-policy 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create IAM role
echo "Step 1: Creating IAM role: $ROLE_NAME"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lexv2.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name lex-policy \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["polly:SynthesizeSpeech"],"Resource":"*"}]}'
echo "  Role ARN: $ROLE_ARN"
sleep 10

# Step 2: Create a bot
echo "Step 2: Creating bot: $BOT_NAME"
BOT_ID=$(aws lexv2-models create-bot --bot-name "$BOT_NAME" \
    --role-arn "$ROLE_ARN" \
    --data-privacy '{"childDirected":false}' \
    --idle-session-ttl-in-seconds 300 \
    --query 'botId' --output text)
echo "  Bot ID: $BOT_ID"

# Step 3: Create a locale
echo "Step 3: Creating English locale"
echo "  Waiting for bot to be available..."
for i in $(seq 1 15); do
    BOT_STATUS=$(aws lexv2-models describe-bot --bot-id "$BOT_ID" --query 'botStatus' --output text)
    [ "$BOT_STATUS" = "Available" ] && break
    sleep 3
done
aws lexv2-models create-bot-locale --bot-id "$BOT_ID" --bot-version DRAFT \
    --locale-id en_US --nlu-intent-confidence-threshold 0.40 \
    --query 'localeId' --output text > /dev/null
echo "  Locale: en_US"

# Wait for locale to be ready
for i in $(seq 1 15); do
    LOC_STATUS=$(aws lexv2-models describe-bot-locale --bot-id "$BOT_ID" --bot-version DRAFT --locale-id en_US \
        --query 'botLocaleStatus' --output text 2>/dev/null || echo "Creating")
    [ "$LOC_STATUS" = "NotBuilt" ] || [ "$LOC_STATUS" = "Built" ] && break
    sleep 3
done

# Step 4: Create an intent
echo "Step 4: Creating OrderPizza intent"
INTENT_ID=$(aws lexv2-models create-intent --bot-id "$BOT_ID" --bot-version DRAFT \
    --locale-id en_US --intent-name OrderPizza \
    --sample-utterances '[{"utterance":"I want to order a pizza"},{"utterance":"Order a pizza"},{"utterance":"I would like a pizza please"}]' \
    --query 'intentId' --output text)
echo "  Intent ID: $INTENT_ID"

# Step 5: Build the bot locale
echo "Step 5: Building bot locale"
aws lexv2-models build-bot-locale --bot-id "$BOT_ID" --bot-version DRAFT --locale-id en_US > /dev/null
echo "  Build started..."
for i in $(seq 1 20); do
    STATUS=$(aws lexv2-models describe-bot-locale --bot-id "$BOT_ID" --bot-version DRAFT --locale-id en_US \
        --query 'botLocaleStatus' --output text)
    echo "  Status: $STATUS"
    [ "$STATUS" = "Built" ] || [ "$STATUS" = "ReadyExpressTesting" ] || [ "$STATUS" = "Failed" ] && break
    sleep 5
done

# Step 6: Describe the bot
echo "Step 6: Bot details"
aws lexv2-models describe-bot --bot-id "$BOT_ID" \
    --query '{Name:botName,Id:botId,Status:botStatus}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws lexv2-models delete-bot --bot-id $BOT_ID --skip-resource-in-use-check"
    echo "  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name lex-policy"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
fi
