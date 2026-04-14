# Transcribe: Transcribe audio to text

## Source

https://docs.aws.amazon.com/transcribe/latest/dg/getting-started.html

## Use case

- **ID**: transcribe/getting-started
- **Level**: beginner
- **Core actions**: `transcribe:StartTranscriptionJob`

## Steps

1. Create a sample audio file (WAV with silence)
2. Upload to S3
3. Start a transcription job
4. Wait for completion
5. Get results
6. List transcription jobs

## Resources created

| Resource | Type |
|----------|------|
| `transcribe-tut-<random>` | S3 bucket |
| `tut-job-<random>` | Transcription job |

## Cost

Transcribe pricing is per second of audio transcribed. This tutorial transcribes 1 second, costing a fraction of a cent.

## Duration

~16 seconds

## Related docs

- [Getting started with Amazon Transcribe](https://docs.aws.amazon.com/transcribe/latest/dg/getting-started.html)
- [Amazon Transcribe API reference](https://docs.aws.amazon.com/transcribe/latest/APIReference/Welcome.html)
- [Supported languages](https://docs.aws.amazon.com/transcribe/latest/dg/supported-languages.html)
- [Amazon Transcribe pricing](https://aws.amazon.com/transcribe/pricing/)

---

## Appendix: Generation details

| Field | Value |
|-------|-------|
| Generation date | 2026-04-14 |
| Source script | New, 106 lines |
| Script test result | EXIT 0, 16s, 6 steps, no issues |
| Issues encountered | None |
| Iterations | v1 |
