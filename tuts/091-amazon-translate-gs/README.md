# Translate: Translate text between languages

Translate text between languages using Amazon Translate, with auto-detection of the source language.

## Source

https://docs.aws.amazon.com/translate/latest/dg/get-started.html

## Use case

- ID: translate/getting-started
- Phase: create
- Complexity: beginner
- Core actions: translate:TranslateText, translate:ListLanguages

## What it does

1. Translates English text to Spanish
2. Translates English text to French
3. Translates English text to Japanese
4. Auto-detects source language (German → English)
5. Lists supported languages

## Running

```bash
bash amazon-translate-gs.sh
```

## Resources created

None. Translate is a stateless API.

## Estimated time

- Run: ~5 seconds

## Cost

Translate pricing is per character. This tutorial translates ~600 characters, costing less than $0.01.

## Related docs

- [Getting started with Amazon Translate](https://docs.aws.amazon.com/translate/latest/dg/get-started.html)
- [Translating text using the API](https://docs.aws.amazon.com/translate/latest/dg/get-started-api.html)
- [Supported languages](https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html)
- [Automatic source language detection](https://docs.aws.amazon.com/translate/latest/dg/auto-detect.html)
