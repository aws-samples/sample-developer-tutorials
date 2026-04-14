# Create a chatbot with Amazon Lex

## Overview

In this tutorial, you use the AWS CLI to create an Amazon Lex V2 chatbot. You create an IAM role, configure an English locale, add an intent with sample utterances, and build the bot locale. You then delete the bot and role during cleanup.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- An IAM principal with permissions for `lexv2-models:CreateBot`, `lexv2-models:CreateBotLocale`, `lexv2-models:CreateIntent`, `lexv2-models:BuildBotLocale`, `lexv2-models:DescribeBot`, `lexv2-models:DescribeBotLocale`, `lexv2-models:DeleteBot`, `iam:CreateRole`, `iam:PutRolePolicy`, `iam:DeleteRolePolicy`, and `iam:DeleteRole`.

## Step 1: Create an IAM role

Create a role that allows Lex to call Amazon Polly for speech synthesis.

```bash
RANDOM_ID=$(openssl rand -hex 4)
ROLE_NAME="lex-tut-role-${RANDOM_ID}"

ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lexv2.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)

aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name lex-policy \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["polly:SynthesizeSpeech"],"Resource":"*"}]}'
echo "Role ARN: $ROLE_ARN"
sleep 10
```

The sleep gives IAM time to propagate the role. Lex requires a service role even for text-only bots.

## Step 2: Create a bot

Create the bot with a 5-minute idle session timeout.

```bash
BOT_NAME="tut-bot-${RANDOM_ID}"

BOT_ID=$(aws lexv2-models create-bot --bot-name "$BOT_NAME" \
    --role-arn "$ROLE_ARN" \
    --data-privacy '{"childDirected":false}' \
    --idle-session-ttl-in-seconds 300 \
    --query 'botId' --output text)
echo "Bot ID: $BOT_ID"
```

`childDirected` is required by COPPA compliance. Set to `true` if the bot is directed at children under 13.

## Step 3: Create an English locale

Wait for the bot to become available, then add an English (US) locale.

```bash
# Wait for bot
for i in $(seq 1 15); do
    BOT_STATUS=$(aws lexv2-models describe-bot --bot-id "$BOT_ID" \
        --query 'botStatus' --output text)
    [ "$BOT_STATUS" = "Available" ] && break
    sleep 3
done

aws lexv2-models create-bot-locale --bot-id "$BOT_ID" --bot-version DRAFT \
    --locale-id en_US --nlu-intent-confidence-threshold 0.40
```

The NLU confidence threshold (0.40) controls how confident Lex must be before matching an utterance to an intent. Lower values match more broadly.

## Step 4: Create an OrderPizza intent

Wait for the locale to be ready, then create an intent with sample utterances.

```bash
# Wait for locale
for i in $(seq 1 15); do
    LOC_STATUS=$(aws lexv2-models describe-bot-locale --bot-id "$BOT_ID" \
        --bot-version DRAFT --locale-id en_US \
        --query 'botLocaleStatus' --output text 2>/dev/null || echo "Creating")
    [ "$LOC_STATUS" = "NotBuilt" ] || [ "$LOC_STATUS" = "Built" ] && break
    sleep 3
done

INTENT_ID=$(aws lexv2-models create-intent --bot-id "$BOT_ID" --bot-version DRAFT \
    --locale-id en_US --intent-name OrderPizza \
    --sample-utterances '[{"utterance":"I want to order a pizza"},{"utterance":"Order a pizza"},{"utterance":"I would like a pizza please"}]' \
    --query 'intentId' --output text)
echo "Intent ID: $INTENT_ID"
```

Sample utterances train the NLU model to recognize when a user wants to trigger this intent. Add more utterances for better accuracy.

## Step 5: Build the bot locale

Build the locale to compile the NLU model.

```bash
aws lexv2-models build-bot-locale --bot-id "$BOT_ID" \
    --bot-version DRAFT --locale-id en_US

for i in $(seq 1 20); do
    STATUS=$(aws lexv2-models describe-bot-locale --bot-id "$BOT_ID" \
        --bot-version DRAFT --locale-id en_US \
        --query 'botLocaleStatus' --output text)
    echo "Status: $STATUS"
    [ "$STATUS" = "Built" ] || [ "$STATUS" = "ReadyExpressTesting" ] && break
    sleep 5
done
```

Building compiles the intents and utterances into a model. The bot must be built before it can handle conversations.

## Step 6: Describe the bot

View the bot configuration.

```bash
aws lexv2-models describe-bot --bot-id "$BOT_ID" \
    --query '{Name:botName,Id:botId,Status:botStatus}' --output table
```

## Cleanup

Delete the bot and its IAM role.

```bash
aws lexv2-models delete-bot --bot-id "$BOT_ID" --skip-resource-in-use-check
aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name lex-policy
aws iam delete-role --role-name "$ROLE_NAME"
```

`--skip-resource-in-use-check` deletes the bot even if it has aliases or versions. Without this flag, you must delete aliases and versions first.

The script automates all steps including cleanup:

```bash
bash amazon-lex-gs.sh
```

## Related resources

- [Getting started with Amazon Lex V2](https://docs.aws.amazon.com/lexv2/latest/dg/getting-started.html)
- [Creating a bot](https://docs.aws.amazon.com/lexv2/latest/dg/build-create.html)
- [Adding intents](https://docs.aws.amazon.com/lexv2/latest/dg/build-intents.html)
- [Amazon Lex pricing](https://aws.amazon.com/lex/pricing/)
