# Detect sentiment, entities, and key phrases with Amazon Comprehend

This tutorial shows you how to use the Amazon Comprehend real-time analysis APIs to detect the dominant language, sentiment, entities, key phrases, and PII in text.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions to call Amazon Comprehend APIs

## Step 1: Detect the dominant language

```bash
aws comprehend detect-dominant-language --text "Amazon Web Services provides cloud computing services that help businesses scale and innovate faster. Customers love the reliability and breadth of services available." \
    --query 'Languages[0].{Language:LanguageCode,Confidence:Score}' --output table
```

## Step 2: Detect sentiment

```bash
aws comprehend detect-sentiment --text "Amazon Web Services provides cloud computing services that help businesses scale and innovate faster. Customers love the reliability and breadth of services available." --language-code en \
    --query '{Sentiment:Sentiment,Positive:SentimentScore.Positive,Negative:SentimentScore.Negative}' --output table
```

## Step 3: Detect entities

Identifies people, places, organizations, dates, and other entity types.

```bash
aws comprehend detect-entities --text "Amazon Web Services provides cloud computing services that help businesses scale and innovate faster. Customers love the reliability and breadth of services available." --language-code en \
    --query 'Entities[].{Text:Text,Type:Type,Score:Score}' --output table
```

## Step 4: Detect key phrases

```bash
aws comprehend detect-key-phrases --text "Amazon Web Services provides cloud computing services that help businesses scale and innovate faster. Customers love the reliability and breadth of services available." --language-code en \
    --query 'KeyPhrases[].{Text:Text,Score:Score}' --output table
```

## Step 5: Detect PII entities

Identifies personally identifiable information such as names, email addresses, phone numbers, and account numbers.

```bash
aws comprehend detect-pii-entities --text "Contact Jane at jane@example.com" --language-code en \
    --query 'Entities[].{Type:Type,Score:Score}' --output table
```

## Cleanup

No cleanup needed. Comprehend is a stateless API — no resources are created.

The script automates all steps:

```bash
bash amazon-comprehend-gs.sh
```
