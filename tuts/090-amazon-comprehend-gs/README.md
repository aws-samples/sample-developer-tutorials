# Comprehend: Detect sentiment, entities, and key phrases

Analyze text using Amazon Comprehend's real-time APIs for language detection, sentiment analysis, entity recognition, key phrase extraction, and PII detection.

## Source

https://docs.aws.amazon.com/comprehend/latest/dg/get-started-api.html

## Use case

- ID: comprehend/getting-started
- Phase: create
- Complexity: beginner
- Core actions: comprehend:DetectSentiment, comprehend:DetectEntities, comprehend:DetectKeyPhrases

## What it does

1. Detects the dominant language of sample text
2. Analyzes sentiment (positive, negative, neutral, mixed)
3. Extracts named entities (people, organizations, dates)
4. Extracts key phrases
5. Detects PII entities (names, emails, phone numbers)

## Running

```bash
bash amazon-comprehend-gs.sh
```

## Resources created

None. Comprehend is a stateless API.

## Estimated time

- Run: ~5 seconds

## Cost

Comprehend pricing is per unit (100 characters). This tutorial analyzes ~500 characters, costing less than $0.01.

## Related docs

- [Real-time analysis with Amazon Comprehend](https://docs.aws.amazon.com/comprehend/latest/dg/get-started-api.html)
- [Sentiment analysis](https://docs.aws.amazon.com/comprehend/latest/dg/how-sentiment.html)
- [Entity recognition](https://docs.aws.amazon.com/comprehend/latest/dg/how-entities.html)
- [PII detection](https://docs.aws.amazon.com/comprehend/latest/dg/how-pii.html)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | New, 57 lines |
| Script test result | EXIT 0, 5s, 5 steps, stateless API |
| Issues encountered | None — stateless API, no resource management needed |
| Iterations | v1 (direct to publish) |
