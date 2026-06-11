#!/bin/bash
# Tutorial: Synthesize speech from text with Amazon Polly
# Source: https://docs.aws.amazon.com/polly/latest/dg/getting-started-cli.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/polly-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

# Step 1: List available voices
echo "Step 1: Listing available English voices"
aws polly describe-voices --language-code en-US \
    --query 'Voices[:5].{Name:Name,Gender:Gender,Engine:SupportedEngines[0]}' --output table

# Step 2: Synthesize speech (standard engine)
echo "Step 2: Synthesizing speech with standard engine"
aws polly synthesize-speech \
    --text "Hello! This is Amazon Polly synthesizing speech from text." \
    --output-format mp3 \
    --voice-id Joanna \
    "$WORK_DIR/standard.mp3" > /dev/null
echo "  Output: standard.mp3 ($(wc -c < "$WORK_DIR/standard.mp3" > /dev/null) bytes)"

# Step 3: Synthesize with neural engine
echo "Step 3: Synthesizing speech with neural engine"
aws polly synthesize-speech \
    --text "This is the neural engine. It sounds more natural and expressive." \
    --output-format mp3 \
    --voice-id Joanna \
    --engine neural \
    "$WORK_DIR/neural.mp3" > /dev/null
echo "  Output: neural.mp3 ($(wc -c < "$WORK_DIR/neural.mp3" > /dev/null) bytes)"

# Step 4: Synthesize with SSML
echo "Step 4: Synthesizing with SSML markup"
aws polly synthesize-speech \
    --text-type ssml \
    --text '<speak>Welcome to <emphasis level="strong">Amazon Polly</emphasis>. <break time="500ms"/> You can control <prosody rate="slow">speech rate</prosody> and <prosody pitch="high">pitch</prosody>.</speak>' \
    --output-format mp3 \
    --voice-id Joanna \
    "$WORK_DIR/ssml.mp3" > /dev/null
echo "  Output: ssml.mp3 ($(wc -c < "$WORK_DIR/ssml.mp3" > /dev/null) bytes)"

# Step 5: List available languages
echo "Step 5: Available languages (first 10)"
aws polly describe-voices --query 'Voices[].LanguageName' --output text | tr '\t' '\n' | sort -u | head -10

# Step 6: Synthesize in another language
echo "Step 6: Synthesizing in Spanish"
aws polly synthesize-speech \
    --text "Hola, esto es Amazon Polly hablando en español." \
    --output-format mp3 \
    --voice-id Lucia \
    "$WORK_DIR/spanish.mp3" > /dev/null
echo "  Output: spanish.mp3 ($(wc -c < "$WORK_DIR/spanish.mp3" > /dev/null) bytes)"

echo ""
echo "Tutorial complete. Audio files saved to $WORK_DIR/"
echo "No AWS resources were created — Polly is a stateless API."
ls -lh "$WORK_DIR"/*.mp3
rm -rf "$WORK_DIR"
