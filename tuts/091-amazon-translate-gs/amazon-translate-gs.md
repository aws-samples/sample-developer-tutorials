# Translate text between languages with Amazon Translate

This tutorial shows you how to use Amazon Translate to translate text between languages, auto-detect the source language, and list supported languages.

## Prerequisites

- AWS CLI configured with credentials and a default region
- Permissions to call Amazon Translate APIs

## Step 1: Translate English to Spanish

```bash
aws translate translate-text \
    --text "Your text here" \
    --source-language-code en --target-language-code es \
    --query 'TranslatedText' --output text
```

## Step 2: Translate English to French

```bash
aws translate translate-text \
    --text "Your text here" \
    --source-language-code en --target-language-code fr \
    --query 'TranslatedText' --output text
```

## Step 3: Translate English to Japanese

```bash
aws translate translate-text \
    --text "Your text here" \
    --source-language-code en --target-language-code ja \
    --query 'TranslatedText' --output text
```

## Step 4: Auto-detect source language

Use `auto` as the source language code to let Translate detect the language:

```bash
aws translate translate-text \
    --text "Amazon Translate ist ein neuronaler maschineller Übersetzungsdienst." \
    --source-language-code auto --target-language-code en \
    --query '{Translation:TranslatedText,DetectedLanguage:SourceLanguageCode}' --output table
```

## Step 5: List supported languages

```bash
aws translate list-languages \
    --query 'Languages[:10].{Name:LanguageName,Code:LanguageCode}' --output table
```

## Cleanup

No cleanup needed. Translate is a stateless API — no resources are created.

The script automates all steps:

```bash
bash amazon-translate-gs.sh
```
