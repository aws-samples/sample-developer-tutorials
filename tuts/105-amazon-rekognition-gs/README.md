# Rekognition: Detect labels in images

## Source

https://docs.aws.amazon.com/rekognition/latest/dg/getting-started.html

## Use case

- **ID**: rekognition/getting-started
- **Level**: beginner
- **Core actions**: `rekognition:DetectLabels`, `rekognition:DetectText`

## Steps

1. Create a sample gradient PNG image
2. Upload the image to S3
3. Detect labels in the image
4. Detect labels from local bytes
5. Detect text in the image
6. Detect image properties

## Resources created

| Resource | Type |
|----------|------|
| `rekognition-tut-<random>-<account>` | S3 bucket |

## Cost

Rekognition pricing is per image analyzed. This tutorial analyzes ~4 images, costing less than $0.01.

## Duration

~10 seconds

## Related docs

- [Getting started with Amazon Rekognition](https://docs.aws.amazon.com/rekognition/latest/dg/getting-started.html)
- [Detecting labels](https://docs.aws.amazon.com/rekognition/latest/dg/labels-detect-labels-image.html)
- [Detecting text](https://docs.aws.amazon.com/rekognition/latest/dg/text-detecting-text-procedure.html)
- [Image properties](https://docs.aws.amazon.com/rekognition/latest/dg/image-properties.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 107 |
| Exit code | 0 |
| Runtime | 10s |
| Steps | 6 |
| Issues | None |
| Version | v1 |
