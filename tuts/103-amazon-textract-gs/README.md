# Textract: Extract text from documents

## Source

https://docs.aws.amazon.com/textract/latest/dg/getting-started.html

## Use case

- **ID**: textract/getting-started
- **Level**: beginner
- **Core actions**: `textract:DetectDocumentText`, `textract:AnalyzeDocument`

## Steps

1. Create a sample PNG image
2. Upload the document to S3
3. Detect text in the document
4. Analyze document for forms and tables
5. Detect text from local file bytes

## Resources created

| Resource | Type |
|----------|------|
| S3 bucket | `AWS::S3::Bucket` |

## Duration

~10 seconds

## Cost

Textract charges per page analyzed. `DetectDocumentText` costs $1.50 per 1,000 pages; `AnalyzeDocument` costs $50 per 1,000 pages for forms and $15 per 1,000 pages for tables. This tutorial analyzes one page, costing less than $0.01. The S3 bucket is deleted during cleanup.

## Related docs

- [Getting started with Amazon Textract](https://docs.aws.amazon.com/textract/latest/dg/getting-started.html)
- [Detecting text](https://docs.aws.amazon.com/textract/latest/dg/detecting-document-text.html)
- [Analyzing documents](https://docs.aws.amazon.com/textract/latest/dg/analyzing-document-text.html)
- [Amazon Textract quotas](https://docs.aws.amazon.com/textract/latest/dg/limits.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 100 |
| Exit code | 0 |
| Runtime | 10s |
| Steps | 5 |
| Issues | Fixed duplicate python block |
| Version | v1 |
