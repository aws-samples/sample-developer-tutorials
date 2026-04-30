#!/bin/bash
WORK_DIR=$(mktemp -d)
exec > >(tee -a "$WORK_DIR/bedrock-$(date +%Y%m%d-%H%M%S).log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}
[ -z "$REGION" ] && echo "ERROR: No region" && exit 1
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"
echo "Step 1: Listing foundation models"
aws bedrock list-foundation-models --query 'modelSummaries[:10].{Id:modelId,Name:modelName,Provider:providerName}' --output table
echo "Step 2: Listing inference profiles"
aws bedrock list-inference-profiles --query 'inferenceProfileSummaries[:5].{Name:inferenceProfileName,Id:inferenceProfileId}' --output table
echo "Step 3: Invoking a model"
RESPONSE=$(aws bedrock-runtime invoke-model --model-id us.anthropic.claude-haiku-4-5-20251001-v1:0 --content-type application/json --accept application/json --body "$(echo '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"What is Amazon Bedrock in one sentence?"}]}' | base64 -w0 | python3 -c 'import sys,base64;sys.stdout.buffer.write(base64.b64decode(sys.stdin.read()))')" "$WORK_DIR/response.json" 2>&1)
python3 -c "import json;r=json.load(open('$WORK_DIR/response.json'));print(f\"  Model: {r.get('model','?')}\\n  Response: {r['content'][0]['text']}\")" 2>/dev/null || echo "  Model invocation failed (check model access)"
echo "Step 4: Listing custom models"
aws bedrock list-custom-models --query 'modelSummaries[:3].{Name:modelName,Base:baseModelId}' --output table 2>/dev/null || echo "  No custom models"
echo "Step 5: Listing model invocation logs"
aws bedrock get-model-invocation-logging-configuration --query 'loggingConfig' --output table 2>/dev/null || echo "  No logging configured"
echo ""
echo "Tutorial complete. No resources were created."
rm -rf "$WORK_DIR"
