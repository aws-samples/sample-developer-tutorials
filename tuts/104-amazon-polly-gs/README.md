# Polly: Synthesize speech from text

## Source

https://docs.aws.amazon.com/polly/latest/dg/getting-started-cli.html

## Use case

- **ID**: polly/getting-started
- **Level**: beginner
- **Core actions**: `polly:DescribeVoices`, `polly:SynthesizeSpeech`

## Steps

1. List available English voices
2. Synthesize speech with the standard engine
3. Synthesize speech with the neural engine
4. Synthesize with SSML markup
5. List available languages
6. Synthesize in Spanish

## Resources created

None. Polly is a stateless API.

## Cost

Polly pricing is per character. This tutorial synthesizes ~300 characters, costing less than $0.01.

## Duration

~5 seconds

## Related docs

- [Getting started with Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/getting-started-cli.html)
- [Voices in Amazon Polly](https://docs.aws.amazon.com/polly/latest/dg/voicelist.html)
- [Using SSML](https://docs.aws.amazon.com/polly/latest/dg/ssml.html)
- [Supported languages](https://docs.aws.amazon.com/polly/latest/dg/SupportedLanguage.html)

---

## Appendix

| Field | Value |
|-------|-------|
| Date | 2026-04-14 |
| Script lines | 68 |
| Exit code | 0 |
| Runtime | 5s |
| Steps | 6 |
| Issues | None |
| Version | v1 |
